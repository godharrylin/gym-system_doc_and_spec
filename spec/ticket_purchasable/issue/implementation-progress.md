# 可購票修正進度與驗收限制

更新日期：2026-09-09。詳細規劃與命令見 [05-remaining-alignment-plan.md](../implement_plan/05-remaining-alignment-plan.md)。其他 issue 中的舊描述尚未全部回填，不可視為最新狀態。

| 項目 | 已完成 | 尚未完成 |
| --- | --- | --- |
| A01／A02 | 集中分類、Registration handler、真實 catalog SQL；修正 Dapper 陣列被 JSON handler 攔截 | 兩支清單完整 HTTP 回歸 |
| A03 | 真實註冊 UnPaid → 延後付款 ExistingMember，付款時最新規則與日期 | 更多付款拒絕／併發 SQL 變體 |
| A04 | SQL／記憶體剛結束來源優先、單堂讓位／恢復、跨家族 FIFO | 已過期排隊候選的 SQL 對照與完整變體 |
| A05 | 移除上限，SQL 前 100 張未來候選不阻擋後方一般票 | 大量資料效能查核 |
| A06 | SKU SINGLE 一致；GymDB SINGLE 設定唯讀查核 | 其他變體按驗收表持續補齊 |
| A07 | 使用者已確認政策；修測試 UTC 寫入、SQL 時間往返及第 30／31 天邊界 | 未知舊資料保持原值；未來匯入須附來源，不代表歷史全數查核 |
| A08 | Application 104、API 43（含 SQL 25）、前端時間測試 5 通過；索引錯誤轉換與購買取消併發 | 完整 HTTP／瀏覽器驗收、核銷／沖銷、更多付款併發與拒絕變體 |
| A09 | 回填時間政策、GymDB fixture／清理、案例覆蓋與明確缺口 | 尚未補齊案例完成後再整體結案；不刪舊計畫 |

不再等待 A07／A08 確認：使用者已允許 GymDB 開發測試並確定未知舊時間資料不整批校正。測試僅使用專屬 ID／marker，修正 xUnit 清理介面後核對殘留為 0；曾留下的本輪 30 筆測試會員已精確清理，不修改既有會員。測試通過仍不代表全部 SQL／HTTP／核銷情境已涵蓋。

後排：Dashboard／Reports／課表台灣日期整理。本次不新增 Active 續約取消、家庭購買、退款或 audit logs 資格判斷。
