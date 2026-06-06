# 裝置進出 CRUD 第一版與第二版規劃

## 背景

目前規格文件中已定義進出紀錄表 `device_record`。這張表用來記錄三叉機、QR Code、RFID、系統開門、人工開門等進出事件。

第一版目標是先完成後台管理用的 CRUD，並採用 soft delete，不做 hard delete。

第二版目標是把裝置進出事件接到真正的門禁業務流程，例如是否允許開門、票券核銷、學生出席紀錄與最近進場時間更新。

## 設計原則

1. 第一版先做資料管理底座，不混入票券與出席邏輯。
2. 刪除一律採用作廢，不直接刪除資料。
3. 查詢預設排除已作廢資料，管理端可透過參數查詢作廢紀錄。
4. 第二版另外建立門禁事件入口，不直接把業務流程塞進 CRUD API。
5. 每一層維持目前專案的 Clean Architecture 分工。

## 第一版：後台 CRUD / 作廢管理

### 目標

完成 `device_record` 的後台管理功能。

員工或管理者可以：

- 查詢進出紀錄
- 查詢單筆進出紀錄
- 新增補登紀錄
- 修改錯誤紀錄
- 作廢紀錄

第一版不負責：

- 判斷是否允許開門
- 扣票券
- 更新學生最近進場時間
- 產生出席紀錄
- 處理 10 分鐘暫時進出規則

### 資料庫需要新增或調整

原本 `device_record` 已有欄位：

- `device_record_sn`
- `usr_id`
- `direction`
- `method`
- `device_id`
- `is_success`
- `device_record_dt`

第一版需要補 soft delete 欄位：

- `is_voided`
- `void_reason`
- `voided_by`
- `voided_dt`

用途：

- `is_voided`：表示紀錄是否作廢。
- `void_reason`：紀錄作廢原因。
- `voided_by`：誰作廢這筆紀錄。
- `voided_dt`：作廢時間。

### API 規劃

第一版建議使用以下 API：

| 功能 | Method | Path |
| --- | --- | --- |
| 查詢進出紀錄列表 | GET | `/api/v1/device-records` |
| 查詢單筆進出紀錄 | GET | `/api/v1/device-records/{sn}` |
| 新增進出紀錄 | POST | `/api/v1/device-records` |
| 更新進出紀錄 | POST | `/api/v1/device-records/{sn}` |
| 作廢進出紀錄 | POST | `/api/v1/device-records/{sn}/delete` |

### 查詢條件

列表查詢建議支援：

- `usrId`
- `direction`
- `deviceId`
- `isSuccess`
- `from`
- `to`
- `includeVoided`

查詢行為：

- `includeVoided = false` 或未提供時，預設只查未作廢紀錄。
- `includeVoided = true` 時，可以查到已作廢紀錄。

### API Request / Response 概念

建立紀錄需要：

- 使用者 ID
- 進出方向
- 感應方式
- 裝置 ID
- 是否成功
- 感應時間

更新紀錄需要：

- 使用者 ID
- 進出方向
- 感應方式
- 裝置 ID
- 是否成功
- 感應時間

作廢紀錄需要：

- 作廢原因
- 作廢操作人員

回傳資料建議包含：

- 紀錄流水號
- 使用者 ID
- 進出方向
- 進出方向名稱
- 感應方式
- 裝置 ID
- 是否成功
- 感應時間
- 是否作廢
- 作廢原因
- 作廢操作人員
- 作廢時間

### Domain 層新增項目

需要新增：

- `DeviceRecord`
- `DeviceDirection`
- `DeviceAccessMethod`
- `IDeviceRecordRepository`

Domain 應負責基本規則：

- `usrId` 不可空。
- `direction` 只允許進場或出場。
- `method` 只允許規格定義的感應方式。
- `deviceId` 不可空。
- 已作廢紀錄不可再被一般更新。

### Application 層新增項目

需要新增：

- 建立裝置進出紀錄 handler
- 更新裝置進出紀錄 handler
- 作廢裝置進出紀錄 handler
- 查詢裝置進出紀錄列表 handler
- 查詢單筆裝置進出紀錄 handler
- 查詢用 result model
- 查詢用 query service interface

