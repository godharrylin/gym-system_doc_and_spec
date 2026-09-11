# 票券異動歷程 Audit Log 設計待辦

整理日期：2026-09-11。

狀態：待確認、尚未實作。本文件記錄 `sdt_ticket_pass_audit_log` 的設計建議，不代表已建立資料表、trigger、查詢 API 或資料 migration。

## 目的與範圍

目前取消已付款後產生的續約票時，`sdt_ticket_pass` 只保留異動後的結果，無法直接從主表知道異動前的狀態。目標是保留每張票券成功提交後的完整版本，使系統能還原：

- 異動前後的 `valid_status`、`end_reason`、`ended_at`。
- 票券何時被建立、啟用、排隊、讓位、到期、用完或取消。
- 剩餘堂數、有效日期及其他票券欄位在每次異動後的值。
- 操作者及同一次異動的識別資訊。

本功能只記錄 pass 生命週期。取消 pass 不等於退款；目前取消 pass 不會把 `order_items_payment_state` 從 `Paid` 改成 `Cancel`。若未來要支援退款或取消付款，應另外定義 order／order item 規格及 audit 行為。

## 已確認的目前狀況

- GymDB 尚無 `dbo.sdt_ticket_pass_audit_log`。
- `dbo.sdt_ticket_pass` 目前沒有 trigger。
- 取消續約票的 SQL 會寫入：
  - `valid_status = 'Cancelled'`
  - `end_reason = 'Cancelled'`
  - `ended_at = 取消時間`
  - `update_dt = 取消時間`
  - `update_pn = 操作者`
- 正式值名稱是 `Cancelled`，不是 `Canceled`。
- 目前只允許取消 `UnActive` 續約票，因此正常取消歷程應為 `UnActive -> Cancelled`。
- 票券還會因啟用、到期、用完、單堂票讓位及排隊票啟用而更新，audit 不應只處理取消一種 UPDATE。
- 現有 `order_audit_logs` 採每個欄位一筆 `old_value/new_value` 的模型，目前沒有 DB trigger；不建議將完整票券版本直接混入該表。

## 建議採用的模型

採「每次異動完成後保存完整快照」：

| audit_log_sn | audit_action | pass_sn | valid_status | end_reason | 說明 |
| ---: | --- | ---: | --- | --- | --- |
| 101 | CREATE | 25 | UnActive | null | 建立排隊票 |
| 102 | UPDATE | 25 | Cancelled | Cancelled | 取消票券 |

第二筆的原始值就是同一 `pass_sn` 的前一筆版本。查詢可透過 `LAG()` 依 `audit_log_sn` 取得 `previous_valid_status`、`previous_end_reason` 等前一版欄位，不必在每筆資料重複保存整組 `old_*` 與 `new_*` 欄位。

第一版建議保存異動後版本：

- INSERT：保存建立完成後的版本，`audit_action = CREATE`。
- UPDATE：保存更新完成後的版本，`audit_action = UPDATE`。
- DELETE：保存刪除前的最後版本，`audit_action = DELETE`。
- 既有資料初始化：保存導入 audit 當下的版本，`audit_action = BASELINE`。

## 建議資料表欄位

### Audit 中繼欄位

| 欄位 | 建議型別 | 用途 |
| --- | --- | --- |
| `audit_log_sn` | `BIGINT IDENTITY` | Audit table 唯一主鍵及版本排序依據 |
| `audit_action` | `VARCHAR(10)` | `CREATE`、`UPDATE`、`DELETE`、`BASELINE` |
| `audit_at` | `DATETIMEOFFSET(3)` | 真實異動時間，輸出時可明確保留 `+08:00` |
| `audit_operator_id` | `VARCHAR(50) NULL` | 操作者；第一版可取 `update_pn` 或 `create_pn` |
| `audit_batch_id` | `UNIQUEIDENTIFIER` | 同一 SQL statement 或未來跨表操作的關聯識別 |
| `audit_source` | `VARCHAR(30) NULL` | 例如 `API`、`BATCH`、`MANUAL_SQL` |
| `audit_event` | `VARCHAR(50) NULL` | 例如 `PASS_CANCELLED`、`PASS_ACTIVATED`；第一版可先保留 null |

`audit_at` 建議使用 `DATETIMEOFFSET`，不要使用沒有時區資訊的 `GETDATE()` 作為稽核時間。由 SQL Server 以明確的台灣時區產生，避免依賴 DB 主機當下設定。

### 票券完整快照欄位

保留主表目前所有欄位名稱及相容型別：

