# 後續調整與驗收規劃

整理日期：2026-09-07。

狀態：2026-09-09 A07／A08 決策已確認：保留註冊台灣時間寫入、未知舊資料不整批校正，GymDB 可作開發測試。已完成時間測試修正及首批真實 SQL／索引／併發驗證；Application 104、API 專案 43、前端時間測試 5 個通過。A09 已更新本批證據與缺口，完整驗收及後排頁面整理尚未全部完成。各項「查核發現」保留為修正前基線，不是最新程式行為。

## 依據與目前進度

- 業務規則以 [01-confirmed-decisions.md](01-confirmed-decisions.md) 為準。
- 本文件補充 [02-implementation-plan.md](02-implementation-plan.md) 的剩餘工作，不取代原計畫。
- 驗收案例與測試安排分別沿用 [03-acceptance-tests.md](03-acceptance-tests.md)、[04-test-implementation-plan.md](04-test-implementation-plan.md)。
- 主要業務邏輯已有修改，但規則分類、註冊驗證、排隊一致性、資料查核、測試與文件回填尚未全部完成。
- 修正前查核基線：Application 84 個通過；選取的 Controller 5 個通過，當時未執行 DB 整合測試。最新數量與範圍見本文件「最新驗證紀錄」。

## 建議執行順序與待辦

以下程式路徑相對於 backend 根目錄；前端路徑另標示。所有項目應分別記錄實作與驗證結果，不以文件更新或測試編譯通過代替驗收。

### A01：規則集中分類

- [x] 讓 catalog 實際使用 `TicketPlanRulePolicy` 的分類能力。
- [x] 同步整理 `Tags`、`EligibilityRuleCodes` 輸出與停用限制規則的查詢防線，避免程式分類與 SQL 各自維護不同規則。
- [x] 保留 HIDDEN 目錄隱藏、FAMILY_ELIGIBLE 暫停、未知資格規則缺 handler 時拒絕的行為。

本批結果：catalog 從啟用的原始 rule codes 建立 Tags，再透過 `BuildEligibilityRuleCodes()` 輸出資格規則；SQL 隱藏／停用防線使用同一 policy 提供的參數集合。真實 SQL 測試發現 `string[]` 被既有 JSON type handler 攔截，已改以 `List<string>` 傳入 Dapper IN 參數，保留 Tags handler。分類、未知規則、停用關聯／全域規則及 HIDDEN／FAMILY SQL 回歸通過，不修改 DB schema。

查核發現：`BuildEligibilityRuleCodes()` 已建立，但未被呼叫；catalog SQL 仍自行硬編碼 HIDDEN／FAMILY_ELIGIBLE 排除條件。

主要位置：

- `src/gym-system.Application/TicketPlansUseCase/Queries/TicketPlanRulePolicy.cs`
- `src/gym-system.Infrastructures/Queries/TicketPlans/DapperTicketPlanCatalogQueryService.cs`

驗收重點：分類變更、新增未知規則、規則或關聯停用時，不會漏掉真正的購買限制。對應 E05、E06 及目錄與保留功能案例。

### A02：註冊共用完整資格驗證

- [x] 註冊情境先檢查規則是否支援 Registration，再檢查 handler 並執行規則條件。
- [x] 缺 handler、規則不適用或任一條件未通過均拒絕。
- [x] NEW_ONLY／RENEWAL 維持不開放註冊；無資格限制的一般方案仍可通過。

本批結果：`ITicketPlanEligibilityRule.SupportsRegistration` 預設 false；註冊與會員共用 handler 驗證迴圈。新增測試驗證明確支援註冊但條件不符、規則不適用、未知 handler、複合規則及既有會員條件不符的拒絕行為。NEW_ONLY／RENEWAL 沿用預設不開放。

查核發現：目前 Registration 分支只回傳 `SupportsRegistration` 的結果，沒有繼續執行 handler。現有規則全不支援註冊，因此目前排除行為有效，但未完成計畫要求的共用驗證流程。

