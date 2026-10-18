-- Applied to development GymDB on 2026-10-17 after user approval; metadata rechecked after commit.
-- Additive/data-preserving migration for existing GymDB. Inspect schema before applying elsewhere.
-- Never invent historical timestamps, delete invalid rows, or convert timezones in bulk.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

IF DB_NAME() <> N'GymDB'
    THROW 51010, 'Expected GymDB. No changes applied.', 1;
IF OBJECT_ID(N'dbo.sdt_att_record', N'U') IS NULL
    THROW 51011, 'Existing sdt_att_record required. Review its actual schema.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Stabilize the preflight and migration against concurrent writers.
    DECLARE @rowCount BIGINT;
    SELECT @rowCount = COUNT_BIG(*) FROM dbo.sdt_att_record WITH (TABLOCKX, HOLDLOCK);
    IF EXISTS (SELECT 1 FROM dbo.sdt_att_record
               WHERE user_id IS NULL OR cls_scdle_arnge_sn IS NULL
                  OR sdt_att_record_status IS NULL OR sdt_att_record_upd_date IS NULL)
        THROW 51012, 'Attendance has NULL required fields. Manual data review required.', 1;
    IF EXISTS (SELECT 1 FROM dbo.sdt_att_record
               GROUP BY user_id, cls_scdle_arnge_sn HAVING COUNT_BIG(*) > 1)
        THROW 51013, 'Duplicate student/session attendance. Manual data review required.', 1;
    IF EXISTS (SELECT 1 FROM dbo.sdt_att_record
               WHERE sdt_att_record_status NOT IN ('Pending', 'CheckIn', 'CheckOut', 'Cancelled', 'NeedsReview'))
        THROW 51017, 'Unrecognized attendance state. Manual data review required.', 1;
    IF EXISTS (SELECT 1 FROM dbo.sdt_att_record a
               WHERE NOT EXISTS (SELECT 1 FROM dbo.sdt_profile s WHERE s.usr_id = a.user_id)
                  OR NOT EXISTS (SELECT 1 FROM dbo.cls_scdle_arnge c WHERE c.cls_scdle_arnge_sn = a.cls_scdle_arnge_sn))
        THROW 51014, 'Orphan attendance. No rows will be deleted by this script.', 1;
    IF COL_LENGTH(N'dbo.sdt_att_record', N'sdt_att_record_create_dt') IS NULL AND @rowCount > 0
        THROW 51015, 'Existing rows have no proven creation timestamp. Confirm backfill policy first.', 1;

    IF COL_LENGTH(N'dbo.sdt_att_record', N'sdt_att_record_create_dt') IS NULL
        EXEC(N'ALTER TABLE dbo.sdt_att_record ADD sdt_att_record_create_dt DATETIME2(3) NOT NULL;');
    IF COL_LENGTH(N'dbo.sdt_att_record', N'sdt_att_record_ticket_eligibility_state') IS NULL
        EXEC(N'ALTER TABLE dbo.sdt_att_record ADD sdt_att_record_ticket_eligibility_state VARCHAR(20) NULL;');

    EXEC(N'IF EXISTS (SELECT 1 FROM dbo.sdt_att_record WHERE sdt_att_record_create_dt IS NULL)
        THROW 51016, ''Creation timestamps need manual review.'', 1;');
    EXEC(N'ALTER TABLE dbo.sdt_att_record ALTER COLUMN sdt_att_record_create_dt DATETIME2(3) NOT NULL;');

    ALTER TABLE dbo.sdt_att_record ALTER COLUMN user_id NVARCHAR(50) NOT NULL;
    ALTER TABLE dbo.sdt_att_record ALTER COLUMN cls_scdle_arnge_sn INT NOT NULL;
    ALTER TABLE dbo.sdt_att_record ALTER COLUMN sdt_att_record_status NVARCHAR(20) NOT NULL;
    ALTER TABLE dbo.sdt_att_record ALTER COLUMN sdt_att_record_chk_in_time DATETIME2(3) NULL;
    ALTER TABLE dbo.sdt_att_record ALTER COLUMN sdt_att_record_chk_out_time DATETIME2(3) NULL;
    ALTER TABLE dbo.sdt_att_record ALTER COLUMN sdt_att_record_upd_date DATETIME2(3) NOT NULL;

    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE object_id = OBJECT_ID(N'dbo.sdt_att_record')
                     AND name = N'UQ_sdt_att_record_user_session')
        CREATE UNIQUE INDEX UQ_sdt_att_record_user_session
            ON dbo.sdt_att_record (user_id, cls_scdle_arnge_sn);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes
                   WHERE object_id = OBJECT_ID(N'dbo.sdt_att_record')
                     AND name = N'IX_sdt_att_record_session_status')
        CREATE INDEX IX_sdt_att_record_session_status
            ON dbo.sdt_att_record (cls_scdle_arnge_sn, sdt_att_record_status, user_id);

    -- No FK, rowversion, new CHECK, data cleanup, or inferred eligibility backfill.
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
