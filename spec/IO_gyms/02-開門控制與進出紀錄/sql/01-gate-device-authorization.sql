-- Stage 02: explicitly approved station/session tables. No users, passes or attendance changes.
-- Run with sqlcmd -b against the intended development GymDB after reviewing this file.
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

BEGIN TRY
    BEGIN TRANSACTION;
    IF OBJECT_ID('dbo.gate_station', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.gate_station
        (
            gate_station_sn INT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gate_station PRIMARY KEY,
            gate_station_code VARCHAR(30) NOT NULL CONSTRAINT UQ_gate_station_code UNIQUE,
            gate_station_name NVARCHAR(50) NOT NULL,
            gate_station_direction TINYINT NOT NULL,
            gate_station_is_active BIT NOT NULL,
            gate_station_current_session_id UNIQUEIDENTIFIER NULL,
            gate_station_create_dt DATETIME2(3) NOT NULL,
            gate_station_up_dt DATETIME2(3) NULL,
            CONSTRAINT CK_gate_station_direction CHECK (gate_station_direction IN (1,2))
        );
    END;

    IF OBJECT_ID('dbo.gate_device_session', 'U') IS NULL
    BEGIN
        CREATE TABLE dbo.gate_device_session
        (
            gate_device_session_sn BIGINT IDENTITY(1,1) NOT NULL CONSTRAINT PK_gate_device_session PRIMARY KEY,
            gate_device_session_id UNIQUEIDENTIFIER NOT NULL CONSTRAINT UQ_gate_device_session_id UNIQUE,
            gate_station_sn INT NOT NULL,
            gate_device_session_status VARCHAR(20) NOT NULL,
            gate_device_session_previous_id UNIQUEIDENTIFIER NULL,
            gate_device_session_create_dt DATETIME2(3) NOT NULL,
            gate_device_session_expire_dt DATETIME2(3) NULL,
            gate_device_session_last_seen_dt DATETIME2(3) NULL,
            gate_device_session_revoke_dt DATETIME2(3) NULL,
            gate_device_session_revoke_reason VARCHAR(30) NULL,
            gate_device_session_revoke_by NVARCHAR(50) NULL,
            gate_device_session_remark NVARCHAR(500) NULL,
            gate_device_session_up_dt DATETIME2(3) NULL,
            CONSTRAINT CK_gate_device_session_status CHECK (gate_device_session_status IN ('Active','Revoked','Expired')),
            CONSTRAINT CK_gate_device_session_expire CHECK
                (gate_device_session_expire_dt IS NULL OR gate_device_session_expire_dt > gate_device_session_create_dt),
            CONSTRAINT CK_gate_device_session_revoked_time CHECK
                (gate_device_session_status <> 'Revoked' OR gate_device_session_revoke_dt IS NOT NULL)
        );
        CREATE UNIQUE INDEX UX_gate_device_session_active_station ON dbo.gate_device_session(gate_station_sn)
            WHERE gate_device_session_status='Active';
        CREATE INDEX IX_gate_device_session_station_create
            ON dbo.gate_device_session(gate_station_sn,gate_device_session_create_dt);
    END;

    -- Do not silently "repair" an existing incompatible schema or replace live authorizations.
    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id=OBJECT_ID('dbo.gate_device_session')
        AND name='gate_device_session_expire_dt' AND is_nullable=1)
        THROW 51001, 'Existing session schema does not support non-expiring authorization. Review required.', 1;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id=OBJECT_ID('dbo.gate_device_session')
        AND name='UX_gate_device_session_active_station' AND is_unique=1 AND has_filter=1)
        THROW 51002, 'Expected unique active-station index missing. Review required.', 1;

    -- Seed timestamps explicitly convert UTC to Taipei; independent of SQL host timezone.
    DECLARE @now DATETIME2(3)=CONVERT(DATETIME2(3),SYSUTCDATETIME() AT TIME ZONE 'UTC' AT TIME ZONE 'Taipei Standard Time');
    IF NOT EXISTS (SELECT 1 FROM dbo.gate_station WHERE gate_station_code='ENTRY_MAIN')
        INSERT dbo.gate_station(gate_station_code,gate_station_name,gate_station_direction,gate_station_is_active,gate_station_create_dt)
        VALUES ('ENTRY_MAIN',N'大門進場站點',1,1,@now);
    IF NOT EXISTS (SELECT 1 FROM dbo.gate_station WHERE gate_station_code='EXIT_MAIN')
        INSERT dbo.gate_station(gate_station_code,gate_station_name,gate_station_direction,gate_station_is_active,gate_station_create_dt)
        VALUES ('EXIT_MAIN',N'大門出場站點',2,1,@now);

    COMMIT;
    SELECT N'Gate device schema ready; existing authorizations preserved.' AS result;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK;
    THROW;
END CATCH;
