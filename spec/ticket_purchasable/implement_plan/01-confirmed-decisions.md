# 已確認決策

日期：2026-09-06。以下為討論後的目標規則，不代表現有程式已全部符合。

## D01：NEW_ONLY 的 30 天

- 採台灣日曆日，註冊當天算第 1 天，共 30 天。
- `assignedDate` 與 `today` 均為台灣日期，使用 `assignedDate >= today.AddDays(-29)`。
- 缺少註冊日期不得通過 NEW_ONLY。
- 例：2026-09-01 註冊，2026-09-30 全日仍可買；2026-10-01 00:00 起不可買。

資料庫 `user_role.user_role_cdt` 應儲存台灣本地時間；若未來有匯入、批次或舊資料，不保證來源時區時，需先轉成台灣日期再判斷。

來源時區未知時，必須先查明來源時間語意才能正確轉換，不可把所有舊資料直接當 UTC 加 8 小時。現行註冊程式透過 Taipei clock 寫入角色指派時間，不代表全部既有資料已查核。

2026-09-09 確認：保留現行註冊寫入流程；修正整合測試直接寫入 UTC 的方式。未來匯入／批次必須在寫入邊界依已知來源時區轉成台灣本地時間，再寫入 `user_role_cdt`；已為台灣時間不重複轉換。SQL 讀取及資格判斷不猜測來源、不自動加 8 小時。來源不明的新匯入資料先隔離／確認，不直接猜測寫入；既有資料無證據則保持原值，本次不做整批校正，也不宣稱既有資料已全數驗證。

## D02：NEW_ONLY 資格消耗依據

- 最終決定以 pass 紀錄及狀態判斷，不以 order item 目前是否非 `Cancel` 決定。
- 同一會員曾取得同 SKU 的 pass，即視為已使用該 SKU 新客資格。
- `UnActive`、`Active`、`Expire`、`Depleted`、`Cancelled` 均算曾取得；取消 pass 不恢復資格。
- 未付款且沒有建立 pass 的訂單不算已取得。
- 同家族但不同 SKU，不因這項同 SKU 歷史條件直接被排除，仍須通過其他資格。
- 錯帳／人工取消例外暫不支援。
- 未來 `order_audit_logs` 列為後續擴充，不納入目前資格判斷。

此決定取代先前「非 Cancel order item 即算買過」的版本。若 order item 狀態改變而 pass 仍存在，也不因此恢復 NEW_ONLY 資格。

## D03：註冊與既有會員共用資格驗證

- 保留 `registration-purchasable` 與會員 `purchasable` 兩支清單 API。
- 共用 `CanPurchaseAsync(context, plan, ct)`，由 Context 區分註冊與既有會員情境。
- 註冊情境排除依賴既有會員狀態的資格規則；新增資格規則預設不開放註冊情境。
- 最後決定：NEW_ONLY 明確不開放註冊情境；RENEWAL 也不開放。
- NEW_ONLY 可在註冊完成後，透過既有會員購買流程依 D01／D02 評估。
- 無資格限制的一般方案，仍可出現在註冊清單；其他上架與購買條件仍須符合。
- 多規則方案必須全部通過；只要其中一條不允許註冊情境，該方案就不開放註冊。

註冊附帶購票的流程也要傳遞註冊情境。即使流程中已建立 Student，不得因此切換成既有會員情境而放行 NEW_ONLY。實際購買與未付款訂單付款時，後端仍須重新檢查適用資格。

延後付款補充決策（2026-09-09 整理）：註冊流程建立 UnPaid 訂單時使用 Registration 驗證；註冊完成後延後付款，一律視為既有會員，使用付款當下的會員資格、最新 catalog 與方案價格重驗，歷史未付款訂單也適用。不為此新增訂單註冊來源欄位。UnPaid 不建立 pass、不占 queue；付款成功後才建立 pass 並依既有 Active／queue 規則啟用，不保證一律立即 Active。

## D04：HIDDEN

