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
            CONSTRAINT UQ_bmc_role_code UNIQUE (bmc_role_code)
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
            -- 1:啟用, 0:不啟用
            user_role_is_active  BIT   NOT NULL CONSTRAINT DF_user_role_is_active DEFAULT (1),
            user_role_cdt        DATETIME2(0)  NOT NULL CONSTRAINT DF_user_role_cdt DEFAULT (SYSDATETIME()),
            user_role_upd_dt      DATETIME2(0)  NOT NULL CONSTRAINT DF_user_role_upd_dt DEFAULT (SYSDATETIME()),
            CONSTRAINT PK_user_role PRIMARY KEY (usr_id, bmc_role_id)
        );
        
        INSERT INTO user_role(usr_id, bmc_role_id)
        VALUES 
        (N'U0000000001', 4),
        (N'U0000000001', 2),
        (N'U0000000002', 2),
        (N'U0000000003', 2),
        (N'U0000000006', 2);
        
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
    - 2026-10-06 同步已確認行為：緩衝期可建立 Pending／暫占資料；正式出席以「課程開始＋十分鐘」截止時的館內狀態確認，不是每個人進場後各等十分鐘。占用儲存與資料建立細節仍待設計，這裡不代表 DB 已完成變更。
    - 截止前離場未回者不成立出席並釋放暫占；確認後中途離場仍保留出席及固定占用，離場／返回另查進出紀錄。
    - 缺票留館保存事實及 Ineligible／remark，不欠堂、不扣負數、不補結算，也不授予同堂回場資格。
    - 2026-10-16 使用者決策：出席／額度占用相關資料表不建立外鍵；關聯完整性由程式端驗證與交易流程維護。此決策不排除主鍵、唯一索引、check constraint 等資料表內部防線。
    - 2026-10-16 唯讀資料品質查核：刪除前共 1 筆，必要關聯欄位無 NULL、學生＋場次無重複；該筆會員與票券 ID 無對應資料、場次仍存在。依使用者明確指示，在確認無其他資料表引用後，以單一交易刪除該筆並確認此表剩 0 筆；未另存副本。
    - 2026-10-16 唯讀查核 GymDB：此表已存在；目前欄位型別為 `sdt_att_record_sn int`、`user_id nvarchar(50) NULL`、`cls_scdle_arnge_sn int NULL`、`sdt_att_record_ticket_id nvarchar(50) NULL`、`sdt_att_record_status nvarchar(20) NULL`、check-in/out `datetime NULL`、remark `nvarchar(max) NULL`、upd_source／upd_by_staff `nvarchar(50) NULL`、upd_date `datetime NULL`。目前僅查到主鍵，未查到學生＋場次唯一索引、外鍵或 check constraint。
    - 2026-10-17 使用者核准後，已套用 [保留資料的 ALTER](spec/IO_gyms/04-出席確認與額度占用/sql/02-align-attendance.sql)：新增 `sdt_att_record_ticket_eligibility_state varchar(20) NULL`、`sdt_att_record_create_dt datetime2(3) NOT NULL`；user_id／場次／狀態／更新時間改為 NOT NULL，進出與更新時間改為 datetime2(3)，新增學生＋場次唯一索引及場次狀態查詢索引。執行前後均為 0 筆，不曾刪除或回填資料，沒有 FK、rowversion 或新增 CHECK。下方 CREATE 仍為新庫目標草案，其 CHECK 不代表本次已部署；實際舊庫沿用原主鍵名稱，不刪表重建。
    - 以下 ID 關聯先採邏輯關聯、不建立 FK，延續現有更正資料表設計原則；正式 migration 前仍須檢查既有資料與完整索引／約束。

    **CREATE TABLE 草案（文件用，未執行）**

    ```sql
    CREATE TABLE dbo.sdt_att_record
    (
        sdt_att_record_sn INT IDENTITY(1,1) NOT NULL,
        user_id NVARCHAR(50) NOT NULL,
        cls_scdle_arnge_sn INT NOT NULL,
        -- 儲存 sdt_ticket_pass.pass_id；Pending 期間可對應暫占票券，A 確認後固定為該堂票券。
        sdt_att_record_ticket_id NVARCHAR(50) NULL,
        -- Attendance fact state; eligibility and credit reservation are separate dimensions.
        sdt_att_record_status NVARCHAR(20) NOT NULL,
        sdt_att_record_ticket_eligibility_state VARCHAR(20) NULL,
        -- Summary timestamps only. device_record remains the source for reconstructing presence.
        sdt_att_record_chk_in_time DATETIME2(3) NULL,
        sdt_att_record_chk_out_time DATETIME2(3) NULL,
        sdt_att_record_remark NVARCHAR(MAX) NULL,
        sdt_att_record_upd_source NVARCHAR(50) NULL,
        sdt_att_record_upd_by_staff NVARCHAR(50) NULL,
        sdt_att_record_create_dt DATETIME2(3) NOT NULL,
        sdt_att_record_upd_date DATETIME2(3) NOT NULL,
        CONSTRAINT PK_sdt_att_record
            PRIMARY KEY (sdt_att_record_sn),
        CONSTRAINT UQ_sdt_att_record_user_session
            UNIQUE (user_id, cls_scdle_arnge_sn),
        CONSTRAINT CK_sdt_att_record_status
            CHECK (sdt_att_record_status IN
                   ('Pending', 'CheckIn', 'CheckOut', 'Cancelled', 'NeedsReview')),
        CONSTRAINT CK_sdt_att_record_ticket_eligibility
            CHECK (sdt_att_record_ticket_eligibility_state IS NULL
                   OR sdt_att_record_ticket_eligibility_state IN ('Eligible', 'Ineligible'))
    );

    CREATE INDEX IX_sdt_att_record_session_status
        ON dbo.sdt_att_record (cls_scdle_arnge_sn, sdt_att_record_status, user_id);

    ```

    **草案待確認事項：** `Cancelled`（截止前預參加取消）及 `NeedsReview`（進出事件不明、待人工確認）狀態碼、欄位 nullability、時間欄位是否保留摘要值、更新來源代碼，須在 migration 及 API／A 流程設計時確認。GymDB 目前的 `sdt_att_record_ticket_id` 為 `nvarchar(50)`，目標草案沿用並以 `sdt_ticket_pass.pass_id` 作邏輯對應；獨立占用表則建議使用 `pass_sn int` 作內部關聯鍵。`sdt_att_record_ticket_id` 不作為占用狀態；獨立占用表才是堂票暫占／固定／釋放／扣堂狀態依據。

    **`rowversion` 決策說明：** 目前未納入 GymDB migration／上方目標 DDL。它不能阻止更新或避免版本遞增；只有更新語句比對讀取時的舊版本值，才可偵測並拒絕過期寫入、避免靜默覆蓋。即使欄位值未變的 UPDATE，SQL Server 仍會改變 rowversion，因此程式仍應避免無效 UPDATE，並處理並行衝突。若後續決定採用樂觀並行控制，須一併改造所有更新路徑；額度加總與占用競態仍需交易鎖及唯一索引。
    
    | **欄位名稱** | **資料類型** | **說明** |
    | --- | --- | --- |
    | **`sdt_att_record_sn`** | int | 出席流水號 |
    | **`user_id`** | `nvarchar(50) NOT NULL` | 邏輯關聯 `users.usr_id`；無外鍵，已部署學生＋場次唯一索引。 |
    | **`cls_scdle_arnge_sn`** | `int NOT NULL` | 邏輯關聯 `cls_scdle_arnge.cls_scdle_arnge_sn`；無外鍵。 |
    | **`sdt_att_record_ticket_id`** | `nvarchar(50)`（目前允許 NULL） | 現況存票券 ID 字串，目標以 `sdt_ticket_pass.pass_id` 邏輯關聯。A 固定該堂票券，B 不依當下 Current Plan 重選；缺票可為 NULL。 |
    | **`sdt_att_record_status`** | `nvarchar(20) NOT NULL` | 出席狀態
    • `Pending`: 緩衝期內，出席尚未確認。中途離場則保留已確認出席、另查進出紀錄
    • `CheckIn`(已簽到)：在「開課＋十分鐘」截止時仍在館內，確認該堂出席事實；合法票券資格另外看 eligibility_state，不以 CheckIn 單獨授權或扣堂。
    • `CheckOut`(已簽退)，課程結束後，有簽退會是這個狀態。 |
    | **`sdt_att_record_ticket_eligibility_state`** | `varchar(20) NULL` | **該學生在「該課程出席確認時」的票券資格狀態。欄位於 2026-10-17 已部署，A 資格確認程式尚未串接。**
      •  `Eligible` : 有符合規則的票券；堂票已成功占用額度
      • `Ineligible`: 沒有可用票券，或沒有足夠可占用額度 |
    | **`sdt_att_record_chk_in_time`** | `datetime2(3) NULL` | 簽到摘要時間；還原進出仍以 `device_record` 為準。 |
    | **`sdt_att_record_chk_out_time`** | `datetime2(3) NULL` | 簽退摘要時間；還原進出仍以 `device_record` 為準。 |
    | **`sdt_att_record_remark`** | `nvarchar(max)`（目前允許 NULL） | 備註 |
    | **`sdt_att_record_upd_source`** | `nvarchar(50)`（目前允許 NULL） | 異動來源
    • `Costumer_Click` (客人點擊)
    • `System_ForgotCheckout` (系統更新)
    • `Staff_Manual` (員工手動補登) |
    | **`sdt_att_record_upd_by_staff`** | `nvarchar(50)`（目前允許 NULL） | 如果是員工補登，此欄位會顯示員工的id |
    | **`sdt_att_record_create_dt`** | `datetime2(3) NOT NULL` | 實際建立時間，台灣本地時間；2026-10-17 新增於空表，沒有回填歷史。 |
    | **`sdt_att_record_upd_date`** | `datetime2(3) NOT NULL` | 資料異動時間，台灣本地時間。 |
    
