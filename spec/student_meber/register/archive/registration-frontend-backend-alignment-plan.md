# 註冊功能前後端串接與操作流程實作規劃

整理日期：2026-09-14。

狀態：本文件第一階段與 Admin 授權串接已於 2026-09-14 完成；會員列表串接、多會員 UI、真正操作者稽核與密碼／OTP 仍維持後續範圍。

## 實作結果（2026-09-14）

- 前端已移除註冊畫面的 Mock 手機查重；手機重複只由正式註冊 request 在後端 transaction 內判斷。
- 後端已加入 `MemberRegistrationRejectedException` 與固定錯誤碼，並將 SQL unique constraint 的 `2601`／`2627` 轉譯為 `MEMBER_PHONE_ALREADY_REGISTERED`。
- 註冊錯誤回應已包含 `code`、`message`、`traceId`；未預期例外由全域 handler 記錄完整 log，只回傳安全訊息。
- 前端註冊 API 已改為 typed response，失敗時保留表單並顯示安全錯誤資訊。
- 成功後會先顯示僅含「註冊成功」的彈窗，按確認或關閉後才返回會員列表畫面。
- Admin Portal 已改接後端登入，使用 `sessionStorage` 保存 access／refresh token 與使用者角色；受保護 request 會附帶 bearer token，`401` 時嘗試 refresh，失敗則清除登入狀態。
- `POST /api/v1/users/register` 與 `GET /api/v1/ticket-plans/registration-purchasable` 已要求 `Admin` role；`OperatorId` 仍為 `ADMIN_PLACEHOLDER`。
- 已新增重複手機錯誤碼、SQL unique 轉譯、同手機競爭、Admin attribute、前端 response／錯誤／refresh 等自動測試。

## 1. 目標

完成後台管理員的會員註冊流程，使前端可以：

1. 載入註冊情境可購買的票券方案。
2. 送出會員資料及可選的票券購買資料。
3. 由後端在正式註冊交易內檢查手機號碼是否重複。
4. 成功時先顯示「註冊成功」彈窗，關閉後才返回上一頁。
5. 失敗時保留表單並顯示可理解的原因及可供除錯的追蹤資訊。
6. 將註冊功能限制為具備 `Admin` role 的登入者。

## 2. 已確認決策

### 2.1 手機查重採方案 A

- 不新增獨立手機查重 API。
- 不在輸入電話時即時查詢 GymDB。
- 不實作 debounce 或取消舊查重 request，因為方案 A 沒有逐字輸入的網路查詢。
- 使用者點擊送出後，前端直接呼叫正式註冊 API。
- 後端沿用 `RegisterMemberHandler` 內的 `IUserRepository.GetExistingPhonesAsync()`，在註冊 transaction 中查詢 GymDB。
- 查到既有電話時，整筆註冊 rollback，前端顯示失敗原因。
- 資料庫 unique constraint 仍是競爭情況的最後防線；不能只依賴送出前的前端狀態。

前端不再使用 `MockStudentRepository` 判斷手機是否已註冊，避免 Mock 資料與 GymDB 不一致而錯誤阻擋或放行。

### 2.2 前端查重狀態

方案 A 不需要 `checking`、`available` 等即時查重狀態，也不需要將任何查重狀態寫入資料庫。

前端只保留必要的本地表單驗證，例如：

- 姓名必填。
- 手機必填及格式檢查。
- 同一份 request 內不得輸入重複手機號碼；目前單人 UI 不會發生，後端仍保留防線。
- 有選票券時必須選擇付款狀態。

### 2.3 成功彈窗

- 註冊成功時只顯示「註冊成功」。
- 不要求在彈窗顯示會員 ID、訂單 ID 或金額。
- 使用者點擊確認、關閉按鈕或其他明確關閉操作後，才返回上一頁。
- API 成功後不得在彈窗顯示前先導頁。

### 2.4 失敗資訊

- 註冊失敗時顯示可安全提供給後台人員的原因。
- 回應可附 `code` 與 `traceId`，方便除錯及查找伺服器 log。
- 完整 exception、stack trace、SQL、連線字串與資料庫內部資訊只記錄於後端，不直接回傳前端。
- 開發環境可視需要額外回傳安全的 exception type；正式環境不可暴露內部細節。

### 2.5 導頁與會員列表

- 第一階段只完成成功彈窗關閉後返回上一頁。
- 會員列表目前仍使用 Mock 資料，改接後端及返回後重新載入列為下一階段。
- 第一階段不保證返回列表後立即看到剛註冊的 GymDB 會員。

### 2.6 權限與操作者

- 註冊功能目前只允許 `Admin` role。
- `OperatorId` 暫時維持 `ADMIN_PLACEHOLDER`，本次不改成 JWT 中的登入者 ID。
- 權限驗證與操作者稽核分開處理；未來需要 audit 時再串接真正操作者。

### 2.7 多會員註冊