- HIDDEN 本身是「不顯示」的目錄規則，不是會員 eligibility rule。
- 一般購買 API 不支援 hidden 方案，透過共用 catalog 查不到方案來拒絕；不能只依賴前端隱藏。
- 未付款訂單付款時，同樣必須確認方案仍能從一般購買目錄取得。
- 暫不支援內部、客服或其他特殊 hidden 購買流程。

## D05：家庭購買暫停

- `FAMILY_ELIGIBLE` 目前完全不參與購買資格，不套用家庭折扣。
- 家庭相關資料與規則設定保留、不刪除、不套用；受益者維持剛好 1 人。
- 未來恢復家庭購買時沿用 `FAMILY_ELIGIBLE` rule code。
- 恢復時另處理家庭關係來源、多受益者全部通過、價格與退款、交易 rollback，以及付款時重驗；不屬於本次實作。

`FAMILY_ELIGIBLE` 是明確暫停的已知規則，不能和「未知資格規則預設拒絕」混為一談。

## D06：續約來源與取消重訂

### 來源選取

- 沿用最新同家族來源：已付款，pass 狀態為 `Active`／`Expire`／`Depleted`，有開始日，且服務層檢查開始日不晚於今天。
- 依 `valid_sdate DESC, pass_sn DESC` 選取一張，再檢查資格；不因這張不合資格而 fallback 到更舊來源。
- 來源本身為 `Cancelled` 或 `UnActive` 時不作來源。
- 若同家族 A 已超過續約期限，較新的 B 仍在期限內，應依 B 判斷，不能被 A 的舊期限阻擋。
- 有非取消 successor 時，來源不可重複承接。
- `Depleted` 來源使用 `endedAt` 對應台灣日期；其他來源使用 `validEndDate`。
- 來源原續約截止日為有效結束日加 9 天，截止日當天可買。
- 符合續約資格時，標準方案仍可買。

### 取消資格

- 本次實作維持目前取消範圍：僅允許 `UnActive` 續約票取消。
- `Active` 續約票即使沒有進場／核銷紀錄，本次也不開放取消；先前「未使用 Active 續約票可取消」的討論作廢。
- 取消後保留 `renewed_from_pass_sn`，票券狀態與結束原因記為 `Cancelled`，記錄取消時間。
- 堂票若曾產生 Consume 使用紀錄，即視為已使用，不因後續 Reverse／沖銷使剩餘堂數回復而恢復取消資格；此規則先寫入商業規格，Active 取消不納入本次實作。

### 重訂期限

```text
originalRenewalDeadline = sourceEffectiveEndDate.AddDays(9)
retryDeadline = Min(cancelledDate.AddDays(1), originalRenewalDeadline)
可重訂日期必須不晚於 retryDeadline
```

所有日期均為台灣日曆日。取消當天及隔天可重訂，但不能延長原續約截止日；不是固定 24 小時，也不是只允許取消當天。

| 取消時間 | 原續約截止日 | 最後可重訂日期 | 起始拒絕時間 |
| --- | --- | --- | --- |
| 9/5 23:50 | 9/5 | 9/5 | 9/6 00:00 |
| 9/5 23:50 | 9/6 | 9/6 | 9/7 00:00 |
| 9/5 23:50 | 9/10 | 9/6 | 9/7 00:00 |

允許期限內重複取消、重訂，但不能超過來源原續約截止日，也不能同時有多張非取消 successor。取消期限失效後，不因原來源仍在一般 grace window 內就重新放行該取消重訂；標準方案仍依其一般資格評估。

## D07：單堂票讓位與 enum

- 維持每位會員全域最多一張 Active，不改成每家族各一張。
- 有可啟用的非單堂票時，優先使用非單堂票。
- 已 Active 的單堂票讓位時回到 `UnActive`，保留剩餘堂數。
- 沒有其他可啟用的非單堂票時，再使用單堂票；不能因存在尚未可啟用的非單堂票就停止使用單堂票。
- 排隊中的單堂票不構成一般續約的 queue 衝突。
- 單堂票之間沿用付款時間、pass 編號排序，讓位不重設原順位。
- 讓位不表示結束，不寫入 `ended_at`／`end_reason`；單堂票開始日與結束日維持 null。
- 非單堂票保留既有續約承接優先及其餘 FIFO；單堂票讓位不表示其他 Active 非單堂票也可被插隊。

