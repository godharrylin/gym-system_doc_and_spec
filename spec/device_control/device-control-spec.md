# Device Test 三叉機控制邏輯規格

- 文件狀態：現行實作規格，已由使用者確認；現場驗收狀態另列。
- 整理日期：2026-10-07。
- 文件位置：doc/spec/device_control/device-control-spec.md。
- 範圍：System Settings 的 Device Test、後端控制 API、CloudServer HTTP 指令與診斷日誌。

## 1. 目的與範圍

提供後台人員測試三叉機進入、出去，以及查詢控制器狀態。
本功能不驗證會員票券、不扣堂、不建立會員進出紀錄，不變更資料表。
正式客人 Check-In／Check-Out、通行完成回饋、部署與內網隔離不屬於本次完成範圍。

## 2. 系統分工

```text
Device Test UI → 後端 Controller → Application Handler → ITurnstileCommandClient
→ Infrastructure CloudServerTurnstileClient → 1001CloudServer → PCB 控制器 → 三叉機
```

以上為 Real 流程；Mock 模式由依賴注入替換成 MockTurnstileCommandClient，不使用 HttpClient 或 CloudServer。
呼叫端只依賴介面並檢查回傳結果，不在 Controller 另開 Mock action，也不寫模式分支。

前端只呼叫健身房後端，不直接呼叫 CloudServer。
控制器序號、接點、URL 與逾時由後端決定，不接受前端任意指定。
原始 DoorControlTool 已確認可透過 RemoteOpenDoor 控制進出；本系統沿用 JSON-RPC 指令格式。
CloudServer 負責與控制器通訊，本系統不自行實作乾接點或底層硬體通訊。

## 3. 權限與設定

兩支 API 都要求有效 Admin access token；操作者從 JWT sub 取得，缺少身分時拒絕。
DeviceTestEnabled 只控制 Device Test API 是否開放，false 仍代表關閉，不代表模擬成功。
Mode 獨立控制共用設備服務的實作，將來正式進出功能可共用，不受測試頁面開關綁定。
目前本機 appsettings.json 已設定 DeviceTestEnabled=true、Mode=Mock，供無板子時開發。

### 3.1 設定位置與完整範例

設定位置：src/gym-system.Api/appsettings.json 的 Turnstile 區段。

```json
"Turnstile": {
  "DeviceTestEnabled": true,
  "Mode": "Mock",
  "BaseUrl": "http://localhost:61080/",
  "ControllerSN": 253260812,
  "EntryDoorNo": 1,
  "ExitDoorNo": 2,
  "TimeoutSeconds": 5
}
```

這是 appsettings.json 的區段，不是獨立完整 JSON 檔；保留其他設定與適當的逗號。

| 欄位 | 用途與使用方式 |
|---|---|
| DeviceTestEnabled | true 開放測試 API；false 回傳 403。設定類別預設 false；不決定 Real／Mock |
| Mode | 精確填 Real 或 Mock；缺少時設定類別預設 Real。Real 使用真實設備，Mock 只回傳模擬結果 |
| BaseUrl | CloudServer 的 HTTP API 位址，不是健身房後端 5268，也不是廠商網頁 61085；Real 時使用 |
| ControllerSN | 實際 PCB 的 9 位數序號；253260812 是目前測試設備，不可當成所有設備的通用值 |
| EntryDoorNo | 進入方向對應的接點，值 1–4；目前 1，現場需核對接線 |
| ExitDoorNo | 出去方向對應的接點，值 1–4；目前 2，必須與 EntryDoorNo 不同 |
| TimeoutSeconds | 等待廠商 HTTP 回應的上限，1–60 秒；目前 5，不是 Docker 啟動等待時間，也不是開門脈衝時間 |

Mock 不使用 BaseUrl／TimeoutSeconds 進行 HTTP 通訊；為了切回 Real 時有一致設定，啟動仍驗證整份設定。

### 3.2 無板子時開發

1. 將 DeviceTestEnabled 設 true、Mode 設 Mock。
2. 確認後端環境不是 Production，停止並重新啟動後端。
3. 以 Admin 登入，進入 System Settings → Device Test。
4. 進入／出去回傳模擬成功；測試連線回傳模擬門狀態。
5. 畫面須出現「Mock 模擬／未控制真實設備」，不需要啟動 Docker、CloudServer 或接板子。