主要位置：`src/gym-system.Application/TicketPlansUseCase/Queries/TicketPlanEligibilityService.cs` 及相關 policy／rule 介面。

驗收重點：使用測試規則驗證「支援註冊但條件不通過」仍拒絕；新增規則不必修改 controller。對應 E01～E05、E07、E11。

### A03：註冊未付款訂單的情境判定

- [x] 查核目前 model／repository 是否保存註冊來源（目前沒有；新決策不需增加）。
- [x] 釐清歷史訂單、建單後方案規則變更時，付款應採用的情境。
- [x] 依確認結論補齊後續付款判定與測試，歷史訂單情境不得由前端任意指定。

已完成部分：新註冊直接提交不開放的 SKU，即使要求 UnPaid，也會在建單前進行 Registration 驗證。

確認結果：後續付款一律建立 ExistingMember Context，訂單不需要保存註冊來源。付款時重驗最新規則；未付款不建立票券，付款成功才建立 pass 並依 queue／Active slot 啟用。

主要位置：

- `src/gym-system.Application/MembersUseCase/Commands/RegisterMember/RegisterMemberHandler.cs`
- `src/gym-system.Application/OrdersUseCase/Services/TicketPurchaseService.cs`
- `src/gym-system.Application/OrdersUseCase/Services/UnpaidTicketOrderPaymentService.cs`
- 訂單 model 與 repository。

使用者已確認延後付款視為既有會員，2026-09-09 回填：歷史未付款訂單採相同規則，不新增來源欄位。已補 `DelayedPayment_ShouldUseExistingMemberRulesAndIssuePassOnlyAfterPayment`、`DelayedPayment_ShouldRejectExpiredOrConsumedNewOnlyEligibility`。另以 `RegisterUnpaidThenPay_ShouldUseCurrentMemberRulesAndPaidDate` 完成真實 SQL 註冊後延後付款；其他 SQL 拒絕與併發變體仍屬 A08。

### A04：記憶體版排隊與 SQL 對齊

- [x] 記錄本次 reconcile 剛結束的來源票編號，傳入候選選取流程。
- [x] 保留直接續約、其他可啟用續約、一般票、單堂票的優先順序及同順位 FIFO。
- [ ] 對照 SQL 版驗證過期候選、未來候選、單堂讓位、再次啟用與快照結果。

本批結果：實際 InMemoryTicketPassRepository（透過 DI 取得）已測剛結束來源優先、單堂讓位保留堂數／日期／付款時間、原 FIFO 恢復、跨家族排隊、未來候選跳過、過期候選與其 successor。SQL 已驗證前述剛結束來源優先、讓位／恢復、跨家族及未來候選；過期候選與其 successor 的 SQL 對照仍未完成。

查核發現：記憶體版呼叫候選選取時固定傳 `justEndedPassSn: null`，導致剛結束來源的直接續約優先分支無法生效。

主要位置：`src/gym-system.Infrastructures/DependencyInjection.cs` 的 `InMemoryTicketPassRepository`。

驗收重點：同時有其他較早付款續約票時，剛結束來源的直接續約仍優先；SQL 與記憶體版結果一致。對應 S03～S05、S09、S11。

### A05：SQL 候選查詢不漏掉後方可用票

- [x] 修正只讀前 100 張候選就停止的流程；可採持續查詢後續批次或等價方式。
- [x] 開始日在未來的候選不能擋住後面的可啟用票券。
- [x] 保持既有優先順序、交易鎖與全域最多一張 Active。

本批結果：移除 SQL 的 TOP (100)，取得該會員全部符合查詢條件的候選，沿用原排序與鎖定。S05b 已以 GymDB 真實 SQL 驗證前 100 張未來續約不阻擋後方可啟用票；大量資料效能尚未驗證。

