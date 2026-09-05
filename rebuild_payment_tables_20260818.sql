:ON ERROR EXIT

USE GymDB;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
SET QUOTED_IDENTIFIER ON;
GO

DECLARE @backup_table_count INT = (
    SELECT COUNT(*)
    FROM sys.tables
    WHERE name IN (
        'rebuild_backup_20260818_ticket_plan_kind',
        'rebuild_backup_20260818_orders',
        'rebuild_backup_20260818_order_items',
        'rebuild_backup_20260818_sdt_ticket_pass',
        'rebuild_backup_20260818_plan_rule',
        'rebuild_backup_20260818_ticket_plan_kind_rule',
        'rebuild_backup_20260818_sdt_profile'
    )
);

IF @backup_table_count NOT IN (0, 7)
    THROW 50001, 'The 20260818 rebuild backup set is incomplete. Rebuild stopped.', 1;

IF COL_LENGTH('dbo.order_items', 'order_items_paid_at') IS NOT NULL
    THROW 50002, 'The target tables already use the rebuilt schema. Rebuild stopped.', 1;

IF @backup_table_count = 0
BEGIN
    SELECT * INTO dbo.rebuild_backup_20260818_ticket_plan_kind FROM dbo.ticket_plan_kind;
    SELECT * INTO dbo.rebuild_backup_20260818_orders FROM dbo.orders;
    SELECT * INTO dbo.rebuild_backup_20260818_order_items FROM dbo.order_items;
    SELECT * INTO dbo.rebuild_backup_20260818_sdt_ticket_pass FROM dbo.sdt_ticket_pass;
    SELECT * INTO dbo.rebuild_backup_20260818_plan_rule FROM dbo.plan_rule;
    SELECT * INTO dbo.rebuild_backup_20260818_ticket_plan_kind_rule FROM dbo.ticket_plan_kind_rule;
    SELECT * INTO dbo.rebuild_backup_20260818_sdt_profile FROM dbo.sdt_profile;
END;
GO

BEGIN TRANSACTION;
GO

    DROP TABLE dbo.ticket_plan_kind_rule;
    DROP TABLE dbo.plan_rule;
    DROP TABLE dbo.sdt_ticket_pass;
    DROP TABLE dbo.order_items;
    DROP TABLE dbo.orders;
    DROP TABLE dbo.ticket_plan_kind;
GO

    CREATE TABLE dbo.ticket_plan_kind (
        ticket_plan_kind_sn INT IDENTITY(1,1) PRIMARY KEY,
        ticket_plan_kind_code NVARCHAR(50) NOT NULL,
        ticket_plan_kind_type NVARCHAR(20) NOT NULL,
        ticket_plan_kind_cname NVARCHAR(100) NOT NULL,
        ticket_plan_kind_price DECIMAL(10,2) NOT NULL,
        ticket_plan_kind_default_credit INT NULL,
        ticket_plan_kind_default_expire_days INT NULL,
        ticket_plan_kind_default_is_active VARCHAR(1) NOT NULL,
        CONSTRAINT UQ_ticket_plan_kind_code UNIQUE (ticket_plan_kind_code)
    );

    INSERT INTO dbo.ticket_plan_kind (
        ticket_plan_kind_code,
        ticket_plan_kind_type,
        ticket_plan_kind_cname,
        ticket_plan_kind_price,
        ticket_plan_kind_default_credit,
        ticket_plan_kind_default_expire_days,
        ticket_plan_kind_default_is_active
    )
    VALUES
        ('SINGLE',     'PACK',   N'單次票',          250,   1,    NULL, 'Y'),
        ('COUPON',     'PACK',   N'折抵票',          0,     1,    30,   'Y'),
        ('FREE_TRIAL', 'PACK',   N'免費體驗票',      0,     1,    14,   'Y'),
        ('PACK_10',    'PACK',   N'10堂票',          2300,  10,   90,   'Y'),
        ('PACK_20',    'PACK',   N'20堂票',          4400,  20,   90,   'Y'),
        ('NEW_PROMO',  'PACK',   N'5堂票-新朋友',    1200,  5,    30,   'Y'),
        ('MONTHLY',    'M_PASS', N'月票',            1960,  NULL, 30,   'Y'),
        ('RENEW',      'M_PASS', N'續約票',          1860,  NULL, 30,   'Y'),
        ('B6G1',       'M_PASS', N'半年票 買6送1',   11760, NULL, 210,  'Y'),
        ('B12G2',      'M_PASS', N'年票 買12送2',    23520, NULL, 420,  'Y');
