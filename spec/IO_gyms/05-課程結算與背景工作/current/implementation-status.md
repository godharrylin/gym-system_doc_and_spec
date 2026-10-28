# 第五階段實作狀態

更新日期：2026-10-25。狀態：B 結算核心及 A／B 串接已實作，本機指定範圍驗證通過；時間精度阻擋已解除。ClassProcessing 仍未啟用，未完成真實設備／現場驗收；第六階段人工入口不在此處宣告完成。

## 已實作與已驗證範圍

- 新增共用 ClassSettlementService 與 SQL 核銷 repository：固定出席／原票券／占用核對，堂票扣 1 堂、核銷、Consumed 關聯；月票不寫零堂數核銷。
- Coordinator 接入 B：工作依到期順序處理，每學生獨立交易；B 不啟用下一張票，耗盡業務時間為本堂結束。
- 在執行前持久化 Running 與嘗試次數；暫時錯誤最多 3 次，重試至少間隔 15 秒；等待前置工作不耗用技術重試次數。跨日未完成工作轉人工。
- 以出席關聯及既有核銷檢查作程式端防重，人工／自動共用核心，未增加扣堂唯一約束、FK、CHECK 或 rowversion。
- 進場回覆區分上一堂處理中、待確認及尚未結算；前端顯示處理中提示，沿用明確 API 結果後清空電話、結束 loading，不新增結算輪詢或自動重送。
- 已完成核銷表 5 欄 ALTER 部署，另經使用者確認以 SQL 03 將 usage_dt／recorded_at 轉為 datetime2(3)。提交前後核對原 1 筆資料在毫秒精度下不變，其他欄位／索引／約束不變，沒有重建或回填。既有 JSON 與 ClassProcessing 啟用設定未修改。
- 新增局部 ClassProcessingSqlParameters：工作查詢／租約／嘗試時間、核銷業務／實際時間參數明確以 DbType.DateTime2 傳送；不調整全域 Dapper 型別映射及 JSON handler。

## 驗證結果

- 相關 Application 單元測試：153／153 通過。首輪有 CS8602 nullable 警告，已局部修正；後續 API／Infrastructure 編譯無錯誤與警告。
- 時間參數修正後：原 43 個 SQL 整合案例全部通過；再補 5 個必要驗收案例後，最終 48／48 通過，無跳過，exit code 0，15.39 秒，編譯 0 錯誤／0 警告。
- 本輪補強：B 單一學生異常不阻止他人完成、過期租約接手且嘗試次數不歸零、同一 tick 先上一堂 B 再下一堂 A 並接續票券（沒有新進場事件）、同日 A／B 都晚跑先確認出席再結算、不明核銷關聯轉人工且不再扣堂。
- 單元測試日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-6ee5b03w\test.log`。
- 最終 SQL 測試日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-sugcim0h\test.log`；修正後原 43 案例日誌：`C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-7c77wrba\test.log`。先前失敗日誌仍保留於 `C:\Users\HarryLin\AppData\Local\Temp\gym-credit-reservation-p2dywgws\test.log`，不覆寫失敗歷史。
- 測試後唯讀查核：出席、工作、工作明細、占用皆 0 筆；核銷表仍為原有 1 筆，沒有殘留本輪測試資料。
- 前端 npm run typecheck 通過，exit code 0；9／9 gate-devices API 測試通過，無跳過，exit code 0；npm run build 成功，實際建置 exit code 0。
- 前端建置有兩則既有提示：index.css 未在建置時找到，以及 MockData 同時被動態／靜態匯入，不因本次驗證擴大修正。建置摘要 helper 曾因輸出 Unicode 字元失敗；已修正 helper 的 UTF-8 輸出並從原日誌核對建置結果，沒有為此重複 build。
- 前端日誌：typecheck `C:\Users\HarryLin\AppData\Local\Temp\gym-stage-five-frontend-mfaxi5gq\verification.log`；裝置 API 測試 `C:\Users\HarryLin\AppData\Local\Temp\gym-stage-five-frontend-kvpf0op5\verification.log`；build `C:\Users\HarryLin\AppData\Local\Temp\gym-stage-five-frontend-r6dhtux5\verification.log`。
- 上述 API 測試不等於瀏覽器畫面或實際設備驗收；ClassProcessing 保持未啟用，未自行啟動後端或呼叫真實控制器。

## 已解除阻擋：SQL 時間參數精度

- 6 個失敗案例均預期在下課＋10 分鐘再過 1 毫秒時，Coordinator 取得 1 個 B 工作，實際取得 0 個。
- 同一輪核心並行結算、處理中拒絕開門、跨日轉人工等案例通過；不能因此推定所有 B 路徑已正確。
- 唯讀 SQL 對照：傳入 `2099-09-06 11:05:00.001`，以 datetime 參數與 `11:05:00.000` 比較 `>`，結果 false；以 datetime2 參數則為 true。datetime 參數會在傳入時捨入，工作表本身仍為 datetime2(3)。
- 依專案 AGENTS.md 已先暫停回報；使用者討論確認後，Database.md 先改完整 CREATE 及欄位目標，再於本輪套用兩欄轉型及局部時間參數修正。原精確邊界測試保持不變，43 案例全通過後再補至 48 案例，未放寬截止規則掩蓋失敗。
- 本次僅對齊核銷表兩欄與工作／核銷參數；其他資料表仍依 IO-17 待辦，在處理相關功能時先提醒使用者確認範圍。

## 待完成

1. 前端瀏覽器／iPad 實際驗證：處理中停止 loading、清空電話、提示重新輸入，不輪詢結算或自動送開門。
2. 真實多程序重啟／中斷恢復、正式部署及控制器驗收另行安排；本機並行／租約 SQL 案例不冒充實際設備驗收。
3. 第六階段正式人工處理入口及沖銷流程仍待實作；本階段共用核心不代表 Admin 已有可用的扣退堂操作畫面。
4. 啟用前確認 StartDate、部署設定、完整學生進出與人工待確認處理流程；不自動開啟 ClassProcessing。
5. 其他資料表時間精度依 IO-17 待辦逐次確認，本輪不批次改型。