查核發現：`SELECT TOP (100)` 取得的候選若全部尚未到啟用日，程式直接回傳 null，沒有繼續查後面的候選。

主要位置：`src/gym-system.Infrastructures/SqlTicketPassRepository.cs` 的 `FindNextActivatablePassAsync()`。

驗收重點：前 100 張候選無法啟用、後方仍有可用一般票或單堂票時，應找到並啟用合格票券。對應 S04、S05、S09。

### A06：統一單堂票識別

- [x] 依原計畫統一以 SKU `SINGLE` 識別單堂票。
- [x] Domain、SQL、記憶體版、啟用、讓位與 queue 衝突檢查使用一致語意。
- [x] 查核現有 SINGLE 方案設定：GymDB 為 PACK／family SINGLE、1 堂、無效期；程式仍只以 SKU SINGLE 識別。

本批結果：移除 FamilyCode == SINGLE 的特殊判斷；記憶體種子單堂 SKU 由 T_001 對齊為 SINGLE，文件 SQL seed 原本已為 SINGLE。已測 SKU 非 SINGLE、family 為 SINGLE 時仍構成 queue 衝突並拒絕讓位。GymDB SINGLE 設定已唯讀查核，不變更既有方案。

查核發現：部分程式採 SKU 或 FamilyCode 為 SINGLE，Domain 的 `Activate()` 則只看 SKU。

主要位置：`TicketPass.cs`、`SqlTicketPassRepository.cs`、`DependencyInjection.cs`。

驗收重點：真正 SINGLE 保持無有效日期且不阻擋續約；非 SINGLE 方案不因家族名稱而套用單堂讓位及無效期邏輯。對應 S01、S02、S06。

### A07：時區處理與資料查核

- [x] 查核現行註冊與 repository 寫入語意；舊資料無來源證據時不整批調整，已由使用者確認。
- [x] 修正 SQL 角色測試直接使用 UTC 的寫入，改用固定台灣 clock；規範未來匯入／批次在輸入邊界轉換。
- [x] 補上明確 UTC 來源先轉台灣時間、台灣來源不重複轉換、SQL 往返與跨午夜第 30／31 天測試。

已完成部分：現行註冊透過 Taipei clock 寫入角色時間，NEW_ONLY 使用日曆日與 `AddDays(-29)`。

本批結論：NEW_ONLY 直接對已採台灣時間契約的 AssignedAt 取 DateOnly，維持現行註冊與讀取流程。匯入轉換放在輸入邊界，不由資格服務猜時區；本次沒有新增尚不存在的匯入 API。既有資料仍沒有全數來源證據，因此不做校正，也不視為歷史資料已全部確認。

主要位置：`NewOnlyTicketPlanEligibilityRule.cs`、`SqlUserRoleRepository.cs`、Taipei clock 及實際匯入路徑。

前置條件：未知來源須先取得證據，不可假設所有資料都是 UTC，也不可全表加 8 小時。依資料來源決定轉換應放在匯入邊界或其他適當位置。對應 N03、N05、N06。

2026-09-09 查核：註冊使用 TaipeiClock；SqlUserRoleRepository 將 AssignedAt 寫入、讀出 user_role_cdt；GymDB 及 `doc/Database.md` 定義 DATETIME2(0)，default 為 SYSDATETIME()。欄位無時區資訊，default 依 DB 主機時間，不能證明全部歷史資料正確。使用者已確認「保留現行流程、修測試、不整批加 8 小時」，本項不再等待隔離 DB 或猜測來源。未來批次須明確供應台灣時間，不依賴主機 default。

### A08：補齊驗收測試與執行證據

