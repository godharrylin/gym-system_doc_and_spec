-- Applied to development GymDB on 2026-10-17 after user approval; metadata rechecked after commit.
-- Matches the two approved working-table definitions in Database.md. Inspect schema before applying elsewhere.
-- No foreign keys or rowversion. Reservation CHECK removal does not change these tables.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;

IF DB_NAME() <> N'GymDB'
    THROW 51020, 'Expected GymDB. No changes applied.', 1;
IF OBJECT_ID(N'dbo.class_processing_job') IS NOT NULL
   OR OBJECT_ID(N'dbo.class_processing_item') IS NOT NULL
    THROW 51021, 'Working-table objects already exist. Review schema instead of recreating.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.class_processing_job
    (
        job_sn BIGINT IDENTITY(1,1) NOT NULL,
        cls_scdle_arnge_sn INT NOT NULL,
        phase VARCHAR(1) NOT NULL,
        processing_state VARCHAR(20) NOT NULL,
        class_start_at DATETIME2(3) NOT NULL,
        class_end_at DATETIME2(3) NOT NULL,
        instructor_id NVARCHAR(50) NOT NULL,
        scheduled_at DATETIME2(3) NOT NULL,
        processing_attempts INT NOT NULL
            CONSTRAINT DF_class_processing_job_attempts DEFAULT (0),
        next_attempt_at DATETIME2(3) NULL,
        lease_owner NVARCHAR(100) NULL,
        lease_token UNIQUEIDENTIFIER NULL,
        lease_expires_at DATETIME2(3) NULL,
        first_started_at DATETIME2(3) NULL,
        last_started_at DATETIME2(3) NULL,
        completed_at DATETIME2(3) NULL,
        last_error_code VARCHAR(60) NULL,
        last_error_message NVARCHAR(1000) NULL,
        created_at DATETIME2(3) NOT NULL,
        updated_at DATETIME2(3) NOT NULL,

        CONSTRAINT PK_class_processing_job PRIMARY KEY (job_sn),
        CONSTRAINT UQ_class_processing_job_session_phase
            UNIQUE (cls_scdle_arnge_sn, phase),
        CONSTRAINT CK_class_processing_job_phase CHECK (phase IN ('A', 'B')),
        CONSTRAINT CK_class_processing_job_state
            CHECK (processing_state IN
                   ('Pending', 'Running', 'Waiting', 'NeedsReview', 'Failed', 'Completed', 'Cancelled')),
        CONSTRAINT CK_class_processing_job_attempts CHECK (processing_attempts >= 0),
        CONSTRAINT CK_class_processing_job_schedule
            CHECK (class_end_at > class_start_at
                   AND ((phase = 'A' AND scheduled_at = DATEADD(MINUTE, 10, class_start_at))
                     OR (phase = 'B' AND scheduled_at = DATEADD(MINUTE, 10, class_end_at)))),
        CONSTRAINT CK_class_processing_job_lease
            CHECK ((processing_state = 'Running' AND lease_owner IS NOT NULL
                    AND lease_token IS NOT NULL AND lease_expires_at IS NOT NULL)
                OR (processing_state <> 'Running' AND lease_owner IS NULL
                    AND lease_token IS NULL AND lease_expires_at IS NULL)),
        CONSTRAINT CK_class_processing_job_completed
            CHECK ((processing_state = 'Completed' AND completed_at IS NOT NULL)
                OR (processing_state <> 'Completed' AND completed_at IS NULL))
    );
    CREATE INDEX IX_class_processing_job_due
        ON dbo.class_processing_job (processing_state, scheduled_at, job_sn)
        INCLUDE (next_attempt_at, lease_expires_at, cls_scdle_arnge_sn, phase);
    CREATE TABLE dbo.class_processing_item
    (
        item_sn BIGINT IDENTITY(1,1) NOT NULL,
        job_sn BIGINT NOT NULL,
        user_id NVARCHAR(50) NOT NULL,
        attendance_sn INT NULL,
        processing_state VARCHAR(20) NOT NULL,
        blocked_by_item_sn BIGINT NULL,
        processing_attempts INT NOT NULL
            CONSTRAINT DF_class_processing_item_attempts DEFAULT (0),
        next_attempt_at DATETIME2(3) NULL,
        first_started_at DATETIME2(3) NULL,
        last_started_at DATETIME2(3) NULL,
        completed_at DATETIME2(3) NULL,
        result_code VARCHAR(60) NULL,
        result_message NVARCHAR(1000) NULL,
        created_at DATETIME2(3) NOT NULL,
        updated_at DATETIME2(3) NOT NULL,

        CONSTRAINT PK_class_processing_item PRIMARY KEY (item_sn),
        CONSTRAINT UQ_class_processing_item_job_user UNIQUE (job_sn, user_id),
        CONSTRAINT CK_class_processing_item_state
            CHECK (processing_state IN
                   ('Pending', 'Running', 'Blocked', 'NeedsReview', 'Failed', 'Completed', 'Skipped')),
        CONSTRAINT CK_class_processing_item_attempts CHECK (processing_attempts >= 0),
        CONSTRAINT CK_class_processing_item_blocked
            CHECK ((processing_state = 'Blocked' AND blocked_by_item_sn IS NOT NULL)
                OR (processing_state <> 'Blocked' AND blocked_by_item_sn IS NULL)),
        CONSTRAINT CK_class_processing_item_no_self_block
            CHECK (blocked_by_item_sn IS NULL OR blocked_by_item_sn <> item_sn),
        CONSTRAINT CK_class_processing_item_completed
            CHECK ((processing_state IN ('Completed', 'Skipped') AND completed_at IS NOT NULL)
                OR (processing_state NOT IN ('Completed', 'Skipped') AND completed_at IS NULL)),
        CONSTRAINT CK_class_processing_item_skip_reason
            CHECK (processing_state <> 'Skipped'
                   OR (result_code IS NOT NULL AND result_message IS NOT NULL
                       AND LEN(LTRIM(RTRIM(result_message))) > 0))
    );
    CREATE INDEX IX_class_processing_item_job_state
        ON dbo.class_processing_item (job_sn, processing_state, item_sn)
        INCLUDE (user_id, attendance_sn, next_attempt_at);
    CREATE INDEX IX_class_processing_item_student_state
        ON dbo.class_processing_item (user_id, processing_state, job_sn)
        INCLUDE (attendance_sn, blocked_by_item_sn);
    CREATE INDEX IX_class_processing_item_blocked_by
        ON dbo.class_processing_item (blocked_by_item_sn, item_sn)
        WHERE blocked_by_item_sn IS NOT NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
