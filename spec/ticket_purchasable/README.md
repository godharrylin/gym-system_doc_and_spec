# Ticket Purchasable 規格索引

本目錄整理「學生可購買票券方案」目前程式碼行為與舊計畫中仍有效的設計決策。

## 文件分工

- `ticket-plan-catalog-spec.md`
  方案目錄、資料開關、規則關聯、對外欄位與目前 SQL 查詢行為。
- `ticket-purchasability-spec.md`
  可購買資格主規格，包含一般購買、NEW_ONLY、RENEWAL、付款時重驗與錯誤案例。
- `ticket-lifecycle-spec.md`
  付款後票券建立、生效日、到期日、FIFO 排隊、續約承接與取消後重試。
- `ticket-purchase-ui-api-spec.md`
  前端與 API 合約，包含註冊可購買清單、會員個人化清單、購買限制與錯誤處理。
- `ticket-purchase-technical-design.md`
  目前實作結構、服務責任、資料表/索引建議、測試建議與待補缺口。

## 舊計畫轉移狀態

以下舊檔案內容已整理進本目錄，但尚未刪除。刪除前建議再人工確認一次差異。

| 舊檔案 | 性質 | 建議去向 |
| --- | --- | --- |
| `doc/spec/student-ticket-plan-purchasable-api-plan.md` | API 與重構計畫，混有舊狀態描述 | 有效內容併入 `ticket-purchasability-spec.md`、`ticket-purchase-ui-api-spec.md`、`ticket-purchase-technical-design.md`；舊的「尚未導入共用 Context/Rule」狀態已過期 |
| `doc/spec/ticket-plan-eligibility-rule-notes.md` | Eligibility rule 技術說明 | 併入 `ticket-purchase-technical-design.md`；需以目前 `RuleCode`、SQL 目錄查詢行為校正 |
| `doc/spec/ticket-plan-rule-implementation-plan.md` | 早期 DB/目錄/API 實作計畫 | 有效的規則資料模型想法併入 `ticket-plan-catalog-spec.md`；多數 API/DTO/前端篩選描述已過期 |
| `C:\Users\HarryLin\Desktop\DayTemp\2026\0828\disscusion plan\01-第一階段票券方案目錄調整規劃.md` | 方案目錄與資料規則計畫 | 併入 `ticket-plan-catalog-spec.md`、`ticket-purchase-technical-design.md` |
| `C:\Users\HarryLin\Desktop\DayTemp\2026\0828\disscusion plan\02-續約購買資格與票券承接調整規劃.md` | 續約資格與承接規格 | 併入 `ticket-purchasability-spec.md`、`ticket-lifecycle-spec.md` |
| `C:\Users\HarryLin\Desktop\DayTemp\2026\0828\disscusion plan\03-票券生效日到期日與FIFO排隊調整規劃.md` | 生命週期與 FIFO 規格 | 併入 `ticket-lifecycle-spec.md` |
| `C:\Users\HarryLin\Desktop\DayTemp\2026\0828\disscusion plan\04-前端方案顯示與家庭功能暫停調整規劃.md` | 前端/API 與家庭功能暫停決策 | 併入 `ticket-purchase-ui-api-spec.md`、`ticket-purchasability-spec.md` |

## 目前處理原則

- 這批文件以「目前程式碼實際行為」為主。
- 舊計畫若是未實作或與程式碼不一致，會標示為「待確認」或「建議調整」，不當作已上線規格。
- 舊檔案先保留，等新文件確認可取代後，再搬移或刪除。
