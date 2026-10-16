# 第二階段子計畫 01：裝置配對、換機、撤銷與授權保存

建立日期：2026-10-06。

狀態：2026-10-16 程式、前端配對流程與開發／測試 GymDB 已實作；正式部署與實機驗收待辦。

上層：[第二階段規劃](impelment_rule.md)。前提：[階段 01 IO-15](../01-會員識別與進場資格/impelment_rule.md)、[issue](../issue/gym-io-issues.md)。

## 1. 已確認目的與操作方式

- 初次進入 Check-In 頁面先檢查裝置授權；無有效授權時顯示配對碼輸入畫面。
- 使用後端固定的進場／出場配對碼，不先做後台產生／管理配對碼的功能。
- 配對碼只由後端驗證，不編譯進前端 JavaScript、不寫入網址或日誌；不是每次進出使用的裝置憑證。
- 配對後給瀏覽器独立授權，使用持久 Cookie；日常關機／再開機不要求每天重新配對。
- 配對碼決定對應站點，進／出方向由後端站點設定決定。
- 每個站點同時只允許一份有效授權；新機確認配對後取代舊機，舊機後續請求被拒絕。
- 裝置不取得 Admin 權限；客人仍只輸入電話識別，不登入帳號，不取得會員 JWT。
- 固定碼被知道後，其他瀏覽器仍可能配對並取代現場設備；撤銷某份授權不是禁止該實體機器再次配對。限制來源、嘗試次數及外洩處理需設計。

## 2. 初次啟用與換機流程

1. 頁面向後端查詢目前瀏覽器授權。有效則顯示該站點的電話輸入畫面，無授權／已失效才顯示配對畫面；網路失敗顯示連線錯誤，不誤認為需要換機。
2. 配對碼送後端驗證，取得站點及是否有舊授權的資訊；此預覽步驟不建立正式新授權、不撤銷舊授權。
3. 有舊授權時，顯示「確認取代目前站點裝置」；使用者取消則原裝置不受影響。
4. 確認時後端重新驗證配對碼、站點啟用及預期的舊授權版本，鎖定站點，開始交易。
5. 將舊 Active 授權標記撤銷（已到期者可轉 Expired），建立新 Active 授權，更新站點目前授權，全部成功才提交。
6. 提交後發出新的裝置 Cookie，顯示對應方向的客人操作畫面。
7. 若預覽後站點已被其他配對取代，回報衝突並要求重新確認，不默默再次取代。
8. 換機只變更裝置授權，不清除會員、館內狀態、出席、占用或票券資料，也不發送開門指令。

DB 提交與瀏覽器收到 Cookie 無法原子完成；提交成功但回應遺失、雙擊或重試時的恢復方式，列入第 9 節待設計，不以撤銷後必然順利取得 Cookie 作假設。

## 3. 授權機制與分層提案

- 後台既有 JWT 保留；API 另外增加裝置專用 Cookie 驗證 scheme，暫名 `GateDevice`，不更換全系統預設 JWT scheme。
- 採 ASP.NET Core Cookie Authentication 及 Data Protection 保護票據。Cookie 內含隨機 session ID 的受保護票據，不存固定配對碼，不給 Admin role。
- 每次進出請求查 DB 的站點／授權有效性，不只相信 Cookie 尚未到期。裝置識別與會員角色判斷是兩層不同流程。
- DB 只存授權識別及狀態，不存完整 Cookie 或可直接重放的明文票據。session ID 單獨不能認證；須先通過框架的票據完整性／解密驗證。
- 本提案不另混用「自訂明文 bearer token」方案。若之後改為 opaque token，需另設安全的憑證雜湊／驗證設計，不能只查 ID。
- API 層負責 Cookie 與 HTTP；Application 處理配對／換機／有效性；Domain 定義站點及授權；Infrastructure 用 Dapper／SQL 儲存及鎖定，沿用專案的 unit of work。
- 前端增加裝置專用 API 呼叫與授權狀態，不沿用 Admin JWT 自動刷新邏輯。

## 4. 資料表建議與共同格式

建議新增 `dbo.gate_station` 與 `dbo.gate_device_session`，不把設備當 users，不使用 sdt_profile 存設備授權。這是模型提案；建表前須查實際 schema 是否已有可復用表，本次沒有建立任何資料庫物件。

