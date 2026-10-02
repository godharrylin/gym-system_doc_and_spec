# 註冊功能實作狀態清單

整理日期：2026-09-19；會員列表狀態更新：2026-09-23。

## 目前結論

註冊功能第一階段已完成，可進行基本人工驗收與後續會員列表串接規劃。

第一階段的完成範圍是：後台 Admin 登入後，可進入註冊頁、載入註冊可購買票券、送出會員註冊及可選購票資料，由後端在正式註冊交易內檢查手機重複，成功後顯示「註冊成功」彈窗，關閉後明確導到 Students & Members 頁面。

## 已完成項目

- 前端註冊頁已改為呼叫後端 `POST /api/v1/users/register`。
- 前端註冊頁已使用後端 `GET /api/v1/ticket-plans/registration-purchasable` 載入註冊情境可購買票券。
- 前端已移除 Mock 手機查重；不再用 Mock 資料判斷手機是否已註冊。
- 手機重複檢查改由後端正式註冊流程統一處理。
- 後端 `RegisterMemberHandler` 會使用 `GetExistingPhonesAsync` 檢查既有手機。
- 後端已加入穩定錯誤碼，例如 `MEMBER_PHONE_ALREADY_REGISTERED`、`DUPLICATE_PHONE_IN_REQUEST`。
- 資料庫 unique constraint 發生 `2601` 或 `2627` 時，後端會轉成可辨識的手機重複商業錯誤。
- 註冊失敗時，前端會保留表單內容並顯示錯誤訊息。
- 錯誤回應已整理為可供前端使用的 `code`、`message`、`traceId` 格式。
- 未預期例外由後端全域 exception handler 處理，只回傳安全訊息，不直接暴露 SQL、stack trace 或連線資訊。
- 前端 `registerMember` 已改為 typed response。
- 註冊成功後會顯示「註冊成功」彈窗。
- 註冊成功彈窗關閉或按確認後，會明確導到 Students & Members 頁面。
- 成功導頁已與返回操作拆開；返回使用 `onBack`，註冊成功使用 `onRegisteredSuccess`。
- 註冊送出期間會停用送出操作，避免重複送出。
- 前端 Admin Portal 已改接後端登入。
- 前端會保存 access token、refresh token 與登入者角色。
- 受保護 API request 會帶 `Authorization: Bearer <access-token>`。
- access token 過期時會嘗試 refresh；refresh 失敗會清除登入狀態。
- `POST /api/v1/users/register` 已限制 `Admin` role。
- `GET /api/v1/ticket-plans/registration-purchasable` 已限制 `Admin` role。
- 未登入呼叫受保護註冊 API 會被拒絕。
- 非 Admin 呼叫受保護註冊 API 會被拒絕。
- 後端已補上手機重複、SQL unique 轉譯、同手機競爭、Admin 授權 attribute 等測試。
- 前端已補上註冊 API response、錯誤處理、token refresh、403 fallback 等測試。
- 已執行前端 build，確認目前前端可編譯。
- 已執行後端 build 與測試，確認第一階段主要流程可編譯與測試通過。

## 尚未完成項目分類

### 會員列表已實作，待瀏覽器人工驗收

現行規格與驗證結果見 [學員列表實作狀態](../../search_studentList/current/student-member-list-implementation-status.md)。

- 已接 GET /api/v1/students，包含搜尋、篩選、每頁預設 15 筆分頁與票券狀態。
- 註冊成功回到 Students & Members，列表重新掛載並載入 API；新會員按既定排序分頁，不保證在第 1 頁，可透過搜尋找到。
- 姓名／電話編輯已接 PATCH API，成功後刷新。
- 新會員高亮及跳到新會員所在頁未納入本階段，仍列後續。

### 後續 backlog

- 尚未實作註冊成功後導到新會員詳細頁；目前需求是導到 Students & Members。
- 操作者仍維持 `ADMIN_PLACEHOLDER`，尚未改成 JWT 中的實際登入者 ID。
- 尚未建立註冊操作者 audit 的完整規格與實作。
- 後台登入目前仍是電話登入，尚未加入密碼、OTP 或其他正式安全驗證機制。
- 尚未建立完整權限模型；目前註冊流程先以 `Admin` role 限制。
- 多會員註冊 UI 尚未實作。
- 家庭或多受益者購票流程尚未納入註冊頁。

### 目前不做的已確認決策

- 未新增獨立手機查重 API。
- 未實作輸入期間的手機查重 debounce 或取消舊請求，因目前決策是送出時由後端統一檢查。
- 前端查重狀態不會寫入資料庫，且目前也沒有此需求。

## 待人工驗收項目

- Admin 登入後可進入註冊頁。
- 未登入狀態無法呼叫註冊與註冊可購買票券 API。
- 非 Admin 登入後無法呼叫註冊與註冊可購買票券 API。
- 註冊頁可以正常載入註冊情境可購買票券。
- 輸入新手機與姓名，不選票券時可以成功建立會員。
- 輸入新手機與姓名，選擇單堂票並選擇已付款時可以成功註冊與購票。
- 輸入新手機與姓名，選擇票券但建立未付款訂單時可以成功建立未付款訂單。
- 輸入已存在手機時，後端回傳手機重複錯誤，前端保留表單並顯示失敗原因。
- 註冊成功時只顯示「註冊成功」彈窗。
- 成功彈窗關閉或按確認後，畫面導到 Students & Members。
- 送出過程中連續點擊 Confirm & Pay 不會建立重複資料。

## 建議下一步

- 先完成註冊流程人工驗收，確認第一階段行為符合預期。
- 依學員列表實作狀態文件完成瀏覽器人工驗收。
- 後續再討論詳細頁、新會員高亮與生命週期排程。
