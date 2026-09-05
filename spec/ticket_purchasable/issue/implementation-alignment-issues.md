# 待實作與待對齊事項

## 1. NEW_ONLY 改成台灣日曆判斷

目前：

- 使用 `Now.AddDays(-30)`。
- 判斷單位是 timestamp，不是台灣日曆日。

建議做法：

- 在 `NewOnlyTicketPlanEligibilityRule` 改用 `IClock.Today` 或等價的台灣 `DateOnly`。
- 將 `AssignedAt` 轉成台灣日期後再比較。
- 比較語意建議為 `assignedDate >= today.AddDays(-30)`。

需先等規格確認：

- `AssignedAt` 是否為台灣本地時間。
- 第 30 天是否仍算可買。

## 2. 目錄查詢輸出 eligibility rule code 集合

目前：

- `DapperTicketPlanCatalogQueryService` 只輸出 `NEW_ONLY`、`RENEWAL` 到 `EligibilityRuleCodes`。

風險：

- 未來新增限制性購買規則時，若 SQL 未同步輸出，購買資格服務不會檢查該規則。

建議做法：

- 定義規則分類，例如 display rule 與 eligibility rule。
- 目錄查詢輸出所有 eligibility rule。
- `HIDDEN` 保留為 display rule，不一定進 eligibility。

是否需要改 DB：

- 若只擴充 SQL code 清單，不一定要改 schema。
- 若要用資料驅動分類，可能需在 rule table 增加欄位或建立明確規則分類資料。

## 3. 註冊清單與一般清單規則同步

目前：

- 註冊清單額外排除 `RENEWAL`。
- 一般個人化清單依 eligibility 判斷。

建議做法：

- 明確定義註冊 API 要排除的規則集合。
- 將排除規則集中管理，避免散落在 controller/query。
- 補註冊清單測試。

需先等規格確認：

- 註冊清單只排除 `RENEWAL`，或排除所有會員狀態型規則。

## 4. Hidden 方案購買防線

目前：

- `HIDDEN` 方案不出現在目錄。
- eligibility service 不檢查 `HIDDEN`。

建議做法：

- 若 hidden 方案不可被任何一般購買 API 購買，購買流程應確保 catalog lookup 拿不到 hidden 方案，或額外明確拒絕。
- 若 hidden 方案保留給特殊流程，需拆分一般購買 catalog 與特殊購買權限。

需先等規格確認：

- Hidden 是否只是不顯示，還是不可直接購買。

## 5. NEW_ONLY 購買歷史查詢是否排除 cancelled pass

目前：

- 查詢依 order item payment state 判斷，沒有明確排除 cancelled pass。

建議做法：

- 若取消後仍算買過，保留目前方向並補測試固定。
- 若取消後不算買過，調整 query 加上 pass 狀態條件。
- 若只允許特定取消原因重買，需新增原因判斷。

需先等規格確認：

- 取消後是否可重新買 NEW_ONLY。

## 6. 續約併發保護

目前設計要求：

- 同一來源 pass 不應同時被多張非取消續約票券承接。

建議做法：

- 確認 DB 是否已有 `renewed_from_pass_sn` filtered unique index。
- 若沒有，補 migration 或 SQL script。
- 購買流程保留交易鎖與付款時重驗。

建議索引語意：

```sql
renewed_from_pass_sn IS NOT NULL
AND valid_status <> 'Cancelled'
```

## 7. 續約來源查詢與生命週期對齊

目前規格依賴：

- latest same-family source。
- source started。
- non-cancelled。
- no active successor。
- queued conflict。
- cancellation retry。

建議做法：

- 對照 `FindLatestRenewalSourceAsync`、successor 查詢、queued 查詢。
- 確認不 fallback 到更舊來源。
- 確認 `endedAt` 與 `validEndDate` 選擇一致。

## 8. 前端日期處理

目前風險：

- 若前端用 `toISOString()` 切日期，台灣跨日可能顯示錯誤日期。

建議做法：

- 前端顯示日曆日需使用台灣日期語意。
- 後端若已輸出日期字串，前端避免再轉 UTC。
- 跨日時補 UI 測試或格式化 helper 測試。

## 9. 家庭購買恢復前置項

目前：

- 家庭購買暫停。
- 受益者必須剛好 1 人。
- 不套用家庭折扣。

未來恢復需補：

- 多受益者 eligibility all-or-nothing。
- 家庭關係檢查。
- 家庭折扣與四捨五入規則。
- 任一受益者失敗時 rollback。
- 前端多受益者選擇與錯誤顯示。