Mock 狀態固定 Door1#–Door4# 為 Closed，時間以台灣現在時間產生；這些都不是設備回報。
切換模式不會略過權限、方向、開關、防並行、取消與服務輸入驗證。

### 3.3 實體設備測試

1. 將 Mode 改成 Real，DeviceTestEnabled 保持 true。
2. 確認 BaseUrl、ControllerSN、接點與逾時符合現場設備。
3. 啟動 CloudServer，確認板子通電與網路設定後，重新啟動健身房後端。
4. 先使用測試連線查看狀態；現場安全確認後再手動測試進入／出去。
5. Real 發生失敗不會切換 Mock，也不會自動重送。

若只想禁止測試 API，把 DeviceTestEnabled 改成 false 後重啟；此時不回傳模擬成功。

### 3.4 正式環境與設定覆蓋

- Production 環境禁止 Mock，即使 DeviceTestEnabled=false 也拒絕啟動；正式環境必須選 Real。
- 本機共用設定為 Mock，部署前務必在正式環境設定覆蓋為 Real。
- ASP.NET Core 的環境設定檔、環境變數等可能覆蓋 appsettings.json；須確認實際啟動環境，不只看檔案內容。
- 可用環境變數 Turnstile__Mode=Real 或 Turnstile__DeviceTestEnabled=false 覆蓋相應設定；模式名稱區分大小寫。
- 本版不提供前端即時切換模式，也不在執行中自動重新選擇服務。

啟動時驗證：

- Mode 為 Real／Mock，且 Production 不使用 Mock。
- BaseUrl 是有效的 HTTP／HTTPS 絕對位址，不含使用者資訊或 fragment。
- ControllerSN 為 9 位數。
- 進出 DoorNO 都在 1–4，且不能相同。
- 逾時在 1–60 秒。

設定以啟動時的物件使用，修改後需重新啟動後端。
localhost 只適用於後端能透過所在主機存取該服務的情境；後端若改跑容器／其他主機，需要調整 URL。
本功能的 Admin 驗證不等於已完成正式系統的整體身分安全與網路隔離。

## 4. 開門 API

```http
POST /api/v1/device-tests/open-door
Content-Type: application/json
Authorization: Bearer <Admin access token>
```

請求範例：

```json
{"direction":"Entry"}
```

方向必須精確為 Entry 或 Exit：

- Entry → 設定中的 EntryDoorNo，目前為 1。
- Exit → 設定中的 ExitDoorNo，目前為 2。
- 其他值不發送指令。

廠商指令格式：
```json
{
  "jsonrpc": "2.0",
  "method": "RemoteOpenDoor",
  "params": [{"ControllerSN":253260812,"DoorNO":1}],
  "id": 1001
}
```

以上 id 是數字示例，不是固定設定。id 在程式中以目前時間毫秒為種子，使用 Interlocked 遞增；不是固定 1001，也不是防重複開門的保證。
使用 JSON 序列化設定保留 ControllerSN／DoorNO 大小寫。
目前 HTTP 傳送使用 PostAsJsonAsync；未改成原工具的 StringContent＋PostAsync。
不跟隨 HTTP redirect，不增加自動重試。

成功回應欄位：

- status：CommandAccepted。
- direction：Entry／Exit。
- message：控制器確認開門指令執行成功；未確認實際通行。
- traceId：本次 HTTP 請求追蹤編號。

API 另回傳 succeeded、outcome、code、isSimulated；message 使用服務結果的說明。
Real 成功定義是廠商回報指令成功；Mock 成功是模擬確認，明確標示未控制設備。
兩種成功都不代表三叉機已轉動、客人已通過或可扣堂。

## 5. 狀態查詢 API

```http
GET /api/v1/device-tests/status
Authorization: Bearer <Admin access token>
```

前端不提供控制器序號。
後端向 CloudServer 發送：
```json
{
  "jsonrpc": "2.0",
  "method": "QueryControllerStatus",
  "params": [{"ControllerSN":253260812}],
  "id": 1002
}
```

