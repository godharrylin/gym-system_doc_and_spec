# 階段 03 實作狀態

更新日期：2026-10-16。

## 已完成

- 前端 Schedule 頁改用 `ApiClassRepository`，課程、老師、模板及場次由後端 API 載入。
- API 回傳及前端保存資料庫實際 `class_id`、老師 ID 與穩定場次 ID；日期使用本地 `yyyy-MM-dd`，不經 UTC ISO 日期轉換。
- 保留查詢空週即時生成，已有任何場次（包含已取消）就不重新生成；建立前用 SQL transaction-owned application lock 鎖定該週。
- 同週手動新增、移動、取消和空週生成共用週鎖；場次異動另以場次鎖序列化，並跨週時依序取得週鎖。
- 自動生成前檢查當週模板的十分鐘間隔，模板資料若互相衝突則整體拒絕生成，不寫入部分場次。
- 新增／修改場次沿用後端十分鐘衝突檢查，場次 ID 保持不變；前端顯示 API 拒絕原因並保留表單。
- 後端依原場次 `StartAt` 及台灣 `IClock`，於 `now >= StartAt` 拒絕所有修改／取消。
- 課表、課程、老師及模板 API 加入 JWT 驗證；既有場次修改 handler 保留 Admin／Staff 角色檢查。
- 所有課程、老師、模板及場次 API 已限制 Admin；既有場次修改 handler 另檢查 Admin／Staff，兩者疊加後仍只有 Admin 可操作。
- 場次詳細視窗不再以 mock 資料或隨機資料製造虛構出席名單。
- 沒有新增資料表、欄位或索引，沒有修改 GymDB 既有資料。

## 待確認／待驗收

- 瀏覽器人工驗收：跨週日期、空週生成、人工新增／修改／取消、十分鐘衝突、開始後拒絕及重新載入持久性。
- 免費課程及場次欄位已保存；學生課程資格、出席、額度占用與扣堂由階段 04／05 完成。
- 查詢歷史空週會依目前啟用模板補生成的既有風險仍存在；未增加歷史日期限制或補認出席行為。

## 驗證結果

- 2026-10-16 後端 build 通過，0 errors／0 warnings。
- Application tests 169／169 通過；新增階段 03 測試 4／4 通過。
- API tests 87／87 通過；另有 34 個 SQL 整合案例需要明確提供資料庫設定，本次一般 API 測試未執行它們。
- 前端 build 與 typecheck 通過；課表 API tests 4／4 通過。
- GymDB 以 rollback transaction 驗證 SQL Server transaction-owned application lock 可用，未留下資料異動。
- 未進行瀏覽器人工驗收。
