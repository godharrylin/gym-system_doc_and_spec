# 第四階段：額度占用資料與交易設計

更新日期：2026-10-17。狀態：出席 ALTER、兩張工作表與占用表均已部署。使用者已確認預參加後的改課／取消處理，已接入排課交易；進出場／A 仍在編寫與驗證。最新 SQL 測試清理查到 4 筆 B 工作殘留，依協作規則暫停相關實作並詢問使用者。最新證據與完成範圍見 [實作狀態](current/implementation-status.md)。

依據：[階段規則](impelment_rule.md)、[Database.md](../../../Database.md)、[SQL 草稿](sql/01-create-credit-reservation.sql)。不設外鍵、不使用 rowversion。

## 資料責任

- `sdt_att_record`：學生對某一實際場次的參加／出席事實與資格；Pending 不等於已取得正式出席。
- `sdt_ticket_credit_reservation`：一筆代表一次對一張堂票的 1 堂額度占用。月票不建立堂數占用。
- `class_processing_job`／`class_processing_item`：場次 A／B 及逐學生處理進度，不代表額度本身。
- `device_record`：開門請求與成功進出事件；Requested／Unknown 不直接代表已入館。
- `sdt_ticket_usage_log`：B 正式扣堂的核銷依據。本次占用表不取代第五階段的核銷防重 migration。

同一出席可以有多筆歷史占用，但同時最多一筆 Reserved／Fixed／NeedsReview。Released、Consumed 不再扣減可用額度；Consumed 的堂數已從票券剩餘堂數扣除，不能再減一次。同一出席已結算後不得因更換冪等鍵再次占用，應在交易內核對出席、既有 Consumed／核銷及更正案件。

## 欄位與儲存格式

| 欄位 | SQL Server 型別 | 可 NULL | 用途 |
| --- | --- | --- | --- |
| `reservation_sn` | `bigint IDENTITY(1,1)` | 否 | 占用主鍵 |
| `attendance_sn` | `int` | 否 | 邏輯對應 sdt_att_record_sn；先建立／取得同學生同場次的 Pending 或正式出席 |
| `pass_sn` | `int` | 否 | 被占用的 sdt_ticket_pass.pass_sn；已建立占用不得直接改此欄位 |
| `reserved_credits` | `int` | 否 | 第一版固定 1，一場一堂；不是票券總堂數 |
| `reservation_state` | `varchar(20)` | 否 | Reserved／Fixed／Released／Consumed／NeedsReview |
| `review_from_state` | `varchar(20)` | 是 | NeedsReview 時必填 Reserved 或 Fixed，保存待確認前的階段；離開待確認狀態時清空 |
| `idempotency_key` | `varchar(160)` | 否 | 穩定 ASCII 操作鍵，不得空白；相同操作重試沿用，換機／網路重試不能任意換鍵 |
| `gate_request_id` | `uniqueidentifier` | 是 | 最初建立占用的進場請求 request_id；不因後續回場覆寫來源 |
| `processing_item_sn` | `bigint` | 是 | A 建立或移轉占用時的來源工作明細；兩個來源欄位至少一個有值 |
| `previous_reservation_sn` | `bigint` | 是 | 換票或重新占用所接續的已釋放占用；保留歷史鏈，不作可用額度依據 |
| `usage_sn` | `int` | 是 | Consumed 時關聯正式核銷 usage_sn；其餘狀態必為 NULL |
| `created_at` | `datetime2(3)` | 否 | 本次占用真正建立時間 |
| `fixed_at` | `datetime2(3)` | 是 | A 實際固定占用時間；原出席截止另取工作 scheduled_at，不把補跑時間偽裝成截止時間 |
| `released_at` | `datetime2(3)` | 是 | 實際釋放時間，只在 Released 有值 |
| `consumed_at` | `datetime2(3)` | 是 | 實際結算時間，只在 Consumed 有值；票券業務 ended_at 另依課程結束時間 |
| `updated_at` | `datetime2(3)` | 否 | 最近實際異動時間 |
| `reason_code` | `varchar(60)` | 是 | Released／NeedsReview 必填原因代碼 |
| `reason_message` | `nvarchar(1000)` | 是 | Released／NeedsReview 必填原因；不放憑證、電話、完整 exception |

所有時間由後端 IClock 寫入台灣本地時間，例如 `2026-10-17 19:10:00.125`，不使用 GETDATE／SYSDATETIME 預設值推測時區。pass_sn、attendance_sn、usage_sn 及 processing_item_sn 型別依目前查核資料設計，部署前仍須唯讀重驗；沒有外鍵不代表可以不驗證關聯。

## 狀態轉換

### 2026-10-17：CHECK 改由程式驗證

占用表的 10 個 CHECK 已從 SQL 草稿及 Database.md 的 CREATE 移除；主鍵、3 個唯一防線、一般索引與 NOT NULL 保留。這不是全資料庫移除 CHECK，其他表的規則不在本次範圍，也未對 GymDB 執行任何 ALTER。

