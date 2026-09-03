# Database New

- 人員資料表 **`users`**
    - 所有角色共用的基本資料。
    - Create Table Code
        
        ```sql
        CREATE TABLE dbo.users
        (
            usr_no INT IDENTITY(1,1) NOT NULL,
        
            usr_id AS (
                'U' + RIGHT(REPLICATE('0', 10)
                + CAST(usr_no AS VARCHAR(10)), 10)
            ) PERSISTED,
        
            usr_name      NVARCHAR(50) NOT NULL,
            usr_phone     VARCHAR(20)  NOT NULL,
            usr_pwd       VARCHAR(255) NOT NULL,
            usr_active    BIT NOT NULL
                CONSTRAINT DF_users_active DEFAULT (1),
            usr_create_dt DATETIME2(0) NOT NULL
                CONSTRAINT DF_users_create_dt DEFAULT (SYSDATETIME()),
        
            CONSTRAINT PK_users PRIMARY KEY (usr_no),
            CONSTRAINT UQ_users_id UNIQUE (usr_id),
            CONSTRAINT UQ_users_phone UNIQUE (usr_phone)
        );
        INSERT INTO dbo.users (usr_name, usr_phone, usr_pwd, usr_active, usr_create_dt)
        VALUES
            (N'管理員1', '0900000000', '0900000000', 1, '2026-05-01 20:04:27.780'),
            (N'老師小美', '0911111111', '0911111111', 1, '2026-05-01 20:04:27.780'),
            (N'老師小愛', '0922222221', '0922222221', 1, '2026-05-01 20:04:27.780'),
            (N'學生小靖', '0933333333', '0933333333', 1, '2026-05-01 20:04:27.780'),
            (N'學生喵喵', '0944444444', '0944444444', 1, '2026-05-01 20:04:27.780'),
            (N'老師1',  '0912345678', '0912345678', 1, '2026-05-01 20:04:27.780'),
            (N'老師2',  '0922111222', '0922111222', 1, '2026-05-01 20:04:27.780');
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `usr_no` | Primary Key | 系統使用，數字 |  |
    | `usr_id` | nvarChar | 唯一ID，前端顯示用，依照usr_no
    產生 |  |
    | `usr_active` | bool | 帳號 啟用/停用 | • 啟用: 1
    • 停用: 0 |
    | `usr_pwd`  | varChar | 使用者密碼
    唯一，目前都是用手機號碼
    admin →0900000000 |  |
    | `usr_name` | Text | 姓名 | 王小明 |
    | `usr_phone` | Text | 聯絡電話 | 0912345678 |
    | `usr_create_dt` | DateTime | 建立時間 | 2025-11-01 |
- 角色表 **`bmc_role`**
    - Create Table Code
        
        ```sql
        -- bmc_role
        CREATE TABLE dbo.bmc_role (
            bmc_role_id         INT            IDENTITY(1,1) NOT NULL,
            bmc_role_name       NVARCHAR(50)   NOT NULL,
            bmc_role_code       VARCHAR(30)    NOT NULL,
            bmc_role_cdt  DATETIME2(0)   NOT NULL CONSTRAINT DF_bmc_role_create_dt DEFAULT (SYSDATETIME()),
            bmc_role_upd_dt     DATETIME2(0)   NOT NULL CONSTRAINT DF_bmc_role_upd_dt DEFAULT (SYSDATETIME()),
            CONSTRAINT PK_bmc_role PRIMARY KEY (bmc_role_id),
            CONSTRAINT UQ_bmc_role_code UNIQUE (bmc_role_code),
        );
        
        INSERT INTO dbo.bmc_role (bmc_role_name, bmc_role_code)
        VALUES 
        (N'員工', 'Staff'),
        (N'老師', 'Instructor'),
        (N'學生', 'Student'),
        (N'管理者', 'Admin');
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`bmc_role_id`** | Primary Key | 唯一ID |  |
    | **`bmc_role_name`** | nvarChar |   • 員工
      • 老師
      • 學生
      • 管理者 |  |
    | **`bmc_role_code`** | nvarChar |   • 員工→ `Staff`
      • 老師→ `Instructor`
      • 學生→ `Student`
      • 管理者→ `Admin` |  |
    | **`bmc_role_cdt`** | DateTime | 建立日期 |  |
    | **`bmc_role_upd_dt`** | DateTime | 更新日期 |  |
- 人員角色關聯資料表 **`user_role`**
    - 一個人可以有多個角色
    - **`usr_id`** 、**`bmc_role_id`** 當作複合主鍵
    - Create Table code
        
        ```sql
        CREATE TABLE dbo.user_role (
            usr_id               NVARCHAR(50)  NOT NULL,
            bmc_role_id          INT           NOT NULL,
            // 1:啟用, 0:不啟用
            user_role_is_active  BIT   NOT NULL CONSTRAINT DF_user_role_is_active DEFAULT (1),
            user_role_cdt        DATETIME2(0)  NOT NULL CONSTRAINT DF_user_role_cdt DEFAULT (SYSDATETIME()),
            user_role_upd_dt      DATETIME2(0)  NOT NULL CONSTRAINT DF_user_role_upd_dt DEFAULT (SYSDATETIME()),
            CONSTRAINT PK_user_role PRIMARY KEY (usr_id, bmc_role_id)
        );
        
        INSERT INTO user_role(usr_id, bmc_role_id)
        VALUES 
        (N'U00001', 4),
        (N'U00001', 2),
        (N'U00002', 2),
        (N'U00003', 2),
        (N'U00006', 2);
        
        CREATE UNIQUE INDEX UX_user_roles_user_role
        ON dbo.user_role (usr_id, bmc_role_id);
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`usr_id`** | Primary Key | 人員id，必須來自`users.usr_id` |  |
    | **`bmc_role_id`** | Primary Key | 角色id，必須來自**`bmc_role.bmc_role_id`** |  |
    | **`user_role_is_active`** | bool | 身分別是否啟用 |  |
    | **`user_role_cdt`** | DateTime | 建立日期 |  |
    | **`user_role_upd_dt`** | DateTime | 更新日期 |  |
- 學生擴展表 **`sdt_profile`**
    - 目前這張表當作快取中心，放的內容是最近一次進場時間及最新的票券，包含剩餘堂數。
    - 未來可以擴充緊急連絡人等靜態欄位資訊
    - 該表更新時機
        - **進場成功時：** 更新 `last_visit_at`。
        - **扣點/核銷時：** 更新 `plan_balance_display` (例如從 10 left 變 9 left) 和 `valid_state`。
        - **購買或付清時：** 更新 `payment_state`。
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `usr_id` | Primary Key | 和User  資料表的`usr_id` 一致 | C00001 |
    | `sdt_profile_cur_visit_at` | DateTime | 最近一次進場時間
    以三叉機log資料更新 |  |
    | `sdt_cur_ticket_id`  | varChar | 最新的票券id |  |
    | `sdt_cur_ticket_type` | Enum | 最新一筆票券的種類 |  |
    | `sdt_cur_ticket_valid_state` | Enum | 最新一筆票券的啟用狀態 |  |
    | `sdt_cur_ticket_payment_state` | Enum | 最新一筆票券的付款狀態 |  |
    | `sdt_cur_ticket_remain_count` | int(nullable) | 最新一筆票券的剩餘堂數(堂票才會有) |  |
    | `sdt_cur_ticket_expire_dt` | DateTime | 最新一筆票券的到期日 |  |
    | `sdt_cur_ticket_up_dt` | DateTime | 更新時間戳 |  |
- 學生票券資料表 **`sdt_ticket_pass`**
    - 學生持有的票券資訊，包括、到期日、使用次數，等使用權利。
    - `order_items_sn` 不可以唯一 ， 因為可能同一張訂單明細`order_items` 買了一個數量以上的相同方案(`order_items.quantity = 2;` pass A: `PACK_10`。pass B:`PACK_10`)。
    - ticket_plan_kind_type = PACK 時 credits_total / credits_remaining 不可為 NULL
    - ticket_plan_kind_type = M_PASS 時 credits_total / credits_remaining 可為 NULL
    - credits_remaining 不可大於 credits_total
    - Create Table
        
        ```sql
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
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `pass_sn` | Primary Key，int | 學生票券流水號 |  |
    | `create_dt` | datetime | 建立日期 |  |
    | `pass_id` | unique | 計算欄位: PASS + YYYYMMDD + 6碼流水號 |  |
    | `order_items_sn` | 關聯邏輯，不要unique，因為可能一張訂單買兩個相同方案 | 關聯到訂單明細表 |  |
    | `orders_sn` | 邏輯關聯，int | 關聯到訂單表(主表) |  |
    | `owner_id` | 邏輯關聯，varchar(21) | 和`users.usr_id`對應 | C00001 |
    | `ticket_plan_kind_code` | nvarchar(50) | 票券代碼快照，來自`order_items_ref_id` |  |
    | `ticket_plan_kind_type` | nvarchar(20) | 票券類型快照，方便判斷月票或堂票。來自`ticket_plan_kind_type` |  |
    | `renewed_from_pass_sn` | int | 新票承接的舊票 pass_sn；一般首購票為 NULL |  |
    | `valid_status` | Text，nvarchar(50) | 啟用狀態:
    `UnActive`(未啟用)
    `Active`(啟用中)
    `Expire`(已過期)
    `Depleted` (已用完)
    `Cancelled` (取消) | `Active` |
    | `valid_sdate` | DateTime | **票券實際生效日期** |  |
    | `valid_edate` | DateTime | **票券實際到期日** |  |
    | `ended_at` |  | 提前用完、取消或實際結束的時間 |  |
    | `end_reason` |  | 建議使用 Expire、Depleted、Cancelled |  |
    | 堂票(Pack) 專用欄位 |  |  |  |
    | `credits_total` | int nullable | 購買總堂數。 | 10 |
    | `credits_remaining` | int nullable | 剩餘堂數。 | 9 |
    |  |  |  |  |
    | `create_pn` | varchar(21) |  |  |
    | `update_dt` | datetime | 更新日期 |  |
    | `update_pn` | varchar(21) |  |  |