- [ ] 將每個驗收案例對應至具體測試或明確追蹤的技術缺口。
- [x] 補規則分類、註冊附帶購買與 UnPaid 建單／付款重驗測試（實際 handler + SQL，非完整 HTTP）。
- [x] 補原截止日當天取消、隔天重訂、反覆重訂與最新來源不 fallback 測試。
- [ ] 補取消 API／canCancel 一致性、單堂讓位／恢復／FIFO／快照的完整流程測試。
- [x] 補實際 SQL 的 pass 歷史、catalog、來源查詢、排隊與狀態更新測試；變體缺口仍列於下方。
- [ ] 補兩筆續約競爭同來源，以及付款／取消／讓位等併發測試，確認 unique index 與錯誤轉換。
- [x] 補 HIDDEN catalog／購買／付款攔截及 FAMILY_ELIGIBLE 暫停測試；清單完整 HTTP 流程仍待驗證。
- [x] 補 paidAtTimestamp DTO、前端 mapping 與台灣時間顯示測試；尚非瀏覽器 UI E2E。
- [x] 記錄測試命令、通過範圍、GymDB 開發資料庫專屬資料清理方式及未涵蓋項目。

此項依 [04-test-implementation-plan.md](04-test-implementation-plan.md) 執行，測試應隨對應修正一起補上，最後再整合驗收。現有單元測試通過不等於 SQL 或併發已驗證；目前有些所需測試尚未建立，並非僅待執行。

### A09：正式規格與完成狀態回填

- [ ] 更新原實作計畫中仍描述修改前程式的段落，區分基線、目標與實際完成狀態。
- [ ] 回填 catalog 集中分類、註冊 Context、paidAtTimestamp 與取消條件等正式規格。
- [ ] 對齊 queue 衝突的文字範圍：目前 SQL 查會員全部家族的非單堂排隊票，部分正式規格誤寫成僅同家族。沿用原 queue 限制的決策，不藉文件整理擅改購買範圍。
- [ ] 在 `issue/` 記錄已修正、待查核、延後項目與驗收證據。
- [ ] 舊計畫保留，未完成轉移與另行確認前不刪除。

主要文件：本目錄、`../ticket-plan-catalog-spec.md`、`../ticket-purchase-ui-api-spec.md`、`../ticket-purchasability-spec.md`、`../ticket-lifecycle-spec.md`、`../ticket-purchase-technical-design.md` 及 `../issue/`。

## 後排項目：其他前端頁面的台灣日曆日期

- [ ] 分批整理 Dashboard、Reports、課表等頁面的 `toISOString().split('T')[0]`，改用符合台灣日曆語意的日期處理。
- [ ] 依欄位用途區分業務日曆日與真實時間點，不全面替換合法的 timestamp 輸出。

會員詳情的票券購買紀錄已接上 paidAtTimestamp；其他頁面依先前同意列為後排，不阻擋後端核心修正。

## 範圍與收尾條件

- Active 續約票取消不在本次範圍，保持僅 UnActive 續約可取消。
- usage log 查核與擴充保留給未來使用紀錄能力；不因此開放 Active 取消。
- 本次不新增家庭購買、HIDDEN 內部購買、退款或 order_audit_logs 資格判斷。
- A03 與 A07 決策已取得結論；不把「未知歷史資料不校正」誤標成全部歷史資料已查核。
- 完成修正後，須同時具備程式差異、對應測試結果與文件狀態；未驗證項目不得標成全部完成。

## 最新驗證紀錄（2026-09-09，GymDB 與時間政策）

以下命令相對於各專案根目錄；連線只設定於該次測試程序，不寫入設定檔：

```powershell
$env:TEST_DB_CONNECTION='Server=LAPTOP-GBB0UO0C;Database=GymDB;Integrated Security=True;TrustServerCertificate=True;Connect Timeout=5'
dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-restore --nologo -v minimal
dotnet test tests/gym-system.Application.Tests/gym-system.Application.Tests.csproj --no-restore --nologo -v minimal
# 以下在 frontend 執行
npm run test:ticket-time
npm run build
```

