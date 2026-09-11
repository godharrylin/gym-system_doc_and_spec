# 實作步驟與影響範圍

狀態：部分已實作，尚未全數驗收。最新進度與缺口見 [後續調整與驗收規劃](05-remaining-alignment-plan.md)。業務依據為 [已確認決策](01-confirmed-decisions.md)。以下程式路徑相對於 backend 根目錄。

## 修改前基線與目標（非最新完成狀態）

| 項目 | 修改前程式 | 目標 |
| --- | --- | --- |
| NEW_ONLY 日期 | `context.Now.AddDays(-30)` | 台灣 DateOnly，`assignedDate >= today.AddDays(-29)` |
| NEW_ONLY 歷史 | pass join order item，排除付款狀態 Cancel | 同 SKU pass 包含 Cancelled，取消不恢復資格 |
| 註冊清單 | controller 只排除 RENEWAL | 共用 CanPurchaseAsync；NEW_ONLY 也不開放註冊 |
| Context | 一律要求有效 Student | 區分註冊預覽與會員驗證，不偽造 Student |
| 取消續約票 | Domain／SQL／CanCancel 都限定 UnActive | 本次維持只允許 UnActive 續約票取消 |
| 重訂 | 最後取消日期必須等於今天 | 取消隔天結束與原續約截止日取較早者 |
| queue 衝突 | 所有 Paid UnActive pass | 單堂票不算衝突 |
| 單堂票 | 占 Active 且沒有最低排序 | 有可啟用非單堂票時讓位回 UnActive |
| rule 分類 | SQL 只硬編碼 NEW_ONLY／RENEWAL | `plan_rule` 來源，程式集中分類 Tags／EligibilityRuleCodes |
| 票券購買紀錄時間 | pass API 目前輸出 `yyyy-MM-dd` | 保留 `paidAt`，新增 `paidAtTimestamp` 到秒，建議 `+08:00` |

## P0：先查核資料與建立測試基礎

- [ ] 確認實際使用的 SQL repository、記憶體替身與既有測試位置，保持兩種實作語意一致。
- [ ] 查核 `user_role_cdt` 的匯入／批次來源時區；不要全表盲目加 8 小時。
- [ ] 查核 `doc/Database.md` 描述的 `sdt_ticket_usage_log` 是否在實際 DB 存在、是否涵蓋堂票與月票，以及每條核銷路徑是否確實寫入。
- [x] 同一來源非取消 successor 的 DB filtered unique index 已由使用者確認存在：`renewed_from_pass_sn IS NOT NULL AND valid_status <> N'Cancelled'`。
- [ ] 實作時仍需以測試確認交易鎖、付款重驗與 DB constraint 的錯誤轉換一致。
- [ ] 以固定台灣 clock 建立 [驗收案例](03-acceptance-tests.md) 所需資料；SQL 整合測試使用隔離測試資料庫。

## P1：NEW_ONLY 日期與 pass 歷史

主要修改位置：

- `src/gym-system.Application/TicketPlansUseCase/Queries/NewOnlyTicketPlanEligibilityRule.cs`
- `src/gym-system.Application/TicketPlansUseCase/Queries/IStudentTicketPurchaseHistoryQueryService.cs`
- `src/gym-system.Infrastructures/Queries/TicketPlans/DapperStudentTicketPurchaseHistoryQueryService.cs`
- `src/gym-system.Infrastructures/DependencyInjection.cs` 的 Taipei clock／相關替身。

執行步驟：

1. 保留既有 clock；一次資格評估取同一個 Now，再轉台灣 DateOnly，避免跨午夜重取 Today 造成不一致。
2. 將 AssignedAt 按已確認時區轉為台灣日期，套用 D01 公式；缺日期仍拒絕。
3. 依 pass 的 owner 與方案 SKU 檢查曾取得紀錄，包含所有既有生命週期狀態及 Cancelled。
4. 移除 order item `payment_state <> 'Cancel'` 對資格恢復的影響。可直接使用 pass 的 `ticket_plan_kind_code`；若保留 join 作資料關聯，不得由付款狀態排除已有 pass。
5. 保持無 pass 的 UnPaid 訂單不消耗資格。不新增錯帳例外或 audit log 依賴。
6. 更新單元與 SQL 查詢測試，確認取消 pass／取消 order item 均不放行仍有 pass 的同 SKU。

