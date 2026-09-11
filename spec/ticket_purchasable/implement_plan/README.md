# 可購買票券邏輯實作計畫

整理日期：2026-09-06；進度更新：2026-09-09。狀態：A07 已確認保留現行註冊、修正測試 UTC 寫入、匯入／批次於邊界轉台灣時間、未知舊資料不整批修正。GymDB 經確認只有開發／測試資料，已完成首批 SQL 驗收。Application 104、API 專案 43（含 GymDB 25）、前端時間測試 5 個通過，前端 build 成功；整份計畫尚未全部驗收。最新證據、專屬資料清理方式與具體缺口見 [後續調整與驗收規劃](05-remaining-alignment-plan.md)。

## 閱讀順序

1. [已確認決策](01-confirmed-decisions.md)：本次討論最後採用的業務規則。
2. [實作步驟與影響範圍](02-implementation-plan.md)：現況差異、修改位置、執行順序與資料查核。
3. [驗收案例](03-acceptance-tests.md)：實作完成後應通過的案例，並非已執行的測試結果。
4. [測試實作計畫](04-test-implementation-plan.md)：將驗收案例對應到測試層級、測試資料與建議測試檔案。
5. [後續調整與驗收規劃](05-remaining-alignment-plan.md)：2026-09-07 查核後的剩餘修正、待確認／待查核事項及後排工作。

## 與現有文件的關係

本次將討論寫入 `implement_plan/`。上層規格與 `issue/` 的原始內容仍可能描述舊行為；本次已決定的變更以 [01-confirmed-decisions.md](01-confirmed-decisions.md) 為準，不能把本計畫當成目前程式已具備的能力。

尤其不要沿用以下舊版本：

- NEW_ONLY 使用 rolling 30 天或日曆 `AddDays(-30)`。
- NEW_ONLY 以 order item 是否非 `Cancel` 作為資格消耗依據。
- 註冊流程允許 NEW_ONLY。
- 續約取消只能當天重訂，或取消可延長來源票原續約截止日。
- Active 單堂票未用完就持續阻擋其他可啟用票券。
- `Tags` 與 `EligibilityRuleCodes` 混用為同一種後端資格依據。
- 前端用 `toISOString().split('T')[0]` 推導台灣日曆日。

實作階段應同步將目標行為回填正式規格，並分別記錄「規格已確認」與「程式已實作／已驗證」，對應關係如下：

| 決策內容 | 正式規格回填位置 |
| --- | --- |
| NEW_ONLY、共用資格、續約來源與期限 | `../ticket-purchasability-spec.md` |
| HIDDEN、RulePolicyRegistry、規則輸出與分類 | `../ticket-plan-catalog-spec.md` |
| 續約取消維持 UnActive、單堂票讓位、enum | `../ticket-lifecycle-spec.md` |
| 兩支清單 API、註冊購買情境、canCancel、家庭暫停、購買紀錄 timestamp | `../ticket-purchase-ui-api-spec.md` |
| Context／handler、repository、資料查核 | `../ticket-purchase-technical-design.md` |
| 追蹤狀態與驗收證據 | `../issue/` 對應文件 |

## 範圍

本計畫包含已確認規則與必要技術調整。技術建議、尚待查核的資料來源均另行標明，不視為額外業務決策。舊計畫保留；本次不執行刪除、封存或 SQL migration。