- `pass_sn`
- `create_dt`
- `pass_id`
- `order_items_sn`
- `orders_sn`
- `owner_id`
- `ticket_plan_kind_code`
- `ticket_plan_kind_type`
- `renewed_from_pass_sn`
- `valid_status`
- `valid_sdate`
- `valid_edate`
- `ended_at`
- `end_reason`
- `credits_total`
- `credits_remaining`
- `create_pn`
- `update_dt`
- `update_pn`

不能讓 audit table 與主表完全採用相同定義：

- Audit table 的 `pass_sn` 會重複，不能作為 PK 或 UNIQUE。
- 主表的 `pass_id` 是 persisted computed column；audit table 應使用普通 `VARCHAR(24)` 保存當時值，不能重新計算。
- 主表的 FK、unique constraint、filtered unique index 不能複製到 audit table，否則同一票券無法保存多個版本。
- Audit table 以 `audit_log_sn` 作為唯一主鍵。

### 建議索引

- `(pass_sn, audit_log_sn DESC)`：取得單張票券完整歷程與前一版。
- `(owner_id, audit_at DESC)`：依會員查詢票券異動。
- `(orders_sn, audit_log_sn DESC)`：依訂單查詢票券異動。

先依實際查詢需求建立必要索引，避免複製主表所有索引造成每次異動額外寫入成本。

## Trigger 設計要求

建議建立一支 `AFTER INSERT, UPDATE, DELETE` trigger，例如 `trg_sdt_ticket_pass_audit`。

實作要求：

- 必須用 `inserted`／`deleted` 做 set-based INSERT，支援一個 statement 同時影響多張票。
- INSERT 與 UPDATE 從 `inserted` 保存版本；DELETE 從 `deleted` 保存最後版本。
- 所有欄位使用明確欄位清單，不使用 `SELECT *`。
- 同一個 statement 影響的多張票共用同一個 `audit_batch_id`。
- Trigger 與主表異動在同一 transaction；主表操作 rollback 時，audit 也必須 rollback。
- Trigger 寫入失敗時，主表異動也失敗，確保不允許「主表成功但歷程缺失」。需搭配錯誤監控。
- Audit table 本身不再建立相同 trigger，避免遞迴。

目前每個票券 UPDATE 都會同步更新 `update_dt/update_pn`，可視為有意義的版本。是否要忽略真正的 no-op UPDATE，可待看到實際發生頻率後再決定；第一版不必先增加複雜的全欄位比較。

## 既有票券 BASELINE

只建立 trigger 而不建立 baseline，既有票券第一次 UPDATE 時只會保存更新後版本，仍無法得知更新前內容。因此建議 migration 在受保護的同一部署交易內：

1. 建立 audit table。
2. 對目前所有 `sdt_ticket_pass` 建立一筆 `BASELINE` 快照。
3. 建立 trigger。
4. 驗證主表筆數與 baseline 筆數一致。
5. Commit。

部署時需避免步驟 2～3 之間仍有票券異動；可使用適當鎖定或維護窗口。Baseline 代表「啟用 audit 時看到的狀態」，不能宣稱它是票券最初建立狀態。

## 操作者、事件與 batch

第一版可使用：

- CREATE：`audit_operator_id = create_pn`
- UPDATE：`audit_operator_id = update_pn`
- DELETE：若沒有額外 context，只能取得被刪資料最後一次的 `update_pn`，不一定是刪除者

Trigger 只能看到資料前後值，無法可靠知道 UPDATE 是由取消 API、自動到期、單堂票讓位或人工 SQL 觸發。若未來需要精確的 `audit_event`、真正刪除者，或讓 pass、order、order item 共用同一 `batch_id`，建議由應用程式在同一 DB connection／transaction 設定 SQL Server `SESSION_CONTEXT`：

- `audit_operator_id`
- `audit_batch_id`
- `audit_source`
- `audit_event`

使用 connection pooling 時，必須在每次 transaction 開始時明確覆寫，在完成或失敗後清除，防止下一個 request 沿用前一個人的 context。這部分可以列為第二階段，不阻擋第一版快照歷程。

## 與 order_audit_logs 的關係

兩種表可以並存：

- `order_audit_logs`：欄位級 old/new，適合付款、金額等訂單變動。
- `sdt_ticket_pass_audit_log`：票券完整版本快照，適合生命週期還原。

若未來要追蹤「一次付款同時改動 orders、order_items、pass」或「一次取消同時改動多張表」，可使用相同 `audit_batch_id` 串聯，但需先統一兩邊 batch ID 的型別與應用程式傳遞方式。目前不需要為了新增 pass audit 立刻改寫既有 order audit。

## 查詢方式

取得某張票的歷程時，以：

```text
PARTITION BY pass_sn ORDER BY audit_log_sn
```