集中入口為 Domain 的 `CreditReservationData.Validate()`：建立及每次狀態轉換驗證完整快照，`CreditReservation.Rehydrate()` 讀取持久化資料時再次驗證。下表對應原本移除的約束：

| 原 CHECK 尾碼 | 程式檢查 |
| --- | --- |
| quantity | ReservedCredits 必須為 1 |
| state | State 必須是已定義 enum，不允許任意數字或未知字串預設放行 |
| key | 冪等鍵必填、ASCII、最長 160 |
| source | 至少一個有效 GateRequestId／ProcessingItemSn |
| previous | PreviousReservationSn 為正數且不等於已分配的 ReservationSn |
| review | NeedsReview 的原階段限 Reserved／Fixed；其他狀態原階段為 NULL |
| fixed | Fixed／Consumed 或原 Fixed 的待確認須有 FixedAt；Reserved／原 Reserved 的待確認不能有 FixedAt |
| release | 只有 Released 有 ReleasedAt，且不可缺少 |
| consume | 只有 Consumed 有 ConsumedAt 與正整數 UsageSn，且兩者必填 |
| reason | Released／NeedsReview 的原因代碼及說明必填，分別最長 60／1000 |

新占用主鍵由 DB 分配，Repository 取得 ID 後須於同一交易提交前再次驗證，避免前一筆 ID 自指；未來 SQL 讀取須嚴格解析 enum，再重建物件。所有批次／匯入也應使用相同入口。這些檢查不會自動攔下直接 SQL，程式未發現錯誤時 rollback 不會自行發生。

已新增 SqlCreditReservationRepository，所有操作要求呼叫端持有交易，INSERT／UPDATE 前核對快照及來源關聯；資料讀取使用嚴格 enum 解析及 Rehydrate，INSERT 取得 ID 後再次檢查自指。更新時先鎖定並比對完整原快照，再允許合法狀態轉換；回傳 SQL 實際存入的 datetime2(3) 精度。CreditReservationService 先使用既有 LockOwnerAsync，再鎖票券、驗證出席歸屬／額度及冪等；這些步驟尚未串入 GatePassageService 或 A，不代表已完成進場授權。

### 允許的狀態變更

| 原狀態 | 目標狀態 | 條件與交易效果 |
| --- | --- | --- |
| 尚無占用 | Reserved | 進場前通過場次、票券及可用額度驗證；與 Pending／進場請求建立同一交易提交 |
| Reserved | Fixed | A 依原截止歷史確認在館內及資格；固定該堂票券，填 fixed_at |
| Reserved | Released | 截止前成功離場、明確開門失敗、派送前撤銷，或 A 換票；保留舊資料及原因 |
| Fixed | Consumed | B 正式扣 1 堂、寫核銷、必要生命週期／profile 與工作完成同一交易提交 |
| Reserved／Fixed | NeedsReview | 開門結果不明、事件／固定票券依據衝突；保存 review_from_state，繼續占用 1 堂 |
| NeedsReview | 原階段或 Released | 人工重驗／明確結果對帳後恢復；不得直接宣告結算成功。恢復原階段後仍按正常 A／B 流程處理 |

Released／Consumed 為這筆占用的終止狀態，不改回 Reserved。正常 Fixed 不因中途離場釋放；已固定的人工撤銷出席走第六階段更正交易，不由一般出場路徑直接釋放。已 Consumed 的沖銷保留原占用及核銷，另新增 Reverse，不回寫成「從未扣堂」。

## 冪等與離場後返回

- 進場建立鍵：`GATE:{requestId:N}:{attendanceSn}:{passSn}`。
- A 建立／換票鍵：`A:{processingItemSn}:{passSn}`。同一固定處理不得反覆在不同票券間試扣；歷史或資料衝突轉待確認。
- 同鍵重送先核對出席、票券、數量及來源相同，再回傳已有結果；唯一鍵衝突不是新的成功授權。若該占用已 Released，重送舊請求不能復活它或再次開門。
- 成功離場釋放後的新一次合法返回，使用新的 gate requestId，在同一筆出席下新增占用；舊占用保持 Released，previous_reservation_sn 記錄前一筆。沒有新的進場操作就不換鍵。
- 已 Fixed 的同堂回場重用既有出席及固定占用，不另建占用；月票回場以有效出席與期限驗證。
- 換票在同一交易內釋放舊占用、驗證新票、建立新占用並同步出席票券。任一步失敗整筆 rollback，舊占用不得消失。兩張票按 pass_sn 排序鎖定。

## 可用堂數與鎖定

`可新增占用額度 = credits_remaining - SUM(Reserved／Fixed／NeedsReview 的 reserved_credits)`。

計算前先取得同學生 profile 與相關票券的交易鎖，再在同一 SQL session／transaction 讀取最新剩餘堂數與有效占用；其他新增占用、扣堂及人工調整寫入路徑必須遵守相同序列。不得從列表快照計算或讀完後離開交易才 INSERT。同一出席已有有效占用時先重用／處理既有項目，不能再次減掉自己的 1 堂後誤判額度不足。

