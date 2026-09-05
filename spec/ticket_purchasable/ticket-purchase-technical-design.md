# 票券可購買技術設計與待補事項

## 目前主要元件

- `DapperTicketPlanCatalogQueryService`
  查詢票券方案目錄、規則關聯與對外 DTO 資料。
- `TicketPlanEligibilityService`
  依方案的 `EligibilityRuleCodes` 執行 rule handler。
- `NewOnlyTicketPlanEligibilityRule`
  驗證新客 30 天與同 SKU 購買歷史。
- `RenewalTicketPlanEligibilityRule`
  驗證續約資格。
- `RenewalTicketPassEligibilityService`
  找來源票券、計算 grace window、判斷 queue conflict、取消重試。
- `TicketPurchaseService`
  購買流程總控，檢查學生、方案、價格、付款、受益者、eligibility，付款成立時建立 pass。
- `UnpaidTicketOrderPaymentService`
  未付款訂單付款時重新檢查價格與 eligibility。
- `RegisterMemberHandler`
  註冊流程帶票券購買時走共用購買服務。
- `TaipeiClock`
  提供台灣時區的 `Now` 與 `Today`。

## Rule 架構

目前 eligibility rule handler 以 `RuleCode` 對應資料規則代碼。每個 handler 提供：

- `RuleCode`
- `AppliesTo`
- `IsSatisfiedAsync`

購買資格服務行為：

- 找不到 handler：不可購買。
- handler 不適用：不可購買。
- handler 驗證失敗：不可購買。
- 沒有任何 rule code：可購買。

這個設計可以支援資料驅動規則，但前提是目錄查詢必須把會影響購買資格的 rule code 正確輸出。

## 目前已知不一致

- 目前目錄 SQL 只輸出 `NEW_ONLY`、`RENEWAL` 到 `EligibilityRuleCodes`。若資料庫新增其他限制規則，購買資格服務不會收到該 code。
- `HIDDEN` 是目錄顯示規則，並非 eligibility service 檢查的規則。
- NEW_ONLY 使用 `Now.AddDays(-30)`，不是純台灣日曆 DateOnly 判斷。
- NEW_ONLY 購買歷史查詢目前沒有明確排除已取消 pass。
- 續約與生命週期舊計畫提到部分 end reason 命名，需與現有 DB 實際值統一。
- 舊計畫中的多受益者家庭購買已被後續決策暫停。

## 台灣日曆調整建議

目標是把涉及「天」的資格判斷改成台灣日曆日，而不是 rolling timestamp。

建議順序：

1. 保留 `IClock` 與 `TaipeiClock`。
2. 在 NEW_ONLY 規則中改用 `DateOnly` 比較。
3. 將 `AssignedAt` 先轉為台灣日期。
4. 使用 `assignedDate >= clock.Today.AddDays(-30)`。
5. 補測試固定 clock，覆蓋台灣 00:00 邊界。

若 `AssignedAt` 已保證是台灣本地時間，可直接取 `.Date` 後轉 `DateOnly`。若來源可能是 UTC，需先透過 `TimeZoneInfo.ConvertTimeFromUtc` 或統一的 clock/helper 轉成台灣時間。

## 資料庫與索引建議

舊計畫中仍有效的資料設計建議：

- `renewed_from_pass_sn`：續約 pass 來源。
- `ended_at`：實際用完或結束時間。
- `end_reason`：結束原因。
- 針對 `renewed_from_pass_sn` 建立 filtered unique index，避免同一來源同時有多張非取消 successor。

建議索引語意：

- `renewed_from_pass_sn IS NOT NULL`
- `valid_status <> Cancelled`

這是為了讓併發購買時，資料庫也能阻擋同一來源被重複承接。

## 同步修改目錄查詢與註冊規則的意思

這不是一定要調整資料庫 schema，而是要讓「資料設定、目錄查詢、註冊清單、購買驗證」對同一批規則有一致理解。

需要同步的點：

- 資料庫有哪些 rule code。
- 目錄查詢哪些 rule code 會輸出到 `EligibilityRuleCodes`。
- 註冊清單要排除哪些 rule code。
- 後端購買服務是否有對應 rule handler。
- 測試資料是否覆蓋這些 rule code。

若只是修正 SQL 輸出既有 rule code，不一定需要改 schema。若要新增欄位描述規則分類，例如「顯示規則」與「購買資格規則」，才會涉及資料庫調整。

## 測試建議

最小必要測試範圍：

- Catalog：HIDDEN 不顯示，停用產品不顯示，停用限制性規則不顯示。
- Eligibility：無規則可買，缺 handler 不可買，NEW_ONLY/RENEWAL 各自通過與失敗。
- NEW_ONLY：30 天內、超過 30 天、剛好邊界、曾買同 SKU。
- RENEWAL：有效期內、到期後 9 天內、超過 9 天、有 queue、同日取消重試、來源已被 successor 占用。
- Purchase：Paid 建 pass，UnPaid 不建 pass，付款時重驗資格。
- Price：未付款訂單建立後改價，付款應失敗。
- Concurrency：兩筆續約同時承接同一來源，最多一筆成功。
- UI/API：註冊清單排除 RENEWAL，既有會員清單依資格顯示。

## 可捨棄舊檔案建議

等本目錄文件確認後，以下舊檔案可刪除或移到 archive：

- `doc/spec/student-ticket-plan-purchasable-api-plan.md`
- `doc/spec/ticket-plan-rule-implementation-plan.md`

以下檔案建議先保留到技術設計確認完全覆蓋後再刪：

- `doc/spec/ticket-plan-eligibility-rule-notes.md`

桌面 `0828\disscusion plan` 四份文件已被轉移進新規格，但因它們是外部討論稿，建議最後再一起封存，不直接刪除。
