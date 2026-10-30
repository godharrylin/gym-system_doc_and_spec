# 第四階段實作狀態

更新日期：2026-10-23。**部分實作，尚未啟用學生課程進場，非第四階段完成／驗收。** 已拆分進場身分識別與基本驗票，實際 Gate 在課程／前置結算檢查前不再整理票券。指定範圍 153 個單元測試通過；使用者停止後端解除 DLL 鎖定後，34 個 SQL 測試亦通過，測後出席／工作／明細／占用四表均為 0。既有 JSON、schema 及功能啟用設定未變更，剩餘跨階段／驗證事項見下節。

2026-10-30 接續進度：GymDB 已套用人工館內更正及通用占用來源 migration；`source_type`／`source_key` 取代舊來源欄位，出席列新增簽到證據來源／流水號。跨日人工更正 2 個 SQL 案例通過，占用與出席整合類別 50／50 通過；測後占用、出席、人工更正均為 0 筆。學生詳細頁程式可查閱目前館內狀態及人工更正；API 未實際啟動，ClassProcessing 功能旗標與設備現場驗收未在本輪確認，不視為正式上線。

## 已完成的程式

2026-10-25 跨階段進度：第五階段已接入 B 核心及 A／B 工作順序，兩個核銷時間欄位已轉為 datetime2(3)，工作／核銷參數精度已修正，48 個 SQL 案例通過，含先上一堂 B 再下一堂 A 的留館接續。以下既有測試與待辦保留為歷史範圍；最新第五階段狀態見 [第五階段實作狀態](../../05-課程結算與背景工作/current/implementation-status.md)。不因本輪測試通過宣告第四階段所有現場驗收完成，ClassProcessing 仍未啟用。

- Domain `CreditReservation`／`CreditReservationData`：集中檢查原 10 個 CHECK；建立、狀態轉換與讀取重建均驗證。NeedsReview 保留原階段與容量，普通出場不能釋放 Fixed。
- `ICreditReservationRepository`／`SqlCreditReservationRepository`：要求呼叫端交易、鎖定讀取、完整原快照比對、合法轉態、來源與學生／票券／出席關聯檢查。INSERT 取得 ID 後檢查自指；不接受未知 enum 或無效持久化資料。
- Application `CreditReservationService`：沿用 LockOwnerAsync，重驗票券、出席歸屬、有效占用容量、同鍵重試、已消耗出席防重、返回的前一筆關聯；固定前重驗最新票券及額度。
- 已加入開課前排課異動同步：Update／Cancel handler 在原交易中同步 IScheduleAttendanceSynchronizer。改時間保留 Pending／占用並重算 A／B 時間；取消釋放暫占、取消預參加與未開始工作；固定占用不由此路徑釋放。相關 4 個 SQL 案例通過，先前測試清理缺陷已修正。
- 已加入 ClassAdmissionPolicy（一般進場／課間預入／同堂回場），相應 10 個單元案例通過。
- 後續已開始出席 Repository、ClassAdmissionService、A 確認服務、Coordinator／Worker 與 GatePassageService 串接；目前為編寫中版本，未完成全流程驗證。新進場流程受 ClassProcessing.Enabled 保護，預設 false，不可將已寫入程式當成已驗收。
- device_record 額外關聯欄位腳本 03 已於預覽後在交易內套用及驗證，五欄均可 NULL，舊事件無改寫／回填；正式功能仍預設停用。
- 占用／出席服務不自行 begin／commit／rollback，由 Gate／A 呼叫端統一控制交易，以確保出席、Requested、占用及工作狀態一起提交。已有實際 SQL rollback、並行占用與 lease 接手案例，但不等於完成跨程序故障及實際硬體驗收。
- 2026-10-23 新增 `IdentifyEntryAsync`：只讀取電話、啟用角色與 profile，不啟用票券、不開交易。具有課程進場服務的 Gate 改呼叫此方法，票券整理留到 ClassAdmissionService 的課程時段／前置結算檢查後；`CheckEntryAsync` 保留既有基本驗票用途，不作為此 Gate 路徑的前置啟用步驟。單元及所新增 SQL 順序回歸案例已通過；不等於完整硬體端到端驗收。

## SQL 預覽與資料庫狀態