Application 應負責：

- 驗證使用者是否存在。
- 判斷紀錄是否存在。
- 判斷紀錄是否已作廢。
- 協調 repository 與 unit of work。
- 不直接寫 SQL。

### Infrastructure 層新增項目

需要新增：

- `SqlDeviceRecordRepository`
- `DapperDeviceRecordQueryService`

Infrastructure 應負責：

- 寫入 `device_record`
- 更新 `device_record`
- 作廢 `device_record`
- 查詢列表
- 查詢單筆
- 透過 Dapper 對應 Application read model

### API 層新增項目

需要新增：

- `DeviceRecordsController`
- 建立 request contract
- 更新 request contract
- 作廢 request contract
- 查詢 response contract
- 單筆 DTO

API 層應負責：

- 接 HTTP request
- 組 Application command/query
- 呼叫 handler
- 將 Application result 轉成 API response

### DI 註冊

需要註冊：

- device record repository
- device record query service
- create handler
- update handler
- delete handler
- list query handler
- single query handler

### 第一版完成標準

第一版完成後應具備：

- 可以查詢裝置進出列表。
- 可以用流水號查單筆紀錄。
- 可以新增補登紀錄。
- 可以更新未作廢紀錄。
- 可以作廢紀錄。
- 作廢紀錄不會從資料庫消失。
- 預設查詢不顯示已作廢紀錄。
- 管理端可以透過 `includeVoided` 查詢作廢資料。

## 第二版：門禁事件與業務流程

### 目標

把裝置進出紀錄從單純 CRUD 提升為真正的門禁業務流程。

第二版要處理：

- 是否允許開門
- 是否有有效票券
- 是否需要核銷票券
- 是否更新學生最近進場時間
- 是否產生或更新出席紀錄
- 10 分鐘暫時進出規則
- 閘門重送事件的防重複處理

### 新增門禁事件入口

第二版建議新增獨立 API：

| 功能 | Method | Path |
| --- | --- | --- |
| 處理門禁事件 | POST | `/api/v1/device-access-events` |

這支 API 給三叉機、QR Code 掃描器、RFID 裝置或系統開門流程使用。

它不應該只是新增 `device_record`，而是要處理完整業務流程。

### 門禁事件 Request 概念

門禁事件應包含：

- 使用者 ID
- 進出方向
- 感應方式
- 裝置 ID
- 發生時間
- 外部事件 ID
- 來源

建議第二版加入：

- `external_event_id`
- `source`
- `failure_reason`

用途：

- `external_event_id`：避免三叉機重送導致重複扣票。
- `source`：區分 Gate、StaffManual、System。
- `failure_reason`：記錄失敗原因。

### 進場流程

進場事件建議流程：

1. 接收門禁事件。
2. 檢查事件是否已處理過。
3. 檢查使用者是否存在。
4. 檢查使用者是否啟用。
5. 檢查使用者是否具有可進場角色。
6. 檢查是否有有效票券。
7. 判斷票券是否過期、用完、未付款或未啟用。
8. 決定是否允許開門。
9. 寫入 `device_record`。
10. 若成功進場，更新 `sdt_profile` 最近進場時間。
11. 若需要核銷，寫入 `sdt_ticket_usage_log`。
12. 建立或更新 `sdt_att_record`。

### 出場流程

出場事件建議流程：

1. 接收門禁事件。
2. 檢查事件是否已處理過。
3. 檢查使用者是否存在。
4. 寫入 `device_record`。
5. 找到最近一筆未完成的出席或進場紀錄。
6. 更新簽退時間。
7. 判斷是否符合 10 分鐘暫時進出規則。
8. 更新出席狀態。

### 10 分鐘暫時進出規則

目前規格提到：

- 進場後 10 分鐘內出去會是 `Pending`。
- 進場後超過 10 分鐘仍未出去，會變成 `CheckIn`。

第二版需要釐清並實作：