資料影響：原則上是判斷與查詢調整，不必先新增 schema；如發現舊時間資料需修正，另提供有來源依據的資料修正計畫。

## P2：共用 Context 與註冊規則

主要修改位置：

- `src/gym-system.Application/TicketPlansUseCase/Queries/StudentTicketPlanEligibilityContext.cs`
- 同目錄的 `ITicketPlanEligibilityService.cs`、`TicketPlanEligibilityService.cs`、`ITicketPlanEligibilityRule.cs` 及 handlers。
- `src/gym-system.Api/Controllers/TicketPlansController.cs` 的 `GetRegistrationPurchasableAsync`。
- `src/gym-system.Application/TicketPlansUseCase/Queries/GetPurchasableTicketPlansForStudentHandler.cs`
- `src/gym-system.Application/MembersUseCase/Commands/RegisterMember/RegisterMemberHandler.cs`
- `src/gym-system.Application/OrdersUseCase/Services/TicketPurchaseService.cs`、`UnpaidTicketOrderPaymentService.cs`
- `src/gym-system.Infrastructures/Queries/TicketPlans/DapperTicketPlanCatalogQueryService.cs`

建議實作：

1. Context 增加情境（例如 Registration／ExistingMember），保留 `CanPurchaseAsync(context, plan, ct)` 的共用入口。
2. 註冊清單由應用層建立無會員身分的 Context；不填虛構 StudentId，也不把 IsActiveStudent 硬設為 true。
3. 既有會員情境仍要求真實有效 Student；實際註冊購買仍要檢查已建立的會員與 profile 等基本條件。
4. rule handler 增加註冊支援設定（例如 `SupportsRegistration`，預設 false）；NEW_ONLY、RENEWAL 明確 false。這是技術命名建議。
5. 共用方法先檢查情境適用性，再執行 rule。缺 handler 或任一規則不通過時拒絕。
6. Controller 移除只排除 RENEWAL 的特例，兩支清單都使用共用服務；維持既有對外 API 與 DTO。
7. RegisterMember 呼叫購買服務時保留 Registration 情境，避免中途建立 Student 後繞過註冊限制。
8. 會員購買與付款維持資格重驗及續約交易內鎖定重驗；共用布林方法不能取代鎖內驗證。
9. SQL 可讀取全部啟用 rule 作為原始 rule code，再由應用層集中分類成 `Tags` 與 `EligibilityRuleCodes`；也可先維持 DTO 欄位，由 query service 內部完成分類。
10. 建立集中規則分類，例如 `RulePolicyRegistry`：`NEW_ONLY`／`RENEWAL` 是 eligibility rule；`HIDDEN` 是 display/catalog rule；`FAMILY_ELIGIBLE` 是 paused rule。
11. `Tags` 可提供 UI 顯示所有已知標籤，但 `CanPurchaseAsync` 僅吃 `EligibilityRuleCodes`。
12. 新增 rule code 時必須先分類；若分類為 eligibility 但沒有 handler，必須拒絕，不得靜默放行。若是未知 rule，預設不要當成可購買。
13. Controller 移除只排除 RENEWAL 的特例，兩支清單都使用共用服務；維持既有對外 API 與 DTO。
14. RegisterMember 呼叫購買服務時保留 Registration 情境，避免中途建立 Student 後繞過註冊限制。
15. 會員購買與付款維持資格重驗及續約交易內鎖定重驗；共用布林方法不能取代鎖內驗證。

資料影響：先採程式集中管理規則情境與分類，不要求為共用服務新增資料庫欄位。若未來需要由資料維護者直接管理分類，再評估在 `plan_rule` 增加 rule purpose；本次不預先建立通用規則平台。

