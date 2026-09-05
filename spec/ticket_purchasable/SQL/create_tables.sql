-- =============================================================================
-- 健身房系統 (Gym System) - 資料表建立腳本 (5 張核心資料表)
-- 檔案位置: C:\Users\HarryLin\Desktop\DayTemp\2026\0903\create_tables.sql
-- 包含資料表:
--   1. ticket_plan_kind        (票券種類表)
--   2. plan_rule               (規則定義表)
--   3. ticket_plan_kind_rule   (票券種類規則關聯表)
--   4. order_items             (訂單明細表)
--   5. sdt_ticket_pass         (學生票券資料表)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. 票券種類表 (ticket_plan_kind)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.ticket_plan_kind (
    ticket_plan_kind_sn INT IDENTITY(1,1) PRIMARY KEY,  -- 主鍵流水號

    ticket_plan_kind_code VARCHAR(50) NOT NULL,        -- 代碼
    ticket_plan_kind_type NVARCHAR(20) NOT NULL,        -- 類型
    ticket_plan_family_code VARCHAR(50) NULL,           -- 屬於哪種家族
    ticket_plan_kind_cname NVARCHAR(100) NOT NULL,       -- 中文名稱

    ticket_plan_kind_price DECIMAL(10,2) NOT NULL,      -- 價格
    ticket_plan_kind_default_credit INT NULL,       -- 額度
    ticket_plan_kind_default_expire_days INT NULL,  -- 有效天數

    ticket_plan_kind_default_is_active varchar(1) NOT NULL,    -- 是否啟用
    
    CONSTRAINT UQ_ticket_plan_kind_code UNIQUE (ticket_plan_kind_code)
);
GO

-- -----------------------------------------------------------------------------
-- 2. 規則定義表 (plan_rule)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.plan_rule (
    plan_rule_sn            VARCHAR(20)    NOT NULL PRIMARY KEY, -- R_001
    plan_rule_code          VARCHAR(50)    NOT NULL,      -- NEW_ONLY
    plan_rule_name          NVARCHAR(100)  NOT NULL,             -- 新客限定
    plan_rule_desc          NVARCHAR(255)  NULL,
    plan_rule_is_active     VARCHAR(1)     NOT NULL DEFAULT 'Y',
    plan_rule_create_dt     DATETIME       NOT NULL DEFAULT GETDATE(),
    plan_rule_up_dt         DATETIME       NULL,
    
    CONSTRAINT UQ_plan_rule_code UNIQUE (plan_rule_code)
);
GO

-- -----------------------------------------------------------------------------
-- 3. 票券種類規則關聯表 (ticket_plan_kind_rule)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.ticket_plan_kind_rule (
    ticket_plan_kind_sn               INT          NOT NULL,
    plan_rule_sn                      VARCHAR(20)  NOT NULL,
    ticket_plan_kind_rule_is_enabled  VARCHAR(1)   NOT NULL
        CONSTRAINT DF_ticket_plan_kind_rule_is_enabled DEFAULT ('Y'),
    ticket_plan_kind_rule_create_dt   DATETIME     NOT NULL DEFAULT GETDATE(),
    ticket_plan_kind_rule_up_dt       DATETIME     NULL,

    CONSTRAINT PK_ticket_plan_kind_rule 
        PRIMARY KEY (ticket_plan_kind_sn, plan_rule_sn)
);
GO

-- -----------------------------------------------------------------------------
-- 4. 訂單明細表 (order_items)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.order_items (
    order_items_sn INT IDENTITY(1,1) NOT NULL,

    -- 邏輯關聯 orders.orders_sn，不建立 DB FK
    orders_sn INT NOT NULL,

    -- 明細編號日期快照，來自 orders.order_buy_date
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

    -- 折扣類別和折扣比率
    discount_type VARCHAR(50) NULL,
    discount_rate DECIMAL(5,4) NULL,
    
    order_items_up_pn VARCHAR(50) NULL,
    order_items_up_dt DATETIME NOT NULL
        CONSTRAINT DF_order_items_up_dt DEFAULT (GETDATE()),

    CONSTRAINT PK_order_items
        PRIMARY KEY (order_items_sn),

    CONSTRAINT UQ_order_items_id
        UNIQUE (order_items_id)
);