1. [占用表建置](../sql/01-create-credit-reservation.sql)：已移除 10 個 CHECK，保留主鍵、3 個唯一防線及查詢索引。
2. [既有出席 ALTER](../sql/02-align-attendance.sql)：補資格狀態與建立時間、對齊必要型別／nullability 及唯一索引；有問題資料即停止，無自動刪除、回填或 UTC 加八小時。
3. [A／B 工作表建置](../../05-課程結算與背景工作/sql/01-create-class-processing.sql)：與 Database.md 定義對齊，補目標 DB、同名物件及交易檢查。這兩張表 CHECK 沿用原設計，不擴大移除範圍。

2026-10-17 使用者回覆「可以套用」後，已完成第 2、3 份腳本：先唯讀核對 schema／資料，再放入同一外層交易執行，驗證後一併 commit，另以新連線再次唯讀查核。

- 出席執行前後均為 0 筆；新增資格狀態／建立時間，對齊型別及 nullability，建立學生＋場次唯一索引與查詢索引。
- class_processing_job 為 20 欄、class_processing_item 為 15 欄，兩表目前均為 0 筆；唯一性及查詢索引已建立，各有 6 個 CHECK。
- 三張表均無外鍵或 rowversion；既有出席沒有新增 CHECK。
- 沒有刪除、回填、批次轉時區或建立測試資料。
- 第 1 份占用表腳本在當時兩份套用範圍之外；使用者接著要求繼續第四階段後，2026-10-17 已另行部署 sdt_ticket_credit_reservation。18 欄、1 個主鍵、3 個唯一防線，無 CHECK、FK 或 rowversion；另以新連線查核及 SQL 測試確認。

後續 migration 前仍須查核最新 schema；舊資料無時間依據時不自行決定回填。Repository 的實際 SQL／並行測試結果如下；A 已有程式及部分整合測試，但未完成整體驗收。

## 驗證結果