2026-10-16：兩表已透過保留既有物件的冪等腳本建立於開發／測試 GymDB，SQL 整合測試通過；其他環境尚未部署。DB 授權不自動到期，`expire_dt = NULL`，直到換機、撤銷或站點停用。

- 時間型別統一 `datetime2(3)`，保存後端 IClock 提供的台灣本地時間，格式範例 `2026-10-06 09:15:30.125`，不保存成顯示用字串。
- Cookie 協定及框架的 ExpiresUtc 使用 UTC 瞬間；與 DB 台灣時間需明確轉換，表示同一時刻，不直接把台灣 DateTime 當 UTC。
- 代碼用 varchar，中文名稱／理由用 nvarchar；GUID 用 SQL `uniqueidentifier`，不是 varchar GUID。
- DB 關聯先依 Database.md 的邏輯關聯方向設計，不新增 FK 約束；主鍵、唯一索引及值域 CHECK 屬本提案資料防線，需在 migration 設計時核准。
- 不用 GETDATE／SYSDATETIME 自動假設 DB 主機時區正確；業務時間由後端明確提供。

### 4.1 `dbo.gate_station`：固定進／出站點

| 欄位名稱 | SQL Server 型別 | NULL | 儲存格式／用途 |
| --- | --- | --- | --- |
| `gate_station_sn` | `int IDENTITY(1,1)` | 否 | 內部主鍵，如 1、2 |
| `gate_station_code` | `varchar(30)` | 否 | 唯一穩定代碼，如 `ENTRY_MAIN`／`EXIT_MAIN`；換 iPad 不改站點 |
| `gate_station_name` | `nvarchar(50)` | 否 | 中文名稱，如「大門進場站點」 |
| `gate_station_direction` | `tinyint` | 否 | `1`＝進場，`2`＝出場；後端決定，不相信前端指定 |
| `gate_station_is_active` | `bit` | 否 | `1`＝站點啟用，`0`＝停用；與單一授權撤銷不同 |
| `gate_station_current_session_id` | `uniqueidentifier` | 是 | 邏輯對應 session 的唯一 ID；未配對／撤銷目前授權後可 NULL |
| `gate_station_create_dt` | `datetime2(3)` | 否 | 建立時間，台灣本地時間 |
| `gate_station_up_dt` | `datetime2(3)` | 是 | 最後設定或目前授權變更時間 |

站點先配置進場與出場各一筆。固定配對碼以後端設定對應 station_code，不存此表；「固定」不代表應提交真實密碼至 Git。廠商控制器 SN／DoorNO 的映射於第二點控制指令另行定義，不在這裡猜測。

### 4.2 `dbo.gate_device_session`：每次配對的授權歷史

| 欄位名稱 | SQL Server 型別 | NULL | 儲存格式／用途 |
| --- | --- | --- | --- |
| `gate_device_session_sn` | `bigint IDENTITY(1,1)` | 否 | 內部流水號主鍵，歷史持續累積 |
| `gate_device_session_id` | `uniqueidentifier` | 否 | 後端產生且唯一的 GUID；對外字串可用 `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`，但 ID 本身不是憑證 |
| `gate_station_sn` | `int` | 否 | 邏輯關聯站點主鍵，不重複存方向 |
| `gate_device_session_status` | `varchar(20)` | 否 | `Active`／`Revoked`／`Expired` |
| `gate_device_session_previous_id` | `uniqueidentifier` | 是 | 新授權指向被取代的舊授權；首次配對為 NULL |
| `gate_device_session_create_dt` | `datetime2(3)` | 否 | 配對成功建立時間 |
| `gate_device_session_expire_dt` | `datetime2(3)` | 是 | NULL＝第一版 DB 授權不自動到期；保留未來期限能力 |
| `gate_device_session_last_seen_dt` | `datetime2(3)` | 是 | 最後有效請求時間，供狀態顯示；不作硬體身分證明 |
| `gate_device_session_revoke_dt` | `datetime2(3)` | 是 | 撤銷生效時間，Revoked 時應有值 |
| `gate_device_session_revoke_reason` | `varchar(30)` | 是 | 建議代碼 `Replaced`／`Manual`；Expired 不冒充人工撤銷 |
| `gate_device_session_revoke_by` | `nvarchar(50)` | 是 | 自動換機可記 `SYSTEM`，人工操作記實際操作者 ID；固定碼配對不能假裝已知道某位 Admin 身分 |
| `gate_device_session_remark` | `nvarchar(500)` | 是 | 說明，例如「新瀏覽器確認配對後取代」；不可存配對碼、Cookie 或會員電話 |
| `gate_device_session_up_dt` | `datetime2(3)` | 是 | 狀態／期限異動時間 |