已確認延後付款使用 ExistingMember：註冊當下仍以 Registration 擋住不開放的 SKU，註冊完成後付款依當時的會員資格及最新方案重驗，包含歷史未付款訂單；不新增來源欄位，不由前端指定情境。未付款不發 pass，付款成功後才依排隊規則啟用。

## P3：續約取消與重訂

主要修改位置：

- `src/gym-system.Domain/Entities/Tickets/TicketPass.cs` 的 Cancel。
- `src/gym-system.Domain/Repositories/ITicketPassRepository.cs`
- `src/gym-system.Infrastructures/SqlTicketPassRepository.cs` 的 CancelQueuedRenewalAsync、來源查詢與鎖定。
- `src/gym-system.Application/TicketsUseCase/Commands/CancelQueuedRenewal/CancelQueuedRenewalHandler.cs`
- `src/gym-system.Application/TicketPlansUseCase/Queries/RenewalTicketPassEligibilityService.cs`
- `src/gym-system.Infrastructures/Queries/TicketPasses/DapperStudentTicketPassQueryService.cs` 的 CanCancel。
- `src/gym-system.Api/Controllers/TicketPassesController.cs` 及記憶體替身。

執行步驟：

1. 定義共用「尚未使用」判定，讓 Domain、取消 API 與 CanCancel 輸出一致。
2. 維持只允許 `UnActive` 續約票取消；已結束票券不能重複取消。SQL UPDATE 的原狀態條件維持 `UnActive`。
3. 保留來源連結與取消紀錄；取消、核銷、reconcile、快照更新需採一致鎖定／交易策略，避免取消與使用同時成功。
4. 取消後來源查詢應排除這張 Cancelled pass，回到仍符合資格的原來源；重訂 C 仍承接 A，不能改接已取消的 B。
5. 原續約上限 `sourceEffectiveEndDate.AddDays(9)` 保留。取消重訂上限改成兩日期取最小；更新 `RENEWAL_RETRY_EXPIRED` 的當天限定訊息。
6. 保留目前以最近一次已取消 successor 的時間判斷重試的實作方向；反覆重訂不能改變來源原截止日。最近一次取消的選取屬沿用現況，需以測試固定，不得隱含改成首次取消或付款日期。
7. 保留既有取消重訂的 queue 例外方向；一般續約 queue 則配合 P4 排除單堂票。資格放行不代表可以搶占已 Active 的非單堂票。
8. 保持已取消來源不可續約、最新來源不 fallback、每來源最多一張非取消 successor 等既有約束。
9. 內部 `CancelQueuedRenewal` 命名可評估改為涵蓋 Active 的名稱；不是必須改對外 cancel URL。

### 使用紀錄規格保留

本次不開放 Active 續約票取消，因此不以使用紀錄放寬取消條件。但以下商業規格先保留，供未來擴充 Active 取消時使用：

- 堂票：剩餘堂數等於總堂數是現有條件；若有扣堂再沖銷，不能只靠餘額推論從未使用。
- 月票：若未來開放 Active 取消，沒有進場／核銷紀錄才可視為尚未使用；效期仍依 Active 時間照常計算。
- `doc/Database.md` 有 `sdt_ticket_usage_log` 與 Consume／Reverse 的描述，但文件存在不代表資料表與寫入流程已完整實作。
- 曾使用後沖銷是否重新算「尚未使用」，本次未定義特殊例外，實作不得自行視為恢復取消資格。
- 若未來要開放 Active 取消，需先補齊記錄／查詢能力；不能僅放寬 Active 狀態條件就宣稱完成。

資料影響：期限可由現有來源日期與取消時間推算，不必先新增截止日欄位。本次不因取消條件調整而新增 usage schema。取消 pass 不等於授權退款或更改付款紀錄，本次不新增財務流程。

## P4：單堂票讓位與 queue

主要修改位置：`TicketPass.cs`、`ITicketPassRepository.cs`、`SqlTicketPassRepository.cs`、`DependencyInjection.cs` 的記憶體 reconcile，以及各呼叫 reconcile 更新會員快照的流程。

核心原則：續約資格看來源票與重訂期限；單堂票只影響啟用順序，不應阻擋續約購買。

建議流程：