- `dotnet test tests/gym-system.Application.Tests/gym-system.Application.Tests.csproj --no-restore --filter FullyQualifiedName~CreditReservation`：61／61 通過，exit code 0，9.06 秒；41 個 Domain 與 20 個服務案例。未辨識到編譯 warning／error。
- 完整測試日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-jnedq2wb\test.log`。
- `dotnet build src/gym-system.Infrastructures/gym-system.Infrastructure.csproj --no-restore`：Repository／服務最後補強後編譯成功，exit code 0，5.97 秒，未辨識到 warning／error。
- 完整 build 日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-xi6q51ki\test.log`。
- `dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-restore --filter FullyQualifiedName~CreditReservationSqlTests`：9／9 實際 SQL 測試通過，無跳過，exit code 0，21.25 秒；編譯未辨識到 warning／error。使用核准的開發 GymDB，未呼叫硬體。
- SQL 案例：沒有呼叫端交易時拒絕；建立／重送／固定及時間精度；失敗 rollback；舊快照不能覆寫新狀態；不合法直接 SQL 資料在程式讀取時拒絕；有效占用唯一索引；最後一堂並行競爭；同操作並行重送；Released 返回及 NeedsReview 保留容量。
- 完整 SQL 測試日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-k8ak1f_r\test.log`。
- 測試資料均使用隨機 TPTEST 標記與自己的 ID，清理前核對擁有者，只清除本次建立資料。測後唯讀查核出席／工作／明細／占用四表均為 0 筆，沒有修改原業務資料。
- 非全部測試或完整產品驗收，未執行硬體、進出場與 A／B／Worker 故障恢復驗收。

## 尚待完成

- 資料庫與占用 Repository 的基礎 SQL／交易／並行驗證已完成；仍需進出場、A、跨程序背景工作全流程測試。
- 測試清理、測試資料型別問題及核准的兩批殘留已處理；本輪指定範圍 153 個單元測試、34 個 SQL 測試通過，包含進場身分拆分與前置結算優先的回歸案例。仍非第四階段完整驗收，不重複列為待實作。
- 完成出席／進出場、Pending、月票零占用、失敗／Unknown、截止時序的整合驗證；關聯欄位已套用，ClassProcessing 預設不啟用。
- A／Coordinator／Worker 已有原截止歷史、租約恢復、個別學生錯誤隔離及重跑案例通過；票券變更完整組合、真正跨程序故障／重試及全流程仍待補驗，不能標示整階段完成。
- 2026-10-23 最新決策：跨日未完成的 A／B 一律 NeedsReview，包括 A 已固定而 B 未完成者；完整歷史還原及三張歷史表暫緩。A 目前已有跨日保守分支；B 跨日防線尚待階段 05 實作，不因文件確認而標成已完成。
- 第五階段 B 正式扣堂與核銷防重仍待實作；B 只結算，不啟用下一張票。進場及下一堂 A 的前置未完成不提前啟用、A 可呼叫共用服務整理排隊票已補 SQL 驗證；B 真正提交後到下一堂的完整銜接仍依賴階段 05，不另建接續工作表，也不以假的 B 完成旗標解除依賴。
- 第六階段人工更正／待確認入口及相關硬體、操作驗收。
- 2026-10-25 第五階段文件已確認 B 嚴格 > 下課＋10 分鐘、最多嘗試 3 次／至少隔 15 秒，以及處理中回覆後停止轉圈、清空電話、不輪詢／不自動重送。核銷擴充改採 attendance_sn 的程式端交易鎖定防重，不新增扣堂唯一約束，新增 recorded_at 提案使用 datetime。以上均為階段 05／06 待實作設計，沒有修改本階段程式、既有 datetime2、JSON、schema 或啟用設定，也沒有新增測試結果。

## 已確認：第一版補跑範圍與代價

第一版範圍最新確認（2026-10-23）：詳見 [本階段規格：縮小範圍與代價](../impelment_rule.md#第一版已確認縮小歷史補跑範圍與代價)。B 只結算，接續由下一次進場／下一堂 A 觸發；接受下一張票不立即啟用、接續異常留在後續流程，以及跨日未完成 A／B 均由人工處理的成本。學生詳細頁查閱、確認與恢復入口仍為第一版依賴，尚未實作。當日 A 衝突／證據檢查及全部待驗證紀錄保留；本輪只有文件對齊，沒有新增測試結果或修改程式／DB。

## 已確認：課間預參加後的排課異動

2026-10-17 使用者回覆「好」確認：取消課程時取消 Pending 並釋放暫占；修改時間時保留 Pending／暫占，跟隨新的出席截止。原始進出事件不改寫，不新增「有 Pending 就禁止改課」的限制。已接入兩個排課 handler 的同一交易。

## 歷史停止點：測試資料清理遺漏（已處理）

- 前批 75 個單元測試通過（61 占用＋10 進場政策＋4 既有排課），exit code 0，11.47 秒，無辨識到的編譯 warning／error。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-2y7bkw81\test.log`。
- 最新 13 個 SQL 案例均通過，exit code 0，15.11 秒，無辨識到的編譯 warning／error。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-jb6_yjai\test.log`。但是事後全表查核發現清理不完整，不能因此宣稱本批 SQL 驗證全部完成。
- 原因：Fixture 追蹤了原先建立的 A job ID；新增排課同步會再建立 B，但清理只刪 A，最後殘留 B。Fixture 的原清理斷言未包含工作表，所以沒有讓上述測試失敗。
- 兩批改課測試留下的確切 B 工作為 job_sn **12、20、29、37**，場次依序為 **19、26、33、40**；建立時間皆為測試固定台灣時間 `2026-09-06 10:02:00`，原場次／老師測試資料已清掉，無工作明細。不是正式取消課程應刪除 B 的需求；正式工作歷史應保留。
- 當時唯讀結果：出席 0、工作 4、工作明細 0、占用 0。該四筆已於下述後續處理刪除；沒有對其他資料做清理。
- 建議：Fixture 按其自行建立且 marker 相符的場次刪除兩階段測試工作及明細，並將兩張工作表加入清理後斷言；獨立交易只刪上述經再次驗證的四筆測試殘留，再重跑。
- 後續 A／Gate 程式仍在編寫中，最新所有變更未完成完整 build／測試。已依專案規則停止相關實作並詢問使用者，等待方向。

## 2026-10-17 後續處理與驗證進度

- 使用者同意後，Fixture 改為按自己建立且 marker／學生相符的場次清除 A、B 工作與明細；清理前檢查意外的其他學生資料，清理後檢查兩張工作表。
- 以獨立交易重新驗證 job_sn 12、20、29、37 的場次、狀態、固定測試時間、原場次／老師已不存在及無明細後，只刪除此四筆測試殘留；沒有刪除其他會員、票券或原始出席資料。未提供自動還原工具，重新測試可重建測試情境。
- 13／13 SQL 測試通過、exit code 0、28.45 秒、編譯 error／warning 均 0；日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-4_mdar5_\test.log`。另以新連線唯讀確認出席、工作、明細、占用四表皆 0。
- 新增 16 個進出歷史測試；含成功回應恰好截止、晚於截止、截止前離場、依歷史補跑、Unknown／Requested／同時間事件、無成功回應時間、Device Test 不影響館內等。當時共 91／91 通過，exit code 0、13.23 秒、編譯 error／warning 均 0；日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-jzso2tw5\test.log`。
- 繼續補強固定出席重跑的資格與占用一致性、票券資料缺漏轉待確認、開門請求綁定的學生／出席／占用／來源檢查，以及 NULL 清理旗標不得推定 false。新增程式尚未完成所有 SQL／流程驗證。
- 前輪單元測試 **100 筆中 97 通過、3 失敗**，exit code 1、10.39 秒、編譯 error／warning 均 0。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-fnq86w7o\test.log`。
- 原因已確認為新增 `ClassAdmissionPolicyTests.InvalidGateBindingCannotGuessOwnershipOrPreparationFlags` 的 InlineData 使用 Int32 常值，而參數為 nullable Int64（`long?`）；xUnit 在呼叫測試方法之前即拋出型別轉換錯誤，三筆未執行到業務檢查。
- 使用者再次同意後，已僅將三筆測試常值改為 `0L`／`2L`，不改業務規則。重跑 **100／100 通過**，exit code 0、10.67 秒、編譯 error／warning 均 0；日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-duza3eui\test.log`。
- 增加 9 個實際 SQL 案例：截止整點 A 拒絕提前封存；Pending 無原始進出歷史保留占用待確認；已確認堂票缺固定占用不能假裝完成；過期 lease 接手後拒絕舊 token；已完成工作明細不能重做；成功進場在截止時固定堂票占用且不先扣堂、重跑不新增；月票固定票券但零占用；截止前離場釋放暫占且不成立出席；Unknown 結果保留占用待確認。
- 最新 SQL **22／22 通過，無跳過**，exit code 0、13.72 秒、編譯 error／warning 均 0；日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-3ra99i7p\test.log`。測試會按自建使用者與 marker 清除事件，並檢查事件／出席／場次／占用／A、B 工作／工作明細無測試殘留；未呼叫硬體。
- 當時 API SQL 測試過程包含編譯 API 與其相依專案，但未另宣稱已跑全部 API／應用測試。當時 device_record 腳本 03 尚未套用；後續已部署及補測，見下節。第四階段仍未完成、未啟用。

