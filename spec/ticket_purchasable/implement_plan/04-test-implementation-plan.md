# 測試實作計畫

狀態：部分實作並完成 GymDB 回歸；最新結果及未涵蓋範圍見 [05-remaining-alignment-plan.md](05-remaining-alignment-plan.md)。本文不是新增業務規格，而是將 [驗收案例](03-acceptance-tests.md) 轉成可落地的測試安排。

## 目標

- 明確每組驗收案例要測在哪一層。
- 固定測試時間、資料命名與前置資料，避免依賴真實今天。
- 區分 unit test、application service test、SQL integration test、API test 與 frontend test。
- 避免測試寫成舊規格，尤其是 rolling 30 天、取消續約只限當天、單堂票阻擋續約等舊行為。

## 測試分層

| 層級 | 目的 | 適合案例 |
| --- | --- | --- |
| Unit tests | 驗證純規則、日期公式、context 分支與 rule handler 行為 | NEW_ONLY、registration context、retry deadline 計算 |
| Application service tests | 驗證購買、付款重驗、取消續約與 reconcile 流程 | 購買、付款、取消、Active slot |
| Repository / SQL integration tests | 驗證實際 SQL 查詢、更新、lock、unique index 與狀態資料 | renewal source、queue conflict、duplicate successor |
| API tests | 驗證 endpoint、DTO 欄位、錯誤碼、canCancel 與 timestamp 格式 | purchasable、registration-purchasable、ticket passes、cancel |
| Frontend tests | 驗證台灣時區顯示與 API mapping；優先級後排 | timestamp 顯示、日期 helper、購買紀錄列表 |

SQL integration test 不能由 mock 取代。只通過 unit test 或 in-memory repository，不代表 DB 查詢、索引與鎖定語意已驗證。

## 固定測試時間

建議所有測試使用固定台灣時間：

```text
2026-09-06 10:00:00 +08:00
```

測試不得呼叫真實 `DateTime.Now`／`DateTime.UtcNow` 作為業務判斷依據；需要 today 時由 fake clock 或測試 fixture 注入。若測試跨午夜語意，使用明確時間，例如：

- `2026-09-05 23:50:00 +08:00`
- `2026-09-06 00:00:00 +08:00`
- `2026-09-07 00:00:00 +08:00`

## 測試資料命名

建議測試資料使用可讀名稱，讓失敗訊息能直接看出情境：

| 類型 | 命名例 |
| --- | --- |
| 會員 | `student_new_day_01`、`student_new_day_30`、`student_new_day_31`、`student_existing_active` |
| 方案 | `plan_new_only`、`plan_standard`、`plan_renewal`、`plan_hidden`、`plan_family_paused`、`plan_unknown_rule` |
| 來源票 | `pass_source_active`、`pass_source_expired`、`pass_source_depleted`、`pass_source_old_expired`、`pass_source_new_valid` |
| 續約票 | `pass_renewal_unactive`、`pass_renewal_active_unused`、`pass_renewal_cancelled`、`pass_renewal_used` |
| 單堂票 | `pass_single_active`、`pass_single_queued`、`pass_single_yielded` |
| 訂單 | `order_unpaid_new_only`、`order_unpaid_renewal`、`order_paid_successor` |

同一測試內不要共用會互相污染的資料。SQL integration test 應使用 transaction rollback、測試專用 schema 清理，或每次產生唯一 suffix。

### 已確認的 GymDB 測試策略（2026-09-09）

- 使用者確認 GymDB 只有開發／測試資料，本次可用，不再以「尚無隔離 DB」阻擋驗證。這不等於允許清空 GymDB。
- `TicketSqlFixture` 使用固定台灣 clock、每案唯一 `TPTEST_` marker，追蹤本案建立的會員、方案與規則 ID；不得修改固定的既有會員。
- SINGLE 及既有 rule 僅讀取／引用；新關聯只建立在本案方案。測試不建立 migration、不改既有 index 或共用規則狀態。
- 應用程式會自行 commit，因此不能假設外層 rollback 能清理全部資料。測試結束以本案 ID 加 marker 驗證所有權，再清理本案 pass、order item、order、profile、role、user、plan 與 rule；fixture 清理失敗則測試失敗。
- 同一 SQL collection 禁止測試間平行；併發案例在單一 fixture 內開獨立 scope／transaction。
- 只透過執行程序的 `TEST_DB_CONNECTION` 明確指定資料庫，不把密碼寫進檔案。若無設定，SQL 測試會略過，不算通過。
- 測試 IDENTITY 流水號可能跳號，不 reseed。非正常中止仍可能留下 marker 資料，須核對該次 ID 後清理，不使用全表刪除或通配字串刪除。
- 時間測試以明確 UTC 值在輸入邊界透過 `TimeZoneInfo.ConvertTimeFromUtc(..., Asia/Taipei)` 轉換後寫入；另驗證台灣時間直接寫入及讀回不再次轉換。保留現行正式註冊流程。

## 驗收案例對應