Active 只是資料狀態，不代表無条件有效。完整有效條件：票據驗證成功、站點啟用、session 属於該站點、session ID 等於站點目前授權、狀態 Active，且 expire_dt 為 NULL 或尚未到期；任一不符即拒絕裝置操作。

last_seen 寫入頻率與可能的續期原子操作後續定義，不把每次請求都更新全部欄位當既定規格。

### 4.3 索引與約束建議

- `PK_gate_station`：station_sn 主鍵。
- `UQ_gate_station_code`：站點代碼唯一。
- `PK_gate_device_session`：session_sn 主鍵。
- `UQ_gate_device_session_id`：session_id 唯一。
- `UX_gate_device_session_active_station`：對 station_sn 建 filtered unique index，條件 `gate_device_session_status = 'Active'`。
- `IX_gate_device_session_station_create`：station_sn、create_dt，用於查看換機歷史。
- CHECK：方向只接受 1／2，授權狀態只接受 Active／Revoked／Expired，expire_dt 必須大於 create_dt，Revoked 需有 revoke_dt。

filtered index 不判斷「現在時間」：已到期但 DB 仍為 Active 的舊資料，在新配對交易中先轉 Expired／清理目前授權，再新增 Active。配合站點行鎖及目前授權指標，不能只先查再插入。

此處只有規劃，不提供已執行 migration 的保證；重跑建表／新增索引前須檢查舊資料及現有物件。

## 5. API 與頁面提案

名稱為提案，正式 request／response 於實作規格再對齊：

| API | 用途 | 授權邊界 |
| --- | --- | --- |
| `POST /api/v1/gate-devices/pairing-preview` | 驗證固定码、顯示站點及是否需換機確認 | 僅配對用途，限制來源／嘗試，不授予 Admin 或開門能力 |
| `POST /api/v1/gate-devices/pair` | 再驗碼、確認取代、建立 Cookie | 配對資料須通過後端驗證，交易中檢查預期舊授權 |
| `GET /api/v1/gate-devices/session` | 查目前授權及站點方向 | 有效裝置 Cookie；失效回傳授權错误，不作會員登入刷新 |
| `POST /api/v1/gate-devices/revoke` | 主動撤銷目前瀏覽器授權並清 Cookie | 僅能撤銷自身有效授權，不能任意撤銷其他站點 |

任意站點的管理撤銷需要獨立受保護的管理入口，介面是否第一版提供仍待確認；知道固定碼不代表可呼叫 Admin API。

前端狀態：檢查授權、輸入配對碼、換機確認、已授權電話輸入、連線錯誤。新機配對前不得因打開頁面就撤銷舊機。不要把完整 session 清單或 Cookie 內容回傳客人頁面。

## 6. 授權保存、撤銷與重啟

- 使用持久 Cookie，日常重開瀏覽器仍可帶授權；私密瀏覽、清網站資料、換瀏覽器／iPad 或授權到期可能需重新配對。
- 每次受保護進出請求都核對 DB；單純刪 Cookie 不等於撤銷資料庫授權。
- 已撤銷授權不能透過 Cookie 自動續期復活；新機取代舊機時，舊機 Cookie 即使未刪仍無效。
- DB 狀態需持久保存，Data Protection 金鑰也需持久保存並妥善保護，避免容器／服務重啟後全部舊 Cookie 無法解讀。
- Cookie 建議 Secure、HttpOnly；SameSite、Origin／CSRF 保護與允許來源依部署定義，不因只在內網就省略。
- 目前 CORS AllowAnyOrigin 不可直接當帶 Cookie 跨來源的正式設定；跨來源 credentials 必須使用明確允許來源，或以同源反向代理整合。部署方案仍待定。
- 撤銷阻止後續操作，不承諾能收回已發給廠商的開門指令；與控制流程再次檢查的時序需後續設計。