## 開門關聯欄位 SQL（已部署至開發 GymDB）

[device_record 關聯欄位](../sql/03-link-gate-request-attendance.sql)：attendance_sn、reservation_sn、admission_kind、created_pending、created_reservation，均允許 NULL，無 FK／CHECK／rowversion／default。用於保存這次開門請求的原始參加種類及是否新建暫占，避免失敗／重啟時猜測應釋放哪筆；不是把 remark 當資格來源。2026-10-17 預覽後，以外層交易套用、驗證五欄型別／長度／nullability，確認舊事件數量不變且無回填後 commit；Database.md 已同步。其他環境不可視為已部署。

## 前輪驗證及清理問題（已處理，保留歷史）

- 加入 5 個 ClassAdmissionService SQL 案例：準備上下文落庫、失敗只釋放自己新占用、第二次失敗不釋放前次占用、Unknown 保留待確認、模擬成功不保留新占用、截止後成功標記待確認（首項包含上下文與失敗清理）。當批 SQL 27／27 通過，exit code 0、14.42 秒，編譯 error／warning 均 0。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-i_go_cjp\test.log`。
- 再加 A Coordinator 正常工作流程／重跑不重占／B 不假完成，以及過期 lease 補跑／缺歷史保留未結算兩案例；當批 SQL **29／29 通過**，exit code 0、11.89 秒，編譯 error／warning 均 0。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-i3ng326i\test.log`。
- GatePassageService 新增 5 個單元案例，連同原有案例確認拒絕不發指令、準備先提交且硬體呼叫不持交易、重送不再準備／開門、取消記 Unknown、模擬不更新最近進場、完成失敗 rollback 且不再次發指令；使用假的控制器，未操作硬體。擴大篩選共 **111／111 通過**，exit code 0、8.05 秒，編譯 error／warning 均 0。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-p90sfl5j\test.log`。
- 最後新增同場次第二位學生無效出席資料的失敗隔離案例，同時擴充 Fixture 支援多個自建學生。當時 SQL **30 筆中 1 通過、29 失敗**，exit code 1、13.19 秒，編譯 error／warning 均 0；不能沿用上批結果宣稱當批程式全通過。日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-wcc06m29\test.log`。
- 已確認的清理錯誤：Fixture 第 708 行起改用 `IN @owners`，參數是 string[]；專案 DapperConfig 全域註冊 StringArrayHandler，SetValue 把 string[] 序列化為 JSON 純量，因此不再展開成 IN 的參數清單，SQL Server 回報靠近 @owners 語法不正確。不是新增五欄 migration 失敗，不需刪除或修改既有 JSON handler。
- 清理交易因此回滾，而 TicketSqlFixture 的 finally 仍清除了該批自建會員／票券，留下事件／場次及其子資料。當時唯讀查核：出席 33、工作 39、工作明細 81、占用 18；逐表以 TPTEST 隨機場次 marker 與原使用者／票券已不存在交叉核對，這四表全數符合本批測試孤兒特徵。該批後續已經核准、備份及刪除，見下節。
- 建議僅修改 Fixture，以每個已核對自建學生的純量參數執行清理，避免 string[] JSON handler；修正測試清理失敗時仍刪父資料的處理次序，再依明確 ID／marker 清單清理本輪資料並重跑。依協作規則已停下，待使用者確認，尚未做上述修正與刪除。第四階段仍未完成、未啟用。