CREATE INDEX IX_order_items_orders_sn
ON dbo.order_items (orders_sn);
GO

-- -----------------------------------------------------------------------------
-- 5. 學生票券資料表 (sdt_ticket_pass)
-- -----------------------------------------------------------------------------
CREATE TABLE dbo.sdt_ticket_pass (
    -- 1. 新增內部實體主鍵流水號 (自動遞增)
    pass_sn INT IDENTITY(1,1) NOT NULL,
    
    -- (為了讓計算欄位可以抓到時間，將 create_dt 移到前面)
    create_dt DATETIME NOT NULL CONSTRAINT DF_sdt_ticket_pass_create_dt DEFAULT (GETDATE()),

    -- 2. 外部唯一ID (計算欄位: PASS + YYYYMMDD + 6碼流水號)
    pass_id AS (
        'PASS' + 
        CONVERT(VARCHAR(8), create_dt, 112) + 
        RIGHT('000000' + CAST(pass_sn AS VARCHAR(6)), 6)
    ) PERSISTED NOT NULL,
    
    -- 關聯到訂單明細表 (不可唯一)
    order_items_sn INT NOT NULL,
    
    -- 關聯到訂單表(主表)
    orders_sn INT NOT NULL,
    
    -- 和 users.usr_id 對應
    owner_id VARCHAR(50) NOT NULL,
    
    -- 票券代碼快照
    ticket_plan_kind_code VARCHAR(50) NOT NULL,
    
    -- 票券類型快照 (例如 PACK 或 M_PASS)
    ticket_plan_kind_type NVARCHAR(20) NOT NULL,
    
    -- 新票承接的來源票券
    renewed_from_pass_sn INT NULL,
      
    -- 啟用狀態: UnActive、Active、Expire、Depleted、Cancelled
    valid_status NVARCHAR(50) NOT NULL,
    
    -- 生效日期
    valid_sdate DATETIME NULL,
    
    -- 票券到期日
    valid_edate DATETIME NULL,
    
    -- 實際結束時間
    ended_at DATETIME NULL,

    -- Expire、Depleted、Cancelled
    end_reason VARCHAR(20) NULL,
    
    -- 購買總堂數
    credits_total INT NULL,
    
    -- 剩餘堂數
    credits_remaining INT NULL,
    
    -- 其他系統欄位
    create_pn VARCHAR(50) NULL,
    update_dt DATETIME NULL,
    update_pn VARCHAR(50) NULL,

    -- === 設定約束條件 ===
    
    -- 1. 設定 Primary Key 為內部流水號，提高查詢與關聯效能
    CONSTRAINT PK_sdt_ticket_pass PRIMARY KEY (pass_sn),
    
    -- 2. 設定對外的 pass_id 為唯一值，確保不重複
    CONSTRAINT UQ_sdt_ticket_pass_id UNIQUE (pass_id)
);

-- 建立索引以增加查詢效能
CREATE INDEX IX_sdt_ticket_pass_order_items_sn ON dbo.sdt_ticket_pass (order_items_sn);
CREATE INDEX IX_sdt_ticket_pass_orders_sn ON dbo.sdt_ticket_pass (orders_sn);
CREATE INDEX IX_sdt_ticket_pass_owner_id ON dbo.sdt_ticket_pass (owner_id);

CREATE UNIQUE INDEX UX_sdt_ticket_pass_renewed_from_pass_sn
  ON dbo.sdt_ticket_pass (renewed_from_pass_sn)
  WHERE renewed_from_pass_sn IS NOT NULL
    AND valid_status <> N'Cancelled';
GO