| 驗收案例 | 主要測試層級 | 建議測試類別 |
| --- | --- | --- |
| N01-N06 | Unit + application | `NewOnlyTicketPlanEligibilityRuleTests` |
| N07-N12 | Repository / SQL integration + application | `StudentTicketPurchaseHistoryQueryServiceTests`、`NewOnlyTicketPlanEligibilityRuleTests` |
| E01-E05 | Unit + API | `TicketPlanEligibilityServiceTests`、`TicketPlansControllerTests` |
| E06 | Repository / SQL integration | `TicketPlanCatalogQueryServiceTests` |
| E07-E11 | Application + API | `RegisterMemberHandlerTests`、`TicketPurchaseServiceTests`、`UnpaidTicketOrderPaymentServiceTests` |
| R01-R05 | Unit + SQL integration | `RenewalTicketPassEligibilityServiceTests`、`SqlTicketPassRepositoryRenewalTests` |
| R06-R10 | Unit + application + SQL integration | `RenewalTicketPassEligibilityServiceTests`、`TicketPurchaseServiceTests` |
| R11 | SQL integration + API | `SqlTicketPassRepositoryRenewalTests`、`OrdersControllerTests` |
| R12 | Application + API | `GetPurchasableTicketPlansForStudentHandlerTests`、`StudentTicketPlansControllerTests` |
| C01-C08 | Application + SQL integration + API | `CancelRenewalTicketPassTests`、`StudentTicketPassesControllerTests` |
| C09 | SQL integration / concurrency | `CancelRenewalConcurrencyTests` |
| C10 | SQL integration / technical verification | `TicketUsageLogQueryTests` 或後續 usage 查核測試 |
| S01-S12 | Domain + SQL integration + application | `TicketPassReconcileCurrentTests`、`SqlTicketPassRepositoryReconcileTests` |
| 目錄與保留功能 | API + SQL integration | `TicketPlanCatalogQueryServiceTests`、`TicketPurchaseServiceTests` |

## 建議測試檔案

後端優先新增或擴充：

- `NewOnlyTicketPlanEligibilityRuleTests`
- `TicketPlanEligibilityServiceTests`
- `RenewalTicketPassEligibilityServiceTests`
- `TicketPlanCatalogQueryServiceTests`
- `SqlTicketPassRepositoryRenewalTests`
- `SqlTicketPassRepositoryReconcileTests`
- `TicketPurchaseServiceTests`
- `UnpaidTicketOrderPaymentServiceTests`
- `RegisterMemberHandlerTests`
- `CancelRenewalTicketPassTests`
- `TicketPlansControllerTests`
- `StudentTicketPlansControllerTests`
- `OrdersControllerTests`

前端後排新增或擴充：

- `taipeiDate.test.ts`
- `ticketPassesApi.test.ts`
- 票券購買紀錄顯示測試。

實際檔名可依現有測試專案命名慣例調整；重點是保留案例 ID 對應，讓驗收表可以追到具體測試。

## 實作順序

1. P0：建立 fake clock、測試資料 builder、SQL fixture 與資料清理策略。
2. P1：補 NEW_ONLY 日期與 pass 歷史測試。
3. P2：補 rule context、registration context 與 catalog rule 分類測試。
4. P3：補 renewal source、retry deadline、non-cancelled successor 與 unique index 測試。
5. P4：補 cancel renewal、Active 續約票不可取消、canCancel 與使用紀錄規格保留測試。
6. P5：補 single ticket yield、queue conflict 排除 SINGLE 與 reconcile 穩定性測試。
7. P6：補 API contract、錯誤碼與購買紀錄 timestamp 到秒測試。
8. P7：補併發測試與付款重驗測試。
9. P8：補 frontend timestamp 顯示與台灣日期 helper 測試。

P3、P4、P5 有交互影響：取消 UnActive 續約票、重訂續約、單堂票讓位必須一起驗證。這組整合案例要放在同一批回歸中驗證。

## 不要測成舊規格

測試不得把以下行為當成正確：

- NEW_ONLY 使用 rolling 30 天或 `today.AddDays(-30)`。
- NEW_ONLY 因 order item 變 `Cancel` 或 pass 取消而恢復資格。
- 註冊流程可購買 NEW_ONLY。
- HIDDEN 只靠前端隱藏，後端仍可直接購買。
- FAMILY_ELIGIBLE 目前參與資格或折扣計算。
- 取消續約票後只允許取消當天重訂。
- 取消續約票可以延長來源票原本的續約截止日。
- Active 續約票可因沒有使用紀錄而取消。本次維持只允許 UnActive 續約票取消。
- 排隊中的 SINGLE 阻擋一般續約購買。
- Active SINGLE 未用完就永久阻擋可啟用非單堂票。
- 前端用 `toISOString().split('T')[0]` 推導台灣日曆日。

## 尚待查核事項

- `sdt_ticket_usage_log` 是否存在於實際 DB，且每條核銷與沖銷路徑都會寫入。
- Active 續約票取消已退出本次範圍；usage log 查核保留給未來擴充。
- SQL integration test 已確認使用 GymDB，依上述專屬 fixture 建立與清理資料；仍須配置 CI 的開發測試資料庫。
- 是否已有 migration/seed helper 可建立 `plan_rule`、`ticket_plan_kind_rule` 與 filtered unique index 測試資料。
- ticket pass API 保留 `paidAt` 日期字串，新增 `paidAtTimestamp` 到秒；需確認前端顯示改用新欄位。
- 併發測試是否能在 CI 穩定執行；若不穩定，需至少保留 DB unique index duplicate insert 測試與交易重驗測試。

## 完成條件

- 每個 `03-acceptance-tests.md` 案例至少對應一個測試或一個明確追蹤的技術缺口。
- NEW_ONLY、registration、renewal、cancel、single yield、hidden/family、timestamp 至少各有一組自動化測試。
- SQL 查詢、unique index、狀態更新與 lock 相關行為必須有 SQL integration test。
- 測試執行結果需記錄命令、通過範圍、未覆蓋項目與任何需要人工 DB 查核的事項。
- 完成後回填正式規格，並在 `issue/` 對應文件標記狀態與測試證據。