B 的扣剩餘堂數與 Fixed → Consumed 同一交易；更新票券必須帶資格、剩餘額度及固定依據條件並檢查影響筆數，不能把先前 C# 讀到的數字無條件寫回。人工改動衝突轉待確認，不扣負數、不換票；如何分辨合法前序扣堂與人工調整須與第五階段核銷／異動紀錄一起實作，單靠本表不宣稱已能辨識全部變更。

鎖順序沿用 Database.md：背景工作執行權（若有）／相關場次 → 學生 profile → pass_sn 排序的票券 → 出席、占用、核銷及處理項目。單筆學生失敗只 rollback 該筆，不能回滾其他已提交學生。狀態沒有變化時不做無效 UPDATE。

## 開門前後兩段短交易

1. 開門前短交易：確認裝置／時段及學生資格，建立或重用出席，建立必要暫占與 Requested；提交後才呼叫三叉機。不持有 DB 交易等待 HTTP。
2. 成功回應：以後端收到成功的時間保存實際進出事件，更新該次操作所需資料；不把 Requested 直接當在館內。非實體模擬不得建立實際出席資格。
3. 明確未開門：在另一交易釋放「本次新建」暫占並保存結果；同堂回場本來就有的 Fixed 不釋放。裝置忙碌、授權撤銷且未派送也需完成此清理。
4. 結果不明或成功後寫入失敗：不能 rollback 硬體，也不能直接重送；保留占用與未確認請求，轉待確認／對帳。不能對「成功已送回但落庫失敗」寫成明確開門失敗。
5. 截止後才成功：保存真實進場事件，不追認截止前出席；該次占用轉待確認，不能因此自動扣堂或授予同堂回場。
6. A 封存與進出結果提交需使用共同的場次／學生協調鎖；先保存 Requested 才派送。截止時仍有 Requested／Unknown 或無法排序的同時事件，就保留該學生待確認，不靠「再等幾秒」推定出席。A 之後到達的結果必須檢查封存／待確認狀態，不能覆蓋已完成結果。跨程序及事件時戳的實際協調實作須以並行測試證明。

## 後續實作與驗證

1. 占用表 SQL 已依先供檢視再執行要求部署。既有 sdt_att_record ALTER 與工作表另由獨立腳本部署，不把占用表 CREATE 當成完整第四階段功能。
2. 實作占用 Repository／應用服務、進出場銜接與 A，統一 ClassAttendanceProcessing 目錄；B 正式扣堂歸第五階段，不能假建已結算結果解除相鄰堂依賴。
3. 測同請求重送、同出席兩個不同請求、最後 1 堂並行占用、離場再回來、原占用已 Released 的重送、換票中途失敗 rollback、NeedsReview 保留容量、Fixed 回場不重占。
4. 測月票零占用、截止整點、成功回應與 DB 提交交錯、Unknown／同時事件待確認、A 重跑與重啟補跑、相鄰堂前置未完成只暫停該學生。
5. 已新增 Domain `ClassAttendanceProcessing/CreditReservation.cs`、`CreditReservationData.cs` 與 `CreditReservationTests`。限定此測試類別的 dotnet test 通過 41／41、exit code 0、耗時 10.06 秒，測試所需編譯未辨識到 warning／error；包含原 10 個 CHECK 的非法快照與各狀態重建。非全專案獨立 build 或全部測試，也非 SQL 並行／硬體驗收。完整日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-b7e96izj\test.log`。靜態核對已確認 SQL 與 Database.md 定義一致，占用表沒有 CHECK，保留 1 個 PK 與 3 個唯一防線。
6. 第一批 Repository／服務的 61／61 單元測試與後續 9／9 真正 SQL 測試均通過（最新紀錄見 current 狀態檔）；上列 41／41 是集中驗證批次的紀錄。尚未完成進出場／A／Worker 串接或硬體驗收。
7. 2026-10-17 已套用 [既有出席 ALTER](sql/02-align-attendance.sql)、[工作表 SQL](../05-課程結算與背景工作/sql/01-create-class-processing.sql) 及後續 [占用表 SQL](sql/01-create-credit-reservation.sql)，均已提交並查核。出席原為空表，沒有刪除或猜測回填；SQL 測試建立的資料已按擁有者核對清理。
8. 預參加後的改課／取消已由使用者確認：取消釋放暫占並取消 Pending，改時間保留且跟隨新截止；原事件保留。IScheduleAttendanceSynchronizer 已接入兩個 handler，同交易處理，固定占用異常會拒絕直接釋放。
9. 改課 SQL 測試的清理程式只追蹤 A，漏掉自動建立 B，最新查到 job_sn 12、20、29、37 四筆測試殘留；未自行刪除，已暫停。這是測試清理缺陷，不改成正式流程刪除 B 歷史。
