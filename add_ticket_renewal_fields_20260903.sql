SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF COL_LENGTH('dbo.ticket_plan_kind', 'ticket_plan_family_code') IS NULL
    BEGIN
        ALTER TABLE dbo.ticket_plan_kind
            ADD ticket_plan_family_code VARCHAR(50) NULL;
    END;

    MERGE dbo.ticket_plan_kind AS target
    USING
    (
        VALUES
            (N'SINGLE',          N'PACK',   'SINGLE',     N'單次票',                    250.00,  1,    NULL, 'Y'),
            (N'COUPON',          N'PACK',   'COUPON',     N'折抵票',                      0.00,  1,      30, 'Y'),
            (N'FREE_TRIAL',      N'PACK',   'FREE_TRIAL', N'免費體驗票',                  0.00,  1,      14, 'Y'),
            (N'PACK_10',         N'PACK',   'PACK_10',    N'10堂票',                   2300.00, 10,     90, 'Y'),
            (N'PACK_10_RENEW',   N'PACK',   'PACK_10',    N'10堂票(續約)',             2200.00, 10,     90, 'Y'),
            (N'PACK_20',         N'PACK',   'PACK_20',    N'20堂票',                   4400.00, 20,     90, 'Y'),
            (N'PACK_20_RENEW',   N'PACK',   'PACK_20',    N'20堂票(續約)',             4300.00, 20,     90, 'Y'),
            (N'NEW_PROMO',       N'PACK',   'NEW_PROMO',  N'5堂票-新朋友',             1200.00,  5,     30, 'Y'),
            (N'MONTHLY',         N'M_PASS', 'MONTHLY',    N'月票',                     1960.00, NULL,   30, 'Y'),
            (N'RENEW',           N'M_PASS', 'MONTHLY',    N'月票(續約)',               1860.00, NULL,   30, 'Y'),
            (N'B6G1',            N'M_PASS', 'HALF_YEAR',  N'半年票 買6送1',           11260.00, NULL,  210, 'Y'),
            (N'B6G1_RENEW',      N'M_PASS', 'HALF_YEAR',  N'半年票(續約) 買6送1',     11160.00, NULL,  210, 'Y'),
            (N'B12G2',           N'M_PASS', 'YEAR',       N'年票 買12送2',            22420.00, NULL,  420, 'Y'),
            (N'B12G2_RENEW',     N'M_PASS', 'YEAR',       N'年票(續約) 買12送2',      22320.00, NULL,  420, 'Y')
    ) AS source
    (
        plan_code,
        plan_type,
        family_code,
        plan_name,
        price,
        default_credit,
        default_expire_days,
        is_active
    )
        ON target.ticket_plan_kind_code = source.plan_code
    WHEN MATCHED THEN
        UPDATE SET
            ticket_plan_kind_type = source.plan_type,
            ticket_plan_family_code = source.family_code,
            ticket_plan_kind_cname = source.plan_name,
            ticket_plan_kind_price = source.price,
            ticket_plan_kind_default_credit = source.default_credit,
            ticket_plan_kind_default_expire_days = source.default_expire_days,
            ticket_plan_kind_default_is_active = source.is_active
    WHEN NOT MATCHED THEN
        INSERT
        (
            ticket_plan_kind_code,
            ticket_plan_kind_type,
            ticket_plan_family_code,
            ticket_plan_kind_cname,
            ticket_plan_kind_price,
            ticket_plan_kind_default_credit,
            ticket_plan_kind_default_expire_days,
            ticket_plan_kind_default_is_active
        )
        VALUES
        (
            source.plan_code,
            source.plan_type,
            source.family_code,
            source.plan_name,
            source.price,
            source.default_credit,
            source.default_expire_days,
            source.is_active
        );

    IF NOT EXISTS
    (
        SELECT 1
        FROM dbo.plan_rule
        WHERE plan_rule_code = 'RENEWAL'
    )
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM dbo.plan_rule
            WHERE plan_rule_sn = 'R_002'
        )
        BEGIN
            THROW 50002, 'Cannot insert RENEWAL rule: plan_rule_sn R_002 is already used.', 1;
        END;

        INSERT INTO dbo.plan_rule
        (
            plan_rule_sn,
            plan_rule_code,
            plan_rule_name,
            plan_rule_desc,
            plan_rule_is_active
        )
        VALUES
        ('R_002', 'RENEWAL', N'續約方案', N'符合續約資格可使用', 'Y');
    END;

    IF COL_LENGTH('dbo.ticket_plan_kind_rule', 'ticket_plan_kind_rule_is_enabled') IS NULL
    BEGIN
        ALTER TABLE dbo.ticket_plan_kind_rule
            ADD ticket_plan_kind_rule_is_enabled VARCHAR(1) NOT NULL
                CONSTRAINT DF_ticket_plan_kind_rule_is_enabled DEFAULT ('Y') WITH VALUES;
    END;

    IF COL_LENGTH('dbo.ticket_plan_kind_rule', 'ticket_plan_kind_rule_up_dt') IS NULL
    BEGIN
        ALTER TABLE dbo.ticket_plan_kind_rule
            ADD ticket_plan_kind_rule_up_dt DATETIME NULL;
    END;

    INSERT INTO dbo.ticket_plan_kind_rule
    (
        ticket_plan_kind_sn,
        plan_rule_sn,
        ticket_plan_kind_rule_is_enabled
    )
    SELECT
        planKind.ticket_plan_kind_sn,
        renewalRule.plan_rule_sn,
        'Y'
    FROM dbo.ticket_plan_kind AS planKind
    CROSS JOIN dbo.plan_rule AS renewalRule
    WHERE planKind.ticket_plan_kind_code IN
    (
        N'RENEW',
        N'B6G1_RENEW',
        N'B12G2_RENEW',
        N'PACK_10_RENEW',
        N'PACK_20_RENEW'
    )
      AND renewalRule.plan_rule_code = 'RENEWAL'
      AND NOT EXISTS
      (
          SELECT 1
          FROM dbo.ticket_plan_kind_rule AS relation
          WHERE relation.ticket_plan_kind_sn = planKind.ticket_plan_kind_sn
            AND relation.plan_rule_sn = renewalRule.plan_rule_sn
      );

    IF COL_LENGTH('dbo.sdt_ticket_pass', 'renewed_from_pass_sn') IS NULL
    BEGIN
        ALTER TABLE dbo.sdt_ticket_pass
            ADD renewed_from_pass_sn INT NULL;
    END;

    IF COL_LENGTH('dbo.sdt_ticket_pass', 'ended_at') IS NULL
    BEGIN
        ALTER TABLE dbo.sdt_ticket_pass
            ADD ended_at DATETIME NULL;
    END;

    IF COL_LENGTH('dbo.sdt_ticket_pass', 'end_reason') IS NULL
    BEGIN
        ALTER TABLE dbo.sdt_ticket_pass
            ADD end_reason VARCHAR(20) NULL;
    END;

    UPDATE dbo.sdt_ticket_pass
    SET valid_status = N'Expire'
    WHERE valid_status = N'Expired';

    UPDATE dbo.sdt_ticket_pass
    SET end_reason = 'Expire'
    WHERE end_reason = 'Expired';

    IF EXISTS
    (
        SELECT renewed_from_pass_sn
        FROM dbo.sdt_ticket_pass
        WHERE renewed_from_pass_sn IS NOT NULL
          AND valid_status <> N'Cancelled'
        GROUP BY renewed_from_pass_sn
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50001, 'Cannot create renewal unique index: duplicated active renewal sources exist.', 1;
    END;

    IF NOT EXISTS
    (
        SELECT 1
        FROM sys.indexes
        WHERE object_id = OBJECT_ID(N'dbo.sdt_ticket_pass')
          AND name = N'UX_sdt_ticket_pass_renewed_from_pass_sn'
    )
    BEGIN
        CREATE UNIQUE INDEX UX_sdt_ticket_pass_renewed_from_pass_sn
            ON dbo.sdt_ticket_pass (renewed_from_pass_sn)
            WHERE renewed_from_pass_sn IS NOT NULL
              AND valid_status <> N'Cancelled';
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;
END CATCH;
