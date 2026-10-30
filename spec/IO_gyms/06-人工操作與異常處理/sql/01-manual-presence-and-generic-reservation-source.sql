-- Target schema for manual presence evidence and generic credit-reservation origin.
-- Review before execution. Keep the API stopped while changing the reservation columns.
-- Match the SET options required by the reservation table's filtered unique indexes.
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
SET XACT_ABORT ON;
IF DB_NAME() <> N'GymDB' THROW 51000, 'This migration targets GymDB only.', 1;
IF OBJECT_ID(N'dbo.sdt_ticket_credit_reservation', N'U') IS NULL
    THROW 51001, 'Credit reservation table is missing.', 1;
IF OBJECT_ID(N'dbo.sdt_att_record', N'U') IS NULL
    THROW 51002, 'Attendance table is missing.', 1;
IF COL_LENGTH(N'dbo.sdt_ticket_credit_reservation', N'gate_request_id') IS NULL
    OR COL_LENGTH(N'dbo.sdt_ticket_credit_reservation', N'processing_item_sn') IS NULL
    THROW 51006, 'Expected old reservation source columns are missing.', 1;
IF COL_LENGTH(N'dbo.sdt_ticket_credit_reservation', N'source_type') IS NOT NULL
    THROW 51003, 'Generic reservation source is already present; inspect schema before rerunning.', 1;
IF COL_LENGTH(N'dbo.sdt_ticket_credit_reservation', N'source_key') IS NOT NULL
    OR COL_LENGTH(N'dbo.sdt_att_record', N'sdt_att_record_check_in_evidence_source') IS NOT NULL
    OR COL_LENGTH(N'dbo.sdt_att_record', N'sdt_att_record_check_in_evidence_sn') IS NOT NULL
    OR OBJECT_ID(N'dbo.sdt_presence_correction_log', N'U') IS NOT NULL
    THROW 51007, 'Part of the target schema already exists; inspect before rerunning.', 1;
IF EXISTS (SELECT 1 FROM dbo.sdt_ticket_credit_reservation
    WHERE (gate_request_id IS NULL AND processing_item_sn IS NULL)
       OR (gate_request_id IS NOT NULL AND processing_item_sn IS NOT NULL))
    THROW 51004, 'Reservation rows with zero or two source references require manual review.', 1;

BEGIN TRY
    BEGIN TRANSACTION;

    ALTER TABLE dbo.sdt_ticket_credit_reservation
        ADD source_type VARCHAR(24) NULL, source_key VARCHAR(64) NULL;

    -- SQL Server compiles a batch before ALTER ADD runs; defer references to new columns.
    EXEC sys.sp_executesql N'
        UPDATE dbo.sdt_ticket_credit_reservation
           SET source_type = CASE WHEN gate_request_id IS NOT NULL
                THEN ''GateRequest'' ELSE ''ClassWorkItem'' END,
               source_key = CASE WHEN gate_request_id IS NOT NULL
                    THEN CONVERT(VARCHAR(36), gate_request_id)
                    ELSE CONVERT(VARCHAR(20), processing_item_sn) END;
        IF EXISTS (SELECT 1 FROM dbo.sdt_ticket_credit_reservation
            WHERE source_type IS NULL OR source_key IS NULL OR LEN(source_key) = 0)
            THROW 51005, ''Reservation source backfill is incomplete.'', 1;
    ';

    ALTER TABLE dbo.sdt_ticket_credit_reservation ALTER COLUMN source_type VARCHAR(24) NOT NULL;
    ALTER TABLE dbo.sdt_ticket_credit_reservation ALTER COLUMN source_key VARCHAR(64) NOT NULL;
    ALTER TABLE dbo.sdt_ticket_credit_reservation DROP COLUMN gate_request_id, processing_item_sn;

    ALTER TABLE dbo.sdt_att_record
        ADD sdt_att_record_check_in_evidence_source VARCHAR(10) NULL,
            sdt_att_record_check_in_evidence_sn BIGINT NULL;

    CREATE TABLE dbo.sdt_presence_correction_log
    (
        correction_sn BIGINT IDENTITY(1,1) NOT NULL,
        request_id UNIQUEIDENTIFIER NOT NULL,
        user_id NVARCHAR(50) NOT NULL,
        attendance_sn INT NULL,
        before_presence VARCHAR(10) NOT NULL,
        after_presence VARCHAR(10) NOT NULL,
        reason NVARCHAR(500) NOT NULL,
        operator_id NVARCHAR(50) NOT NULL,
        corrected_at DATETIME2(3) NOT NULL,
        CONSTRAINT PK_sdt_presence_correction_log PRIMARY KEY (correction_sn),
        CONSTRAINT UQ_sdt_presence_correction_request UNIQUE (request_id)
    );
    CREATE INDEX IX_sdt_presence_correction_user_time
        ON dbo.sdt_presence_correction_log (user_id, corrected_at DESC, correction_sn DESC);

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