- Application：104 通過、0 失敗。
- API 專案完整回歸：43 通過、0 失敗、0 略過；其中 25 個使用真實 GymDB（`TicketPurchasabilitySqlTests` 15、註冊 4、角色 4、會員查詢 2）。其餘為 Controller／記憶體等測試，不等於 43 個 HTTP E2E。
- 前端 `tests/ticketPurchaseTime.test.mjs`：5 通過；使用現有 Vite 載入實際 TS 模組、mock fetch，不連外。涵蓋台灣跨午夜、秒數、不同主機時區、API mapping 與舊日期欄位相容性。
- 前端 build 成功；仍有既有 index.css 缺檔與 MockData 靜態／動態混合 import 警告，不屬於票券邏輯變更。
- GymDB 已確認 filtered unique index：`renewed_from_pass_sn IS NOT NULL AND valid_status <> N'Cancelled'`。已測直接重複 insert 轉成 `RenewalSourceAlreadyUsedException`，以及取消後可重用原來源。
- 同來源兩筆購買併發：僅一筆提交，另一筆回 `RENEWAL_SOURCE_ALREADY_USED`，沒有額外訂單。另測購買／取消／單堂讓位併發，全域一張 Active 且 profile 快照一致。這不是高負載／全部交錯順序的證明。
- 修正 xUnit v2 清理生命週期：測試類別使用 `IAsyncLifetime`，fixture 使用 `await using`。開發過程曾留下 30 筆本次測試會員，已依核對的精確 ID + marker 清理，未刪既有會員；隨後完整重跑並核對 marker 殘留為 0。IDENTITY 跳號保留、不 reseed。
- 沒有修改既有 `user_role_cdt`、schema、unique index 或共用 rule／SINGLE 設定。

### 案例追蹤與尚未涵蓋範圍

SQL 下列測試位於 `tests/gym-system.Api.Tests/TicketPurchasabilitySqlTests.cs`，註冊位於 `RegisterMemberSqlIntegrationTests.cs`；既有單元測試位於 Application.Tests。

| 驗收範圍 | 執行證據／尚待補齊 |
| --- | --- |
| N01～N06 | `TicketPlanEligibilityServiceTests` 30／31 天與 `TaiwanRoleTime_RoundTrip_ShouldRespectThirtiethCalendarDay` SQL 跨午夜／轉換；未證明全部歷史資料來源 |
| N07～N09、N11～N12 | `History_ShouldKeepEligibilityConsumedForEveryPassStatus` 驗證所有 pass 狀態、Cancel item、其他會員／SKU；人工取消無例外，不查 audit |
| N10 | 延後付款測試驗證 UnPaid 沒有 pass；尚未單獨 SQL 驗證 NEW_ONLY UnPaid 存在時的清單結果 |
| E01～E06 | Eligibility service／policy／Controller 測試與 `Catalog_ShouldUseSharedClassificationAndDisabledRuleGuards`；兩支清單完整 HTTP 尚待補 |
| E07、E11、E12 | 真實註冊 handler + SQL rollback／延後付款 ExistingMember 回歸 |
| E08～E10、E13 | 既有 eligibility／register／unpaid payment 單元測試；E13 等 SQL 拒絕分支尚未逐一覆蓋 |
| R01～R04 | `RenewalSource_ShouldSelectLatestAndUseDepletedEnd` + renewal 單元測試；SQL 排除狀態／未來／異家族變體尚待逐一補齊 |
| R05～R10 | renewal 單元測試及 `Cancellation_ShouldPreserveOriginalDeadlineAndPermitReplacement`、`CancellationRetry_ShouldEndAtNextTaiwanDayWithoutResettingGrace`；重訂期限以較早截止日為上限 |
| R11 | `DuplicateSuccessor_ShouldMapUniqueIndexViolationAndRollback`、`ConcurrentRenewalPurchases_ShouldCommitOnlyOneSuccessor` |
| R12 | 既有標準方案 eligibility 測試；與續約清單同時顯示的完整 HTTP 尚待補 |
| C01～C03、C06、C08 | 真實取消 handler、`TicketPassContract_ShouldPreserveSecondsAndMatchCancellationRules`、`CancellationReplacement_ShouldYieldSingleAndKeepOriginalSource`；尚未經取消 HTTP endpoint |
| C04～C05、C07 | 既有取消程式防線；耗堂、非續約、重複取消等 SQL／HTTP 拒絕變體仍待補，不以 Active 月票案例代表全部 |
| C09～C10 | 保留缺口：核銷／沖銷與取消的整合語意／併發尚未驗證；本次不新增 usage 能力、不開 Active 取消 |
| S01～S04、S06～S07、S10～S11 | 真實 SQL 單堂讓位／恢復／跨家族 FIFO + 既有 InMemoryTicketPassReconcileTests；部分情境變體僅記憶體測試 |
| S05、S05b、S09 | SQL 前 100 張未來候選與剛結束來源優先通過；已過期排隊候選及 successor 的 SQL 對照尚待補；大量資料效能未測 |
| S08 | `CancellationReplacement_ShouldYieldSingleAndKeepOriginalSource` 已測完整取消、單堂啟用、重訂讓位與來源保留 |
| S12 | `ConcurrentPurchaseAndCancellation_ShouldKeepOneActiveAndMatchingSnapshot`；不同未付款訂單競爭付款、更多交錯及 CI 重複穩定性尚待補 |
| HIDDEN／FAMILY、timestamp | `HiddenAndPausedFamily_ShouldRemainEnforcedAtPurchaseAndPayment`、DTO + 前端時間測試；瀏覽器畫面 E2E 尚未執行 |