## 最新處理：保留 JSON 設定、修正清理並重跑通過

- 使用者確認「好，不動既有 JSON 設定」後，僅修改 CreditReservationSqlTests 的 Fixture；StringArrayHandler 與 DapperConfig 均沒有改動。不再傳 string[] 給清理 SQL，改逐一傳入已核對擁有者的純量參數。
- 子資料清理及清理後斷言放在同一交易，通過才 commit；失敗則 rollback，且不再透過 finally 繼續刪除父層會員／票券，保留完整 ownership marker 供追查。
- 已新增回歸案例：刻意放入非本 Fixture device marker 的自建事件，確認清理拒絕擴大範圍，子資料回滾，會員／票券／出席／占用保持存在；最後只還原該確切測試事件的 marker，正常清理後通過。
- 先唯讀建立完整資料與精確 ID 快照，再在獨立 Serializable 交易取得 calendar 鎖，重讀比對快照及檢查會員／票券已不存在、沒有新增子資料；僅刪除快照 ID。實際清除：測試場次 31、出席 33、工作 39、明細 81、占用 18、進出事件 12。未刪除會員、票券或其他未列入快照的業務資料。
- 完整資料備份位於本機 `C:\Users\HarryLin\AppData\Local\Temp\gym-reservation-cleanup-d2442e75d62246c4a0078a9e5a18c2a4.xml`，保留欄位型別與原值，可供必要時人工還原；未提供自動還原或上傳備份。
- 首次重跑 30／30 通過，exit code 0、13.19 秒，編譯 error／warning 均 0；日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-ahtbjubi\test.log`。
- 加入上述回歸案例後，最新 **31／31 SQL 測試通過，無跳過**，exit code 0、12.66 秒，編譯 error／warning 均 0。指令：`dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-restore --filter FullyQualifiedName~CreditReservationSqlTests --logger console;verbosity=normal`；工作目錄為 backend 根目錄，經 Python 收集日誌及摘要。完整日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-_5_f1o7w\test.log`。
- 測後新連線唯讀驗證六張表的快照 ID 均無殘留，出席／工作／工作明細／占用四表全表均為 0。沒有呼叫硬體，沒有修改商業規則、JSON 設定或額外資料庫 schema；本輪不另執行重複 build，SQL 測試已編譯 API 及其相依專案。