並使用 `LAG()` 產生前一版欄位。例如取消紀錄可呈現：

```text
previous_valid_status = UnActive
valid_status          = Cancelled
previous_end_reason   = null
end_reason            = Cancelled
audit_operator_id     = U...
audit_at              = 2026-09-11 ... +08:00
```

若 UI 經常需要 old/new 格式，建議建立 query service 或 view 計算，不在 audit table 冗餘保存兩份完整資料。

## 測試與驗收建議

### Trigger／SQL integration

- 新增一張 pass，恰好產生一筆 CREATE。
- 同一 statement 新增多張 pass，每張都有 CREATE 且共用 batch ID。
- `UnActive -> Active`、`Active -> Expire/Depleted`、`UnActive -> Cancelled` 各產生一筆 UPDATE。
- 單堂票 `Active -> UnActive` 讓位時保存堂數、付款關聯及 null 日期。
- 批次 UPDATE 多張 pass 不漏資料。
- 主表 transaction rollback 時不留下 audit。
- Trigger 故意寫入失敗時主表不可單獨成功。
- Baseline 筆數與 migration 當下主表筆數一致。
- 以 `LAG()` 查詢可正確取得取消前的 `UnActive/null`。
- DELETE 若納入範圍，保存最後版本及 DELETE action。

### 現有流程回歸

- 建票後立即 reconcile 可能在同一 transaction 產生 CREATE(UnActive) 與 UPDATE(Active)，順序正確。
- 取消後仍符合目前 filtered unique index 語意，可重新承接原續約來源。
- Audit 不參與 NEW_ONLY、RENEWAL 或目前可購買資格判斷，不改變既有商業規則。
- Audit table 新增不改變 pass 建立、取消、啟用、排隊與 profile snapshot 的 transaction 結果。

### GymDB 測試清理

現有 SQL 測試會建立並清除專屬 pass。Audit trigger 上線後，測試 fixture 必須：

1. 先保存本測試擁有的精確 `pass_sn`。
2. 刪除測試 pass；如果 DELETE trigger 產生 audit，待 trigger 完成後再清除這些測試 pass 的 audit。
3. 只依精確 `pass_sn` 加上既有 test marker／owner 驗證清理，不得清空 audit table。
4. 測試結束驗證本次 marker 的主表與 audit 殘留皆為 0。

正式環境的 audit 應為 append-only；上述刪除權限只供可控的開發／測試資料清理，不應授予正式應用程式帳號。

## 儲存與維運注意事項

- 完整快照會增加寫入量與儲存量，堂數每次扣除都可能新增一個版本；實作前應估算 pass 更新頻率及保留期限。
- 預設建議 audit 隨票券歷程長期保留，不因主表刪除而 cascade delete。
- 主表未來增加、移除或改型欄位時，同一個 migration 必須同步修改 audit table 與 trigger。
- 應監控 trigger 失敗、audit 寫入延遲及 audit table 容量。
- 不在 audit table 建立指向會被刪除之主表資料的強制 FK，避免歷史紀錄被主表生命週期限制。
- 若還需要保存「失敗的取消嘗試」，不可只靠 trigger；同 transaction rollback 會移除 audit，失敗嘗試應另用應用程式安全事件紀錄或 outbox/logging。

## 實作前待確認決策

建議預設採以下選項，確認後再建立 implementation plan 與 migration：

- [ ] 採完整版本快照；CREATE 及每次成功 UPDATE 各保存異動後版本，以 `LAG()` 取得原值。
- [ ] Audit table 包含主表所有快照欄位及額外 audit 中繼欄位，不要求 schema 完全相同。
- [ ] 對現有票券建立一次 BASELINE；既有主表資料本身不修改。
- [ ] 納入 DELETE audit，但正式業務流程禁止直接刪票。
- [ ] 第一版操作者取 `create_pn/update_pn`，`audit_event/audit_source` 可為 null。
- [ ] `SESSION_CONTEXT`、跨 `order_audit_logs` 共用 batch ID 列第二階段。
- [ ] Audit 只供歷程與查核，不納入本次 NEW_ONLY、RENEWAL 等購買資格。
- [ ] 明確定義正式保存期限及可查詢 audit 的權限角色。

## 建議後續步驟

1. 先確認本文件最後一節的設計決策。
2. 另建 implementation plan，列出 migration、trigger、query service／API、測試 fixture 及 rollback script。
3. 先在 GymDB 以專屬測試 pass 驗證 trigger 與 transaction，不直接拿既有票券做破壞性測試。
4. 驗證完成後才決定是否提供 UI 歷程查詢；建立 audit table 與建立查詢 API 可拆成兩階段。