1. 鎖定會員並處理目前票券過期／用完，維持全域最多一張 Active。
2. 若目前是未用完單堂票，先找出「今天確實可啟用」的非單堂票；沒有候選時維持單堂票 Active。
3. 有候選時，在同一交易將單堂票 Active → UnActive，再啟用該候選，不寫結束原因、不清空或補滿堂數、不改原 paidAt／passSn。
4. 若沒有 Active，先選可啟用非單堂票；沒有才選單堂票。單堂票使用 `ticket_plan_kind_code == SINGLE` 識別，不把全部 PACK 當單堂票。
5. 非單堂候選維持：剛結束來源的直接續約、其他可啟用續約、一般票，再依 paidAt／passSn 排序。
6. 已過期或開始日在未來的候選不能卡住後面的可用票；續約開始日仍依既有承接排程計算。
7. 修改一般續約 queue 衝突查詢，排除 SINGLE；仍須攔截其他原本構成衝突的非單堂排隊票。
8. 取消 UnActive 續約票後若會員後續重訂續約成功，Active 單堂票仍不得阻擋該續約票在可啟用日讓位啟用。
9. 快照、票券清單、SQL／記憶體實作同步更新。不要只改 queue ORDER BY 而漏掉已 Active 單堂票的讓位。

Domain 建議增加限定單堂票的讓位操作，保留既有一般 Activate 的前置條件；不要讓其他票券可任意回到 UnActive。重複 reconcile 應穩定，不發生不必要的來回切換。

資料影響：沿用 UnActive，無須新增 enum。查核唯一 Active 的 DB 約束是否存在；若有，在同一交易先讓位再啟用，避免中間狀態違反約束。

## P5：前端日期與購買紀錄 timestamp

主要修改位置：

- `src/gym-system.Api/Controllers/StudentTicketPassesController.cs`
- `src/gym-system.Api/Contracts/TicketPasses/*`
- `gym-system-frontend/infrastructure/api/ticketPassesApi.ts`
- `gym-system-frontend/infrastructure/time/taipeiDate.ts`
- 票券紀錄、會員詳情、報表相關顯示元件。

建議流程：

1. 後端票券購買紀錄保留既有 `PaidAt` 日期字串，新增 `PaidAtTimestamp` 到秒 timestamp；建議格式為 `yyyy-MM-ddTHH:mm:ss+08:00` 或等價可明確表示台灣時間的格式。
2. `ValidStartDate`／`ValidEndDate` 若仍是業務日曆日，可維持 `yyyy-MM-dd`；不要和 timestamp 欄位混用。
3. 前端票券購買紀錄顯示 timestamp 時，固定使用台灣時區格式化。
4. 前端不得用 `toISOString().split('T')[0]` 推導台灣日曆日；目前已知報表、dashboard、課表有類似用法，票券購買紀錄優先，其餘可後續分批整理。
5. 前端不自行判斷可購買資格；購買按鈕與清單以後端 API 結果為準。

優先級：不阻擋後端 eligibility 與續約邏輯實作，可排在後續前端對齊階段。

## P6：目錄防線、驗證與文件回填

- [ ] HIDDEN 清單過濾、直接購買拒絕、UnPaid 付款重驗一致。
- [ ] FAMILY_ELIGIBLE 保留且不套用；多受益者仍拒絕。
- [ ] 以併發測試確認同一來源非取消 successor 的 filtered unique index 會被正確轉換成 `RENEWAL_SOURCE_ALREADY_USED`。
- [ ] 執行 P1～P4 單元與 SQL 整合測試，尤其使用／取消、兩筆重訂、單堂讓位與付款的併發。
- [ ] 實作時同步回填上層正式規格，完成後在 issue 記錄測試證據與狀態。
- [ ] 舊計畫先保留；另行確認完成轉移後才處理封存或刪除。

建議順序為 P0 → P1 → P2 → P3／P4 → P5 → P6。P3 與 P4 在取消重訂後續約啟用、單堂票讓位的案例相依，整合驗收必須一起通過；P5 可後排，但 ticket pass API 欄位格式變更要和前端同步。