- 票券核銷表 **`sdt_ticket_usage_log`**
    - 學生票券的使用紀錄，Insert only
    - 維持實際 `usage_sn` 單一主鍵；票券關聯沿用 `pass_id`，不新增 `pass_sn` 複合主鍵。
    - 2026-10-16 唯讀查核 GymDB：實際欄位為 `usage_sn int`（PK）、`pass_id nvarchar(50)`、`usage_dt datetime`、`usage_type nvarchar(50)`、`deducted_credits int`、`rem_credits_snapshot int`、`operator_id nvarchar(50)`、`remark nvarchar(max)`；尚未查到 `attendance_sn`、`idempotency_key`、`usage_action` 或對應 Consume／Reverse 欄位。下表中未出現在此清單的欄位是設計／目標描述，不代表 GymDB 已部署。
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | `usage_sn` | Primary Key | 核銷紀錄流水號 | 1, 2, 3... |
    | `pass_id` | nvarchar(50) nullable（既有） | 沿用現有票券 ID 關聯；新課程核銷由程式要求有值及歸屬一致 | P1 |
    | `attendance_sn` | int NULL（2026-10-25 已新增） | 指向確切出席；新課程 Consume 必填，鎖定後查本堂 Consume 作業務防重 | 123 |
    | `usage_action` | varchar(20) NULL（2026-10-25 已新增） | Consume／Reverse；新課程核銷必填，舊資料無依據不推測回填 | Consume |
    | `usage_type` | nvarchar(50) nullable（既有） | 新課程核銷來源 Manual／Auto_Settlement；僅記來源，不作唯一防重條件。舊來源值不批次改寫 | Manual |
    | `usage_dt` | datetime2(3) NULL（2026-10-25 已轉型） | 業務時間設計：本堂結束時間；不是新進場事件時間 | 2026-03-13 20:00:00.000 |
    | `deducted_credits` | int nullable（既有） | 新課程 Consume 由程式要求為 1；月票不建立核銷，Reverse 的增退量表示留階段 06 細化 | 1 |
    | `credits_before_snapshot` | int NULL（2026-10-25 已新增） | 扣堂前餘額；新課程 Consume 必填，與扣後餘額核對 | 5 |
    | `rem_credits_snapshot` | int nullable（既有） | 沿用扣堂後餘額，不另外新增 credits_after_snapshot | 4 |
    | `recorded_at` | datetime2(3) NULL（2026-10-25 已轉型） | 真正處理時的台灣本地時間；新課程 Consume 必填，與 usage_dt 分開 | 2026-03-13 20:10:05.125 |
    | `reversed_usage_sn` | int NULL（2026-10-25 已新增、預留） | 第六階段 Reverse 指向原 Consume，不設外鍵；第五階段先不實作沖銷 | 456 |
    | `operator_id` | nvarchar(50) nullable（既有） | 操作者 ID（系統自動結算可記系統來源） | admin_01 |
    | `remark` | nvarchar(max) nullable（既有） | 備註 | 手動扣點說明 |

    - Create Table（完整結構：13 欄及兩個時間欄位 datetime2(3) 已部署）

        以下供新建資料庫參考；GymDB 已有此表及核銷資料，5 欄擴充及 usage_dt／recorded_at 的 ALTER COLUMN 轉型均已部署，保留資料、沒有重建。除這兩欄型別外，其餘欄位維持既有定義與 NULL 設定。主鍵採明確名稱；現有 GymDB 的系統產生主鍵名稱不因此變更。

        ```sql
        CREATE TABLE dbo.sdt_ticket_usage_log
        (
            usage_sn INT IDENTITY(1,1) NOT NULL,
            pass_id NVARCHAR(50) NULL,
            usage_dt DATETIME2(3) NULL,
            usage_type NVARCHAR(50) NULL,
            deducted_credits INT NULL,
            rem_credits_snapshot INT NULL,
            operator_id NVARCHAR(50) NULL,
            remark NVARCHAR(MAX) NULL,

            -- 第五階段：關聯出席、核銷類型及扣堂前餘額
            attendance_sn INT NULL,
            usage_action VARCHAR(20) NULL,
            credits_before_snapshot INT NULL,
            -- 台灣本地實際處理時間，與 usage_dt 業務時間分開
            recorded_at DATETIME2(3) NULL,
            -- 預留第六階段沖銷指向原核銷
            reversed_usage_sn INT NULL,

            CONSTRAINT PK_sdt_ticket_usage_log PRIMARY KEY (usage_sn)
        );
        ```

        不新增 FK、CHECK、扣堂唯一約束／索引或 rowversion；新課程核銷必要值及防重由共用程式、鎖定與交易處理。

    **2026-10-25 第五階段欄位部署完成：** 經使用者確認後執行 [ALTER SQL](spec/IO_gyms/05-課程結算與背景工作/sql/02-extend-ticket-usage-log.sql)，保留原 8 欄並新增 attendance_sn、usage_action、credits_before_snapshot、recorded_at 四個核心欄位，另預留 reversed_usage_sn，共 13 欄。提交前驗證新增欄位型別／允許 NULL／無預設值、原欄位定義及索引／約束不變，原 1 筆核銷資料各欄位值不變；提交後再次確認 13 欄與 1 筆資料。新欄位均為 NULL，不回填。新增時間欄位採 datetime；既有進出事件／占用／工作表 datetime2 不轉型。B 結算程式仍待實作，新課程必要值檢查及防重是程式目標，不因 schema 部署視為完成。

    不新增核銷 idempotency_key，也不新增「同堂扣一次」的 UNIQUE constraint／unique index、FK、CHECK 或 rowversion。人工與 B 共用服務，依既定順序在同一交易取得相關鎖，再查 attendance_sn ＋ Consume、核對票券／占用／核銷一致性；扣堂、寫核銷、Consumed 關聯及工作完成一併提交或回滾。接受直接 SQL 或未遵守鎖定流程者可繞過防重的限制；既有主鍵、占用表冪等鍵與索引不移除。

    **2026-10-25 後續決策及部署：時間精度對齊完成。** 經使用者確認後執行 [時間精度 ALTER](spec/IO_gyms/05-課程結算與背景工作/sql/03-align-usage-time-precision.sql)，將同一張 sdt_ticket_usage_log 的 usage_dt、recorded_at 兩欄改為 datetime2(3)，保留小數點第三位，允許 NULL 及台灣本地時間原則不變。提交前後驗證兩欄型別／scale=3／允許 NULL，原 1 筆資料在毫秒精度下核對一致，其餘欄位、索引與約束不變；沒有重建、刪除或回填。此決策取代上方先前部署時採 datetime 的目標，歷史部署記錄仍保留。C# 維持 DateTime；背景工作及核銷 repository 已局部明確傳 DbType.DateTime2，不修改全域 Dapper 或 JSON 設定。舊資料已遺失的精度不推測補回。

    **後續提醒：** 其他相關資料表的時間型別本輪不批次修改；未來處理票券、付款、會員或課表等資料表時，先提示時間精度尚待對齊，再確認欄位範圍、相依項目與資料保留方式後修改。詳見 [時間型別對齊待辦](spec/IO_gyms/issue/gym-io-issues.md#io-17-相關資料表時間精度對齊待處理時先提醒)。

    原 Consume 不刪除；Reverse 沿用原出席／票券並指向原核銷，防重同樣由共用交易與程式檢查。反覆沖銷後補認依第一版規則轉人工，不藉新 request_id 重扣。詳見 [階段 05 規劃](spec/IO_gyms/05-課程結算與背景工作/impelment_rule.md)。
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
    - 2026-10-16 第二階段採加欄方式擴充既有表，沒有刪除或重建舊資料。`Requested` 先於外部控制呼叫寫入；完成後更新為 `Succeeded`／`Failed`／`Unknown`／`Denied`。只有廠商明確成功、且不是 Mock，`affects_presence` 才可為 1。
    
    | **欄位名稱** | **資料類型** | **說明** | **範例** |
    | --- | --- | --- | --- |
    | **`device_record_sn`** | PK | 流水號 | 1 |
    | **`usr_id`** | FK | 誰刷的 | U0001 |
    | **`direction`** | Int / Enum | 進或出 | 1: 進, 2: 出 |
    | **`method`** | VarChar | 感應方式 | `QR_Code`, `RFID`, `System_Open`, `Manual_Open` |
    | **`device_id`** | VarChar | 機器編號 (新增) | Gate_01, Gate_02 |
    | **`is_success`** | Boolean | 是否成功開啟 (新增) | true (成功), false (失敗) |
    | **`device_record_dt`** | DateTime | 感應時間 | 2026-03-13 19:10:00 |
    | **`request_id`** | UniqueIdentifier / Unique filtered index | 呼叫方同一次操作的防重識別，不是授權憑證 | GUID |
    | **`gate_station_sn`** | Int | 邏輯對應進／出站點 | 1 |
    | **`gate_device_session_id`** | UniqueIdentifier | 操作當下的瀏覽器裝置授權 | GUID |
    | **`identity_kind`** | VarChar(20) | `Staff`／`Student`／`IdentifiedUser` 等身分快照 | Staff |
    | **`role_snapshot`** | NVarChar(1000) / JSON | 操作當下啟用角色，不存電話或 token | `["Admin"]` |
    | **`operation_kind`** | VarChar(30) | 第一版正常客人站點使用 `CustomerGate` | CustomerGate |
    | **`outcome`** | VarChar(20) | `Requested`／`Succeeded`／`Failed`／`Unknown`／`Denied` | Succeeded |
    | **`result_code`** | VarChar(80) | 穩定結果代碼 | COMMAND_ACCEPTED |
    | **`requested_at`** | DateTime2(3) | 後端收到操作並建立紀錄的台灣時間 | 2026-10-16 19:10:00.000 |
    | **`responded_at`** | DateTime2(3) | 收到廠商結果或確定拒絕的時間 | 2026-10-16 19:10:00.125 |
    | **`completed_at`** | DateTime2(3) | 此筆處理落庫完成的業務結果時間 | 2026-10-16 19:10:00.125 |
    | **`remark`** | NVarChar(500) | 非敏感異常說明，不存 Cookie／配對碼／電話 | 結果不明原因 |
    | **`affects_presence`** | Bit | 1 才能作館內狀態推導事件；失敗、拒絕、Unknown、Mock 必須為 0 | 1 |
    | **`is_simulated`** | Bit | 是否由 Turnstile Mock 產生；Mock 成功不等於實際進出 | 0 |
    | **`attendance_sn`** | Int NULL | 第四階段：此次開門準備對應的出席主鍵；邏輯關聯，不設外鍵 | 123 |
    | **`reservation_sn`** | BigInt NULL | 此次使用的占用；月票無占用時為 NULL；是否由本次建立另看下方旗標 | 456 |
    | **`admission_kind`** | VarChar(20) NULL | `RegularEntry`／`PreEntry`／`Return`；不是自由文字授權原因 | RegularEntry |
    | **`created_pending`** | Bit NULL | 本次是否新建／恢復 Pending；失敗時不得取消先前有效參加 | 1 |
    | **`created_reservation`** | Bit NULL | 本次是否新建占用；失敗只處理自己的新占用，不能釋放他次請求占用 | 1 |

    實際變更腳本：[第二階段 device_record 擴充](spec/IO_gyms/02-開門控制與進出紀錄/sql/02-extend-device-record.sql)。館內狀態第一版由每位使用者最後一筆 `affects_presence = 1` 的成功進／出事件推導；`sdt_profile_cur_visit_at` 仍只是學生最近成功進場時間，不單獨代表目前在館內。

    2026-10-17 已在開發／測試 GymDB 套用[第四階段開門關聯欄位](spec/IO_gyms/04-出席確認與額度占用/sql/03-link-gate-request-attendance.sql)：以上 5 欄均可 NULL，無新外鍵、CHECK、rowversion 或預設值，既有進出紀錄不回填、不改寫。舊紀錄全 NULL 表示沒有此階段準備上下文；已填 attendance_sn 卻缺少種類／旗標時視為資料不完整，不把 NULL 猜成 false。

## 進出站點與瀏覽器授權（第二階段資料設計）

整理日期：2026-10-10。依據：[裝置配對、換機、撤銷與授權保存規劃](spec/IO_gyms/02-開門控制與進出紀錄/01-device-pairing-and-authorization-plan.md)。

2026-10-16 已對開發／測試用 GymDB 執行經確認的冪等腳本，建立 `gate_station`、`gate_device_session`，並建立 `ENTRY_MAIN`／`EXIT_MAIN` 站點；執行後 SQL 整合測試已回滾測試資料並通過。其他環境仍須個別部署，不可因 GymDB 已完成便視為 NAS／正式環境已完成。

- 已確認：後端固定配對碼、獨立瀏覽器授權、持久 Cookie、新機確認後取代舊機、每站點只允許一份有效授權。
- 配對碼放後端設定，不存這兩張表，不放前端、Cookie、網址或日誌；真實配對碼不提交 Git。
- DB 不存完整 Cookie／明文票據；Cookie 由 ASP.NET Core 保護，單獨知道 session ID 不能認證。
- 已確認 DB 授權不自動到期，直到確認換機、裝置自行撤銷或站點停用才失效；`expire_dt = NULL` 表示不設 DB 到期日。瀏覽器 Cookie 採持久保存與有效使用續簽，但瀏覽器清除網站資料時仍須重新配對。
- 所有 `datetime2(3)` 存台灣本地時間，格式如 `2026-10-10 09:15:30.125`。由後端 IClock 明確提供，不使用 DB 主機預設時間猜測時區；Cookie ExpiresUtc 另轉為同一時刻的 UTC。
- 關聯採邏輯關聯，不新增 DB 外鍵；應用程式與交易必須檢查關聯一致性。主鍵、唯一索引及 CHECK 如下。

### `dbo.gate_station`：固定進／出站點

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `gate_station_sn` | `int IDENTITY(1,1)` | 否 | 內部主鍵，整數流水號 |
| `gate_station_code` | `varchar(30)` | 否 | 唯一代碼，如 `ENTRY_MAIN`／`EXIT_MAIN`；換機不改站點 |
| `gate_station_name` | `nvarchar(50)` | 否 | 中文名稱，如「大門進場站點」 |
| `gate_station_direction` | `tinyint` | 否 | `1`＝進場，`2`＝出場，由後端設定 |
| `gate_station_is_active` | `bit` | 否 | `1`＝啟用，`0`＝停用；後端建立資料時明確指定 |
| `gate_station_current_session_id` | `uniqueidentifier` | 是 | 邏輯對應目前有效 session ID；未配對／撤銷後可 NULL |
| `gate_station_create_dt` | `datetime2(3)` | 否 | 站點建立時間，台灣本地時間 |
| `gate_station_up_dt` | `datetime2(3)` | 是 | 設定或目前授權最後變更時間 |

### `dbo.gate_device_session`：配對授權與換機歷史

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `gate_device_session_sn` | `bigint IDENTITY(1,1)` | 否 | 歷史紀錄的內部主鍵 |
| `gate_device_session_id` | `uniqueidentifier` | 否 | 後端產生的唯一 GUID；顯示格式 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`，ID 不是憑證 |
| `gate_station_sn` | `int` | 否 | 邏輯對應站點主鍵；不重複保存方向 |
| `gate_device_session_status` | `varchar(20)` | 否 | `Active`／`Revoked`／`Expired` |
| `gate_device_session_previous_id` | `uniqueidentifier` | 是 | 被新授權取代的前一份 session ID，首次配對為 NULL |
| `gate_device_session_create_dt` | `datetime2(3)` | 否 | 配對成功建立時間 |
| `gate_device_session_expire_dt` | `datetime2(3)` | 是 | NULL＝第一版不自動到期；保留未來明確設定期限的擴充能力 |
| `gate_device_session_last_seen_dt` | `datetime2(3)` | 是 | 最後有效請求時間，不是硬體識別依據 |
| `gate_device_session_revoke_dt` | `datetime2(3)` | 是 | 撤銷時間，Revoked 時必填 |
| `gate_device_session_revoke_reason` | `varchar(30)` | 是 | 建議 `Replaced`／`Manual`；Expired 不冒充人工撤銷 |
| `gate_device_session_revoke_by` | `nvarchar(50)` | 是 | 自動換機記 `SYSTEM`；人工撤銷記實際操作者 ID，不由配對碼推定 Admin 身分 |
| `gate_device_session_remark` | `nvarchar(500)` | 是 | 說明，不存配對碼、Cookie 或會員電話 |
| `gate_device_session_up_dt` | `datetime2(3)` | 是 | 狀態／期限異動時間 |

### CREATE TABLE／索引語法

下列為 SSMS／sqlcmd 可辨識的批次示例，`GO` 不是應用程式可直接送出的 T-SQL。沒有 DROP／覆蓋既有表，也沒有 INSERT 真實資料；執行與正式 migration 都需要另外確認。

```sql
-- 結構參考；開發／測試 GymDB 已使用下方連結的冪等腳本套用。
-- Filtered index 所需的連線 SET 選項。
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET ARITHABORT ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET NUMERIC_ROUNDABORT OFF;
GO

CREATE TABLE dbo.gate_station
(
    gate_station_sn INT IDENTITY(1,1) NOT NULL,
    gate_station_code VARCHAR(30) NOT NULL,
    gate_station_name NVARCHAR(50) NOT NULL,
    gate_station_direction TINYINT NOT NULL,
    gate_station_is_active BIT NOT NULL,
    gate_station_current_session_id UNIQUEIDENTIFIER NULL,
    gate_station_create_dt DATETIME2(3) NOT NULL,
    gate_station_up_dt DATETIME2(3) NULL,

    CONSTRAINT PK_gate_station PRIMARY KEY (gate_station_sn),
    CONSTRAINT UQ_gate_station_code UNIQUE (gate_station_code),
    CONSTRAINT CK_gate_station_direction
        CHECK (gate_station_direction IN (1, 2))
);
GO

CREATE TABLE dbo.gate_device_session
(
    gate_device_session_sn BIGINT IDENTITY(1,1) NOT NULL,
    gate_device_session_id UNIQUEIDENTIFIER NOT NULL,
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

    CONSTRAINT PK_gate_device_session
        PRIMARY KEY (gate_device_session_sn),
    CONSTRAINT UQ_gate_device_session_id
        UNIQUE (gate_device_session_id),
    CONSTRAINT CK_gate_device_session_status
        CHECK (gate_device_session_status IN ('Active', 'Revoked', 'Expired')),
    CONSTRAINT CK_gate_device_session_expire
        CHECK (gate_device_session_expire_dt IS NULL
               OR gate_device_session_expire_dt > gate_device_session_create_dt),
    CONSTRAINT CK_gate_device_session_revoked_time
        CHECK (gate_device_session_status <> 'Revoked'
               OR gate_device_session_revoke_dt IS NOT NULL)
);
GO

-- 每個站點最多一筆 Active；Expired／Revoked 的歷史保留。
CREATE UNIQUE INDEX UX_gate_device_session_active_station
    ON dbo.gate_device_session (gate_station_sn)
    WHERE gate_device_session_status = 'Active';
GO

CREATE INDEX IX_gate_device_session_station_create
    ON dbo.gate_device_session
       (gate_station_sn, gate_device_session_create_dt);
GO
```

### 執行邏輯與資料庫防線的分工

- 換機須鎖定站點，在同一交易撤銷舊授權、建立新授權、更新 current_session_id，不只先查後插入。
- filtered unique index 限制 Active 筆數，不用現在時間動態判斷到期；已過期但仍標 Active 的舊授權需先轉 Expired 再建立新份。
- 有效授權仍須符合：Cookie 驗證成功、站點啟用、session 屬於站點且等於目前授權、狀態 Active、未到期。
- 無 FK 不代表可以任意關聯；previous_id 必須指向同站點歷史，current_session_id 必須指向該站點授權，由後端交易檢查。
- 實際冪等建表／站點 seed 腳本：[裝置授權 schema](spec/IO_gyms/02-開門控制與進出紀錄/sql/01-gate-device-authorization.sql)。配對碼不存 DB；Cookie 金鑰路徑及內網部署參數仍須在各環境設定。

## 出席與扣堂更正資料設計（第六階段）

整理日期：2026-10-15。同步日期：2026-10-16。相關規劃：[人工操作與異常處理](spec/IO_gyms/06-人工操作與異常處理/impelment_rule.md)。本節與階段 06 已同步更正、恢復及第一版界線；本輪僅對齊說明，不修改下列 CREATE 語法，也未執行 SQL。

**文件狀態：僅新增資料表說明及 CREATE 語法，未執行 SQL、未修改 GymDB，也未實作更正流程。** 不可直接對已有同名物件的資料庫重跑；正式 migration 前須核對實際 schema、既有資料、型別及約束，不刪表重建。

### 已確認的規則與資料分工

- 沿用 `sdt_att_record` 保存目前出席結果、`sdt_ticket_usage_log` 保存扣堂／沖銷；另新增 `sdt_att_correction` 保存更正案件，及 `sdt_att_record_audit_log` 保存不可覆寫的出席變動歷史。
- 第一版由 Admin 自行確認並執行，不另設第二位人員審核；`Pending` 是尚未處理，不是等待另一位主管簽核。理由、依據、操作者及結果仍須保存，後端須驗證權限。
- 允許撤銷誤判出席，以及補認原本符合歷史資格、但被漏記的出席；不作遲到通融，不拿事後買票補原本沒有的資格，原本正確的 Ineligible 仍不補結算。
- 沖銷只允許整筆退回原 Consume 的堂數，不提供任意輸入加減堂數，也不刪除或改寫原扣堂紀錄；Reverse 必須關聯原 Consume。月票更正沒有堂數增減。
- 已影響後續票券啟用者先列 `NeedsReview`，保存案件與原因，不提供一鍵退堂，也不先把舊票恢復為 Active；具體人工解決流程仍待討論。
- 館內狀態更正採操作當下生效，不連帶回溯出席／扣堂；回溯由本節的獨立案件處理。更正歷史出席也不把學生現在的館內狀態改成在館內。
- 申請進度可以更新，但每次實際出席變動另新增稽核列；不可把更正申請表當成不可變稽核表，也不能只覆寫 remark。
- 兩張新表採邏輯關聯，不新增外鍵，沿用本文件的設計原則；應用服務須在交易中驗證學生、場次、出席、票券與原核銷的關聯一致性。
- 識別欄位以 `nvarchar(50)` 保存使用者／操作者 ID，不保存電話、密碼或 token；正式 migration 前應核對 `users.usr_id` 及現有關聯欄位的實際型別、長度與定序。`SYSTEM` 僅供系統稽核來源，不能代替人工更正的真實 Admin 身分。
- 所有 `datetime2(3)` 保存台灣本地的實際處理時間，格式如 `2026-10-15 14:30:05.125`，由後端共用 IClock 提供；不使用 DB 主機預設時間猜測時區。原場次／截止業務時間由場次及快照另保留，不把今天操作的時間偽裝為過去。

### `dbo.sdt_att_correction`：更正申請與處理進度

一筆代表一位學生、某一實際場次的一次更正案件。未建立出席資料的漏記案件也能先保存；之後成功建立出席才回填 `attendance_sn`。同一學生／場次可以有多次案件，不在案件表上把這組欄位設為唯一；第一版反覆撤銷後再次補認轉 NeedsReview，不提供一鍵再次扣退，不因允許多筆案件就開放重複扣退。

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `correction_sn` | `bigint IDENTITY(1,1)` | 否 | 更正案件內部主鍵 |
| `request_id` | `uniqueidentifier` | 否 | 唯一請求識別；前端／呼叫方對同一次送出及重試保留同一 GUID，不是授權憑證 |
| `attendance_sn` | `int` | 是 | 邏輯對應 `sdt_att_record_sn`；漏記且尚無出席資料時可 NULL，Completed 時不可 NULL |
| `user_id` | `nvarchar(50)` | 否 | 被更正的學生 ID，不是操作者 |
| `cls_scdle_arnge_sn` | `int` | 否 | 被更正的實際場次，不用課程模板 ID |
| `correction_type` | `varchar(30)` | 否 | `RevokeAttendance`＝撤銷誤判出席；`ConfirmAttendance`＝補認原本符合條件的漏記出席 |
| `processing_state` | `varchar(20)` | 否 | `Pending`／`NeedsReview`／`Completed`／`Failed`／`Rejected`，見下方語意 |
| `reason` | `nvarchar(500)` | 否 | 更正原因，必填且不得只有空白 |
| `evidence_note` | `nvarchar(max)` | 是 | 歷史事件、調查依據與說明；不能只憑備註把不具資格者改成 Eligible |
| `target_pass_sn` | `int` | 是 | 本案原固定票券或歷史核對後的目標票券；不能由任意挑選目前票券繞過歷史資格 |
| `target_usage_sn` | `int` | 是 | 要整筆沖銷的原 Consume；與 `target_pass_sn` 一起定位，兼容文件目前的核銷複合主鍵描述；尚未扣堂或無堂數變動時可 NULL |
| `requested_by` | `nvarchar(50)` | 否 | 建立案件的實際 Admin ID，不接受前端任意冒填 |
| `processed_by` | `nvarchar(50)` | 是 | 最近實際處理的 Admin ID，可以與 requested_by 相同；Completed／Rejected 時必填 |
| `requested_at` | `datetime2(3)` | 否 | 案件建立時間，台灣本地時間 |
| `processed_at` | `datetime2(3)` | 是 | 最近實際處理時間；NeedsReview／Failed 重試時可更新，不是原上課時間 |
| `updated_at` | `datetime2(3)` | 否 | 案件進度最後變更時間；建立時也須明確提供 |
| `result_code` | `varchar(50)` | 是 | 可機器辨識的結果／阻擋代碼；完整代碼清單留應用契約設計 |
| `result_message` | `nvarchar(500)` | 是 | 顯示處理結果、缺少依據或衝突原因；不寫密碼、token、連線字串或完整 exception |
| `row_version` | `rowversion` | 否 | SQL Server 自動產生的 8-byte 並行控制值，不是日期；API 傳輸格式待契約設計 |

狀態語意及執行限制：

- `Pending`：案件已保存，尚未完成更正；不代表已准許扣堂或需要第二人簽核。
- `NeedsReview`：歷史不足、已影響後續票券或資料衝突，須人工確認；不把它轉成 Ineligible 來結案，也不盲目自動重試。
- `Completed`：本案所需的出席、占用／額度、核銷與稽核都已一致提交，不只代表開啟過畫面或送出過請求。
- `Failed`：技術處理未完成，保存原因；是否可重試須重新核對最新狀態，不能繞過業務衝突。
- `Rejected`：經確認不符合更正條件，保留案件與理由；不是「已退堂」。
- 同一 `request_id` 重送須核對學生、場次、類型等請求內容：內容相同回傳既有案件／結果，內容不同拒絕，不能將唯一索引衝突當成執行成功。
- 完成案件不可再次執行。對出席及額度操作前仍須鎖定相關資料／檢查版本並驗證狀態；案件唯一鍵不能單獨防止不同 request_id 重複退同一筆 Consume。
- 案件的 `row_version` 只保護案件更新，不等於出席／票券資料也已具備並行控制；既有表的版本、鎖定及交易防線仍需設計。

### `dbo.sdt_att_record_audit_log`：出席資料變動歷史

一筆保存一次操作對某筆出席的變動前後快照。一般系統建立／更新出席亦可寫入，這時 `correction_sn` 為 NULL；人工更正需關聯案件。同次交易若對同筆出席多次內部更新，應彙整為一筆交易前／交易後的完整快照。

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `audit_sn` | `bigint IDENTITY(1,1)` | 否 | 稽核流水號 |
| `attendance_sn` | `int` | 否 | 變動的出席主鍵；補認建立出席後即可取得，不能用 NULL 代替未處理案件 |
| `correction_sn` | `bigint` | 是 | 人工更正案件；非更正的一般系統異動可 NULL |
| `operation_id` | `uniqueidentifier` | 否 | 同一次實際操作的批次識別；串接多筆相關異動，不是裝置授權或 Admin token |
| `change_type` | `varchar(20)` | 否 | `Insert`／`Update`；撤銷出席仍保留資料並寫 Update，不刪除出席 |
| `change_source` | `varchar(50)` | 否 | 異動來源代碼，例如系統 A／B、人工更正；確切來源清單在應用設計時對齊，不由字串授予權限 |
| `before_data` | `nvarchar(max)` | 是 | 異動前完整出席快照 JSON；Insert 時為 NULL，Update 時必須有值 |
| `after_data` | `nvarchar(max)` | 否 | 異動後完整出席快照 JSON；保留欄位名稱、型別語意與 NULL，不放憑證 |
| `operator_id` | `nvarchar(50)` | 否 | 人工更正記實際 Admin；系統異動可記 SYSTEM，並配合 change_source 區分 |
| `reason` | `nvarchar(500)` | 否 | 變動原因；人工更正必須能對應案件原因，系統操作也保存可追溯說明 |
| `changed_at` | `datetime2(3)` | 否 | 此次實際變動時間，不回填成課程截止時間 |

- 快照使用 JSON 文字，不使用 SQL Server 新版原生 JSON 型別；以下 `ISJSON` 檢查需目標 SQL Server 支援。正式 migration 前核對版本。
- 稽核快照不是機器判斷資格／扣堂的主要資料來源，不依解析 remark 決定結算；正式欄位、原事件、固定占用及核銷仍是依據。
- Insert-only 是實作要求；以下 CREATE 不會自動阻擋 UPDATE／DELETE。須在應用寫入路徑及適當 DB 權限落實，不能在尚未配置權限前宣稱不可竄改。
- 建議由具商業上下文的應用服務在同一交易寫入。是否增加 trigger 作額外防線仍待設計，本次不建立 trigger、不修改 DB 帳號權限，也不把新表當成既有 pass audit log 的替代品。
- 尚未完成更正的案件不建立假的出席異動稽核；其原因保存在案件表。更正過程失敗而交易回滾時，出席稽核與額度／出席一同回滾，再以獨立處理保存失敗結果，不能將回滾的異動記為已成功。

### CREATE TABLE／索引語法：出席更正與稽核

以下是兩張新表的文件示例，不含既有出席／核銷表的 ALTER，不是可直接完成全部功能的 migration。`GO` 僅供 SSMS／sqlcmd 分批，不可原樣經 Dapper 當成一個 T-SQL 指令送出。沒有 DROP、UPDATE 既有資料或 INSERT 真實案件。

```sql
-- 文件示例：本次未執行。先核對目標 DB、SQL Server 版本及同名物件。
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.sdt_att_correction
(
    correction_sn BIGINT IDENTITY(1,1) NOT NULL,
    request_id UNIQUEIDENTIFIER NOT NULL,
    attendance_sn INT NULL,
    user_id NVARCHAR(50) NOT NULL,
    cls_scdle_arnge_sn INT NOT NULL,
    correction_type VARCHAR(30) NOT NULL,
    processing_state VARCHAR(20) NOT NULL,
    reason NVARCHAR(500) NOT NULL,
    evidence_note NVARCHAR(MAX) NULL,
    target_pass_sn INT NULL,
    target_usage_sn INT NULL,
    requested_by NVARCHAR(50) NOT NULL,
    processed_by NVARCHAR(50) NULL,
    requested_at DATETIME2(3) NOT NULL,
    processed_at DATETIME2(3) NULL,
    updated_at DATETIME2(3) NOT NULL,
    result_code VARCHAR(50) NULL,
    result_message NVARCHAR(500) NULL,
    row_version ROWVERSION NOT NULL,

    CONSTRAINT PK_sdt_att_correction PRIMARY KEY (correction_sn),
    CONSTRAINT UQ_sdt_att_correction_request UNIQUE (request_id),
    CONSTRAINT CK_sdt_att_correction_type
        CHECK (correction_type IN ('RevokeAttendance', 'ConfirmAttendance')),
    CONSTRAINT CK_sdt_att_correction_state
        CHECK (processing_state IN
               ('Pending', 'NeedsReview', 'Completed', 'Failed', 'Rejected')),
    CONSTRAINT CK_sdt_att_correction_reason
        CHECK (LEN(LTRIM(RTRIM(reason))) > 0),
    CONSTRAINT CK_sdt_att_correction_target_usage
        CHECK (target_usage_sn IS NULL OR target_pass_sn IS NOT NULL),
    CONSTRAINT CK_sdt_att_correction_completed_attendance
        CHECK (processing_state <> 'Completed' OR attendance_sn IS NOT NULL),
    CONSTRAINT CK_sdt_att_correction_processed
        CHECK (processing_state NOT IN ('Completed', 'Rejected')
               OR (processed_by IS NOT NULL AND processed_at IS NOT NULL))
);
GO

CREATE INDEX IX_sdt_att_correction_state_requested
    ON dbo.sdt_att_correction (processing_state, requested_at, correction_sn);
GO

CREATE INDEX IX_sdt_att_correction_student_session
    ON dbo.sdt_att_correction (user_id, cls_scdle_arnge_sn, correction_sn);
GO

CREATE TABLE dbo.sdt_att_record_audit_log
(
    audit_sn BIGINT IDENTITY(1,1) NOT NULL,
    attendance_sn INT NOT NULL,
    correction_sn BIGINT NULL,
    operation_id UNIQUEIDENTIFIER NOT NULL,
    change_type VARCHAR(20) NOT NULL,
    change_source VARCHAR(50) NOT NULL,
    before_data NVARCHAR(MAX) NULL,
    after_data NVARCHAR(MAX) NOT NULL,
    operator_id NVARCHAR(50) NOT NULL,
    reason NVARCHAR(500) NOT NULL,
    changed_at DATETIME2(3) NOT NULL,

    CONSTRAINT PK_sdt_att_record_audit_log PRIMARY KEY (audit_sn),
    CONSTRAINT UQ_sdt_att_record_audit_operation
        UNIQUE (operation_id, attendance_sn),
    CONSTRAINT CK_sdt_att_record_audit_change_type
        CHECK (change_type IN ('Insert', 'Update')),
    CONSTRAINT CK_sdt_att_record_audit_before_json
        CHECK (before_data IS NULL OR ISJSON(before_data) = 1),
    CONSTRAINT CK_sdt_att_record_audit_after_json
        CHECK (ISJSON(after_data) = 1),
    CONSTRAINT CK_sdt_att_record_audit_snapshot
        CHECK ((change_type = 'Insert' AND before_data IS NULL)
               OR (change_type = 'Update' AND before_data IS NOT NULL)),
    CONSTRAINT CK_sdt_att_record_audit_reason
        CHECK (LEN(LTRIM(RTRIM(reason))) > 0)
);
GO

CREATE INDEX IX_sdt_att_record_audit_attendance_time
    ON dbo.sdt_att_record_audit_log (attendance_sn, changed_at, audit_sn);
GO

CREATE INDEX IX_sdt_att_record_audit_correction
    ON dbo.sdt_att_record_audit_log (correction_sn, audit_sn);
GO
```

### 尚待完成的既有表及交易整合（不是本次 ALTER）

- `sdt_att_record` 的撤銷狀態、`settlement_state`、有效核銷關聯、資料版本及學生＋實際場次唯一性仍需正式設計／migration；不得只因建立案件／稽核表就宣稱可安全退堂。原有 CheckOut 不等於撤銷出席。
- `sdt_ticket_usage_log` 的實際 schema 尚須重查；本文件已有 Consume／Reverse、attendance_sn、idempotency_key 及快照不代表 GymDB 均已存在。原文複合主鍵與 usage_sn 唯一性須對齊，本次先以 target_pass_sn＋target_usage_sn 記原核銷，不擅自更換既有主鍵。
- 核銷需補齊與更正案件的可追溯關聯、防重請求唯一性及同一原 Consume 最多整筆沖銷一次的 DB／交易防線；僅在這兩張新表設唯一鍵不能保證不重複扣退堂。若核銷維持複合識別，沖銷關聯也必須能唯一定位原筆。
- 同一學生／場次的有效扣堂唯一性仍待技術設計；已沖銷後再次補認的反覆更正已確認第一版轉 NeedsReview、不一鍵再次扣退，不以多筆案件或更換 request_id 繞過「不重複扣堂」。
- 成功更正須將出席、占用釋放／恢復、額度、Consume／Reverse、出席稽核及案件完成標記放入一致的交易；正式送出前重驗最新狀態與歷史資格，不能只依畫面預覽結果執行。
- 已影響接續票券、歷史依據不足及資料衝突，保存 NeedsReview 原因，不先做部分退堂或改啟用狀態；原已完成的扣堂也不透過背景工作整批重跑來更正。
- 稽核新增與案件更新尚需統一寫入服務、並行鎖定、權限及測試；完整額度占用／工作進度表、館內狀態更正稽核和對帳機制仍屬後續設計範圍，不由本節兩張表取代。
- 第一版正式入口為學生詳細頁，Schedule 不加入結算操作，獨立 Classes 列後續；Admin 確認並重新處理後須重驗，上一堂修復成功才依序恢復後續未完成工作。台灣午夜換日／當日重新確認只影響當日館內依據，歷史 A／B 仍依原場次歷史補跑；這些規則不代表本節已新增館內狀態或背景工作表。

## 課程出席背景工作資料設計（第四／第五階段）

整理日期：2026-10-16。使用者已同意新增 `class_processing_job` 與 `class_processing_item`。相關規劃：[出席確認與額度占用](spec/IO_gyms/04-出席確認與額度占用/impelment_rule.md)、[課程結算與背景工作](spec/IO_gyms/05-課程結算與背景工作/impelment_rule.md)。

**資料庫狀態：2026-10-17 使用者核准後，以下兩張工作表已在開發 GymDB 建立並提交，欄位及索引已唯讀查核；背景工作程式仍未實作。** 這兩張表保存工作進度，不取代出席表、額度占用表或扣堂紀錄。部署至其他環境前仍須核對同名物件及關聯欄位，不刪表重建。

2026-10-17 已依本節語法套用 [工作表建置腳本](spec/IO_gyms/05-課程結算與背景工作/sql/01-create-class-processing.sql)，與出席 ALTER 在同一外層交易提交；job 20 欄、item 15 欄，目前均為 0 筆，兩表各有 6 個 CHECK、沒有外鍵或 rowversion。占用表移除 CHECK 的決策未擴大到這兩張表。後續繼續第四階段時，亦已另行部署占用表並完成 9 個 SQL 整合測試；建表不代表 Worker／A／B 程式已完成。

### 已確認的規則與資料分工

- 程式功能目錄命名 `ClassAttendanceProcessing`。Application 層的 Coordinator 協調 A／B 與票券接續，Infrastructure 層的 Worker 找出到期工作及取得執行權；只使用一套背景工作入口。
- A 在開課十分鐘截止後確認出席、固定票券與占用；B 在下課十分鐘後正式結算。包含截止整點的事件收齊後才能封存，不能把 A 延到下課後才首次執行。
- 一個場次各有一筆 A、B 工作；每筆工作再分成每學生一筆處理項目。同堂一人失敗不回滾其他已完成學生，也不能只靠整堂的 Completed 判斷某學生是否已扣堂。
- 相鄰場次先上一堂 B、接續票券，再下一堂 A；上一堂未完成者只暫停該學生。Coordinator 必須驗證依賴，不單靠工作時間排序或等待整班完成。
- 不新增外鍵、不使用 `rowversion`。關聯存在性、學生／場次一致性、執行權及狀態轉換由應用服務在交易內重驗；PK、唯一索引與 CHECK 作額外防線。
- 所有 `datetime2(3)` 保存台灣本地時間，例如 `2026-10-16 19:10:00.000`，由後端共用 IClock 明確提供。預定時間、業務快照與實際處理時間分開；不使用資料庫主機的預設時間猜測時區。
- `lease_token` 是每次取得工作時重新產生的 GUID，不是裝置／使用者授權憑證。舊 Worker 不能只憑相同 worker 名稱繼續寫入。

### `dbo.class_processing_job`：每場次 A／B 工作

一筆代表一個實際場次的一個處理階段。建立時保存場次時間及老師快照；開始上課後依既有規則禁止編輯場次，不能靠修改工作快照繞過此限制。開課前允許的排課異動須同步重算尚未執行的工作；取消場次須在場次驗證及工作處理路徑明確處理，不能留下可執行的過期工作。

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `job_sn` | `bigint IDENTITY(1,1)` | 否 | 工作主鍵 |
| `cls_scdle_arnge_sn` | `int` | 否 | 實際課程場次，邏輯對應既有場次表 |
| `phase` | `varchar(1)` | 否 | `A`＝出席確認；`B`＝課程結算 |
| `processing_state` | `varchar(20)` | 否 | `Pending`／`Running`／`Waiting`／`NeedsReview`／`Failed`／`Completed`／`Cancelled` |
| `class_start_at` | `datetime2(3)` | 否 | 原場次開始時間快照 |
| `class_end_at` | `datetime2(3)` | 否 | 原場次結束時間快照；課程造成耗盡時供業務 ended_at 使用 |
| `instructor_id` | `nvarchar(50)` | 否 | 該場次老師 ID 快照；部署前核對既有老師識別欄位 |
| `scheduled_at` | `datetime2(3)` | 否 | 原應執行時間：A＝開始＋十分鐘，B＝結束＋十分鐘；重試不覆寫 |
| `processing_attempts` | `int` | 否 | 成功取得工作執行權的累計次數，初值 0；輪詢但未取得執行權不增加 |
| `next_attempt_at` | `datetime2(3)` | 是 | 下次可自動嘗試時間；人工待確認不得只靠此欄位自動重跑 |
| `lease_owner` | `nvarchar(100)` | 是 | 持有執行權的服務實例／Worker 識別，不保存密碼或 token |
| `lease_token` | `uniqueidentifier` | 是 | 本次執行權識別，每次重新取得都換新值 |
| `lease_expires_at` | `datetime2(3)` | 是 | 執行權到期時間；長工作須條件式續租 |
| `first_started_at` | `datetime2(3)` | 是 | 第一次實際開始處理時間 |
| `last_started_at` | `datetime2(3)` | 是 | 最近一次取得執行權的時間 |
| `completed_at` | `datetime2(3)` | 是 | 整個工作確實完成的時間；有未完成學生時不可填成已完成 |
| `last_error_code` | `varchar(60)` | 是 | 最近一次技術／資料錯誤代碼 |
| `last_error_message` | `nvarchar(1000)` | 是 | 最近一次原因摘要，不存完整 exception 或連線資訊 |
| `created_at` | `datetime2(3)` | 否 | 工作建立時間 |
| `updated_at` | `datetime2(3)` | 否 | 工作最近狀態變更時間 |

工作狀態語意：

- `Pending`：尚未執行；`scheduled_at` 之前不能執行業務處理。
- `Running`：已取得有期限的執行權；資料庫租約只管工作取得，仍須交易鎖與條件更新保護實際資料。
- `Waiting`：已有部分完成，但仍有待執行／依賴尚未解除的項目；下次只處理未完成者。
- `NeedsReview`：目前剩餘項目需人工確認；其他可處理者應先繼續，不能一遇人工案件就停止整班。
- `Failed`：工作層技術錯誤，保留原因，依退避策略重試；既有 Completed 項目保留。
- `Completed`：名單已可靠封存，所有必要項目均 Completed 或有明確理由的 Skipped。名單查詢失敗／尚未封存不能因目前零筆 item 就宣告完成；確定無出席學生時可完成。
- `Cancelled`：開課前取消場次、且未執行出席／扣堂的工作；不拿此狀態取消已成立出席或沖銷扣堂。

### `dbo.class_processing_item`：逐學生處理進度

一筆代表一位學生在某一 A／B 工作的進度。A 可先保存待確認項目，尚無出席主鍵時 `attendance_sn` 可為 NULL；B 成功結算須關聯固定的出席及占用，不能到結算時重新挑 Current Plan。工作明細不是占用本身，不在此表另存一份可扣額度。

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `item_sn` | `bigint IDENTITY(1,1)` | 否 | 學生處理項目主鍵 |
| `job_sn` | `bigint` | 否 | 所屬工作；透過 job 判斷場次與 A／B，不重複存一份可能不一致的 phase |
| `user_id` | `nvarchar(50)` | 否 | 該學生 ID，不使用電話作識別鍵 |
| `attendance_sn` | `int` | 是 | 邏輯對應出席主鍵；缺歷史待確認或確認無出席時可 NULL |
| `processing_state` | `varchar(20)` | 否 | `Pending`／`Running`／`Blocked`／`NeedsReview`／`Failed`／`Completed`／`Skipped` |
| `blocked_by_item_sn` | `bigint` | 是 | 阻擋此學生的上一個未完成項目，限同學生且較前的業務依賴；不可自指或形成循環 |
| `processing_attempts` | `int` | 否 | 此項目實際處理次數，初值 0；不能以整堂 attempts 代替 |
| `next_attempt_at` | `datetime2(3)` | 是 | 暫時性失敗下次可自動重試的時間 |
| `first_started_at` | `datetime2(3)` | 是 | 此學生項目第一次實際開始時間 |
| `last_started_at` | `datetime2(3)` | 是 | 最近一次實際嘗試時間 |
| `completed_at` | `datetime2(3)` | 是 | Completed／Skipped 實際完成時間 |
| `result_code` | `varchar(60)` | 是 | 成功、略過、暫停或異常代碼；不能只依 remark 判定狀態 |
| `result_message` | `nvarchar(1000)` | 是 | 原因摘要；區分歷史不足、結算故障及票券不具資格 |
| `created_at` | `datetime2(3)` | 否 | 項目建立時間 |
| `updated_at` | `datetime2(3)` | 否 | 項目最近狀態變更時間 |

- `Pending`／`Running`：尚未處理／正在父工作有效租約下處理。恢復時不得單憑 Running 就認定已扣堂，也不能直接再扣。
- `Blocked`：同一學生前置工作未完成；保存阻擋項目，不能改成 Ineligible。前置修復後重新驗證，再恢復處理。
- `NeedsReview`：歷史不完整、Requested／Unknown 事件無法釐清、固定占用衝突等；不推測出席、不換票、不盲目重試。
- `Failed`：暫時性技術錯誤，交易已回滾；保存原因及下次重試時間。超過技術重試上限後保留異常供人工處理。
- `Completed`：該階段對該學生所需資料均已一致提交；A 確認缺票留館的出席事實也可完成，但票券資格另記 Ineligible，不能由此授予回場或允許扣堂。
- `Skipped`：有依據可確認不需執行，例如截止前已離場，或 B 遇到不允許補結算的 Ineligible。須有結果原因；系統失敗／缺歷史不得標成 Skipped。
- 本表不新增每學生的第二套租約；逐筆處理、錯誤保存及恢復均驗證父 job 的 token／期限。父租約到期後接手者先核對交易結果，再恢復未完成項目。

### CREATE TABLE／索引語法：背景工作與逐學生進度

以下為工作表定義；2026-10-17 已透過獨立腳本部署至開發 GymDB。此處 `GO` 供 SSMS／sqlcmd 分批，不可直接將含 GO 的全文送入 Dapper。不含額度占用表、既有出席／核銷表 ALTER，也不建立外鍵或 rowversion。

```sql
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

CREATE TABLE dbo.class_processing_job
(
    job_sn BIGINT IDENTITY(1,1) NOT NULL,
    cls_scdle_arnge_sn INT NOT NULL,
    phase VARCHAR(1) NOT NULL,
    processing_state VARCHAR(20) NOT NULL,
    class_start_at DATETIME2(3) NOT NULL,
    class_end_at DATETIME2(3) NOT NULL,
    instructor_id NVARCHAR(50) NOT NULL,
    scheduled_at DATETIME2(3) NOT NULL,
    processing_attempts INT NOT NULL
        CONSTRAINT DF_class_processing_job_attempts DEFAULT (0),
    next_attempt_at DATETIME2(3) NULL,
    lease_owner NVARCHAR(100) NULL,
    lease_token UNIQUEIDENTIFIER NULL,
    lease_expires_at DATETIME2(3) NULL,
    first_started_at DATETIME2(3) NULL,
    last_started_at DATETIME2(3) NULL,
    completed_at DATETIME2(3) NULL,
    last_error_code VARCHAR(60) NULL,
    last_error_message NVARCHAR(1000) NULL,
    created_at DATETIME2(3) NOT NULL,
    updated_at DATETIME2(3) NOT NULL,

    CONSTRAINT PK_class_processing_job PRIMARY KEY (job_sn),
    CONSTRAINT UQ_class_processing_job_session_phase
        UNIQUE (cls_scdle_arnge_sn, phase),
    CONSTRAINT CK_class_processing_job_phase CHECK (phase IN ('A', 'B')),
    CONSTRAINT CK_class_processing_job_state
        CHECK (processing_state IN
               ('Pending', 'Running', 'Waiting', 'NeedsReview', 'Failed', 'Completed', 'Cancelled')),
    CONSTRAINT CK_class_processing_job_attempts CHECK (processing_attempts >= 0),
    CONSTRAINT CK_class_processing_job_schedule
        CHECK (class_end_at > class_start_at
               AND ((phase = 'A' AND scheduled_at = DATEADD(MINUTE, 10, class_start_at))
                 OR (phase = 'B' AND scheduled_at = DATEADD(MINUTE, 10, class_end_at)))),
    CONSTRAINT CK_class_processing_job_lease
        CHECK ((processing_state = 'Running' AND lease_owner IS NOT NULL
                AND lease_token IS NOT NULL AND lease_expires_at IS NOT NULL)
            OR (processing_state <> 'Running' AND lease_owner IS NULL
                AND lease_token IS NULL AND lease_expires_at IS NULL)),
    CONSTRAINT CK_class_processing_job_completed
        CHECK ((processing_state = 'Completed' AND completed_at IS NOT NULL)
            OR (processing_state <> 'Completed' AND completed_at IS NULL))
);
GO

CREATE INDEX IX_class_processing_job_due
    ON dbo.class_processing_job (processing_state, scheduled_at, job_sn)
    INCLUDE (next_attempt_at, lease_expires_at, cls_scdle_arnge_sn, phase);
GO

CREATE TABLE dbo.class_processing_item
(
    item_sn BIGINT IDENTITY(1,1) NOT NULL,
    job_sn BIGINT NOT NULL,
    user_id NVARCHAR(50) NOT NULL,
    attendance_sn INT NULL,
    processing_state VARCHAR(20) NOT NULL,
    blocked_by_item_sn BIGINT NULL,
    processing_attempts INT NOT NULL
        CONSTRAINT DF_class_processing_item_attempts DEFAULT (0),
    next_attempt_at DATETIME2(3) NULL,
    first_started_at DATETIME2(3) NULL,
    last_started_at DATETIME2(3) NULL,
    completed_at DATETIME2(3) NULL,
    result_code VARCHAR(60) NULL,
    result_message NVARCHAR(1000) NULL,
    created_at DATETIME2(3) NOT NULL,
    updated_at DATETIME2(3) NOT NULL,

    CONSTRAINT PK_class_processing_item PRIMARY KEY (item_sn),
    CONSTRAINT UQ_class_processing_item_job_user UNIQUE (job_sn, user_id),
    CONSTRAINT CK_class_processing_item_state
        CHECK (processing_state IN
               ('Pending', 'Running', 'Blocked', 'NeedsReview', 'Failed', 'Completed', 'Skipped')),
    CONSTRAINT CK_class_processing_item_attempts CHECK (processing_attempts >= 0),
    CONSTRAINT CK_class_processing_item_blocked
        CHECK ((processing_state = 'Blocked' AND blocked_by_item_sn IS NOT NULL)
            OR (processing_state <> 'Blocked' AND blocked_by_item_sn IS NULL)),
    CONSTRAINT CK_class_processing_item_no_self_block
        CHECK (blocked_by_item_sn IS NULL OR blocked_by_item_sn <> item_sn),
    CONSTRAINT CK_class_processing_item_completed
        CHECK ((processing_state IN ('Completed', 'Skipped') AND completed_at IS NOT NULL)
            OR (processing_state NOT IN ('Completed', 'Skipped') AND completed_at IS NULL)),
    CONSTRAINT CK_class_processing_item_skip_reason
        CHECK (processing_state <> 'Skipped'
               OR (result_code IS NOT NULL AND result_message IS NOT NULL
                   AND LEN(LTRIM(RTRIM(result_message))) > 0))
);
GO

CREATE INDEX IX_class_processing_item_job_state
    ON dbo.class_processing_item (job_sn, processing_state, item_sn)
    INCLUDE (user_id, attendance_sn, next_attempt_at);
GO

CREATE INDEX IX_class_processing_item_student_state
    ON dbo.class_processing_item (user_id, processing_state, job_sn)
    INCLUDE (attendance_sn, blocked_by_item_sn);
GO

CREATE INDEX IX_class_processing_item_blocked_by
    ON dbo.class_processing_item (blocked_by_item_sn, item_sn)
    WHERE blocked_by_item_sn IS NOT NULL;
GO
```

### 交易、執行權及恢復要求

1. 取得／續租工作使用短交易與條件更新，原子性確認狀態、scheduled_at、next_attempt_at 及舊租約到期；取得成功才寫入新 token。不能先 SELECT 後無條件 UPDATE。
2. 每位學生各自一筆交易，不把全班放在同一交易。統一取得鎖的順序為工作執行權／相關場次 → 學生 profile → 依 pass_sn 排序的票券 → 出席／占用／核銷／處理項目；涉及多個同類資源依穩定識別排序。購票、取消、人工更正等共用學生／票券鎖的路徑須一併核對，避免反向取得鎖。
3. 每筆業務交易先鎖定父工作並確認仍為 Running、token 相同且租約有效，持有鎖到提交；條件不符就停止舊 Worker。新 Worker 不得跳過尚持鎖的交易自行接手。不得在持有 DB 交易時等待硬體網路回應。
4. B 的扣堂、核銷、占用轉 Consumed、必要的票券生命週期／profile 更新及 item Completed 必須一起提交；任何一步失敗整筆 rollback。A 的固定出席／占用及 item 完成亦同。不能先完成 item 再扣堂。
5. rollback 後，另開短交易驗證 token 及項目仍未完成，再保存 Failed／NeedsReview、次數與原因；不得在已回滾的交易內保存失敗，也不得用晚到的錯誤覆蓋新 Worker 已提交的結果。
6. 項目 Completed／Skipped 後不由自動重試改回 Pending。整堂重跑只接續未完成項目；人工更正走獨立更正案件。前置未完成只 Blocked 該學生，其他學生持續。
7. 兩張表的唯一鍵只防止重複工作／明細，不能單獨保證不重複占用或扣堂；占用表、出席唯一性及核銷冪等限制仍須完成。補跑使用原截止歷史、原可用且已付款票券；不能拿現在館內名單或事後付款替代。
8. attempts 與 last/result 欄位只保存累計次數及最近原因，不是每次嘗試的完整歷史。每次處理另以 job_sn、item_sn、lease_token 作結構化日誌關聯；完整重試稽核的保存方式須在第五階段實作時補齊，不宣稱這兩張表已保存每次錯誤內容。
9. 本次不指定輪詢秒數、租約長度、重試退避與上限；由後續 Worker 設定及測試落實。截止事件未收齊、Unknown／Requested 或無法排序的同時事件依已確認規則待人工確認，不以額外等待秒數推定成功。


## 堂票額度占用資料設計（第四階段）

整理日期：2026-10-17。**占用表已部署至開發 GymDB，18 個欄位、1 個主鍵及 3 個唯一防線經查核符合本節定義，沒有 CHECK、外鍵或 rowversion。** 詳細狀態轉換、冪等鍵及開門前後交易見 [額度占用設計](spec/IO_gyms/04-出席確認與額度占用/credit-reservation-design.md)；完整 [建表腳本](spec/IO_gyms/04-出席確認與額度占用/sql/01-create-credit-reservation.sql) 已依先預覽再執行的要求套用。Repository 的 9 個 SQL 整合測試通過，非第四階段全流程或硬體驗收。

### `dbo.sdt_ticket_credit_reservation`：堂票暫占與固定占用

一筆代表一筆出席對某張票券的 1 堂占用；月票不建立。多筆 Released 保留離場／換票歷史，同一出席最多一筆有效 Reserved／Fixed／NeedsReview。換票釋放舊筆並新增，不直接修改 pass_sn。沒有外鍵或 rowversion。

2026-10-17 使用者決策：本占用表的 10 個 CHECK 全部移至程式驗證，保留 PK、idempotency_key 唯一限制及兩個 filtered unique index（有效出席占用／核銷），另保留查詢索引與欄位型別／NOT NULL。此決策只調整本占用表，不移除本文件其他資料表的 CHECK；已依此直接建立新表，沒有對 GymDB 執行 DROP CONSTRAINT。

- 程式由 `CreditReservationData.Validate()` 統一檢查數量、合法狀態、鍵、來源、自指、待確認原階段、固定／釋放／扣堂時間、核銷關聯及原因。`CreditReservation` 建立及每次狀態轉換都呼叫該驗證；Rehydrate 讀取既有資料時亦驗證，拒絕不合法狀態。
- 新資料尚未分配 reservation_sn，程式無法事先比較新主鍵是否等於 previous_reservation_sn；未來 Repository 取得 INSERT 產生的 ID 後，須在交易提交前以該 ID 重新驗證。已有主鍵的資料在重建／寫入前直接驗證。
- 未來 Repository 寫入前須驗證完整快照；匯入／批次應呼叫相同驗證。直接 SQL 將不再有這 10 個 CHECK 的防線；狀態字串解析不得對未知值預設成 Reserved。驗證失敗須拋錯並 rollback，不默默修正資料。
- 2026-10-17 `SqlCreditReservationRepository` 與 `CreditReservationService` 已通過 61 個單元測試及 9 個實際 SQL 整合測試：涵蓋呼叫端交易、來源／關聯及快照驗證、舊快照拒寫、容量／冪等、固定前重驗、最後一堂並行競爭與 rollback。INSERT 取得主鍵後再次驗證，回傳 SQL 實際儲存時間精度。場次時間／資格、歷史還原、開門前後交易及 A／Worker 仍未串接，不能宣稱第四階段已完成。

| 欄位名稱 | SQL Server 型別 | 可為 NULL | 儲存格式與用途 |
| --- | --- | --- | --- |
| `reservation_sn` | `bigint IDENTITY(1,1)` | 否 | 占用主鍵 |
| `attendance_sn` | `int` | 否 | 出席主鍵；先建立或取得同學生同場次出席 |
| `pass_sn` | `int` | 否 | 被占用票券主鍵 |
| `reserved_credits` | `int` | 否 | 第一版固定 1 |
| `reservation_state` | `varchar(20)` | 否 | Reserved／Fixed／Released／Consumed／NeedsReview |
| `review_from_state` | `varchar(20)` | 是 | NeedsReview 必填 Reserved 或 Fixed，保存原階段 |
| `idempotency_key` | `varchar(160)` | 否 | 同操作重試沿用的唯一 ASCII 鍵，不得空白 |
| `gate_request_id` | `uniqueidentifier` | 是 | 建立占用的進場請求 GUID |
| `processing_item_sn` | `bigint` | 是 | A 建立／移轉占用的工作明細；與 gate_request_id 至少一個有值 |
| `previous_reservation_sn` | `bigint` | 是 | 前一筆已釋放占用，保留換票／返回歷史鏈 |
| `usage_sn` | `int` | 是 | Consumed 時的正式核銷主鍵；其他狀態為 NULL |
| `created_at` | `datetime2(3)` | 否 | 實際建立時間 |
| `fixed_at` | `datetime2(3)` | 是 | A 實際固定時間，不偽裝為原截止時間 |
| `released_at` | `datetime2(3)` | 是 | 實際釋放時間，僅 Released 有值 |
| `consumed_at` | `datetime2(3)` | 是 | 實際結算時間，僅 Consumed 有值 |
| `updated_at` | `datetime2(3)` | 否 | 實際最後異動時間 |
| `reason_code` | `varchar(60)` | 是 | Released／NeedsReview 必填原因代碼 |
| `reason_message` | `nvarchar(1000)` | 是 | Released／NeedsReview 必填說明 |

- 時間全部由後端 IClock 明確寫入台灣本地時間，格式例如 `2026-10-17 19:10:00.125`，不設資料庫預設時間。
- 可新增額度＝票券 credits_remaining 減去 Reserved／Fixed／NeedsReview 的占用總額；Consumed 已正式扣堂，不再次減掉。
- Released／Consumed 不復活；離場後返回使用新請求建立新占用，同次重送只回傳原結果。Fixed 同堂回場不另占。
- NeedsReview 保留原 Reserved／Fixed 階段及額度，人工重驗後才能恢復，不從 Unknown 推定成功。
- 進場前先短交易建立占用及 Requested，提交後才呼叫硬體；明確未開門釋放本次新占用，成功後落庫失敗保留待確認，不重送硬體命令。
- B 扣堂、核銷、占用轉 Consumed、必要生命週期／profile 及工作完成標記一起提交。唯一索引不能代替交易、核銷冪等及歷史資格驗證。
- 本節只新增占用表；既有 sdt_att_record ALTER、兩張工作表建置及第五階段核銷防重須另行整合，不宣稱本 CREATE 可完成全部流程。

### CREATE TABLE／索引語法：額度占用

以下為完整 SQL 草稿中的表與索引定義；執行前仍需核對目標 schema。完整腳本會拒絕非 GymDB 或已有同名物件的情況，所有建表／索引在同一交易，失敗 rollback；不刪除或覆寫既有資料。

```sql
CREATE TABLE dbo.sdt_ticket_credit_reservation
(
    reservation_sn BIGINT IDENTITY(1,1) NOT NULL,
    attendance_sn INT NOT NULL,
    pass_sn INT NOT NULL,
    reserved_credits INT NOT NULL,
    reservation_state VARCHAR(20) NOT NULL,
    review_from_state VARCHAR(20) NULL,
    idempotency_key VARCHAR(160) NOT NULL,
    gate_request_id UNIQUEIDENTIFIER NULL,
    processing_item_sn BIGINT NULL,
    previous_reservation_sn BIGINT NULL,
    usage_sn INT NULL,
    created_at DATETIME2(3) NOT NULL,
    fixed_at DATETIME2(3) NULL,
    released_at DATETIME2(3) NULL,
    consumed_at DATETIME2(3) NULL,
    updated_at DATETIME2(3) NOT NULL,
    reason_code VARCHAR(60) NULL,
    reason_message NVARCHAR(1000) NULL,

    CONSTRAINT PK_sdt_ticket_credit_reservation PRIMARY KEY (reservation_sn),
    CONSTRAINT UQ_sdt_ticket_credit_reservation_key UNIQUE (idempotency_key)
);

-- One effective credit hold per attendance, including holds awaiting review.
CREATE UNIQUE INDEX UX_sdt_credit_reservation_live_attendance
    ON dbo.sdt_ticket_credit_reservation (attendance_sn)
    WHERE reservation_state IN ('Reserved', 'Fixed', 'NeedsReview');

CREATE INDEX IX_sdt_credit_reservation_pass_state
    ON dbo.sdt_ticket_credit_reservation (pass_sn, reservation_state)
    INCLUDE (attendance_sn, reserved_credits);

CREATE INDEX IX_sdt_credit_reservation_attendance_history
    ON dbo.sdt_ticket_credit_reservation (attendance_sn, reservation_sn);

CREATE UNIQUE INDEX UX_sdt_credit_reservation_usage
    ON dbo.sdt_ticket_credit_reservation (usage_sn)
    WHERE usage_sn IS NOT NULL;
```
