-- Additive only: preserve existing columns and records. No inference/backfill of old passage facts.
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
IF DB_NAME() <> N'GymDB' THROW 51000, 'Expected GymDB. No changes applied.', 1;
IF OBJECT_ID('dbo.device_record', 'U') IS NULL THROW 51003, 'Existing device_record table required.', 1;
BEGIN TRY
    BEGIN TRANSACTION;
    IF COL_LENGTH('dbo.device_record','request_id') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD request_id UNIQUEIDENTIFIER NULL;');
    IF COL_LENGTH('dbo.device_record','gate_station_sn') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD gate_station_sn INT NULL;');
    IF COL_LENGTH('dbo.device_record','gate_device_session_id') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD gate_device_session_id UNIQUEIDENTIFIER NULL;');
    IF COL_LENGTH('dbo.device_record','operator_id') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD operator_id NVARCHAR(50) NULL;');
    IF COL_LENGTH('dbo.device_record','identity_kind') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD identity_kind VARCHAR(20) NULL;');
    IF COL_LENGTH('dbo.device_record','role_snapshot') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD role_snapshot NVARCHAR(1000) NULL;');
    IF COL_LENGTH('dbo.device_record','operation_kind') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD operation_kind VARCHAR(30) NULL;');
    IF COL_LENGTH('dbo.device_record','outcome') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD outcome VARCHAR(20) NULL;');
    IF COL_LENGTH('dbo.device_record','result_code') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD result_code VARCHAR(80) NULL;');
    IF COL_LENGTH('dbo.device_record','requested_at') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD requested_at DATETIME2(3) NULL;');
    IF COL_LENGTH('dbo.device_record','responded_at') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD responded_at DATETIME2(3) NULL;');
    IF COL_LENGTH('dbo.device_record','completed_at') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD completed_at DATETIME2(3) NULL;');
    IF COL_LENGTH('dbo.device_record','remark') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD remark NVARCHAR(500) NULL;');
    IF COL_LENGTH('dbo.device_record','affects_presence') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD affects_presence BIT NULL;');
    IF COL_LENGTH('dbo.device_record','is_simulated') IS NULL
        EXEC(N'ALTER TABLE dbo.device_record ADD is_simulated BIT NULL;');

    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_device_record_outcome'
        AND parent_object_id=OBJECT_ID('dbo.device_record'))
        EXEC(N'ALTER TABLE dbo.device_record WITH CHECK ADD CONSTRAINT CK_device_record_outcome CHECK
            (outcome IS NULL OR outcome IN (''Requested'',''Dispatched'',''Succeeded'',''Failed'',''Unknown'',''Denied''));');
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_device_record_roles'
        AND parent_object_id=OBJECT_ID('dbo.device_record'))
        EXEC(N'ALTER TABLE dbo.device_record WITH CHECK ADD CONSTRAINT CK_device_record_roles CHECK
            (role_snapshot IS NULL OR ISJSON(role_snapshot)=1);');
    IF NOT EXISTS (SELECT 1 FROM sys.check_constraints WHERE name='CK_device_record_presence'
        AND parent_object_id=OBJECT_ID('dbo.device_record'))
        EXEC(N'ALTER TABLE dbo.device_record WITH CHECK ADD CONSTRAINT CK_device_record_presence CHECK
            (affects_presence IS NULL OR affects_presence=0 OR
             (outcome IS NOT NULL AND outcome=''Succeeded'' AND responded_at IS NOT NULL
              AND usr_id IS NOT NULL AND direction IS NOT NULL AND direction IN (1,2)
              AND is_success IS NOT NULL AND is_success=1));');
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.device_record') AND name='UX_device_record_request_id')
        EXEC(N'CREATE UNIQUE INDEX UX_device_record_request_id ON dbo.device_record(request_id) WHERE request_id IS NOT NULL;');
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.device_record') AND name='IX_device_record_user_response')
        EXEC(N'CREATE INDEX IX_device_record_user_response ON dbo.device_record(usr_id,responded_at,device_record_sn)
            INCLUDE(direction,outcome,affects_presence);');
    COMMIT;
    SELECT N'Device record extension ready; legacy records unchanged.' AS result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