以上 id 是數字示例，實際由程式動態產生。

此指令不包含 DoorNO，不呼叫 RemoteOpenDoor，不執行開門。
API 設定禁止快取；前端 fetch 使用 cache: no-store。

廠商原始碼的 QueryControllerStatus 分支會建立控制器查詢封包，從通訊接收封包整理 ControllerInformation。
這是程式碼核對結果，不取代現場 PCB 在線／斷線對照驗收。

成功回應欄位：

- status：QuerySucceeded。
- controllerSN：控制器序號。
- controllerTime：設備回報時間字串，格式 yyyy-MM-dd HH:mm:ss；不擅自推定或轉換設備時區。
- doorStates：回傳的 Door1# 至 Door4#，只接受 Open／Closed。
- checkedAt：後端取得有效結果後的 UTC DateTimeOffset 時間。
- message：本次控制器狀態查詢成功；不代表持續在線或實際通行。
- traceId：本次請求追蹤編號。

ControllerInformation 必須是物件，Time 必須符合指定格式，至少有一個有效門狀態。
不要求所有四個門都存在；非法門狀態或缺少有效資料視為無法確認。
不回傳 LastSixRecords、ReturnPacket、卡號及其他未列入回應模型的廠商資訊。
Open／Closed 是設備回報門狀態，不代表實際完成一次三叉機轉動。
查詢結果不判定 Docker 是否啟動完成，也不保證下一次開門會成功。

查詢 API 另回傳 succeeded、outcome、code、isSimulated；Mock 的 controllerTime／doorStates 明確標示為模擬資料。

## 6. 廠商回應驗證

此節適用 Real 實作。HTTP 必須成功；正常 result 回應必須符合：

- jsonrpc = 2.0。
- 回應 id 與請求相同。
- result 為物件，success 為布林值。
- success = true、code = 1。
- ControllerSN 與指定設備一致。

廠商回傳 JSON-RPC error 或 success = false 時，回傳 CONTROLLER_REJECTED。
狀態查詢另驗證 ControllerInformation。
非 JSON、欄位缺漏／型別錯誤、id 或序號不一致，不視為成功。
這些預期的設備／通訊錯誤由服務轉為明確結果，而不是要求呼叫端以例外辨識硬體失敗。
輸入／權限／忙碌等拒絕與取消、未預期程式錯誤仍維持原有例外或取消流程。

## 7. 併發、取消與重試

前端使用立即生效的 busy 防線與按鈕 disabled；進入、出去、測試連線互斥。
後端查詢與開門共用 singleton DeviceTestCommandGate：

- 同一後端程序只允許一個設備測試請求執行。
- 忙碌時回傳 409；不排隊、不延後執行。
- 完成、失敗或取消後釋放 gate。

此限制只適用單一後端程序／目前單一設定控制器，不是跨主機鎖，不涵蓋外部 DoorControlTool。
取消或逾時釋放 gate，不代表硬體已停止執行；沒有永久去重或 exactly-once 保證。

不對逾時、502、網路失敗或控制器拒絕自動重送。
前端沿用共用 apiFetch：僅首次 401 時嘗試更新 token，成功後再送一次；原本 401 請求未通過授權。
請求中斷不能當成未開門，也不能作為自動重送的理由。

## 8. 錯誤契約與 UI 意義

| HTTP | code／情境 | 意義 |
|---|---|---|
| 400 | INVALID_DEVICE_DIRECTION | 方向不合法，未發送 |
| 400 | INVALID_DEVICE_TARGET | 控制器序號或接點不合法，未發送 |
| 401 | 驗證失敗 | 尚未登入或 token 無效 |
| 403 | 權限不足 | 非 Admin，禁止操作 |
| 403 | DEVICE_OPERATOR_REQUIRED | 缺少操作者身分 |
| 403 | DEVICE_TEST_DISABLED | 功能關閉，未發送 |
| 409 | DEVICE_BUSY | 正在處理其他請求，此次未發送 |
| 502 | CONTROL_SERVICE_HTTP_ERROR | 廠商 HTTP 回應失敗 |
| 502 | CONTROLLER_REJECTED | 廠商拒絕／回報失敗，詳細原因看後端日誌 |
| 502 | CONTROL_SERVICE_UNAVAILABLE | 連線未完成 |
| 502 | CONTROL_INVALID_RESPONSE | 無法解析或核對回應 |
| 504 | CONTROL_COMMAND_TIMEOUT | 未在期限內取得回應 |
| 500 | DEVICE_TEST_ERROR／DEVICE_STATUS_ERROR | 未預期錯誤，結果未確認 |
| 499 | 請求取消 | 程式嘗試回傳，客戶端可能已無法收到 |