GO

    CREATE TABLE dbo.orders (
        orders_sn INT IDENTITY(1,1) NOT NULL,
        order_buy_date DATETIME NOT NULL CONSTRAINT DF_orders_buy_date DEFAULT (GETDATE()),
        orders_id AS (
            'ORD' +
            CONVERT(VARCHAR(8), order_buy_date, 112) +
            RIGHT('000000' + CAST(orders_sn AS VARCHAR(6)), 6)
        ) PERSISTED NOT NULL,
        orders_buyer_id VARCHAR(50) NULL,
        orders_buyer_name NVARCHAR(50) NULL,
        orders_overall_payment_state VARCHAR(20) NULL,
        orders_total_amount DECIMAL(10,2) NOT NULL CONSTRAINT DF_orders_total_amount DEFAULT (0),
        orders_actual_amount DECIMAL(10,2) NOT NULL CONSTRAINT DF_orders_actual_amount DEFAULT (0),
        orders_create_pn VARCHAR(50) NULL,
        orders_create_dt DATETIME NOT NULL CONSTRAINT DF_orders_create_dt DEFAULT (GETDATE()),
        orders_up_pn VARCHAR(50) NULL,
        orders_up_dt DATETIME NOT NULL CONSTRAINT DF_orders_up_dt DEFAULT (GETDATE()),
        CONSTRAINT PK_orders PRIMARY KEY (orders_sn),
        CONSTRAINT UQ_orders_id UNIQUE (orders_id)
    );
GO

    CREATE TABLE dbo.order_items (
        order_items_sn INT IDENTITY(1,1) NOT NULL,
        orders_sn INT NOT NULL,
        order_items_buy_date DATETIME NOT NULL,
        order_items_id AS (
            'ITM' +
            CONVERT(VARCHAR(8), order_items_buy_date, 112) +
            RIGHT('000000' + CAST(order_items_sn AS VARCHAR(6)), 6)
        ) PERSISTED NOT NULL,
        order_items_type VARCHAR(20) NOT NULL,
        order_items_ref_id VARCHAR(50) NOT NULL,
        order_items_name NVARCHAR(100) NOT NULL,
        order_items_payment_state VARCHAR(20) NOT NULL,
        order_items_paid_at DATETIME NULL,
        order_items_payment_method VARCHAR(20) NOT NULL,
        order_items_unit_price DECIMAL(10,2) NOT NULL,
        order_items_total_amount DECIMAL(10,2) NOT NULL,
        order_items_actual_amount DECIMAL(10,2) NOT NULL,
        order_items_quantity INT NOT NULL,
        bonus_benefit_quantity INT NOT NULL
            CONSTRAINT DF_order_items_bonus_benefit_quantity DEFAULT (0),
        bonus_benefit_unit VARCHAR(20) NULL,
        order_items_create_pn VARCHAR(50) NULL,
        order_items_create_dt DATETIME NOT NULL
            CONSTRAINT DF_order_items_create_dt DEFAULT (GETDATE()),
        discount_type VARCHAR(50) NULL,
        discount_rate DECIMAL(5,4) NULL,
        order_items_up_pn VARCHAR(50) NULL,
        order_items_up_dt DATETIME NOT NULL
            CONSTRAINT DF_order_items_up_dt DEFAULT (GETDATE()),
        CONSTRAINT PK_order_items PRIMARY KEY (order_items_sn),
        CONSTRAINT UQ_order_items_id UNIQUE (order_items_id)
    );

    CREATE INDEX IX_order_items_orders_sn ON dbo.order_items (orders_sn);
GO

    CREATE TABLE dbo.sdt_ticket_pass (
        pass_sn INT IDENTITY(1,1) NOT NULL,
        create_dt DATETIME NOT NULL CONSTRAINT DF_sdt_ticket_pass_create_dt DEFAULT (GETDATE()),
        pass_id AS (
            'PASS' +
            CONVERT(VARCHAR(8), create_dt, 112) +
            RIGHT('000000' + CAST(pass_sn AS VARCHAR(6)), 6)
        ) PERSISTED NOT NULL,
        order_items_sn INT NOT NULL,
        orders_sn INT NOT NULL,
        owner_id VARCHAR(21) NOT NULL,
        ticket_plan_kind_code NVARCHAR(50) NOT NULL,
        ticket_plan_kind_type NVARCHAR(20) NOT NULL,
        valid_status NVARCHAR(50) NOT NULL,
        valid_sdate DATETIME NULL,
        valid_edate DATETIME NULL,
        credits_total INT NULL,
        credits_remaining INT NULL,
        create_pn VARCHAR(21) NULL,
        update_dt DATETIME NULL,
        update_pn VARCHAR(21) NULL,
        CONSTRAINT PK_sdt_ticket_pass PRIMARY KEY (pass_sn),
        CONSTRAINT UQ_sdt_ticket_pass_id UNIQUE (pass_id)
    );

    CREATE INDEX IX_sdt_ticket_pass_order_items_sn ON dbo.sdt_ticket_pass (order_items_sn);
    CREATE INDEX IX_sdt_ticket_pass_orders_sn ON dbo.sdt_ticket_pass (orders_sn);
    CREATE INDEX IX_sdt_ticket_pass_owner_id ON dbo.sdt_ticket_pass (owner_id);