- 學生出席課程紀錄表 `sdt_att_record`
    - 資料新增條件: 從三叉機傳送進入的紀錄過10min 後都沒有出去的紀錄。
    
    | **欄位名稱** | **資料類型** | **說明** |
    | --- | --- | --- |
    | **`sdt_att_record_sn`** | int | 出席流水號 |
    | **`user_id`** | Foreign Key | 使用者編號，關連到`user`表，用它來驗證身份。 |
    | **`cls_scdle_arnge_sn`** | Foreign Key | 課程編號，關連到`cls_scdle_arnge`表 |
    | **`sdt_att_record_ticket_id`** | Foreign Key | 票券，以什麼票券進入該堂課 |
    | **`sdt_att_record_status`** | varChar | 出席狀態
    • `Pending`(暫時進出)，進場後，10min內出去會是這個狀態。
    • `CheckIn`(已簽到)，進場10min後都在內場，會變這個狀態。
    • `CheckOut`(已簽退)，課程結束後，有簽退會是這個狀態。 |
    | **`sdt_att_record_chk_in_time`** | DateTime | 簽到 |
    | **`sdt_att_record_chk_out_time`** | DateTime | 簽退 |
    | **`sdt_att_record_remark`** | varChar (Nullable) | 備註 |
    | **`sdt_att_record_upd_source`** | varChar | 異動來源
    • `Costumer_Click` (客人點擊)
    • `System_ForgotCheckout` (系統更新)
    • `Staff_Manual` (員工手動補登) |
    | **`sdt_att_record_upd_by_staff`** | varChar | 如果是員工補登，此欄位會顯示員工的id |
    | **`sdt_att_record_upd_date`** | DateTime | 資料異動時間 |
    
- 票券核銷表 **`sdt_ticket_usage_log`**
    - 學生票券的使用紀錄，Insert only
    - `usage_sn` , `pass_sn` 做為複合主鍵
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `usage_sn` | Primary Key | 核銷紀錄流水號 | 1, 2, 3... |
    | `pass_sn` | int not null | 關聯到 `sdt_ticket_pass` |  |
    | `attendance_sn` | int nullable | 關連到 `sdt_att_record` |  |
    | `idempotency_key` | varchar(100) not null | 相同裝置事件或相同請求重送時，避免扣除兩次。 |  |
    | `usage_action` | VARCHAR(20) NOT NULL | 區分一般核銷 `Consume` 與沖銷 `Reverse` |  |
    | `usage_type` | Enum | 核銷方式：
     • `Manual` (櫃檯手動)
     • `Gate_Entry` (閘門進場)
     • **`Auto_Consecutive`** (未離場，自動核銷) | Gate |
    | `usage_dt` | DateTime | 核銷/進場時間 | 2026-03-13 19:30:00 |
    | `deducted_credits` | Int not null | 這次扣了多少堂（月票則存 0） | 1 |
    | `credits_before_snapshot` | int nullable | 堂數快照，註銷前餘額
    (月票為null) |  |
    | `credits_after_snapshot` | Int | 堂數快照，註銷後餘額(月票為null) | 9 |
    | `reversed_usage_sn` | int | 沖銷時指向原始核銷紀錄；依目前「只保留主鍵、不建立外鍵」原則，不設外鍵約束。 |  |
    | `operator_id` | VarChar | 操作者 ID（閘門進場可存 System） | admin_01 |
    | `remark` | Text | 備註 | 逾時未進場補發、或手動扣點說明 |