- 多會員操作介面暫緩。
- 目前維持單一會員輸入畫面。
- Request／後端 command 可繼續保留陣列結構，供未來擴充。
- 本次不新增家庭或多受益者購票。

## 3. 現況基線

### 已串接

- 前端以 `POST /api/v1/users/register` 送出註冊。
- 前端以 `GET /api/v1/ticket-plans/registration-purchasable` 載入註冊可購票方案。
- 前端 payload 的 `members`、`ticketPurchase`、方案 ID、數量與付款狀態可對應後端 contract。
- 後端接受 `PAID`／`UNPAID` 大小寫格式。
- 後端在 transaction 內查詢現有手機號碼，失敗時 rollback。
- 後端已具備 JWT authentication 與 role claim 基礎能力。

### 尚未完成

- 前端仍以 `MockStudentRepository` 做輸入階段查重。
- 前端 `registerMember()` 尚未回傳 typed registration response。
- 成功後目前直接返回，尚無成功彈窗。
- 失敗回應尚未全面統一為 `code/message/traceId`。
- 前端 Admin 登入仍為 Mock 固定電話驗證，沒有取得及附加後端 access token。
- 註冊與註冊票券清單 endpoint 尚未限制 `Admin`。
- 會員列表仍使用 Mock 資料。
- 尚無完整前端至後端 HTTP／瀏覽器驗收。

## 4. 預計實作順序

### 第一步：移除前端 Mock 手機查重

調整 `useAddMemberViewModel`：

- 移除 `registerMembersUseCase.isPhoneDuplicate()` 呼叫。
- 移除輸入電話時的非同步查重。
- 移除或簡化只為 Mock 查重存在的 `isDuplicate` 狀態。
- 保留必填、手機格式與 request 內重複等同步表單驗證。
- 送出時不要先寫入 Mock repository。

本步不新增 API，也不需要 debounce、AbortController 或查重狀態資料表。

### 第二步：統一正式註冊的重複手機錯誤

後端沿用目前 `RegisterMemberHandler` 的查重位置，調整錯誤表達：

- 現有電話回傳穩定錯誤碼，例如 `MEMBER_PHONE_ALREADY_REGISTERED`。
- 同一 request 內重複電話使用另一個明確錯誤碼，例如 `DUPLICATE_PHONE_IN_REQUEST`。
- 仍在同一 transaction 內完成檢查與新增。
- 若資料庫 unique constraint 在競爭情況下拒絕新增，轉換成相同或可辨識的手機重複商業錯誤，不把 SQL exception 直接送到前端。
- 確認失敗後沒有殘留 user、role、profile、order、order item 或 pass。

### 第三步：建立 typed 註冊 response

前端新增與後端一致的型別：

```ts
type RegisterMemberResponse = {
    memberIds: string[];
    orderId: string | null;
    totalAmount: number | null;
    actualAmount: number | null;
};
```

將：

```ts
registerMember(request): Promise<void>
```

改為：

```ts
registerMember(request): Promise<RegisterMemberResponse>
```

ViewModel 暫存成功結果，以確定 request 已完成。第一階段彈窗只顯示「註冊成功」，不顯示詳細欄位；關閉彈窗或離開頁面後即可清除結果。

### 第四步：統一錯誤 contract 與後端 logging

已知商業錯誤建議回傳：

```json
{
  "code": "MEMBER_PHONE_ALREADY_REGISTERED",
  "message": "手機號碼已被註冊",
  "traceId": "00-..."
}
```

未預期錯誤建議回傳：

```json
{
  "code": "INTERNAL_SERVER_ERROR",
  "message": "註冊失敗，請聯絡系統管理員",
  "traceId": "00-..."
}
```

實作方向：

- 優先使用 ASP.NET Core `ProblemDetails` 或等價的統一錯誤 contract。
- 已知的驗證、重複手機、方案不存在及購買資格問題對應固定 HTTP status 與 code。
- 未預期 exception 由全域 exception handler 記錄完整 stack trace。
- Log 加入 `traceId`，讓前端提供的追蹤編號可以找到伺服器錯誤。
- 正式環境不得回傳 stack trace、SQL 或 connection string。

前端解析 `code/message/traceId`；失敗時保留全部表單資料，不導頁、不開成功彈窗。

### 第五步：實作成功彈窗與關閉後導頁

在註冊 ViewModel 增加：

- `registrationResult`
- `isSuccessDialogOpen`
- `closeSuccessDialog()`

成功流程：

```text
按下送出
→ 防止重複送出
→ POST /api/v1/users/register
→ 收到成功 response
→ 開啟「註冊成功」彈窗
→ 使用者確認或關閉
→ 關閉彈窗
→ 呼叫 onSuccess()
→ 返回上一頁
```

要求：

- `onSuccess()` 只執行一次。
- 彈窗開啟期間不可重複提交。
- 成功 response 到達前不可顯示成功。
- 關閉前不可返回上一頁。
- 失敗時不開成功彈窗。

### 第六步：串接後端 Admin 登入