現有程式 enum 的名稱及數值如下，實作不應改成 `Unactive`、`Expired` 或 pass `Cancel`：

| TicketValidStatus | 數值 | 意義 |
| --- | --- | --- |
| UnActive | 1 | 未啟用／排隊，亦包含讓位後的單堂票 |
| Active | 2 | 目前啟用 |
| Expire | 3 | 已過期 |
| Depleted | 4 | 已用完 |
| Cancelled | 5 | 已取消 |

| TicketEndReason | 數值 | 意義 |
| --- | --- | --- |
| Expire | 1 | 因到期結束 |
| Depleted | 2 | 因用完結束 |
| Cancelled | 3 | 因取消結束 |

`end_reason` 未結束時可為 null。order item 的付款狀態 `Cancel` 與 pass 的 `Cancelled` 是不同 enum／欄位，不互換。

## D08：rule 分類與 catalog 輸出

- `plan_rule` 繼續作為方案規則來源，不先新增資料表或 schema。
- 採程式集中分類方式，例如 `RulePolicyRegistry`。這是技術命名建議，不要求實作名稱完全相同。
- `Tags` 給 UI 顯示，可包含 `NEW_ONLY`、`RENEWAL`、`FAMILY_ELIGIBLE`、`HIDDEN`。
- `EligibilityRuleCodes` 只放目前真的要執行購買資格驗證的規則；目前目標為 `NEW_ONLY`、`RENEWAL`。
- `HIDDEN` 是 catalog/display rule，不進 eligibility；一般購買 catalog 查不到 hidden 方案。
- `FAMILY_ELIGIBLE` 是已知暫停規則，不進 eligibility，也不套用折扣。
- 新增 rule code 時必須先分類。若是購買資格規則但沒有 handler，後端不得默默放行。

實作時要注意：`Tags` 不能作為後端購買資格依據；`EligibilityRuleCodes` 不能漏掉真正限制購買的規則。若未來資料維護需要讓營運人員直接管理分類，再另行評估在 DB 增加 rule purpose 欄位。

## D09：前端日期與票券購買紀錄時間

- 可購買資格、續約期限、NEW_ONLY 30 天均以後端台灣日曆判斷為準。
- 前端不自行判斷票券是否可買，只顯示後端 API 結果。
- 票券購買紀錄顯示需要到秒；後端應輸出 timestamp 到秒，建議帶明確台灣 offset，例如 `2026-09-06T14:23:45+08:00`。
- 本次採新增 API contract 欄位，不調整資料表欄位；保留既有 `paidAt` 日期字串，新增 `paidAtTimestamp`。
- 前端顯示 timestamp 時固定使用台灣時區格式化。
- 前端不得用 `toISOString().split('T')[0]` 推導台灣日曆日；此類調整優先級可放到後續前端對齊階段。

日期型別需分清楚：業務日曆日使用 `yyyy-MM-dd`；真實時間點使用帶秒 timestamp。前端不要把 `yyyy-MM-dd` 再轉成 `Date` 後切 UTC 日期。

## D10：續約資格與單堂票關係

- 續約資格只看來源票與重訂期限。
- 單堂票只影響啟用順序，不應阻擋續約購買。
- 排隊中的單堂票不構成續約 queue conflict。
- Active 單堂票若遇到可啟用的非單堂票，應讓位回 `UnActive`；這是生命週期排序，不是購買資格拒絕原因。

因此，第 7 項實作要拆成兩個判斷層次：購買資格層處理來源票、原續約截止日、取消重訂期限與 successor；生命週期層處理 Active slot、單堂票讓位與 queue 啟用順序。
