# 階段 01 目前實作狀態

更新日期：2026-10-16。依據：[階段規格](../impelment_rule.md)。

狀態：後端核心已實作，本機建置與非 SQL 自動測試通過；完整進出授權、SQL 整合與現場驗收尚未完成。不是整體第一版已完成或已部署的證明。

## 已實作

- 新增內部 `IGymAccessEligibilityService`／`GymAccessEligibilityService`，提供 CheckEntryAsync／CheckExitAsync，電話 Trim 後只接受 ASCII `09xxxxxxxx`，精確查 users，不呼叫登入、不發 token。
- 進場檢查帳號啟用及啟用角色；Admin／Staff／Instructor 優先於 Student。保留所有啟用角色及此次身分類別，不另外定義三種工作角色之間的新優先順序。
- 工作人員不進入學生 profile／票券／交易流程；無適用角色回「尚未註冊會員」。Student 缺 profile 拒絕並記錄原因，不補建資料、不誤報過期。
- Student 經共用生命週期整理後檢查原始票券結果，不把 profile 或會員列表 Current Plan 當授權。檢查已付款、Active、起迄日期、堂數及資料完整性；效期按台灣日期，只有 SKU SINGLE 沿用無日期規則。
- 回傳 BasicEligibilityPassed、原因碼、身分類別、啟用角色、後端評估時間及當前票券；學生通過仍標示 RequiresClassAndReservationCheck，不提供 CanOpenDoor，不代表可繞過後續裝置／課程／占用驗證。
- 已識別使用者出場不因帳號／角色停用、profile 缺漏、票券過期或額度不足拒絕，保存結構化診斷日誌；出場診斷不整理／啟用票券、不改 profile 或館內狀態。可選診斷故障不變成票券拒絕；請求取消仍傳遞取消。
- 抽出 `ICurrentTicketService`／`CurrentTicketService` 共用生命週期與 profile 同步；購票、延遲付款、票券查詢、取消續約及學生進場都使用同一元件。呼叫端管理交易，服務不自行 Begin／Commit，避免巢狀交易。
- 共用啟用日期依來源原因區分：Depleted 當天、Expire 隔天，且不早於付款日；SQL 與記憶體 repository 同步。不改續約可購買／取消重訂期限，不代表已實作歷史還原。
- 原始票券快照補上 PlanCode、TicketStartDate，供資格檢查；不新增 profile DB 欄位。記憶體 ToSnapshot 改為必須傳入時間，不再自行用 DateTime.UtcNow；共用流程使用同一次後端台灣時間。
- 新增 StudentProfileSnapshotUpdateException，繼承 InvalidOperationException；票券查詢轉回既有 KeyNotFound／NotFound 語意，購票／註冊仍失敗回滾。已經使用者確認更新舊註冊測試的精確例外型別，保留回滾一次／提交零次斷言。

## 驗證結果

工作目錄：`D:\HarryLin\GitHub\Web\gyme-system\gym-system-backend`。建置／測試由本機 `.artifacts/io-stage01/verify.py` 包裝，以參數陣列、shell=False 執行，完整日誌保留在本機暫存目錄；helper 與產物由既有 `.artifacts/` 忽略，不加入版本控制。

| 項目 | 命令 | 結果 |
| --- | --- | --- |
| Solution 建置 | `dotnet build gym-system-backend.slnx --no-restore --verbosity minimal` | exit 0，6.19 秒，0 錯誤／0 警告 |
| Application 測試 | `dotnet test tests/gym-system.Application.Tests/gym-system.Application.Tests.csproj --no-build --no-restore` | exit 0，3.94 秒，149 通過、0 失敗 |
| API／repository 測試 | `dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-build --no-restore` | exit 0，5.75 秒，79 通過、0 失敗、33 SQL 測試跳過 |
| Git 格式檢查 | `git diff --check` | 通過 |

測試命令另帶 TRX logger 與專用 results-directory；完整參數保存在摘要日誌。本輪未設定 TEST_DB_CONNECTION，因此不能將 33 項跳過當成 SQL 驗證通過。測試輸出未提供一般編譯警告總數，摘要標為未知；測試失敗數由 TRX 判讀，不以 build 成功取代測試。

主要涵蓋：電話格式／精確查詢、帳號／角色停用、三種工作角色兼 Student、profile 缺漏、到期日與次日、SINGLE 無日期、耗盡同日接續、真正未到啟用日仍不搶位、單堂讓位保留堂數、profile 不是授權來源、快照失敗回滾、出場唯讀／異常診斷及既有查詢 NotFound 行為。

完整本機日誌（暫存檔可能日後被系統清理，未上傳／提交）：

- Build：`C:\Users\HarryLin\AppData\Local\Temp\gym-io-stage01-j5uia3nl\build.log`
- Application：`C:\Users\HarryLin\AppData\Local\Temp\gym-io-stage01-e_y7d4na\application-tests.log`
- API：`C:\Users\HarryLin\AppData\Local\Temp\gym-io-stage01-8bm037ks\api-tests.log`

## 未完成／不在本輪範圍

- SQL 整合驗收：新增 GymAccessLifecycleSqlTests，涵蓋真實 repository 當日接續及同交易 profile 同步，但本輪跳過，未建立／清理任何 DB 測試資料，也未修改 schema。
- 階段 02 的裝置授權、後端站點方向、公開進出 API、前端 Check-In 串接、廠商開門與成功事件、館內狀態及持久化操作紀錄；目前只記基本識別／出場異常日誌，不能等同完整業務稽核。
- 階段 03／04 的真實場次、時段／回場、暫占／固定占用、帳面與可用額度差異及截止票券固定；本階段不扣堂、不保留額度，不能因基本通過就開門。
- 階段 05 的 A／B、歷史補跑及接續業務日期還原。共用服務是目前狀態整理，不可直接傳入過去日期並宣稱歷史授權完成。
- 階段 06 的人工進出、更正、跨日待確認及後續恢復；本輪沒有新增相關 API／資料表。
- IO-11 全寫入路徑查核仍未全部完成；本輪已對齊共用票券流程與記憶體快照，既有其他寫入、SQL 預設值、匯入／批次仍需逐項盤點，不批次加八小時。
- 實際 iPad、SQL 交易／鎖定與廠商設備、部署網路及人工場地驗收。

## 下一階段銜接限制

- 接續階段 02 時，先完成裝置與站點方向授權，再呼叫內部識別用例；不得直接暴露未授權的電話查詢或把結果當作 Admin token。
- 學生仍須在後續交易內整合課程／回場及有效占用；工作角色與多角色結果可供操作紀錄保存，但實際成功進場時的身分固定與角色變更處理仍需銜接。
- 測試跳過與待人工驗收項目保持未完成；不以本文件替代後續階段授權。
