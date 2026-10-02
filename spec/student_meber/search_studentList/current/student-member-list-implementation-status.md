# 學員列表實作狀態

文件整理日期：2026-10-02；下列實作與測試紀錄日期：2026-09-23。本次只整理文件，未重跑測試或新增功能。

現行規格：[student-member-list-spec.md](student-member-list-spec.md)。

歷史規劃：[封存計畫](../archive/01-student-member-list-implementation-plan.md)。

## 閱讀與維護方式

- current：現行規則與最新完成／未完成清單。
- implement_plan：接下來要做的計畫；目前只有排程待確認計畫，尚不可直接實作。
- archive：已執行或被新版取代的計畫，保留歷史語意，不以其中舊待辦判斷當前狀態。

## 本階段已實作

- Admin 專用 GET /api/v1/students 與 PATCH /api/v1/students/{studentId}。
- sdt_profile 為主，EXISTS 檢查 Student，查詢不額外排除停用使用者或角色。
- 姓名／電話 Trim 後包含搜尋，LIKE 特殊字元作為文字處理。
- 有效 Active 中選最早建立票券，否則最新票券（含 Cancelled）；相同時間以 pass_sn 決定。
- 後端台灣日期計算 Expiring、已過期 Active 顯示 Expire；保留 validStatus 原值，列表不更新生命週期。
- 付款狀態取同一張 pass 的 order item，不混入其他未付款訂單。
- 後端篩選、狀態排序、UnPaid 優先與每頁預設 15 筆分頁，總數與當頁基於同一次投影。
- 前端列表不再使用 mock 學員或自行推導票券狀態；無票券 No Ticket，狀態為「-」。
- 搜尋 400ms debounce、立即取消舊請求、版本檢查、離頁清理；等待及載入時禁止翻頁。
- 姓名／電話編輯重用既有 repository，排除本人查重，DB unique 違反轉為 409；失敗保留表單且可重試。
- 編輯完成刷新；註冊成功返回列表時元件重新掛載並讀取 API。
- Visited Today、手動進場保留且停用；LAST VISIT 為「-」。
- 購票與學生詳細頁入口保留；BuyTicketModal 的輸入型別縮小至實際需要的 id/name/phone，沒有改購買規則。
- 補入 vite-env.d.ts 的 vite/client 宣告；新增 npm run typecheck、npm run test:students。

## 資料庫

沒有新增資料表、欄位、索引或約束。已唯讀確認 GymDB 存在 UQ_users_phone 唯一約束。

整合測試沿用 TicketSqlFixture，僅建立帶有唯一 TPTEST 標記的資料，按確切 ID 清理並驗證；不清除既有開發資料。正常完成的測試已自行清理其資料。

## 驗證

- 後端 API 建置通過。
- Application 測試：104 項通過。
- StudentMemberListTests：12 項通過（含 6 項 SQL 整合測試）；另執行 2 項既有註冊查重 SQL 回歸測試。
- 前端型別檢查與 Vite production build 通過。
- 前端學生列表、註冊、票券日期測試合計 16 項通過。
- 本機臨時 API HTTP 驗證：未登入 GET 401、Student GET/PATCH 403、Admin GET 200、非法頁碼 400、不存在學員 PATCH 404、空白編輯欄位 400。臨時 API 已關閉。
- SQL 測試涵蓋選票順序、台灣日期邊界、唯讀狀態、角色與 profile 範圍、全量篩選後分頁、特殊字元、付款來源、排序、姓名／電話修改及 unique 衝突。
- 前端競態測試涵蓋 400ms 重計時、transport 忽略 abort 的舊成功回應、舊失敗、離頁與計時取消。
- 未使用瀏覽器完成端到端人工操作驗收，不能將自動測試視為該項已完成。

現有工具警告：Vite build 有 /index.css 缺少與 MockData 混合 import 提示；多個既有 Vite 測試 server 並行可能提示 WebSocket port 已使用。測試與 build 均成功；沒有更改上述既有設定。

## 待人工驗收

1. Admin 登入後查看列表、搜尋、切換篩選与翻頁。
2. 快速輸入並清空搜尋，確認 loading、分頁停用與結果顯示符合操作感受。
3. 編輯姓名／電話，確認成功刷新、重複電話顯示原因且保留輸入。
4. 完成註冊並關閉成功彈窗，確認返回列表後重新查詢；新會員依既定排序分頁，未必在第 1 頁，可用姓名／電話搜尋。
5. 確認 Visited Today、手動進場可見但不可操作，LAST VISIT 顯示「-」。

## 未完成：已提取為待確認計畫

- [生命週期排程](../implement_plan/02-ticket-pass-lifecycle-scheduler-plan.md)：尚未實作；執行頻率、補查、鎖定與部署細節待討論。最後階段處理，文件中的每 30 分鐘等參數仍是建議。

## 未完成：待規劃／延後

以下尚未形成可直接實作的規格，先集中留在此處；決定要執行時再各自提取至 implement_plan。

- LAST VISIT、Visited Today、手動進場的真實功能。
- 學員詳細頁及購票／付款其他功能整合；詳細頁現有 mock 邏輯未在本階段改寫，真實學員詳細資訊另行處理。
- 新會員高亮、自動跳到新會員所在頁，未納入本階段規格。
- 持久化操作者／修改歷史、退款與部分取消。

列表查詢不啟用下一張票，排程完成前可能短暫顯示 UnActive，這是已接受的過渡行為。
