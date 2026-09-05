SET ANSI_NULLS ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET QUOTED_IDENTIFIER ON;
SET NUMERIC_ROUNDABORT OFF;
GO

SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @Today DATE = CONVERT(DATE, GETDATE());
    DECLARE @Now DATETIME = GETDATE();
    DECLARE @OperatorId VARCHAR(50) = 'TEST_SEED';

    DECLARE @TargetUsers TABLE
    (
        usr_id VARCHAR(50) NOT NULL PRIMARY KEY
    );

    INSERT INTO @TargetUsers (usr_id)
    VALUES
        ('U0000000008'),
        ('U0000000009'),
        ('U0000000010'),
        ('U0000000011'),
        ('U0000000012'),
        ('U0000000013'),
        ('U0000000014');

    IF EXISTS
    (
        SELECT 1
        FROM @TargetUsers AS targetUser
        LEFT JOIN dbo.users AS users
            ON users.usr_id = targetUser.usr_id
        LEFT JOIN dbo.sdt_profile AS profile
            ON profile.usr_id = targetUser.usr_id
        WHERE users.usr_id IS NULL
           OR profile.usr_id IS NULL
    )
    BEGIN
        THROW 50001, N'測試會員或學生 Profile 不完整，停止建立票券測試資料。', 1;
    END;

    -- 僅清除指定測試會員的舊票券與訂單資料。
    DELETE ticketPass
    FROM dbo.sdt_ticket_pass AS ticketPass
    LEFT JOIN dbo.order_items AS orderItem
        ON orderItem.order_items_sn = ticketPass.order_items_sn
    LEFT JOIN dbo.orders AS orders
        ON orders.orders_sn = orderItem.orders_sn
    WHERE ticketPass.owner_id IN (SELECT usr_id FROM @TargetUsers)
       OR orders.orders_buyer_id IN (SELECT usr_id FROM @TargetUsers);

    DELETE orderItem
    FROM dbo.order_items AS orderItem
    INNER JOIN dbo.orders AS orders
        ON orders.orders_sn = orderItem.orders_sn
    WHERE orders.orders_buyer_id IN (SELECT usr_id FROM @TargetUsers);

    DELETE orders
    FROM dbo.orders AS orders
    WHERE orders.orders_buyer_id IN (SELECT usr_id FROM @TargetUsers);

    UPDATE profile
    SET sdt_cur_ticket_id = NULL,
        sdt_cur_ticket_type = NULL,
        sdt_cur_ticket_valid_state = NULL,
        sdt_cur_ticket_payment_state = NULL,
        sdt_cur_ticket_remain_count = NULL,
        sdt_cur_ticket_expire_dt = NULL,
        sdt_cur_ticket_up_dt = @Now
    FROM dbo.sdt_profile AS profile
    WHERE profile.usr_id IN (SELECT usr_id FROM @TargetUsers);

    DECLARE @TicketRows TABLE
    (
        row_key VARCHAR(50) NOT NULL PRIMARY KEY,
        owner_id VARCHAR(50) NOT NULL,
        plan_code VARCHAR(50) NOT NULL,
        paid_at DATETIME NOT NULL,
        valid_status NVARCHAR(50) NOT NULL,
        valid_sdate DATETIME NULL,
        valid_edate DATETIME NULL,
        ended_at DATETIME NULL,
        end_reason VARCHAR(20) NULL,
        credits_remaining INT NULL,
        renewed_from_row_key VARCHAR(50) NULL
    );

    INSERT INTO @TicketRows
    (
        row_key,
        owner_id,
        plan_code,
        paid_at,
        valid_status,
        valid_sdate,
        valid_edate,
        ended_at,
        end_reason,
        credits_remaining,
        renewed_from_row_key
    )
    VALUES
        -- U0000000008：單次票，無期限。
        ('U08_SINGLE', 'U0000000008', 'SINGLE', @Now,
         N'Active', NULL, NULL, NULL, NULL, 1, NULL),

        -- U0000000009：月票使用中，另有一張標準 10 堂票排隊。
        ('U09_MONTHLY', 'U0000000009', 'MONTHLY', DATEADD(DAY, -10, @Today),
         N'Active', DATEADD(DAY, -10, @Today), DATEADD(DAY, 19, @Today), NULL, NULL, NULL, NULL),
        ('U09_PACK_QUEUE', 'U0000000009', 'PACK_10', DATEADD(DAY, -1, @Today),
         N'UnActive', NULL, NULL, NULL, NULL, 10, NULL),

        -- U0000000010：10 堂票提前用完，寬限期內購買的續約票從付款日生效。
        ('U10_PACK_SOURCE', 'U0000000010', 'PACK_10', DATEADD(DAY, -60, @Today),
         N'Depleted', DATEADD(DAY, -60, @Today), DATEADD(DAY, 29, @Today),
         DATEADD(DAY, -3, @Today), 'Depleted', 0, NULL),
        ('U10_PACK_RENEW', 'U0000000010', 'PACK_10_RENEW', @Now,
         N'Active', @Today, DATEADD(DAY, 89, @Today), NULL, NULL, 10, 'U10_PACK_SOURCE'),

        -- U0000000011：來源月票仍有效；續約票今天取消，另有標準票排隊。
        -- 取消當天仍應允許重新購買同家族續約票。
        ('U11_MONTHLY_SOURCE', 'U0000000011', 'MONTHLY', DATEADD(DAY, -10, @Today),
         N'Active', DATEADD(DAY, -10, @Today), DATEADD(DAY, 19, @Today), NULL, NULL, NULL, NULL),
        ('U11_CANCELLED_RENEW', 'U0000000011', 'RENEW', DATEADD(DAY, -2, @Today),
         N'Cancelled', NULL, NULL, @Now, 'Cancelled', NULL, 'U11_MONTHLY_SOURCE'),
        ('U11_PACK_QUEUE', 'U0000000011', 'PACK_20', DATEADD(DAY, -1, @Today),
         N'UnActive', NULL, NULL, NULL, NULL, 20, NULL),

        -- U0000000012：10 堂票使用中，剩餘 5 堂。
        ('U12_PACK_ACTIVE', 'U0000000012', 'PACK_10', DATEADD(DAY, -20, @Today),
         N'Active', DATEADD(DAY, -20, @Today), DATEADD(DAY, 69, @Today), NULL, NULL, 5, NULL),

        -- U0000000013：月票使用中，續約票已提前付款並排隊。
        ('U13_MONTHLY_SOURCE', 'U0000000013', 'MONTHLY', DATEADD(DAY, -20, @Today),
         N'Active', DATEADD(DAY, -20, @Today), DATEADD(DAY, 9, @Today), NULL, NULL, NULL, NULL),
        ('U13_MONTHLY_RENEW', 'U0000000013', 'RENEW', @Now,
         N'UnActive', NULL, NULL, NULL, NULL, NULL, 'U13_MONTHLY_SOURCE'),

        -- U0000000014：月票已到期 5 天，仍在 +9 天續約寬限期內。
        ('U14_MONTHLY_EXPIRE', 'U0000000014', 'MONTHLY', DATEADD(DAY, -34, @Today),
         N'Expire', DATEADD(DAY, -34, @Today), DATEADD(DAY, -5, @Today),
         DATEADD(DAY, -5, @Today), 'Expire', NULL, NULL);

    IF EXISTS
    (
        SELECT 1
        FROM @TicketRows AS ticketRow
        LEFT JOIN dbo.ticket_plan_kind AS planKind
            ON planKind.ticket_plan_kind_code = ticketRow.plan_code
        WHERE planKind.ticket_plan_kind_code IS NULL
    )
    BEGIN
        THROW 50002, N'測試情境使用的票券方案不存在。', 1;
    END;

    DECLARE @OrderMap TABLE
    (
        row_key VARCHAR(50) NOT NULL PRIMARY KEY,
        orders_sn INT NOT NULL,
        orders_id VARCHAR(50) NOT NULL
    );

    MERGE dbo.orders AS target
    USING
    (
        SELECT
            ticketRow.row_key,
            ticketRow.owner_id,
            users.usr_name,
            ticketRow.paid_at,
            planKind.ticket_plan_kind_price
        FROM @TicketRows AS ticketRow
        INNER JOIN dbo.users AS users
            ON users.usr_id = ticketRow.owner_id
        INNER JOIN dbo.ticket_plan_kind AS planKind
            ON planKind.ticket_plan_kind_code = ticketRow.plan_code
    ) AS source
        ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT
        (
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
        VALUES
        (
            source.paid_at,
            source.owner_id,
            source.usr_name,
            'Paid',
            source.ticket_plan_kind_price,
            source.ticket_plan_kind_price,
            @OperatorId,
            source.paid_at,
            @OperatorId,
            source.paid_at
        )
    OUTPUT
        source.row_key,
        INSERTED.orders_sn,
        INSERTED.orders_id
    INTO @OrderMap (row_key, orders_sn, orders_id);

    DECLARE @ItemMap TABLE
    (
        row_key VARCHAR(50) NOT NULL PRIMARY KEY,
        order_items_sn INT NOT NULL,
        order_items_id VARCHAR(50) NOT NULL
    );

    MERGE dbo.order_items AS target
    USING
    (
        SELECT
            ticketRow.*,
            orderMap.orders_sn,
            planKind.ticket_plan_kind_cname,
            planKind.ticket_plan_kind_price
        FROM @TicketRows AS ticketRow
        INNER JOIN @OrderMap AS orderMap
            ON orderMap.row_key = ticketRow.row_key
        INNER JOIN dbo.ticket_plan_kind AS planKind
            ON planKind.ticket_plan_kind_code = ticketRow.plan_code
    ) AS source
        ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT
        (
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
        VALUES
        (
            source.orders_sn,
            source.paid_at,
            'Ticket',
            source.plan_code,
            source.ticket_plan_kind_cname,
            'Paid',
            source.paid_at,
            'Cash',
            source.ticket_plan_kind_price,
            source.ticket_plan_kind_price,
            source.ticket_plan_kind_price,
            1,
            0,
            NULL,
            @OperatorId,
            source.paid_at,
            NULL,
            NULL,
            @OperatorId,
            source.paid_at
        )
    OUTPUT
        source.row_key,
        INSERTED.order_items_sn,
        INSERTED.order_items_id
    INTO @ItemMap (row_key, order_items_sn, order_items_id);

    DECLARE @PassMap TABLE
    (
        row_key VARCHAR(50) NOT NULL PRIMARY KEY,
        pass_sn INT NOT NULL,
        pass_id VARCHAR(50) NOT NULL
    );

    -- 先建立不承接其他票券的來源票及標準票。
    MERGE dbo.sdt_ticket_pass AS target
    USING
    (
        SELECT
            ticketRow.*,
            orderMap.orders_sn,
            itemMap.order_items_sn,
            planKind.ticket_plan_kind_type,
            planKind.ticket_plan_kind_default_credit
        FROM @TicketRows AS ticketRow
        INNER JOIN @OrderMap AS orderMap
            ON orderMap.row_key = ticketRow.row_key
        INNER JOIN @ItemMap AS itemMap
            ON itemMap.row_key = ticketRow.row_key
        INNER JOIN dbo.ticket_plan_kind AS planKind
            ON planKind.ticket_plan_kind_code = ticketRow.plan_code
        WHERE ticketRow.renewed_from_row_key IS NULL
    ) AS source
        ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT
        (
            create_dt,
            order_items_sn,
            orders_sn,
            owner_id,
            ticket_plan_kind_code,
            ticket_plan_kind_type,
            renewed_from_pass_sn,
            valid_status,
            valid_sdate,
            valid_edate,
            ended_at,
            end_reason,
            credits_total,
            credits_remaining,
            create_pn,
            update_dt,
            update_pn
        )
        VALUES
        (
            source.paid_at,
            source.order_items_sn,
            source.orders_sn,
            source.owner_id,
            source.plan_code,
            source.ticket_plan_kind_type,
            NULL,
            source.valid_status,
            source.valid_sdate,
            source.valid_edate,
            source.ended_at,
            source.end_reason,
            source.ticket_plan_kind_default_credit,
            source.credits_remaining,
            @OperatorId,
            @Now,
            @OperatorId
        )
    OUTPUT
        source.row_key,
        INSERTED.pass_sn,
        INSERTED.pass_id
    INTO @PassMap (row_key, pass_sn, pass_id);

    -- 再建立續約票，並使用剛建立的來源 pass_sn。
    MERGE dbo.sdt_ticket_pass AS target
    USING
    (
        SELECT
            ticketRow.*,
            orderMap.orders_sn,
            itemMap.order_items_sn,
            sourcePass.pass_sn AS renewed_from_pass_sn,
            planKind.ticket_plan_kind_type,
            planKind.ticket_plan_kind_default_credit
        FROM @TicketRows AS ticketRow
        INNER JOIN @OrderMap AS orderMap
            ON orderMap.row_key = ticketRow.row_key
        INNER JOIN @ItemMap AS itemMap
            ON itemMap.row_key = ticketRow.row_key
        INNER JOIN @PassMap AS sourcePass
            ON sourcePass.row_key = ticketRow.renewed_from_row_key
        INNER JOIN dbo.ticket_plan_kind AS planKind
            ON planKind.ticket_plan_kind_code = ticketRow.plan_code
        WHERE ticketRow.renewed_from_row_key IS NOT NULL
    ) AS source
        ON 1 = 0
    WHEN NOT MATCHED THEN
        INSERT
        (
            create_dt,
            order_items_sn,
            orders_sn,
            owner_id,
            ticket_plan_kind_code,
            ticket_plan_kind_type,
            renewed_from_pass_sn,
            valid_status,
            valid_sdate,
            valid_edate,
            ended_at,
            end_reason,
            credits_total,
            credits_remaining,
            create_pn,
            update_dt,
            update_pn
        )
        VALUES
        (
            source.paid_at,
            source.order_items_sn,
            source.orders_sn,
            source.owner_id,
            source.plan_code,
            source.ticket_plan_kind_type,
            source.renewed_from_pass_sn,
            source.valid_status,
            source.valid_sdate,
            source.valid_edate,
            source.ended_at,
            source.end_reason,
            source.ticket_plan_kind_default_credit,
            source.credits_remaining,
            @OperatorId,
            @Now,
            @OperatorId
        )
    OUTPUT
        source.row_key,
        INSERTED.pass_sn,
        INSERTED.pass_id
    INTO @PassMap (row_key, pass_sn, pass_id);

    IF (SELECT COUNT(*) FROM @OrderMap) <> 12
       OR (SELECT COUNT(*) FROM @ItemMap) <> 12
       OR (SELECT COUNT(*) FROM @PassMap) <> 12
    BEGIN
        THROW 50003, N'測試訂單、明細或票券沒有完整建立 12 筆。', 1;
    END;

    IF EXISTS
    (
        SELECT owner_id
        FROM dbo.sdt_ticket_pass
        WHERE owner_id IN (SELECT usr_id FROM @TargetUsers)
          AND valid_status = N'Active'
        GROUP BY owner_id
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50004, N'測試會員同時存在多張 Active 票券。', 1;
    END;

    -- sdt_profile 只保存目前 Active 票券快照；排隊票及歷史票留在 sdt_ticket_pass。
    UPDATE profile
    SET sdt_cur_ticket_id = activePass.pass_id,
        sdt_cur_ticket_type = activePass.ticket_plan_kind_type,
        sdt_cur_ticket_valid_state = activePass.valid_status,
        sdt_cur_ticket_payment_state = 'Paid',
        sdt_cur_ticket_remain_count = CASE
            WHEN activePass.ticket_plan_kind_type = N'PACK'
                THEN activePass.credits_remaining
            ELSE NULL
        END,
        sdt_cur_ticket_expire_dt = activePass.valid_edate,
        sdt_cur_ticket_up_dt = @Now
    FROM dbo.sdt_profile AS profile
    INNER JOIN dbo.sdt_ticket_pass AS activePass
        ON activePass.owner_id = profile.usr_id
       AND activePass.valid_status = N'Active'
    WHERE profile.usr_id IN (SELECT usr_id FROM @TargetUsers);

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

-- 驗證一：各測試會員持有的票券、狀態、承接來源與日期。
SELECT
    users.usr_id,
    users.usr_name,
    ticketPass.pass_sn,
    ticketPass.pass_id,
    ticketPass.ticket_plan_kind_code,
    ticketPass.valid_status,
    ticketPass.valid_sdate,
    ticketPass.valid_edate,
    ticketPass.credits_total,
    ticketPass.credits_remaining,
    ticketPass.renewed_from_pass_sn,
    ticketPass.ended_at,
    ticketPass.end_reason,
    orderItem.order_items_paid_at
FROM dbo.sdt_ticket_pass AS ticketPass
INNER JOIN dbo.users AS users
    ON users.usr_id = ticketPass.owner_id
INNER JOIN dbo.order_items AS orderItem
    ON orderItem.order_items_sn = ticketPass.order_items_sn
WHERE ticketPass.owner_id BETWEEN 'U0000000008' AND 'U0000000014'
ORDER BY ticketPass.owner_id, ticketPass.pass_sn;
GO

-- 驗證二：每種狀態的筆數，預期 Active=6、UnActive=3、Expire=1、Depleted=1、Cancelled=1。
SELECT
    valid_status,
    COUNT(*) AS pass_count
FROM dbo.sdt_ticket_pass
WHERE owner_id BETWEEN 'U0000000008' AND 'U0000000014'
GROUP BY valid_status
ORDER BY valid_status;
GO

-- 驗證三：學生 Profile 的目前票券快照。
SELECT
    users.usr_id,
    users.usr_name,
    profile.sdt_cur_ticket_id,
    profile.sdt_cur_ticket_type,
    profile.sdt_cur_ticket_valid_state,
    profile.sdt_cur_ticket_payment_state,
    profile.sdt_cur_ticket_remain_count,
    profile.sdt_cur_ticket_expire_dt
FROM dbo.sdt_profile AS profile
INNER JOIN dbo.users AS users
    ON users.usr_id = profile.usr_id
WHERE profile.usr_id BETWEEN 'U0000000008' AND 'U0000000014'
ORDER BY profile.usr_id;
GO