- 訂單表 **`orders`**
    - Create Table
        
        ```sql
        CREATE TABLE dbo.orders (
            -- 1. 實體主鍵 (提高查詢效能)
            orders_sn INT IDENTITY(1,1) NOT NULL,
            
            -- 2. 購買日期 (不可為空)
            order_buy_date DATETIME NOT NULL CONSTRAINT DF_orders_buy_date DEFAULT (GETDATE()),
            
            -- 3. 程式中使用的訂單編號 (計算欄位 ORD + YYYYMMDD + 5碼流水號)
            orders_id AS (
                'ORD' + 
                CONVERT(VARCHAR(8), order_buy_date, 112) + 
                RIGHT('000000' + CAST(orders_sn AS VARCHAR(6)), 6)
            ) PERSISTED NOT NULL,
            
            -- 4. 購買者資訊 (外鍵與快照)
            orders_buyer_id VARCHAR(50) NULL,
            orders_buyer_name NVARCHAR(50) NULL,
            
            -- 5. 訂單狀態
            orders_overall_payment_state VARCHAR(20) NULL,
                
            -- 6. 金額欄位 (DECIMAL(10,2) 支援到千萬位數，小數點2位)
            orders_total_amount DECIMAL(10,2) NOT NULL CONSTRAINT DF_orders_total_amount DEFAULT (0),
            orders_actual_amount DECIMAL(10,2) NOT NULL CONSTRAINT DF_orders_actual_amount DEFAULT (0),
           
            -- 7. 系統操作紀錄
            orders_create_pn VARCHAR(50) NULL,
            orders_create_dt DATETIME NOT NULL CONSTRAINT DF_orders_create_dt DEFAULT (GETDATE()),
            orders_up_pn VARCHAR(50) NULL,
            orders_up_dt DATETIME NOT NULL CONSTRAINT DF_orders_up_dt DEFAULT (GETDATE()),
        
            -- === 設定約束條件 ===
            CONSTRAINT PK_orders PRIMARY KEY (orders_sn),     -- 設定 orders_sn 為真實 Primary Key
            CONSTRAINT UQ_orders_id UNIQUE (orders_id)        -- 設定 orders_id 唯一，避免重複
        );
        
        insert into orders
        (
        	order_buy_date,
        	orders_buyer_id,
        	orders_buyer_name,
        	orders_overall_payment_state,
        	orders_total_amount,
        	orders_actual_amount,
        	orders_create_dt,
        	orders_create_pn
        
        )
        values
        -- 購買月票
        (GETDATE(), 'U0000000005', '學生喵喵', 'Paid', 1960.00, 1960.00, GETDATE(), 'Test')
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `orders_sn` | Primary Key int | 訂單流水號，數字，增加查詢效能 |  |
    | `order_buy_date` | DateTime not null | 購買日期 |  |
    | `orders_id` | not null  | 程式中用這個
    `ORD` +`YYYYMMDD`+ `orders_sn` (補零到6碼) | YYYYMMdd是購買日期 |
    | `orders_buyer_id` | varChar | 購買者id | `users.usr_id` |
    | `orders_buyer_name`  | nvarChar(50) | 查詢快照，購買者名稱 |  |
    | `orders_overall_payment_state` | enum | 訂單總付款狀態
      • `Paid` (全品項付清)
      •  `Refund` (退款)
      • `UnPaid` (未付清)
      • `Cancel` (取消訂單) |  |
    | `orders_total_amount`  | decimal | 訂單總金額 |  |
    | `orders_actual_amount`  | decimal | 訂單實收總額 |  |
    | `orders_create_dt` | DateTime | 建立該筆訂單的時間 |  |
    | `orders_up_pn` | varChar | 更新該筆訂單的人 | `users.usr_id` |
    | `orders_up_dt` | DateTime | 更新該筆訂單的時間 |  |
- 訂單明細表 **`order_items`**
    - 購買商品或方案數量
    - Create Table
        
        ```sql
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
        
            -- 7. 折扣類別和折扣比率
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
        
        -- ---- value
        insert into order_items(
        	orders_sn ,
        	order_items_buy_date,
        	order_items_type,
        	order_items_ref_id,
        	order_items_name,
        	order_items_payment_state,
        	order_items_payment_method,
        	order_items_unit_price,
        	order_items_total_amount,
        	order_items_actual_amount,
        	order_items_quantity,
        	bonus_benefit_quantity,
        	bonus_benefit_unit,
        	order_items_create_pn
        )
        values
        (1, '2026-08-14 16:47:19.787', 'Ticket', 'MONTHLY', '月票', 'Paid', 'Cash', '1960.00', '1960.00', '1960.00', '1', 0, null, 'test_id')
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `order_items_sn` | Primary Key | 訂單明細流水號 DB 內部用 |  |
    | `orders_sn` | INT NOT NULL, INDEX | 訂單流水號，邏輯關聯 `orders.orders_sn`，不建立 DB FK |  |
    | `order_items_buy_date` | DateTime not null | 明細編號日期快照，來自`orders`，用於產生 `order_items_id`  |  |
    | `order_items_id` | VARCHAR(32) NOT NULL UNIQUE | 訂單明細流水號 對外的code
    `ITM` + `YYYYMMdd` + `order_items_sn` (補零到6碼) | `YYYYMMdd` 購買日期 |
    | `order_items_type` | Enum | 訂單品項類別
      • `Ticket` 
      • `Product`  |  |
    | `order_items_ref_id` | varChar | 訂單品項編號
      • 票券 →`ticket_plan_kind_code`     
      • 商品 → `products_code` |  |
    | `order_items_name` | nvarchar | 品項名稱快照 |  |
    | `order_items_payment_state` | Enum | 付款狀態
      • `Paid`
      • `UnPaid`
      • `Refund`
      • `Cancel` |  |
    | `order_items_paid_at` | DATETIME nullable | 付款日期，付款後才開始計算有效日 |  |
    | `order_items_payment_method` | Enum | 付款方式
      • 目前會是Cash |  |
    | `order_items_unit_price` | Decimal | 明細單價快照
    票券 →`ticket_plan_kind_price` 
    商品
    →`product_unit_price`  |  |
    | `order_items_total_amount` | Decimal | 這筆訂單應收的錢 |  |
    | `order_items_actual_amount` | Decimal | 這筆訂單實際收的錢 |  |
    | `order_items_quantity` | int | **品項購買數量**
    票券
     • 方案票券張數(幾份方案)
    商品 
      • 商品數量 |  |
    | `bonus_benefit_quantity` | int NOT NULL DEFAULT 0 | **額外贈送權益數量**
    票券
     • 月票 → 天數
     • 堂票 → 次數
    商品 
     • 商品數量 |  |
    | `bonus_benefit_unit` | varchar(20) nullable
    bonus_benefit_quantity > 0 時，bonus_benefit_unit 不可為 NULL | **額外贈送權益的單位
      • `Days` 
      • `Credits` 
      • `Pieces`** |  |
    | `discount_type` | varchar(50) nullable | 折扣類別，目前只有
    `Family` 、`Renewal` 方案 |  |
    | `discount_rate`  | decimal(5, 4) nullable | 折扣比例，95折0.95 |  |
    | `order_items_create_pn` | VarChar(50) | 建立資料的人 | `users.usr_id` |
    | `order_items_create_dt` | DateTime | 建立該明細資料的時間 |  |
    | `order_items_up_pn` | varChar | 更新檔案的人 | `users.usr_id` |
    | `order_items_up_dt` | DateTime | 更新檔案時間 |  |
- 訂單通用變更紀錄表 **`order_audit_logs`**
    - 利用`batch_id` 「把同一次操作中，產生的多筆欄位改動串在一起」。
        
        當使用者做一次**「付錢」(Pay)**的操作時，系統會改動**多個資料表 / 多個欄位**，因此會產生**多筆 audit log**。這些 log 雖然是不同資料，但都屬於**同一個行為**，所以用**同一個 `batch_id`**來關聯。
        
    - 另一個比較省空間的改動是，以整張表為單位改。
        - target_table 欄位
        - change_data欄位(JSON格式)
    
    | **欄位名稱** | **資料型別** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`log_sn`** | Primary Key | 紀錄流水號 | 1, 2, 3... |
    | **`orders_sn`** | 邏輯關聯 | 整筆交易的編號（必填，用來快速找出一筆單的所有歷史）。 |  |
    | **`batch_id`** | varChar | 該次改動的流水號
    (有可能一次改兩個欄位，所以該欄位可以重複) | C20260313001 |
    | **`order_items_sn`** | 邏輯關聯 | **(可為空)** 關聯的明細流水號 | ITM_005 (若是改主表則填 NULL) |
    | **`target_table`** | Varchar | 發生變動的資料表名稱 | `orders` 或 `order_items` |
    | **`target_column`** | Varchar | **變動的欄位名稱** | `payment_state`, `actual_amount` |
    | **`old_value`** | **NVarChar** | 變更前的值（轉成文字儲存） | `Unpaid` 或 `1860` |
    | **`new_value`** | **NVarChar** | 變更後的值（轉成文字儲存） | `Paid` 或 `1800` |
    | **`operator_id`** | Varchar | 操作者 ID（是誰改的） | `admin_01` |
    | **`log_dt`** | DateTime | 紀錄產生的時間 | 2026-03-13 14:00:00 |
    | **`remark`** | Text | 備註（選填） | 學生現場付現、手動折扣 60 元 |
