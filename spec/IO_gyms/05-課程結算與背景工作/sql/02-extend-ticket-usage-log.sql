-- Applied to development GymDB on 2026-10-25 after user confirmation.
-- Verified before commit: original data, column definitions and defenses unchanged.
-- Post-commit: 13 columns; original one usage row preserved; no backfill.
-- Read-only GymDB inspection on 2026-10-25 confirmed the original eight columns,
-- an identity usage_sn primary key, and one existing row. Preserve all old values.
-- No new FK, CHECK, unique index, idempotency_key, rowversion, default or backfill.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'GymDB'
    THROW 51040, 'Expected GymDB. No changes applied.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.sdt_ticket_usage_log', N'U') IS NULL
        THROW 51041, 'Usage table is missing. Inspect schema before applying.', 1;

    -- Do not silently accept a partially applied or differently defined schema.
    IF EXISTS (
        SELECT 1 FROM sys.columns
        WHERE object_id = OBJECT_ID(N'dbo.sdt_ticket_usage_log')
          AND name IN (N'attendance_sn', N'usage_action', N'credits_before_snapshot',
                       N'recorded_at', N'reversed_usage_sn')
    )
        THROW 51042, 'Proposed usage columns already exist. Review schema instead of reapplying.', 1;

    ALTER TABLE dbo.sdt_ticket_usage_log ADD
        attendance_sn INT NULL,
        usage_action VARCHAR(20) NULL,
        credits_before_snapshot INT NULL,
        recorded_at DATETIME NULL,
        reversed_usage_sn INT NULL;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

-- Metadata verification only; no member or usage values are returned.
SELECT c.name, TYPE_NAME(c.user_type_id) AS sql_type, c.max_length, c.is_nullable
FROM sys.columns c
WHERE c.object_id = OBJECT_ID(N'dbo.sdt_ticket_usage_log')
  AND c.name IN (N'attendance_sn', N'usage_action', N'credits_before_snapshot',
                 N'recorded_at', N'reversed_usage_sn')
ORDER BY c.column_id;