目前前端 Admin Portal 使用固定電話的 Mock 驗證。要讓後端真正限制 `Admin`，前端需要：

- 改呼叫現有 `POST /api/v1/auth/login`。
- 接收 access token、refresh token、到期時間及 roles。
- 登入結果必須包含 `Admin`，否則不進入後台。
- 建立共用 authenticated API client，對受保護 request 加上：

```http
Authorization: Bearer <access-token>
```

- 處理 access token 到期及 refresh。
- `401` 清除登入狀態並要求重新登入。
- `403` 顯示沒有 Admin 權限。
- 前端 route guard 只負責操作體驗，不能取代後端授權。

目前登入只依電話取得 token，尚無密碼或 OTP。第一階段可完成角色限制，但正式安全強度不足；密碼／OTP 應另立安全規格。

### 第七步：後端限制 Admin role

在登入串接可用後，保護註冊相關 endpoint：

```csharp
[Authorize(Roles = "Admin")]
```

至少包含：

- `POST /api/v1/users/register`
- `GET /api/v1/ticket-plans/registration-purchasable`

本次不從登入 claim 取得操作者，`OperatorId` 仍為 `ADMIN_PLACEHOLDER`。

## 5. 第一階段完成後的操作結果

第一階段完成範圍為：移除 Mock 查重、後端送出查重錯誤、typed response、錯誤資訊、成功彈窗與關閉後導頁。

```text
填寫會員資料
→ 選擇是否購票及付款狀態
→ 按下送出
→ 後端 transaction 查 GymDB 手機號碼
  ├─ 重複／其他錯誤：rollback、顯示原因、保留表單
  └─ 成功：commit、顯示「註冊成功」
→ 關閉成功彈窗
→ 返回上一頁
```

此階段不包含會員列表串接，也不包含即時手機查重。

## 6. 下一階段：會員列表串接

成功彈窗及導頁完成後，另案處理：

- 建立後端會員列表查詢 API。
- 定義分頁、搜尋、票券摘要及篩選 contract。
- 前端 `StudentListPage`／ViewModel 改接後端，不再讀取 Mock dashboard data。
- 返回會員列表後重新查詢，使新會員立即出現。
- 決定是否使用註冊 response 的第一個 `memberId` 高亮新會員；目前不自動導向詳情頁。

## 7. 明確不在本次範圍

- 獨立手機查重 API。
- 輸入期間的 debounce／AbortController 查重。
- 將前端查重狀態寫入資料庫。
- 多會員新增／移除 UI。
- 家庭或多受益者購票。
- 註冊完成後自動導向會員詳細頁。
- 會員列表後端串接。
- 將 `ADMIN_PLACEHOLDER` 改成登入者 ID。
- 密碼、OTP 或其他高強度登入驗證。

## 8. 測試與驗收

### 後端

- 新手機可成功註冊。
- GymDB 已有手機時回傳固定錯誤碼與安全訊息。
- 同一 request 內重複手機時拒絕。
- 兩個同手機註冊 request 競爭時最多一筆成功，另一筆轉為商業錯誤。
- 重複手機、資格失敗、票券不存在及未預期失敗均不留下部分資料。
- 無票券、Paid 票券及 UnPaid 訂單三種註冊結果保持正確。
- 未登入呼叫註冊 endpoint 回 `401`。
- 非 Admin token 回 `403`。
- Admin token 可完成註冊。
- Response 不包含 stack trace、SQL 或連線資訊。
- 後端 log 可用 response `traceId` 找到完整 exception。

### 前端

- 電話輸入不再呼叫 Mock 查重或獨立查重 API。
- 點擊送出只呼叫正式註冊 API 一次。
- 送出期間按鈕停用，避免重複 request。
- 重複手機顯示後端原因並保留表單。
- 已知錯誤顯示 message；可顯示 code／traceId 供回報。
- 未預期錯誤不顯示敏感資訊。
- 成功後只顯示「註冊成功」。
- 成功彈窗未關閉前不導頁。
- 點擊確認或關閉後只導頁一次。
- `401` 導回登入；`403` 顯示權限不足。

### 整合流程

```text
Admin 登入
→ 開啟註冊頁
→ 載入 registration-purchasable
→ 送出註冊
→ 後端交易內查重及註冊／購票
→ 顯示成功彈窗
→ 關閉彈窗
→ 返回上一頁
```

## 9. 完成條件

- 前端不再以 Mock 資料判斷註冊手機是否重複。
- 不存在獨立查重 request，因此不需要 debounce。
- 正式註冊 API 是唯一的 GymDB 手機查重入口，且 transaction／unique constraint 防線有效。
- 成功彈窗與關閉後導頁符合已確認流程。
- 失敗原因、錯誤碼與 traceId 可用，且不暴露敏感 exception 資訊。
- `Admin` role 才能呼叫註冊相關 endpoint。
- `OperatorId` 仍保持 `ADMIN_PLACEHOLDER`。
- 會員列表與多會員 UI 明確保留到後續階段，不誤標為本次已完成。