由 Controller 處理的錯誤使用 code、message、traceId。
來自服務結果的錯誤另包含 succeeded=false、outcome、isSimulated；Controller 依結果代碼映射 HTTP。
ASP.NET 自動模型驗證的 400、驗證／授權中介層的 401／403、取消時的 499，不保證是同一 JSON 格式；前端有 fallback 訊息。
502 不等於硬體壞掉；不能只靠一次失敗判定正在啟動。
開門逾時、連線中斷或無法核對回應時，結果可能不明，應先確認現場，不能直接重送。
查詢失敗只表示本次狀態未確認。

## 9. UI 行為

位置：System Settings → Device Test。
提供測試連線、進入／Enter、出去／Exit 三個按鈕。
不會載入頁面就自動查詢，也不輪詢。

開門結果區顯示待命、送出中、成功、錯誤／結果不明及 Trace ID。
查詢結果區顯示查詢中、成功、失敗及 Trace ID。
每次新查詢先清除上一筆成功狀態，避免把舊結果誤認為目前結果。
最近一次查詢時間：

- 成功使用後端 checkedAt。
- 查詢未成功時顯示前端記錄的發起時間。
- 使用 Asia/Taipei 顯示到秒，與設備回報時間分開標示。

查詢成功時顯示控制器序號、設備時鐘與有效門狀態。
查詢失敗不永久封鎖開門按鈕；只在請求執行期間互斥，也不自動觸發開門。
畫面說明測試連線不會開門、開門不等於通行，且測試不扣堂。
成功訊息顯示 Mock 模擬或 Real 真實設備；模擬時間與門狀態標示不是設備資料。
HTTP 錯誤有 outcome 時，依 Failed／Unknown 顯示結果；缺少時維持保守的未知結果提示。

## 10. 診斷日誌

CloudServer Client 記錄：

- 方法、ControllerSN、DoorNO（查詢時無值）、RPC id、HTTP 狀態與 ActivityId。
- 廠商白名單欄位：reply id、ControllerSN、success、code、msg、Reason、JSON-RPC error code／message。
- 逾時、連線與 JSON 解析錯誤。

Controller 記錄操作者、方向（開門）、結果、耗時、TraceId 與 ActivityId。
Controller 另記錄 IsSimulated；Real request 標示 Mode=Real，Mock 記錄 synthetic／no hardware command dispatched，不產生廠商 HTTP 日誌。
TraceId 與 RPC id 是不同識別碼；可透過 ActivityId 串聯 API 與廠商呼叫日誌。
不記錄登入 token、整包回應、LastSixRecords 或 ReturnPacket。
指定診斷欄位只記錄純量、移除 CR/LF、長度限制 1024 字元；超長加上截斷標示。
日誌依目前 logging provider 輸出，尚未新增專用持久化檔案／資料庫稽核。
F12 Response 保持簡化的錯誤訊息，原始 msg／Reason 在後端日誌查閱。

## 11. 驗證狀態與未完成事項

最近驗證結果：

- 後端 DeviceTestTests＋TurnstileModeTests：50 項通過（本次模式與結果契約測試）。
- 前端 Device Test API 測試：13 項通過。
- 共用 API 元件回歸：註冊 5 項、會員列表 6 項通過；會員列表測試有 Node MockTimers 實驗性警告，不影響通過。
- 前端型別檢查、建置及 Git 差異格式檢查通過。
- 測試使用假 HTTP 回應，不操作真實控制器或資料庫。
- 後端驗證使用獨立暫存輸出，不停止既有服務。
- 授權測試包含 Admin 標記／操作者檢查；不將它視為完整登入與 HTTP 授權端到端驗收。
- 尚未完成瀏覽器互動自動化驗收及完整現場硬體驗收。