## 2026-10-23 進場順序修正及 DLL 鎖定（已解除）

- 已確認舊順序：Gate 呼叫 CheckEntryAsync 時先以獨立交易整理票券，之後 ClassAdmissionService 才檢查上一堂 B，可能造成前置未完成卻已啟用下一張票。現改由 Gate 先做只讀身分檢查，票券整理仍由既有課程進場交易處理；不複製生命週期或新增歷史表。
- 新增 5 個身分識別測試，並擴充 Gate 單元測試確認課程準備拒絕及成功／重送路徑不呼叫提前整理票券的基本驗票方法。連同原有相關案例共 **153／153 通過**，exit code 0、16.23 秒，辨識到編譯 error／warning 均 0。工作目錄 backend 根目錄，經既有 Python helper 收集完整日誌；日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-6y_hbcn6\test.log`。
- 已加入三個待執行 SQL 案例：真實 Gate／身分／課程服務組合遇上一堂未結算時不提前啟用排隊票；下一堂 A 前置未完成時不整理票券；下一堂 A 可根據既有進場歷史呼叫共用服務啟用排隊票，不需要確認時再送新開門請求。沒有實作 B，測試僅建立自有前置狀態；控制器為拒絕任何實際呼叫的測試替身。
- SQL 驗證指令：`dotnet test tests/gym-system.Api.Tests/gym-system.Api.Tests.csproj --no-restore --filter FullyQualifiedName~CreditReservationSqlTests --logger console;verbosity=normal`，同樣由 Python 包裝。**在建置階段失敗，SQL 測試未啟動**；exit code 1、22.03 秒。辨識到 6 筆去重後 MSBuild error、30 筆含重試序號的 warning，均指向輸出檔案鎖定，不能當成 C# 邏輯編譯錯誤或 SQL 案例失敗。
- 原因：正在運行的 `gym-system.Api`（PID 73332）鎖住 API Debug 輸出目錄中的 Domain／Application／Infrastructure DLL，MSBuild 複製重試十次後回報 MSB3027／MSB3021；warning 為 MSB3026。完整日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-26d5yaxv\test.log`。
- 已依協作規則暫停，未自行停止使用者後端、變更建置參數繞過或重跑。本次 SQL 案例尚未執行，沒有因此建立測試資料、修改 schema 或呼叫硬體；功能與 ClassProcessing 設定未啟用，JSON 設定未改。待使用者停止後端或確認後續驗證方式，再繼續。

### 使用者停止後端後的驗證結果

- 使用者回覆「暫停了」後，唯讀確認原鎖檔 API 程序 PID 73332 已不存在；未自行終止其他程序，也未自行重啟後端。
- 沿用上述 SQL 測試指令、工作目錄及 Python 日誌包裝重跑，**34／34 通過，無跳過**，exit code 0、15.28 秒，辨識到編譯 error／warning 均 0。完整日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-d3f865k5\test.log`。這次包含正常編譯 API 與相依專案，不另外執行無新疑點的重複 build。
- 新增三案例均通過：真實 Gate 編排使用只讀身分檢查，前置 B 未完成時回 Denied／PREVIOUS_SETTLEMENT_PENDING 且排隊票保持 UnActive；下一堂 A 回 Blocked 且不提前啟用；無前置阻擋時 A 可使用既有成功進場事件整理並固定排隊票，不需確認時再送進場請求。測試未建立真實裝置授權、不呼叫硬體，也沒有假裝實作 B 正式結算。
- 測後另用新連線唯讀核對 GymDB：出席、工作、工作明細、占用四表全表均 0；測試 Fixture 亦檢查其自有會員、票券、場次及進出事件的清理。沒有修改既有業務資料、資料庫 schema、JSON 或 ClassProcessing 啟用設定。
- 最近應用層單元測試仍為本輪修正後的 153／153 通過（上一節日誌）；本次只接續先前被鎖住的 SQL 驗證，未宣稱重新跑過全部應用／API 測試。B 扣堂、跨日 B 防線、人工處理入口與完整硬體驗收仍未完成，第四階段不得因此標為已上線。
