# 票券可購買 Issue 索引

本目錄整理 `ticket_purchasable` 規格中仍需要確認、對齊或補測試的事項。

## 文件

- `spec-confirmation-issues.md`
  需要產品或規格確認後才能決定做法的事項。
- `implementation-alignment-issues.md`
  已知需要和目前程式碼、SQL、API 或前端對齊的事項。
- `test-coverage-issues.md`
  建議補上的測試案例與驗證方向。

## 建議處理順序

1. 先確認 `spec-confirmation-issues.md` 的產品語意。
2. 再依確認結果拆實作項目。
3. 最後用 `test-coverage-issues.md` 補對應測試。

## 目前優先級建議

| 優先級 | 項目 | 原因 |
| --- | --- | --- |
| P0 | NEW_ONLY 台灣日曆定義 | 會直接影響可購買資格邊界 |
| P0 | NEW_ONLY 取消後是否仍算買過 | 會影響促銷票券是否可重買 |
| P0 | 續約併發保護 | 會影響同一來源票券是否可能被重複承接 |
| P1 | 目錄查詢輸出 rule code 集合 | 影響未來規則擴充安全性 |
| P1 | 註冊清單與一般清單規則同步 | 影響 API 行為一致性 |
| P1 | 續約與 UnPaid 付款重驗測試 | 影響付款時資格正確性 |
| P2 | 前端台灣日期顯示 | 影響跨日時 UI 日期正確性 |
| P2 | 家庭購買恢復前置規格 | 目前功能暫停，可先保留 |
