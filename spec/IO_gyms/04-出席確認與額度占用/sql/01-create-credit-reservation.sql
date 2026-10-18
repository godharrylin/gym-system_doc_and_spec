-- Applied to development GymDB on 2026-10-17; metadata rechecked after commit.
-- No foreign keys, rowversion, CHECK constraints, or existing-data changes.
-- All 10 reservation CHECK rules are enforced by CreditReservationData.Validate in code.
-- Keep primary key and unique indexes as concurrency/idempotency safeguards.
-- The attendance-table migration and processing-job tables are separate prerequisites.
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
    THROW 51000, 'Expected GymDB. No changes applied.', 1;
IF OBJECT_ID(N'dbo.sdt_ticket_credit_reservation') IS NOT NULL
    THROW 51001, 'Reservation object already exists. Inspect its schema before migration.', 1;
IF OBJECT_ID(N'dbo.sdt_att_record', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sdt_ticket_pass', N'U') IS NULL
    THROW 51002, 'Existing attendance and ticket pass tables are required.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    CREATE TABLE dbo.sdt_ticket_credit_reservation
    (
        reservation_sn BIGINT IDENTITY(1,1) NOT NULL,
        attendance_sn INT NOT NULL,
        pass_sn INT NOT NULL,
        reserved_credits INT NOT NULL,
        reservation_state VARCHAR(20) NOT NULL,
        review_from_state VARCHAR(20) NULL,
        idempotency_key VARCHAR(160) NOT NULL,
        gate_request_id UNIQUEIDENTIFIER NULL,
        processing_item_sn BIGINT NULL,
        previous_reservation_sn BIGINT NULL,
        usage_sn INT NULL,
        created_at DATETIME2(3) NOT NULL,
        fixed_at DATETIME2(3) NULL,
        released_at DATETIME2(3) NULL,
        consumed_at DATETIME2(3) NULL,
        updated_at DATETIME2(3) NOT NULL,
        reason_code VARCHAR(60) NULL,
        reason_message NVARCHAR(1000) NULL,

        CONSTRAINT PK_sdt_ticket_credit_reservation PRIMARY KEY (reservation_sn),
        CONSTRAINT UQ_sdt_ticket_credit_reservation_key UNIQUE (idempotency_key)
    );

    -- One effective credit hold per attendance, including holds awaiting review.
    CREATE UNIQUE INDEX UX_sdt_credit_reservation_live_attendance
        ON dbo.sdt_ticket_credit_reservation (attendance_sn)
        WHERE reservation_state IN ('Reserved', 'Fixed', 'NeedsReview');

    CREATE INDEX IX_sdt_credit_reservation_pass_state
        ON dbo.sdt_ticket_credit_reservation (pass_sn, reservation_state)
        INCLUDE (attendance_sn, reserved_credits);

    CREATE INDEX IX_sdt_credit_reservation_attendance_history
        ON dbo.sdt_ticket_credit_reservation (attendance_sn, reservation_sn);

    CREATE UNIQUE INDEX UX_sdt_credit_reservation_usage
        ON dbo.sdt_ticket_credit_reservation (usage_sn)
        WHERE usage_sn IS NOT NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