## 7. 實作結果與後續順序

1. 已完成 station／session repository、換機交易、唯一約束、DB 狀態查詢與 GymDB schema。
2. 已保留既有 JWT，另加入 GateDevice Cookie、每次 DB 重驗、來源檢查及配對限流。
3. 已完成配對預覽／確認／查狀態／自行撤銷 API 與前端配對門檻；知道配對碼不會取得 Admin 權限。
4. 已完成自動測試：錯碼、持久 Cookie、API 重啟、換機、舊 Cookie、撤銷、並行資料防線及 SQL rollback。
5. 待部署：以環境設定提供固定碼、絕對金鑰目錄與實際網址；HTTP 僅允許受控內網，不暴露外網。
6. 待實機：兩台 iPad 的瀏覽器保存、斷電重啟、實際換機及現場網路驗收。

## 8. 驗收案例

- 初次正確碼取得對應方向；錯誤碼不得配對或影響舊設備。
- 新機預覽／取消不撤銷舊機；確認成功只有新授權有效。
- 兩個瀏覽器同時確認不產生兩份 Active，預期版本過時回報衝突。
- 偽造 ID、方向、只有 Admin JWT 或沒有有效 Cookie 不繞過裝置驗證。
- 工作人員電話只作進場識別，不發放管理員 token。
- 舊 Cookie、新機取代、主動撤銷、站點停用及明確設定的到期，皆按各自狀態拒絕；第一版 DB 到期為 NULL。
- Cookie 關閉瀏覽器／關機再開機應維持；API 自動測試已確認持久金鑰可跨重啟讀取，iPad／NAS 仍待現場驗收。清除網站資料需重新配對。
- 資料庫或網路不可用顯示連線錯誤，不擅自開門／續期／換機。
- 配對提交後回應遺失不自動再次取代；使用者回到頁面先查目前 Cookie，未收到 Cookie 時重新走有明確換機確認的流程。

## 9. 尚待部署／後續擴充

- DB 授權不自動到期已確認；Cookie 為一年傳輸期限並在有效使用時續簽，不等於 DB 到期。Safari 清理／限制 Cookie 時須重新配對。
- 固定碼外洩後需更換環境 secret；第一版已有同源限制與每來源每分鐘十次配對限流，正式網段／反向代理後仍需驗證來源 IP 行為。
- 自行撤銷已完成；任意站點的 Admin 管理撤銷入口後續實作。
- 配對預覽 token 五分鐘有效且含舊 session 版本；版本衝突需重新確認，不默默覆蓋。
- 已授權同站點瀏覽器重輸同碼保留原 session，不新增歷史或自我撤銷。
- 第一版內網 HTTP 已確認，因此 Cookie 無法使用 Secure；以同源 `/api`、HttpOnly、SameSite=Strict、Origin／Sec-Fetch 檢查補強。未來能改 HTTPS 時應啟用 Secure。
- GymDB schema 已完成；正式 NAS／其他 DB 仍須執行同一腳本並核對結果。
- 控制器 SN、DoorNO、兩台 iPad 與 Data Protection 金鑰目錄須現場驗收，不能由自動測試宣告硬體完成。

後台電話登入安全議題仍獨立待辦，不擅自更改客人的電話進出需求。此文件的「已完成」只指程式、自動測試及開發／測試 GymDB；不包含現場設備或正式部署驗收。

## 10. 技術依據

- 持久 Cookie、指定 scheme、Data Protection 及 ValidatePrincipal 的 DB 狀態驗證，參考 [Microsoft Cookie Authentication 文件](https://learn.microsoft.com/en-us/aspnet/core/security/authentication/cookie?view=aspnetcore-10.0)。框架支援不代表本專案已完成設定。
- filtered unique index 的設計依據為 [Microsoft SQL Server filtered index 文件](https://learn.microsoft.com/en-us/sql/relational-databases/indexes/create-filtered-indexes?view=sql-server-ver17)，實際 migration 前仍需核對 schema 與既有資料。