仍需優先補上表的 SQL／HTTP 拒絕變體與付款併發，再完成 A04／A08／A09 全量收尾。其他頁面日期整理依原決定後排；不把本輪成功直接標成整份計畫已完成。

## 歷史驗證紀錄（2026-09-09，A03～A06；DB 確認前）

```powershell
dotnet test tests/gym-system.Application.Tests/gym-system.Application.Tests.csproj --no-restore --nologo -v minimal
dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-restore --nologo -v minimal --filter "FullyQualifiedName~InMemoryTicketPassReconcileTests|FullyQualifiedName~TicketPlansControllerTest"
```

- Application：104 個通過、0 失敗；較前批新增延後付款 3 個案例。
- 選取的 API 專案測試：13 個通過、0 失敗（10 個實際記憶體 repository 測試、3 個 Controller 測試）。這不是實際 HTTP／SQL 整合驗收。
- E12／E13 已對應延後付款測試；S01～S07、S09～S11 有本批記憶體測試覆蓋，非代表全部 SQL／情境變體已驗收。
- `TEST_DB_CONNECTION` 未設定；本批未執行實際 SQL、unique index、併發或前端測試。
- A09 已回填付款情境、queue 範圍、單堂 SKU、狀態 enum 與 UI/API timestamp；完整案例對照及其他 issue 收尾尚未完成。
- 待使用者提供舊時間資料來源，以及允許建立／清理測試資料的隔離 SQL 測試 DB，才能完成 A07／A08 相關驗收。

## 本批驗證紀錄（2026-09-07，A01／A02）

以下命令相對於 backend 根目錄：

```powershell
dotnet test tests/gym-system.Application.Tests/gym-system.Application.Tests.csproj --no-restore --nologo -v minimal
dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-restore --nologo -v minimal --filter "FullyQualifiedName~TicketPlansControllerTest"
git diff --check
```

- Application：101 個通過，0 失敗；本批新增 17 個測試案例。
- TicketPlansControllerTest：3 個通過，0 失敗。
- Git 差異空白檢查：無錯誤；存在工作目錄 LF／CRLF 提示。
- 本批未執行實際 SQL、併發及前端測試，A08 仍未完成。
