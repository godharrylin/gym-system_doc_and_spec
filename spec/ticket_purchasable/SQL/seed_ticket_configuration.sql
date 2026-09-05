SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    -- 1. 票券方案設定資料（14 筆）
    INSERT INTO dbo.ticket_plan_kind
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
        ('SINGLE',          'PACK',   'SINGLE',     N'單次票',                    250.00,  1,    NULL, 'Y'),
        ('COUPON',          'PACK',   'COUPON',     N'折抵票',                      0.00,  1,      30, 'Y'),
        ('FREE_TRIAL',      'PACK',   'FREE_TRIAL', N'免費體驗票',                  0.00,  1,      14, 'Y'),
        ('NEW_PROMO',       'PACK',   'NEW_PROMO',  N'5堂票-新朋友',             1200.00,  5,      30, 'Y'),
        ('PACK_10',         'PACK',   'PACK_10',    N'10堂票',                   2300.00, 10,      90, 'Y'),
        ('PACK_10_RENEW',   'PACK',   'PACK_10',    N'10堂票(續約)',             2200.00, 10,      90, 'Y'),
        ('PACK_20',         'PACK',   'PACK_20',    N'20堂票',                   4400.00, 20,      90, 'Y'),
        ('PACK_20_RENEW',   'PACK',   'PACK_20',    N'20堂票(續約)',             4300.00, 20,      90, 'Y'),
        ('MONTHLY',         'M_PASS', 'MONTHLY',    N'月票',                     1960.00, NULL,    30, 'Y'),
        ('RENEW',           'M_PASS', 'MONTHLY',    N'月票(續約)',               1860.00, NULL,    30, 'Y'),
        ('B6G1',            'M_PASS', 'HALF_YEAR',  N'半年票 買6送1',           11260.00, NULL,   210, 'Y'),
        ('B6G1_RENEW',      'M_PASS', 'HALF_YEAR',  N'半年票(續約) 買6送1',     11160.00, NULL,   210, 'Y'),
        ('B12G2',           'M_PASS', 'YEAR',       N'年票 買12送2',            22420.00, NULL,   420, 'Y'),
        ('B12G2_RENEW',     'M_PASS', 'YEAR',       N'年票(續約) 買12送2',      22320.00, NULL,   420, 'Y');

    -- 2. 方案規則設定資料（4 筆）
    INSERT INTO dbo.plan_rule
    (
        plan_rule_sn,
        plan_rule_code,
        plan_rule_name,
        plan_rule_desc,
        plan_rule_is_active
    )
    VALUES
        ('R_001', 'NEW_ONLY',       N'新會員限定', N'只能讓新會員使用',             'Y'),
        ('R_002', 'RENEWAL',        N'續約方案',   N'符合續約資格可使用',           'Y'),
        ('R_003', 'FAMILY_ELIGIBLE',N'家庭方案',   N'符合家庭方案資格',             'Y'),
        ('R_004', 'HIDDEN',         N'特殊方案',   N'不顯示於一般票券購買清單',     'Y');

    -- 3. 票券方案與規則關聯（14 筆）
    -- 使用 Code 查找 Identity 流水號，不寫死 ticket_plan_kind_sn。
    INSERT INTO dbo.ticket_plan_kind_rule
    (
        ticket_plan_kind_sn,
        plan_rule_sn,
        ticket_plan_kind_rule_is_enabled
    )
    SELECT
        planKind.ticket_plan_kind_sn,
        planRule.plan_rule_sn,
        'Y'
    FROM
    (
        VALUES
            ('MONTHLY',        'FAMILY_ELIGIBLE'),
            ('B6G1',           'FAMILY_ELIGIBLE'),
            ('B12G2',          'FAMILY_ELIGIBLE'),
            ('PACK_10',        'FAMILY_ELIGIBLE'),
            ('PACK_20',        'FAMILY_ELIGIBLE'),
            ('RENEW',          'FAMILY_ELIGIBLE'),
            ('RENEW',          'RENEWAL'),
            ('B6G1_RENEW',     'RENEWAL'),
            ('B12G2_RENEW',    'RENEWAL'),
            ('PACK_10_RENEW',  'RENEWAL'),
            ('PACK_20_RENEW',  'RENEWAL'),
            ('NEW_PROMO',      'NEW_ONLY'),
            ('FREE_TRIAL',     'NEW_ONLY'),
            ('COUPON',         'HIDDEN')
    ) AS ruleMapping
    (
        ticket_plan_kind_code,
        plan_rule_code
    )
    INNER JOIN dbo.ticket_plan_kind AS planKind
        ON planKind.ticket_plan_kind_code = ruleMapping.ticket_plan_kind_code
    INNER JOIN dbo.plan_rule AS planRule
        ON planRule.plan_rule_code = ruleMapping.plan_rule_code;

    -- 若任何 Code 拼錯或主檔遺漏，避免只建立部分關聯。
    IF @@ROWCOUNT <> 14
    BEGIN
        THROW 50001, N'方案規則關聯未完整建立，預期 14 筆。', 1;
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
GO

-- 4. 執行結果驗證
SELECT
    planKind.ticket_plan_kind_code,
    planKind.ticket_plan_kind_cname,
    planKind.ticket_plan_family_code,
    planKind.ticket_plan_kind_price,
    planKind.ticket_plan_kind_default_credit,
    planKind.ticket_plan_kind_default_expire_days,
    planRule.plan_rule_code,
    relation.ticket_plan_kind_rule_is_enabled
FROM dbo.ticket_plan_kind AS planKind
LEFT JOIN dbo.ticket_plan_kind_rule AS relation
    ON relation.ticket_plan_kind_sn = planKind.ticket_plan_kind_sn
LEFT JOIN dbo.plan_rule AS planRule
    ON planRule.plan_rule_sn = relation.plan_rule_sn
ORDER BY
    planKind.ticket_plan_kind_sn,
    planRule.plan_rule_code;
GO