- 票券種類表 **`ticket_plan_kind`**
    - 負責分類票券種類，月票的有效天數
    - `ticket_plan_family_code`
        - 定義票券方案屬於哪個家族，例如: 月票和月票(續約)，是屬於月票家族。
        - 設計目的是要讓同方案家族能續約。
        - 方案家族表格
            
            
            | Code | FamilyCode |
            | --- | --- |
            | COUPON | COUPON |
            | FREE_TRIAL | FREE_TRIAL |
            | NEW_PROMO | NEW_PROMO |
            | SINGLE | SINGLE |
            | MONTHLY | MONTHLY |
            | RENEW | MONTHLY |
            | B6G1 | HALF_YEAR |
            | B6G1_RENEW | HALF_YEAR |
            | B12G2 | YEAR |
            | B12G2_RENEW | YEAR |
            | PACK_10 | PACK_10 |
            | PACK_10_RENEW | PACK_10 |
            | PACK_20 | PACK_20 |
            | PACK_20_RENEW | PACK_20 |
    - Create Table code
        
        ```sql
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
        
        INSERT INTO dbo.ticket_plan_kind (
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
        -- 單次與抵用券
        ('SINGLE',      'PACK', 'SINGLE',      N'單次票',       250,   1,   null,   'Y'),
        ('COUPON',      'PACK', 'COUPON',      N'折抵票',       0,     1,   30,  'Y'),
        ('FREE_TRIAL',  'PACK', 'FREE_TRIAL',  N'免費體驗票',    0,     1,   14,   'Y'),
        
        -- 堂票系列 (PACK)
        ('PACK_10',            'PACK', 'PACK_10',   N'10堂票',         2300,  10,  90,  'Y'),
        ('PACK_10_RENEW',      'PACK', 'PACK_10',   N'10堂票(續約)',   2200,  10,  90,  'Y'),
        ('PACK_20',            'PACK', 'PACK_20',   N'20堂票',         4400,  20,  90,  'Y'),
        ('PACK_20_RENEW',      'PACK', 'PACK_20',   N'20堂票(續約)',    4300,  20,  90,  'Y'),
        ('NEW_PROMO',          'PACK', 'NEW_PROMO', N'5堂票-新朋友',  1200,  5,   30,  'Y'),
        
        -- 月票系列 (M_PASS)
        ('MONTHLY',     'M_PASS', 'MONTHLY',    N'月票',            1960,  null, 30,  'Y'),
        ('RENEW',       'M_PASS', 'MONTHLY',    N'月票(續約)',          1860,  null, 30,  'Y'),
        ('B6G1',        'M_PASS', 'HALF_YEAR',  N'半年票 買6送1',    11260, null, 210, 'Y'),
        ('B6G1_RENEW',  'M_PASS', 'HALF_YEAR',  N'半年票(續約) 買6送1',    11160, null, 210, 'Y'),
        ('B12G2',       'M_PASS', 'YEAR',       N'年票 買12送2',    22420, null, 420, 'Y'),
        ('B12G2_RENEW', 'M_PASS', 'YEAR',       N'年票(續約) 買12送2',    22320, null, 420, 'Y')
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `ticket_plan_kind_sn` | INT (PK) | 僅提供資料庫關聯使用 |  |
    | `ticket_plan_kind_code` | Enum | 票券代碼，唯一索引，提供工程師在程式碼中調用
      • `SINGLE`(單次)
      • `COUPON`(折抵票)
      • `PACK_10`(10堂票)
      • `PACK_20`(20堂票)
      • `NEW_PROMO`(是否為新客 ，用於"5堂-新朋友"方案，這個方案只能買一次)
      • `RENEW`(續約票，在有效期間內至來源票結束日 +9 天內)
    • `MONTHLY`月票
    • `B12G2` 買12送2月票
    • `B6G1` 買6送1月票
    • `FREE_TRIAL`(免費體驗票) |  |
    | `ticket_plan_kind_type` | Enum | 票券種類
      • `PACK`(堂票) 
      • `M_PASS`(月票) |  • `PACK`(堂票)
        • `SINGLE`
        • `COUPON` 
        • `PACK_10`
        • `PACK_20`
        • `FREE_TRIAL`
        • `NEW_PROMO`
     • `M_PASS`(月票)
        • `RENEW`
        • `MONTHLY`
        • `B12G2` 
        • `B6G1`  |
    | `ticket_plan_family_code`  | VARCHAR(50) | 此欄位定義隸屬於哪一種票券家族方案。
    
    `` |  |
    | `ticket_plan_kind_cname` | varChar | 票券名稱
      • `SINGLE`→ 單次
      • `MONTHLY`→ 月票
      • `COUPON` → 抵用券
      • `PACK_10`→ 10堂票
      • `PACK_20`→ 20堂票
      • `NEW_PROMO`→ 新朋友方案
      • `RENEW`→ 續約票
      • `FREE_TRIAL`→ 免費體驗
    票
      • `B12G2` →買12送2月票
      • `B6G1` →買6送1月票 |  |
    | `ticket_plan_kind_price` | Decimal(10,2) | 票券價格
      • `SINGLE`→ 250
      • `MONTHLY`→ 1960
      • `COUPON` → 0
      • `PACK_10`→ 2300
      • `PACK_20`→ 4400
      • `NEW_PROMO`→ 1200
      • `RENEW`→ 1860 
      • `FREE_TRIAL`→ 0
      • `B12G2` →22420
      • `B12G2_RENEW` → 22320
      • `B6G1` → 11260
      • `B6G1_RENEW`→ 11160 |  |
    | `ticket_plan_kind_default_credit` | INT NULL | 預設使用次數
    月票一律null |  • `M_PASS`→ null
     • `SINGLE`→ 1
     • `COUPON` → 1
     • `PACK_10`→ 10
     • `PACK_20`→ 20
     • `FREE_TRIAL`→ 1
     • `NEW_PROMO`→ 5
     |
    | `ticket_plan_kind_default_expire_days` | int | 預設到期天數 |   • `SINGLE`→ null
      • `MONTHLY`→ 30
      • `COUPON` → 30
      • `PACK_10`→ 90
      • `PACK_20`→ 90
      • `NEW_PROMO`→ 30
      • `RENEW`→ 30
      • `FREE_TRIAL`→ 14
      • `B12G2` → 420
      • `B6G1` → 210 |
    | `ticket_plan_kind_default_is_active` | varChar(1) | 是否上架
      • `Y`上架
      • `N`下架不顯示 |  |
- 規則定義表 **`plan_rule`**
    - 定義產品(票券、商品、課程)適用的規則，為了能夠讓前端畫面根據規則顯示可購買的票券。
    - Create Table code
        
        ```sql
        -- 1) Tag 字典表
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
        
        INSERT INTO plan_rule (
            plan_rule_sn,
            plan_rule_code,
            plan_rule_name,
            plan_rule_desc
        )
        VALUES
        ('R_001', 'NEW_ONLY', N'新會員限定', N'只能讓新會員使用'),
        ('R_002', 'RENEWAL', N'續約方案', N'符合續約資格可使用'),
        ('R_003', 'FAMILY_ELIGIBLE', N'家庭方案', N'符合家庭方案資格'),
        ('R_004', 'HIDDEN', N'特殊方案', N'特殊方案');
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `plan_rule_sn` | varChar(PK) | 僅提供資料庫關聯使用格式: R_數字`R_001` |  |
    | `plan_rule_code` | Enum | 規則代碼，唯一索引，提供工程師在程式碼中調用 
      • `FAMILY_ELIGIBLE` 家庭方案
      • `RENEWAL` 續約方案
      • `NEW_ONLY` 新會員方案
      • `HIDDEN` 特殊方案 |  |
    | `plan_rule_name` | nvarChar | 規則名稱
      • `FAMILY_ELIGIBLE` →家庭方案
      • `RENEWAL`  →續約方案
      • `NEW_ONLY`  →新會員方案
      • `HIDDEN`  →特殊方案 |  |
    | `plan_rule_desc` | nvarChar | 規則描述
      • `FAMILY_ELIGIBLE` →95折優惠
      • `RENEWAL`  → 續約優惠
      • `NEW_ONLY`  →限定新會員使用
      • `HIDDEN`  →特殊方案 |  |
    | `plan_rule_is_active` | VARCHAR(1) | 是否啟用此規則，全域開關。
    規則全域停用或無法執行時，依賴限制型規則的方案不可購買，不得省略驗證後放行。
     • 啟用: `Y`
     • 不啟用: `N` |  |
    | `plan_rule_create_dt` | DateTime | 規則建立日期 |  |
    | `plan_rule_up_dt` | DateTime | 規則更新日期 |  |
