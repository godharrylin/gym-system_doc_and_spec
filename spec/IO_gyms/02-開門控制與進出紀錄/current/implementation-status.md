# 階段 02 實作狀態

更新日期：2026-10-16。

## 已完成

- 裝置專用 Cookie 授權，不持有 Admin JWT；進／出方向由 DB 站點決定。
- 固定碼配對預覽、確認換機、單站點單 Active 授權、自行撤銷及舊裝置失效。
- DB 授權不自動到期；瀏覽器 Cookie 持久保存及續簽。清除網站資料後仍須重新配對。
- 同源 `/api`、HTTP 內網模式、HttpOnly、SameSite=Strict、Origin／Sec-Fetch 檢查及配對限流。
- `gate_station`、`gate_device_session` 及 `device_record` 擴充已套用至開發／測試 GymDB；舊 `device_record` 資料未改寫。
- 進出 API 只接受後端站點方向與 `phone + requestId`；不相信前端傳入方向、角色或控制器資料。
- 第一階段電話／角色／基本票券檢查已接入。工作人員進場、已識別使用者出場可以進入控制流程。
- 學生進場在課程時段及額度占用尚未完成時固定拒絕，不能僅憑 Current Plan 或基本票券開門。
- 外部控制前先保存 Requested；結果分 Succeeded／Failed／Unknown／Denied。相同 request ID 不重送命令。
- 廠商明確成功回應的後端接收時間作事件時間；失敗、Unknown、Denied 與 Mock 不改館內狀態。
- 前端 `/#/checkin` 已完成配對及電話送出，裝置 client 不帶 Admin token、不自動重試不明結果。

## 尚未完成

- 階段 03／04 的實際場次、時間窗口、回場資格、Pending 暫占及學生額度占用；因此學生進場仍 fail closed。
- 現場三叉機的成功、失敗、逾時、控制器 SN、Entry／Exit DoorNO 及兩台 iPad 實機驗收。
- NAS／正式環境的內網網址、反向代理、`GateDevices` secrets、Data Protection 持久金鑰目錄及 DB 部署。
- 開門成功但最終 DB 更新失敗時，已有 Requested 可追查且重送不會再開門；人工查閱／結案入口列後續。
- 多實例分散式控制器鎖與更完整的高併發硬體排隊；目前只有單一 API process 的 command gate。
- Admin 任意撤銷其他站點裝置的管理入口；目前完成的是裝置自行撤銷及新機取代。

## 驗證狀態

- 2026-10-16 後端 build 通過，0 error／0 warning。
- Application tests 165／165、非 SQL API tests 87／87 通過；一般 API 測試執行另有 34 個需明確提供 GymDB 連線的案例未執行，未將其誤列為通過。
- 階段 02 GymDB SQL 整合測試 1／1 通過，已驗證配對換機、撤銷、Request 防重、結果更新、方向映射及 transaction rollback。
- 前端 build、typecheck 及裝置 API tests 9／9 通過。
- 實體硬體與 iPad 驗收尚未執行，不標記為通過。

## 部署前必要設定

`appsettings.json` 預設 `GateDevices:Enabled=false`，不含真實配對碼。部署時以環境 secret 提供：

- `GateDevices__Enabled=true`
- `GateDevices__AllowHttp=true`（只限已確認的受控內網第一版）
- `GateDevices__EntryPairingCode=<secret>`
- `GateDevices__ExitPairingCode=<secret>`
- `GateDevices__KeyRingPath=<NAS 上的絕對持久目錄>`

前端必須由同一個瀏覽器來源以 `/api` 反向代理到後端。第一版不支援跨來源裝置 Cookie，也不能沿用全域 `AllowAnyOrigin` 作裝置權限；若未來改成不同來源，須另行設計及驗證 CORS、Cookie `SameSite` 與 CSRF 防護。