GO

    CREATE TABLE dbo.plan_rule (
        plan_rule_sn VARCHAR(20) NOT NULL PRIMARY KEY,
        plan_rule_code VARCHAR(50) NOT NULL UNIQUE,
        plan_rule_name NVARCHAR(100) NOT NULL,
        plan_rule_desc NVARCHAR(255) NULL,
        plan_rule_is_active VARCHAR(2) NOT NULL DEFAULT 'Y',
        plan_rule_create_dt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        plan_rule_up_dt DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
GO

    CREATE TABLE dbo.ticket_plan_kind_rule (
        ticket_plan_kind_sn INT NOT NULL,
        plan_rule_sn VARCHAR(20) NOT NULL,
        ticket_plan_kind_tag_create_dt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT PK_ticket_plan_kind_rule
            PRIMARY KEY (ticket_plan_kind_sn, plan_rule_sn),
        CONSTRAINT FK_tpkt_kind
            FOREIGN KEY (ticket_plan_kind_sn)
            REFERENCES dbo.ticket_plan_kind(ticket_plan_kind_sn),
        CONSTRAINT FK_tpkt_rule
            FOREIGN KEY (plan_rule_sn)
            REFERENCES dbo.plan_rule(plan_rule_sn)
    );
GO

    SET IDENTITY_INSERT dbo.orders ON;

    INSERT INTO dbo.orders (
        orders_sn,
        order_buy_date,
        orders_buyer_id,
        orders_buyer_name,
        orders_overall_payment_state,
        orders_total_amount,
        orders_actual_amount,
        orders_create_pn,
        orders_create_dt,
        orders_up_pn,
        orders_up_dt
    )
    SELECT
        orders_sn,
        order_buy_date,
        orders_buyer_id,
        orders_buyer_name,
        orders_overall_payment_state,
        orders_total_amount,
        orders_actual_amount,
        orders_create_pn,
        orders_create_dt,
        orders_up_pn,
        orders_up_dt
    FROM dbo.rebuild_backup_20260818_orders;

    SET IDENTITY_INSERT dbo.orders OFF;

    SET IDENTITY_INSERT dbo.order_items ON;

    INSERT INTO dbo.order_items (
        order_items_sn,
        orders_sn,
        order_items_buy_date,
        order_items_type,
        order_items_ref_id,
        order_items_name,
        order_items_payment_state,
        order_items_paid_at,
        order_items_payment_method,
        order_items_unit_price,
        order_items_total_amount,
        order_items_actual_amount,
        order_items_quantity,
        bonus_benefit_quantity,
        bonus_benefit_unit,
        order_items_create_pn,
        order_items_create_dt,
        discount_type,
        discount_rate,
        order_items_up_pn,
        order_items_up_dt
    )
    SELECT
        order_items_sn,
        orders_sn,
        order_items_buy_date,
        order_items_type,
        order_items_ref_id,
        order_items_name,
        order_items_payment_state,
        CASE
            WHEN order_items_payment_state = 'Paid'
                THEN COALESCE(order_items_create_dt, order_items_buy_date)
            ELSE NULL
        END,
        order_items_payment_method,
        order_items_unit_price,
        order_items_total_amount,
        order_items_actual_amount,
        order_items_quantity,
        bonus_benefit_quantity,
        bonus_benefit_unit,
        order_items_create_pn,
        order_items_create_dt,
        discount_type,
        discount_rate,
        order_items_up_pn,
        order_items_up_dt
    FROM dbo.rebuild_backup_20260818_order_items;

    SET IDENTITY_INSERT dbo.order_items OFF;

    SET IDENTITY_INSERT dbo.sdt_ticket_pass ON;

    INSERT INTO dbo.sdt_ticket_pass (
        pass_sn,
        create_dt,
        order_items_sn,
        orders_sn,
        owner_id,
        ticket_plan_kind_code,
        ticket_plan_kind_type,
        valid_status,
        valid_sdate,
        valid_edate,
        credits_total,
        credits_remaining,
        create_pn,
        update_dt,
        update_pn
    )
    SELECT
        pass_sn,
        create_dt,
        order_items_sn,
        orders_sn,
        owner_id,
        ticket_plan_kind_code,
        ticket_plan_kind_type,
        valid_status,
        CASE WHEN ticket_plan_kind_code = 'SINGLE' THEN NULL ELSE valid_sdate END,
        CASE WHEN ticket_plan_kind_code = 'SINGLE' THEN NULL ELSE valid_edate END,
        credits_total,
        credits_remaining,
        create_pn,
        update_dt,
        update_pn
    FROM dbo.rebuild_backup_20260818_sdt_ticket_pass;

    SET IDENTITY_INSERT dbo.sdt_ticket_pass OFF;

    INSERT INTO dbo.plan_rule (
        plan_rule_sn,
        plan_rule_code,
        plan_rule_name,
        plan_rule_desc,
        plan_rule_is_active,
        plan_rule_create_dt,
        plan_rule_up_dt
    )
    SELECT
        plan_rule_sn,
        plan_rule_code,
        plan_rule_name,
        plan_rule_desc,
        plan_rule_is_active,
        plan_rule_create_dt,
        plan_rule_up_dt
    FROM dbo.rebuild_backup_20260818_plan_rule;

    INSERT INTO dbo.ticket_plan_kind_rule (
        ticket_plan_kind_sn,
        plan_rule_sn,
        ticket_plan_kind_tag_create_dt
    )
    SELECT
        ticket_plan_kind_sn,
        plan_rule_sn,
        ticket_plan_kind_tag_create_dt
    FROM dbo.rebuild_backup_20260818_ticket_plan_kind_rule;

    UPDATE profile
    SET
        profile.sdt_cur_ticket_type = pass.ticket_plan_kind_type,
        profile.sdt_cur_ticket_valid_state = pass.valid_status,
        profile.sdt_cur_ticket_payment_state = item.order_items_payment_state,
        profile.sdt_cur_ticket_remain_count = pass.credits_remaining,
        profile.sdt_cur_ticket_expire_dt = pass.valid_edate,
        profile.sdt_cur_ticket_up_dt = GETDATE()
    FROM dbo.sdt_profile AS profile
    INNER JOIN dbo.sdt_ticket_pass AS pass
        ON pass.pass_id = profile.sdt_cur_ticket_id
    INNER JOIN dbo.order_items AS item
        ON item.order_items_sn = pass.order_items_sn;

COMMIT TRANSACTION;
GO

SELECT 'ticket_plan_kind' AS table_name, COUNT(*) AS row_count FROM dbo.ticket_plan_kind
UNION ALL SELECT 'orders', COUNT(*) FROM dbo.orders
UNION ALL SELECT 'order_items', COUNT(*) FROM dbo.order_items
UNION ALL SELECT 'sdt_ticket_pass', COUNT(*) FROM dbo.sdt_ticket_pass
UNION ALL SELECT 'plan_rule', COUNT(*) FROM dbo.plan_rule
UNION ALL SELECT 'ticket_plan_kind_rule', COUNT(*) FROM dbo.ticket_plan_kind_rule;

SELECT
    ticket_plan_kind_code,
    ticket_plan_kind_default_credit,
    ticket_plan_kind_default_expire_days
FROM dbo.ticket_plan_kind
WHERE ticket_plan_kind_code IN ('SINGLE', 'MONTHLY', 'RENEW', 'B6G1', 'B12G2')
ORDER BY ticket_plan_kind_sn;

SELECT
    order_items_sn,
    order_items_payment_state,
    order_items_paid_at
FROM dbo.order_items
ORDER BY order_items_sn;

SELECT
    pass_sn,
    pass_id,
    owner_id,
    ticket_plan_kind_code,
    valid_status,
    valid_sdate,
    valid_edate,
    credits_total,
    credits_remaining
FROM dbo.sdt_ticket_pass
ORDER BY pass_sn;

SELECT
    COUNT(*) AS orphan_order_items
FROM dbo.order_items AS item
LEFT JOIN dbo.orders AS orders
    ON orders.orders_sn = item.orders_sn
WHERE orders.orders_sn IS NULL;

SELECT
    COUNT(*) AS orphan_passes
FROM dbo.sdt_ticket_pass AS pass
LEFT JOIN dbo.order_items AS item
    ON item.order_items_sn = pass.order_items_sn
LEFT JOIN dbo.orders AS orders
    ON orders.orders_sn = pass.orders_sn
WHERE item.order_items_sn IS NULL OR orders.orders_sn IS NULL;
GO