- 票券種類規則關聯表 **`ticket_plan_kind_rule`**
    - 定義哪一種票券套用哪些規則。一種票券可以適用多個規則；一種規則可以用在多個票券。
    - `ticket_plan_kind_sn` , `plan_rule_sn` 當複合主鍵。
    - Create Table code
        
        ```sql
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
                  /* 月票、半年票、年票及堂票的既有家庭方案設定 */
                  (N'MONTHLY',        'FAMILY_ELIGIBLE'),
                  (N'B6G1',           'FAMILY_ELIGIBLE'),
                  (N'B12G2',          'FAMILY_ELIGIBLE'),
                  (N'PACK_10',        'FAMILY_ELIGIBLE'),
                  (N'PACK_20',        'FAMILY_ELIGIBLE'),
        
                  /* 月票續約目前既有家庭方案設定 */
                  (N'RENEW',          'FAMILY_ELIGIBLE'),
        
                  /* 五張續約 SKU */
                  (N'RENEW',          'RENEWAL'),
                  (N'B6G1_RENEW',     'RENEWAL'),
                  (N'B12G2_RENEW',    'RENEWAL'),
                  (N'PACK_10_RENEW',  'RENEWAL'),
                  (N'PACK_20_RENEW',  'RENEWAL'),
        
                  /* 新會員限定 */
                  (N'NEW_PROMO',      'NEW_ONLY'),
                  (N'FREE_TRIAL',     'NEW_ONLY'),
        
                  /* 特殊隱藏方案 */
                  (N'COUPON',         'HIDDEN')
          ) AS ruleMapping
          (
              ticket_plan_kind_code,
              plan_rule_code
          )
          INNER JOIN dbo.ticket_plan_kind AS planKind
              ON planKind.ticket_plan_kind_code =
                 ruleMapping.ticket_plan_kind_code
          INNER JOIN dbo.plan_rule AS planRule
              ON planRule.plan_rule_code =
                 ruleMapping.plan_rule_code;
                 
        -- 最後驗證：
        
          SELECT
              planKind.ticket_plan_kind_code,
              planKind.ticket_plan_family_code,
              planKind.ticket_plan_kind_cname,
              planKind.ticket_plan_kind_price,
              planKind.ticket_plan_kind_default_credit,
              planKind.ticket_plan_kind_default_expire_days,
              planRule.plan_rule_code,
              relation.ticket_plan_kind_rule_is_enabled
          FROM dbo.ticket_plan_kind AS planKind
          LEFT JOIN dbo.ticket_plan_kind_rule AS relation
              ON relation.ticket_plan_kind_sn =
                 planKind.ticket_plan_kind_sn
          LEFT JOIN dbo.plan_rule AS planRule
              ON planRule.plan_rule_sn =
                 relation.plan_rule_sn
          ORDER BY
              planKind.ticket_plan_kind_sn,
              planRule.plan_rule_code;
        ```
        
    - 目前票券對應的方案表
        
        
        | **票券名稱 (Name)** | **票種 (Type)** | **目前的 Tags 設定** | **這些 Tags 產生的影響** |
        | --- | --- | --- | --- |
        | 單次票 (Single Pass) | 次數票  | [] (無) | 所有人皆可看見、購買。不支援家庭方案。 |
        | 月票 (Monthly) | 期限票  | ['FAMILY_ELIGIBLE'] | 可用於家庭方案折扣。 |
        | 月票續約票 (Renewal) | 期限票  | ['RENEWAL', 'FAMILY_ELIGIBLE'] | 限舊會員續約時才會顯示。可用於家庭方案折扣。 |
        | 半年票 買6送1 (7 Months) | 期限票 | [’FAMILY_ELIGIBLE’] | 可用於家庭方案折扣。 |
        | 半年票(續約) 買6送1 (7 Months) | 期限票 | ['RENEWAL'] |  |
        | 年票 買12送2 (14 Months) | 期限票  | ['FAMILY_ELIGIBLE'] | 可用於家庭方案折扣。 |
        | 年票(續約) 買12送2 (14 Months) | 期限票  | ['RENEWAL'] |  |
        | 5堂票-新朋友 (Short Trial) | 次數票  | ['NEW_ONLY'] | 限新會員才會顯示。不支援家庭方案。 |
        | 免費體驗票 (Free Trial) | 次數票  | ['NEW_ONLY'] | 限新會員才會顯示。不支援家庭方案。 |
        | 10堂票 (10 Sessions) | 次數票  | [’FAMILY_ELIGIBLE’] | 可用於家庭方案折扣。 |
        | 10堂票 續約 (10 Sessions) | 次數票  | ['RENEWAL'] |  |
        | 20堂票 (20 Sessions) | 次數票  | [’FAMILY_ELIGIBLE’] | 可用於家庭方案折扣。 |
        | 20堂票 續約 (20 Sessions) | 次數票  | ['RENEWAL'] |  |
        | 折抵票 (Custom) | 次數票  | ['HIDDEN'] | （預計）在前台結帳介面中要被隱藏起來，僅供內部邏輯替換使用。 |
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `ticket_plan_kind_sn` | INT，Composite PK，邏輯關聯 ticket_plan_kind | 票券種類，必須來自
    `ticket_plan_kind.ticket_plan_kind_sn` |  |
    | `plan_rule_sn` | VARCHAR(20)，Composite PK，邏輯關聯 plan_rule | 規則種類，必須來自
    `plan_rule.plan_rule_sn` |  |
    | `ticket_plan_kind_rule_is_enabled` | varchar(1) | 定義該票券的此規則是否啟用 | 啟用 → `Y`
    不啟用 → `N` |
    | `ticket_plan_kind_rule_create_dt`  | DateTime | 該規則建立日期 |  |
    | `ticket_plan_kind_rule_up_dt` | DateTime | 規則更改日期 |  |
