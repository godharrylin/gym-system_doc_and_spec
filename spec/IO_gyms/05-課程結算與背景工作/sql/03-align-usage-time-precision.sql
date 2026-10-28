-- Approved scope: only usage_dt and recorded_at; preserve nullable columns and rows.
-- Applied to development GymDB on 2026-10-25 after Database.md review and user approval.
-- Verified before/after commit: one row preserved at millisecond precision,
-- other columns and indexes/constraints unchanged. No rebuild or backfill.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'GymDB'
    THROW 51043, 'Expected GymDB. No changes applied.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF (SELECT COUNT(*) FROM sys.columns
        WHERE object_id=OBJECT_ID(N'dbo.sdt_ticket_usage_log')
          AND name IN (N'usage_dt', N'recorded_at')
          AND system_type_id=61 AND is_nullable=1) <> 2
        THROW 51044, 'Expected two nullable datetime columns. Inspect schema before applying.', 1;

    ALTER TABLE dbo.sdt_ticket_usage_log
        ALTER COLUMN usage_dt DATETIME2(3) NULL;

    ALTER TABLE dbo.sdt_ticket_usage_log
        ALTER COLUMN recorded_at DATETIME2(3) NULL;

    IF (SELECT COUNT(*) FROM sys.columns
        WHERE object_id=OBJECT_ID(N'dbo.sdt_ticket_usage_log')
          AND name IN (N'usage_dt', N'recorded_at')
          AND system_type_id=42 AND scale=3 AND is_nullable=1) <> 2
        THROW 51045, 'Time precision verification failed.', 1;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