使用者已觀察到：Docker 啟動後稍等，控制可成功。這是現場觀察，不是固定等待秒數的規格。
使用者另已回報板子控制驗證成功；不將這份回報擴大為完整實際通行／扣堂／部署驗收。
尚待現場確認：進出方向、控制器在線／斷線查詢、啟動初期回應、設備時間、錯誤日誌。

本版暫不處理：

- Docker starting／healthy／unhealthy 判斷、Healthcheck 與啟動等待流程。
- 自動輪詢、連線恢復與開門自動重試。
- 三叉機實際轉動／通行完成偵測。
- 客人電話識別、會員資格、扣堂、進出紀錄。
- 多控制器、多後端實例的分散式互斥及持久化防重複。
- 正式內網防火牆、NAS 部署、自動啟動、備份與斷電恢復。

## 12. 主要程式位置

後端：

- src/gym-system.Api/Controllers/DeviceTestsController.cs
- src/gym-system.Api/Contracts/Devices/DeviceTestRequest.cs
- src/gym-system.Api/Program.cs
- src/gym-system.Application/DevicesUseCase/TurnstileSettings.cs
- src/gym-system.Application/DevicesUseCase/TurnstileCommandResult.cs
- src/gym-system.Application/DevicesUseCase/SendDeviceTestCommandHandler.cs
- src/gym-system.Application/DevicesUseCase/GetDeviceTestStatusHandler.cs
- src/gym-system.Infrastructures/Devices/CloudServerTurnstileClient.cs
- src/gym-system.Infrastructures/Devices/MockTurnstileCommandClient.cs
- src/gym-system.Api/Devices/TurnstileServiceRegistration.cs
- tests/gym-system.Api.Tests/DeviceTestTests.cs
- tests/gym-system.Api.Tests/TurnstileModeTests.cs

前端：

- presentation/pages/admin/SettingsPage.tsx
- presentation/components/admin/DeviceTestSettings.tsx
- infrastructure/api/deviceTestApi.ts
- infrastructure/api/apiClient.ts
- tests/deviceTestApi.test.mjs

參考：

- C:/Users/HarryLin/Desktop/註冊 APP 專案/webapi-en/jsonCommand.pdf
- C:/Users/HarryLin/Desktop/註冊 APP 專案/webapi-en/Readme.pdf
- D:/HarryLin/Tool/DoorControlTool/DoorControlTool/Form1.cs
- 廠商 Vw3000.en/Vw3000/wgcomm/m1002CloudServerWEBAPI.py（只讀核對，未修改）

## 13. 共用服務結果契約

OpenDoorAsync 與 QueryStatusAsync 都回傳 TurnstileCommandResult。呼叫端只依賴 ITurnstileCommandClient，不需要知道底層模式。

| 欄位 | 定義 |
|---|---|
| Outcome | Succeeded／Failed／Unknown |
| Succeeded | 由 Outcome == Succeeded 推導，不可獨立設定，避免矛盾 |
| IsSimulated | 模擬實作為 true，Real 為 false；用於 UI／日誌辨識，不用於會員資格判斷 |
| Code | COMMAND_ACCEPTED、STATUS_QUERY_SUCCEEDED 或對應錯誤代碼 |
| Message | 結果說明；Mock 必須說明未操作實際設備 |
| Snapshot | 狀態查詢成功時提供 ControllerStatusSnapshot；開門或失敗時為 null |

結果意義：

- Succeeded：本次指令／查詢已確認成功；Mock 只代表模擬結果。
- Failed：廠商明確回報拒絕／失敗，或服務因無效目標拒絕發送。
- Unknown：逾時、HTTP／連線問題、回應無法解析或核對；不是「確定未開門」。

Controller 明確檢查 Succeeded；false 不回傳 HTTP 200 成功，也不執行後續成功流程。
HTTP 映射只在 API 層處理；共用結果模型不包含 HTTP 狀態碼。
Real 無自動 Mock fallback；取消不產生模擬成功，未預期錯誤不吞掉轉成成功。

未來呼叫端須先檢查結果，再決定業務流程；不得把指令成功自行視為實際通行完成或已符合扣堂時機。