- 產品種類表 **`products`** (目前暫時用不到)
    
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`products_id`** | PK | 商品內部流水號 |  |
    | **`products_code`** | varChar | 商品代碼
    給`order_items_ref_id` 關聯用 |  |
    | **`products_name`** | varChar | 商品名稱 |  |
    | **`products_category`** | Enum | 商品類別
    `Food`, `Equipment` |  |
    | **`products_unit_price`** | Decimal | 商品價格(定價) |  |
    | **`products_stock_qty`** | int  | 商品庫存量 |  |
    | **`products_safety_stock`** | int | 安全庫存量 |  |
    | **`products_is_active`** | boolean | 是否上架 |  |
    | **`products_create_dt`** | DateTime | 商品建立日 |  |
    | **`products_update_dt`** | DateTime | 最後更新時間(最後異動庫存時間) |  |
- 預設課程表 **`class`**
    - 課程預設資訊，實際排課表是在`cls_scdle_arnge`
    - Create Table Code
        
        ```sql
        CREATE TABLE dbo.class (
            -- 課程序號 (主鍵)
            class_sn            INT             IDENTITY(1,1) NOT NULL,
            -- 1. 先定義計算資料行與 PERSISTED
            class_id AS ('CLS' + RIGHT(REPLICATE('0', 6) + CAST(class_sn AS VARCHAR(6)), 6)) PERSISTED,
            -- 2. 獨立宣告 UNIQUE 約束條件
            CONSTRAINT UQ_class_id UNIQUE (class_id),
                
            -- 課程名稱
            class_name          NVARCHAR(100)   NULL,
            -- 標籤顏色
            class_label_color   NVARCHAR(200)    NULL,
            -- 課程時長
            class_duration      INT             NULL,
            -- 是否免費 (0: 否, 1: 是)
            class_is_free       BIT          NOT NULL CONSTRAINT DF_class_is_free DEFAULT(0),
            -- 預設授課老師 ID
            class_default_instructor_id NVARCHAR(50)    NULL,
            -- 預設授課老師 名字
            class_default_instructor_name NVARCHAR(50)    NULL,
            -- 課程狀態 (0: 下架, 1: 上架)
            class_is_active     BIT          NOT NULL CONSTRAINT DF_class_is_active DEFAULT (1),
            -- 課程分類
            class_type          NVARCHAR(50)    NULL,
            -- 建立資訊
            class_create_pn     NVARCHAR(50)    NULL,
            class_create_dt     DATETIME        NULL CONSTRAINT DF_class_create_dt DEFAULT (GETDATE()),
            -- 更新資訊
            class_up_pn         NVARCHAR(50)    NULL,
            class_up_dt         DATETIME        NULL CONSTRAINT DF_class_up_dt DEFAULT (GETDATE()),
            -- 定義主鍵
            CONSTRAINT PK_class PRIMARY KEY (class_sn),
        );
        
        INSERT INTO dbo.class (
            class_name, 
            class_label_color, 
            class_duration, 
            class_is_free, 
            class_default_instructor_id, 
            class_default_instructor_name, 
            class_is_active, 
            class_type, 
            class_create_pn,  
            class_up_pn
        )
        VALUES 
            (N'基礎重量訓練', '#FF5733', 60, 0, 'U0000000001', N'管理員1', 1, N'重訓', 'Admin', 'Admin'),
            (N'極限燃脂拳擊', '#C70039', 50, 0, 'U0000000002', N'老師小美', 1, N'有氧', 'Admin', 'Admin'),
            (N'舒緩陰瑜珈', '#DAF7A6', 90, 1, 'U0000000001', N'管理員1', 1, N'瑜珈', 'Admin', 'Admin'),
            (N'核心皮拉提斯', '#581845', 60, 0, 'U0000000003', N'老師小愛', 1, N'核心', 'Admin', 'Admin'),
            (N'進階健體專班', '#2ECC71', 120, 0, 'U0000000002', N'老師小美', 0, N'重訓', 'Admin', 'Admin'),
            (N'攀岩協調性訓練', '#2ECC71', 80, 0, 'U0000000006', N'老師1', 1, N'協調', 'Admin', 'Admin'),
            (N'臀大肌推舉訓練', '#FF5733', 30, 0, 'U0000000006', N'老師1', 1, N'重訓', NULL, NULL);
        
        SELECT *  FROM class
        
        -- 請確保 dbo.users 表中已經存在這些 usr_id
        INSERT INTO dbo.class (
            class_name, 
            class_label_color, 
            class_duration, 
            class_is_free, 
            class_default_instructor_id,
            class_default_instructor_name,
            class_is_active, 
            class_type, 
            class_create_pn, 
            class_up_pn
        )
        VALUES 
        (N'基礎重量訓練', N'#FF5733', 60, 0, N'U0000000001', N'管理員1', 1, N'重訓', N'Admin', N'Admin'),
        (N'極限燃脂拳擊', N'#C70039', 50, 0, N'U0000000002', N'老師小美', 1, N'有氧', N'Admin', N'Admin'),
        (N'舒緩陰瑜珈', N'#DAF7A6', 90, 1, N'U0000000001', N'管理員1', 1, N'瑜珈', N'Admin', N'Admin'),
        (N'核心皮拉提斯', N'#581845', 60, 0, N'U0000000003', N'老師小愛', 1, N'核心', N'Admin', N'Admin'),
        (N'進階健體專班', N'#2ECC71', 120, 0, N'U0000000002', N'老師小美', 0, N'重訓', N'Admin', N'Admin'); -- 這筆預設為下架狀態
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`class_sn`** | PK | 課程流水號 |  |
    | **`class_id`** | varChar ，唯一 | 課程唯一，避免將流水號直接暴露在api上， | CLS000001 |
    | **`class_name`** | varChar | 課程名稱 |  |
    | **`class_label_color`** | varChar | 課程標籤顏色(對應到前端顏色) |  |
    | **`class_duration`** | int | 上課時長(min) |  |
    | **`class_is_free`** | Boolean | 該堂課是否免費 |  |
    | **`class_default_instructor_id`** | Foreign key | 該課程預設指導老師，關連到 `users` 表 | 不一定要有這個 |
    | **`class_default_instructor_name`** | nvarChar | 該預設課程老師名字，讓刪除老師資料時，不要因為完全依賴`users`表而報錯 |  |
    | **`class_is_active`** | boolean | 該堂課現在是否開課狀態 |  |
    | **`class_type`** | Enum | 課程種類
    目前沒分類，當作未來擴充 |  |
    | **`class_create_pn`** | Foreign key | 建立課程人員 |  |
    | **`class_create_dt`** | DateTime | 建立日期 |  |
    | **`class_up_pn`**  | Foreign key | 更新人員 |  |
    | **`class_up_dt`**  | DateTime | 更新日期 |  |
- 排課規則表 **`cls_scdle_rules`**
    - 這張資料表會作為schedule template 使用。
    - Create Table
        
        ```sql
        CREATE TABLE dbo.cls_scdle_rules (
            -- 👇 PK（內部用）
            cls_scdle_rules_seq INT IDENTITY(1,1) NOT NULL,
            -- 👇 對外業務編號
            cls_scdle_rules_sn AS (
                'SCHR' + RIGHT('000000000' + CAST(cls_scdle_rules_seq AS VARCHAR(10)), 10)
            ) PERSISTED,
            
            -- 關聯到 class 表
            class_id						        VARCHAR(15)     NOT NULL,
            -- 星期幾 (1-7)
            cls_scdle_rules_day_wk			INT             NOT NULL,
            -- 開始時間 (不含日期)
            cls_scdle_rules_st				  TIME            NOT NULL,
        	  -- 上課時長
        	  cls_scdle_duration				  INT				      NOT NULL, 
        	  -- 結束時間 (由資料庫自動計算：開始時間 + 時長，並實體儲存)
            cls_scdle_rules_et          TIME            NOT NULL,
        	  -- 結束後的緩衝時間 (分鐘)
        	  cls_scdle_rules_buffer_time		INT				NOT NULL,
            -- 老師 ID 
            cls_scdle_instructor_id			VARCHAR(21)     NOT NULL,
            -- 此規則是否還在執行，用來Soft delete (預設為 1: true)
            cls_scdle_rules_is_active		BIT             NOT NULL CONSTRAINT DF_cls_scdle_rules_is_active DEFAULT (1),
            -- 定義主鍵
            CONSTRAINT PK_cls_scdle_rules	PRIMARY KEY (cls_scdle_rules_sn)
        );
        
        -- 新增排課規則範本
        INSERT INTO dbo.cls_scdle_rules (
            class_id,
            cls_scdle_rules_day_wk,
            cls_scdle_rules_st,
            cls_scdle_duration,
            cls_scdle_rules_et,
            cls_scdle_rules_buffer_time,
            cls_scdle_instructor_id,
            cls_scdle_rules_is_active
        )
        VALUES
        -- 規則 1：每週一 09:00，基礎重量訓練 (60分鐘)，換場緩衝 15 分鐘
        ('CLS000001', 1, '09:00:00', 60, '10:00:00', 15, 'U000000001', 1),
        
        -- 規則 2：每週三 18:30，極限燃脂拳擊 (50分鐘)，換場緩衝 10 分鐘
        ('CLS000002', 3, '18:30:00', 50, '19:20:00', 10, 'U0000000002', 1),
        
        -- 規則 3：每週五 20:00，舒緩陰瑜珈 (90分鐘)，換場緩衝 15 分鐘
        ('CLS000003', 5, '20:00:00', 90, '21:30:00', 15, 'U0000000001', 1),
        
        -- 規則 4：每週六 10:00，核心皮拉提斯 (70分鐘，依據圖片)，換場緩衝 10 分鐘
        ('CLS000004', 6, '10:00:00', 70, '11:10:00', 10, 'U0000000003', 1);
        
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`cls_scdle_rule_seq`** | Primary Key 
    int | 資料庫序號 |  |
    | **`cls_scdle_rules_sn`** | varChar | 規則唯一編號 | SCHR00000001 |
    | **`class_id`** | varchar(15) | 關聯到 `class`表 | CLS000004 |
    | **`cls_scdle_rules_day_wk`** | Int | 星期幾 (1-7 ) | 1 (週一) |
    | **`cls_scdle_rules_st`** | Time | 開始時間 (不含日期) | 09:00:00 |
    | **`cls_scdle_duration`** | int | 上課時長(分鐘) |  |
    | **`cls_scdle_rules_et`** | Time | 結束時間 (不含日期 |  |
    | **`cls_scdle_rules_buffer_time`** | int | 結束後緩衝時間(分鐘) |  |
    | **`instructor_id`** | varchar(21) | 關連到 `user_role`表，老師 ID | U0000000003 |
    | **`cls_scdle_rules_is_active`** | Boolean | 此規則是否還在執行，用來Soft delete | true |
- 排課實例表 **`cls_scdle_arnge`**
    - 記錄實際安排的課程表
    - Create Table
        
        ```sql
        CREATE TABLE dbo.cls_scdle_arnge (
            -- 排課流水號 (主鍵，自動遞增)
            cls_scdle_arnge_sn              INT             IDENTITY(1,1) NOT NULL,
           
            -- 獨立日期欄位 (往上移，讓下方的 ID 可以取用它)
            cls_scdle_date                  DATE            NOT NULL,
            
            -- 唯一ID (由資料庫自動計算：CLS + YYYYMMDD + 7碼流水號)
            cls_scdle_arnge_id AS (
                'CLSA' + 
                CONVERT(VARCHAR(8), cls_scdle_date, 112) + 
                RIGHT(REPLICATE('0', 7) + CAST(cls_scdle_arnge_sn AS VARCHAR(7)), 7)
            ) PERSISTED,
            
            -- 關聯到 class 表
            class_id                        VARCHAR(15)     NULL,
            
            -- 課程名稱快照
            class_name                      NVARCHAR(100)   NULL,
            
            -- 標籤顏色快照
            class_label_color               NVARCHAR(200)   NULL,
            
            -- 這堂課當前的指導老師，關聯到 users
            cls_scdle_arnge_instructor_id   VARCHAR(21)     NULL, 
            
            -- 授課老師名字快照
            instructor_name                 NVARCHAR(50)    NULL,
            
            -- 課程開始時間
            cls_scdle_arnge_st              DATETIME        NOT NULL,
            
            -- 課程結束時間
            cls_scdle_arnge_et              DATETIME        NOT NULL,
            
            -- 該課程狀態 (Cancel, Open, Ongoing, Finished)
            cls_scdle_status                VARCHAR(50)     NULL,
            
            -- 該堂課是否免費 (預設為和課程定義一樣)
            cls_scdle_arnge_is_free         BIT             NOT NULL,
              
            -- 課程目前異動/新增來源 (Auto, Manual)
            cls_scdle_source                VARCHAR(20)     NULL,
            
            -- 關聯到 cls_scdle_rules 用Soft reference
            cls_scdle_rules_sn              VARCHAR(40)     NULL,          
            
            -- 建立時間 (預設為當前時間)
            cls_scdle_arnge_create_dt       DATETIME        NOT NULL CONSTRAINT DF_cls_scdle_arnge_create_dt DEFAULT (GETDATE()),
            
            -- 更新時間 (預設為當前時間)
            cls_scdle_arnge_up_dt           DATETIME        NULL CONSTRAINT DF_cls_scdle_arnge_up_dt DEFAULT (GETDATE()),
            
                 
            -- 定義主鍵
            CONSTRAINT PK_cls_scdle_arnge PRIMARY KEY (cls_scdle_arnge_sn),
            
            -- 定義唯一約束條件，確保產生的 ID 絕對不會重複
            CONSTRAINT UQ_cls_scdle_arnge_id UNIQUE (cls_scdle_arnge_id)
        );
        
        -- 新增實際排課資料
        INSERT INTO dbo.cls_scdle_arnge (
            cls_scdle_date,
            class_id, 
            class_name, 
            class_label_color, 
            cls_scdle_arnge_instructor_id, 
            instructor_name, 
            cls_scdle_arnge_st, 
            cls_scdle_arnge_et, 
            cls_scdle_status,
            cls_scdle_arnge_is_free, 
            cls_scdle_source, 
            cls_scdle_rules_sn
        )
        VALUES 
        -- 實例 1：來自規則 1 (週一)。狀態: 已結束 (Finished)
        ('2026-05-18', 'CLS000001', N'基礎重量訓練', '#FF5733', 'U0000000001', N'管理員1', 
         '2026-05-18 09:00:00', '2026-05-18 10:00:00', 'Finished', '0', 'Auto', 'SCHR0000000001'),
        
        -- 實例 2：來自規則 2 (週三)。注意：原本是老師小美，這邊假設因為請假換成老師1來代課，狀態: 開放中 (Open)
        ('2026-05-20', 'CLS000002', N'極限燃脂拳擊', '#C70039', 'U0000000006', N'老師1', 
         '2026-05-20 18:30:00', '2026-05-20 19:20:00', 'Open', '0', 'Auto', 'SCHR0000000002'),
        
        -- 實例 3：來自規則 3 (週五)。狀態: 開放中 (Open)
        ('2026-05-22', 'CLS000003', N'舒緩陰瑜珈', '#DAF7A6', 'U0000000001', N'管理員1', 
         '2026-05-22 20:00:00', '2026-05-22 21:30:00', 'Open', '1', 'Auto', 'SCHR0000000003'),
        
        -- 實例 4：手動加開 (Manual)。沒有對應規則 (rules_sn = NULL)。狀態: 取消 (Cancel)
        ('2026-05-24', 'CLS000007', N'臀大肌推舉訓練', '#FF5733', 'U0000000006', N'老師1', 
         '2026-05-24 14:00:00', '2026-05-24 14:30:00', 'Cancel', '0', 'Manual', NULL);
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`cls_scdle_arnge_sn`** |  | 排課流水號 |  |
    | **`cls_scdle_date`**  | DATE | 獨立日期欄位，方便以「天」為單位查詢 |  |
    | **`cls_scdle_arnge_id`** |  | 唯一ID，CLSA+西元年+月份+日期+**`cls_scdle_arnge_sn`** 向左補7個0 |  |
    | **`class_id`** | varchar(15) | 關連到**`class`** 表 |  |
    | **`class_name`** | NVARCHAR(100) | 課程名稱快照 |  |
    | **`class_label_color`** | nvarchar(20) | 標籤顏色快照 |  |
    | **`cls_scdle_arnge_instructor_id`** | varChar(21) | 這堂課當前的指導老師
    關連到**`users`** |  |
    | **`instructor_name`** | nvarchar(50) | 授課老師名字快照 |  |
    | **`cls_scdle_arnge_st`** | DateTime | 課程開始時間 |  |
    | **`cls_scdle_arnge_et`** | DateTime | 課程結束時間 |  |
    | **`cls_scdle_status`** | varchar(50) | 該課程狀態
      • **`Cancel`**
      • **`Open`
      • `Ongoing`
      • `Finished`** |  |
    | **`cls_scdle_arnge_is_free`** | bool | 該堂課是否為免費 |  |
    | **`cls_scdle_source`** | varchar(20) | 課程目前異動/新增來源
      • `Auto`
      • `Manual` |  |
    | **`cls_scdle_rules_sn`** | varchar | 關連到`cls_scdle_rules`
    用Soft reference |  |
    | **`cls_scdle_arnge_create_dt`** | datetime | 建立時間 |  |
    | **`cls_scdle_arnge_up_dt`** | datetime | 更新時間 |  |
- 排課異動表 **`cls_scdle_arnge_log`**
    - 將課程異動存入JSON/Text，格式如下:
        
        ```json
        {
          "instructor_id": { "old": "admin_01", "new": "admin_05" },
          "st_time": { "old": "09:00", "new": "10:00" },
          "status": { "old": "normal", "new": "changed" }
        }
        ```
        
    - Create Table
        
        ```sql
        CREATE TABLE dbo.cls_scdle_arnge_log (
            -- 紀錄流水號 (主鍵，自動遞增)
            cls_scdle_arnge_log_sn      INT             IDENTITY(1,1) NOT NULL,
            
            -- 關聯到排課實例表 (哪一堂課被改了)
            cls_scdle_arnge_sn          INT             NOT NULL,
            
            -- 異動資料欄位與值 (儲存 JSON 格式)
            cls_scdle_changed_data      NVARCHAR(MAX)   NOT NULL,
            
            -- 操作者 ID (長度設定 50 較有彈性，可依您的 users 表調整)
            operator_id                 VARCHAR(50)     NOT NULL,
            
            -- 紀錄產生的時間 (預設帶入當前時間)
            cls_scdle_arnge_log_dt      DATETIME        NOT NULL CONSTRAINT DF_cls_scdle_arnge_log_dt DEFAULT (GETDATE()),
            
            -- 異動原因 (選填)
            cls_scdle_arnge_log_remark  NVARCHAR(MAX)   NULL,
        
            -- 定義主鍵
            CONSTRAINT PK_cls_scdle_arnge_log PRIMARY KEY (cls_scdle_arnge_log_sn),
            
            -- (選擇性強烈建議) 確保寫入的異動資料真的是合法的 JSON 格式
            CONSTRAINT CK_cls_scdle_changed_data_IsJson CHECK (ISJSON(cls_scdle_changed_data) = 1)
        );
        
        -- 新增排課異動紀錄
        INSERT INTO dbo.cls_scdle_arnge_log (
            cls_scdle_arnge_sn, 
            cls_scdle_changed_data, 
            operator_id, 
            cls_scdle_arnge_log_remark
        )
        VALUES 
        -- 紀錄 1：對應實例 2 (cls_scdle_arnge_sn = 2)，原本是 U0000000002 (老師小美)，後來換成 U0000000006 (老師1)
        (2, 
         N'{
            "cls_scdle_arnge_instructor_id": { "old": "U0000000002", "new": "U0000000006" },
            "instructor_name": { "old": "老師小美", "new": "老師1" }
         }', 
         'admin_01', 
         N'原老師小美生病請假，由老師1代課'),
        
        -- 紀錄 2：對應實例 4 (cls_scdle_arnge_sn = 4)，課程被取消
        (4, 
         N'{
            "cls_scdle_status": { "old": "Open", "new": "Cancel" }
         }', 
         'admin_01', 
         N'報名人數不足，手動取消課程');
        ```
        
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`cls_scdle_arnge_log_sn`** | Primary Key | 紀錄流水號 | 1, 2, 3... |
    | **`cls_scdle_arnge_sn`** | Foreign Key | 關聯到 `cls_scdle_arnge` | 501 (哪一堂課被改了) |
    | **`cls_scdle_changed_data`** |  | 異動資料欄位與值 |  |
    | **`operator_id`** | VarChar | 操作者 ID | admin_01 |
    | **`cls_scdle_arnge_log_dt`** | DateTime | 紀錄產生的時間 | 2026-03-13 14:00:00 |
    | **`cls_scdle_arnge_log_remark`** | Text | 異動原因 (選填)
    保留 |  |
- 進出紀錄表 **`device_record`**
    - 三叉機刷入刷出都會產生這張表
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`device_record_sn`** | PK | 流水號 | 1 |
    | **`usr_id`** | FK | 誰刷的 | U0001 |
    | **`direction`** | Int / Enum | 進或出 | 1: 進, 2: 出 |
    | **`method`** | VarChar | 感應方式 | `QR_Code`, `RFID`, `System_Open`, `Manual_Open` |
    | **`device_id`** | VarChar | 機器編號 (新增) | Gate_01, Gate_02 |
    | **`is_success`** | Boolean | 是否成功開啟 (新增) | true (成功), false (失敗) |
    | **`device_record_dt`** | DateTime | 感應時間 | 2026-03-13 19:10:00 |