- 進場當下是否先建立 `Pending`。
- 10 分鐘內出場是否不扣票。
- 10 分鐘內出場是否只保留暫時進出紀錄。
- 超過 10 分鐘如何轉成正式出席。
- 是否需要背景排程處理 Pending 轉 CheckIn。

### 票券核銷流程

第二版需要接上：

- `sdt_ticket_pass`
- `sdt_ticket_usage_log`
- `sdt_profile`

堂票邏輯：

- 檢查剩餘堂數。
- 成功進場後扣 1。
- 寫入核銷紀錄。
- 更新剩餘堂數快照。

月票邏輯：

- 檢查有效期間。
- 成功進場後可寫入核銷紀錄。
- 扣點數可為 0。

失敗情境：

- 使用者不存在
- 使用者停用
- 沒有有效票券
- 票券過期
- 票券用完
- 票券未付款
- 重複事件

失敗也應寫入 `device_record`，並標記 `is_success = false`。

### 出席紀錄流程

第二版需要與 `sdt_att_record` 整合。

可能狀態：

- `Pending`
- `CheckIn`
- `CheckOut`

進場成功後：

- 建立或更新出席紀錄。
- 初始狀態可為 `Pending`。

超過 10 分鐘：

- 將 `Pending` 轉為 `CheckIn`。

出場時：

- 更新簽退時間。
- 視規則轉為 `CheckOut` 或保留暫時進出狀態。

### 背景任務

第二版可能需要背景任務：

- 定期掃描超過 10 分鐘的 `Pending` 出席紀錄。
- 將符合條件者轉為 `CheckIn`。
- 處理忘記簽退的紀錄。

### 第二版資料庫建議補充

建議 `device_record` 補：

- `external_event_id`
- `source`
- `failure_reason`
- `processed_dt`

可能也需要補索引：

- `usr_id`
- `device_record_dt`
- `device_id`
- `external_event_id`
- `is_voided`

### 第二版新增 Domain / Application 項目

可能新增：

- `DeviceAccessEvent`
- `DeviceAccessDecision`
- `ProcessDeviceAccessEventHandler`
- `IDeviceAccessEventRepository`
- `ITicketEligibilityService`
- `IAttendanceService`
- `IDeviceAccessIdempotencyService`

第二版要避免把所有流程寫在 Controller。

Controller 只應負責接 request，真正業務流程放在 Application use case。

## 第一版與第二版差異

| 項目 | 第一版 | 第二版 |
| --- | --- | --- |
| 主要目的 | 後台紀錄管理 | 門禁業務流程 |
| 是否開門判斷 | 不做 | 要做 |
| 是否扣票券 | 不做 | 要做 |
| 是否更新學生最近進場 | 不做 | 要做 |
| 是否產生出席紀錄 | 不做 | 要做 |
| 是否處理 10 分鐘規則 | 不做 | 要做 |
| 刪除策略 | 作廢 | 作廢 |
| API 性質 | CRUD | Event Processing |
| 適用對象 | 後台管理者 | 閘門、QR、RFID、系統事件 |

## 建議實作順序

### 第一階段

1. 補 `device_record` soft delete 欄位。
2. 完成後台 CRUD API。
3. 完成查詢 filter。
4. 完成作廢功能。
5. 補基本測試。
6. 確認後台管理流程可用。

### 第二階段

1. 新增門禁事件 API。
2. 新增有效票券判斷。
3. 新增進場成功 / 失敗決策。
4. 新增票券核銷流程。
5. 新增 `sdt_profile` 更新流程。
6. 新增 `sdt_att_record` 整合。
7. 新增 10 分鐘暫時進出規則。
8. 新增防重複事件處理。
9. 新增背景任務。

## 總結

第一版是資料管理底座，目標是讓後台可以安全管理 `device_record`，並且透過 soft delete 保留歷史紀錄。

第二版才是完整門禁業務引擎，目標是讓每一次刷入刷出都能正確影響會員票券、出席紀錄與門禁結果。

這樣拆分可以避免第一版就把 CRUD、開門、扣票、出席全部混在一起，也讓後續擴充時比較容易維護。
