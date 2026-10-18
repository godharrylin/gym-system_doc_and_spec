-- Applied to development GymDB on 2026-10-17 after preview and verification.
-- Other environments require deployment. Preserve old events; do not infer/backfill historical class context.
-- No new table, foreign key, CHECK constraint, rowversion, or default values.
SET NOCOUNT ON;
SET XACT_ABORT ON;

IF DB_NAME() <> N'GymDB'
    THROW 51030, 'Expected GymDB. No changes applied.', 1;
IF OBJECT_ID(N'dbo.device_record', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sdt_att_record', N'U') IS NULL
   OR OBJECT_ID(N'dbo.sdt_ticket_credit_reservation', N'U') IS NULL
    THROW 51031, 'Gate, attendance and reservation tables are required.', 1;
IF EXISTS (
    SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID(N'dbo.device_record')
    AND name IN ('attendance_sn','reservation_sn','admission_kind','created_pending','created_reservation')
)
    THROW 51032, 'Admission context columns already exist. Inspect schema instead of overwriting.', 1;

BEGIN TRY
    BEGIN TRANSACTION;
    ALTER TABLE dbo.device_record ADD
        attendance_sn INT NULL,
        reservation_sn BIGINT NULL,
        admission_kind VARCHAR(20) NULL,
        created_pending BIT NULL,
        created_reservation BIT NULL;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
