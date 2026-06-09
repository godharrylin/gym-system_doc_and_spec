# 前端事件流程 + 後端 API 規格

## 目標

`Schedule & Classes` 頁面進入後，預設進入「排課編輯模式」。

流程重點：

1. 先載入目前週次的實際排課。
2. 如果該週沒有實際排課，後端自動套用週排課模板，建立該週資料並回傳。
3. 使用者按「下一周」或「上一周」時，前端傳入新的 `weekStart`，後端依同樣規則處理。

## 前端事件流程

### 1. 進入頁面

1. 使用者點進 `Schedule & Classes`。
2. 頁面預設進入 `EDITOR`（排課編輯模式）。
3. 前端計算目前週的週一日期，作為 `weekStart`。
4. 前端呼叫後端：

```http
GET /admin/schedule/week?weekStart=2026-06-03
```

5. 後端回傳該週可直接顯示的課表資料。

### 2. 後端查詢邏輯

後端收到 `weekStart` 後：

1. 先查這一週是否已經有「實際週排課資料」。
2. 如果有，直接回傳。
3. 如果沒有，依週排課模板產生該週資料，寫入資料庫後回傳。

### 3. 點擊「下一周」

1. 前端把目前 `weekStart` 加 7 天。
2. 重新呼叫同一支 API，帶新的 `weekStart`。
3. 後端用同一套邏輯判斷是否要補資料。

### 4. 點擊「上一周」

1. 前端把目前 `weekStart` 減 7 天。
2. 重新呼叫同一支 API，帶新的 `weekStart`。
3. 後端回傳該週實際課表。

### 5. 儲存/修改排課

1. 前端對單筆課程做新增、修改、刪除或覆寫。
2. 前端送出對應 API。
3. 完成後重新載入目前週次資料。

## 建議的 API 規格

### A. 取得某週課表

```http
GET /admin/schedule/week?weekStart=YYYY-MM-DD
```

#### Query

- `weekStart`: 該週週一日期，格式 `YYYY-MM-DD`

#### Response

```json
{
  "weekStart": "2026-06-03",
  "weekEnd": "2026-06-09",
  "source": "REAL",
  "sessions": [
    {
      "sessionId": "sess_123",
      "scheduleId": "sch_1",
      "date": "2026-06-03",
      "dayOfWeek": 3,
      "startTime": "09:00",
      "classDefId": "def_1",
      "className": "Morning Yoga",
      "instructorId": "instr_1",
      "instructorName": "Sarah Connor",
      "duration": 60,
      "color": "bg-emerald-100 border-emerald-300 text-emerald-800",
      "isFree": false,
      "status": "ACTIVE"
    }
  ]
}
```

#### 行為

- `weekStart` 必須由前端傳入。
- 後端根據 `weekStart` 算出整週範圍。
- 若該週沒有實際資料，後端自動從模板建立後回傳。並將`soure` 訂為 `Template` 
- 這個 API 必須是 idempotent，重複呼叫不應產生重複資料。

### B. 取得週排課模板

```http
GET /admin/schedule/template
```

#### 用途

- 後台維護週模板時使用。
- 或作為 fallback / 管理介面資料來源。

### C. 建立或補齊某週資料

```http
POST /admin/schedule/week/ensure
```

#### Request Body

```json
{
  "weekStart": "2026-06-03"
}
```

#### Response

```json
{
  "weekStart": "2026-06-03",
  "created": true,
  "sessions": []
}
```

#### 建議

- 如果你想讓前端只打一次 API，建議把「查詢 + 補資料」合併成 `GET /admin/schedule/week`。
- 如果你想把「查詢」和「補資料」拆開，則前端先打 `POST /admin/schedule/week/ensure`，再打 `GET /admin/schedule/week?weekStart=...`。

## 日期傳遞建議

### 前端應該傳什麼？

建議前端傳：

- `weekStart`，格式 `YYYY-MM-DD`

不建議只讓後端自己猜「當周」。

### 為什麼要傳日期？

- 使用者可以看上一周、下一周，不一定是今天。
- 可以避免時區造成的日期誤判。
- API 行為會更可測試，也更容易重現問題。

## 我建議採用的最終做法

1. 前端進入排課頁時，先算出目前週一日期。
2. 前端把 `weekStart` 傳給 `GET /admin/schedule/week?weekStart=...`。
3. 後端判斷該週是否已有實際排課。
4. 沒有的話就從模板補齊並寫入資料庫。
5. 前端切換下一周/上一周時，重複同樣流程。

這樣可以把「資料存在不存在」的判斷集中在後端，前端只負責傳週次與顯示結果。

## 補充：編輯與儲存邏輯規格

  1. 前端編輯交互 (Edit UX)
   * 不需打 API：當使用者點擊 Grid 中的課程卡片時，前端直接從本地 state 中的 sessions 陣列（已包含 SessionOverride
     資訊）讀取該筆課程的現有屬性並填充至表單。
   * 資料一致性：編輯表單顯示的內容應優先採用 SessionOverride 的欄位值，若無異動則顯示 ClassDefinition 的預設值。

  2. 儲存異動 API 規格 (Save Change)
   * 行為：僅傳送「目前修改的那一筆」課程異動，而非整週資料。
   * API 路徑：POST /admin/schedule/session/override
   * 關鍵鍵值 (Primary Key)：必須包含 scheduleId 與 date。
       * scheduleId: 關聯的週排課模板 ID (rulesn)。
       * date: 該堂課發生的具體日期 (YYYY-MM-DD)。
   * 欄位說明：
       * 僅需傳送有異動或必要的欄位（如 instructorId, startTime, name, isCancelled 等）。
       * 後端應根據 scheduleId + date 進行 UPSERT 操作。

  3. 刪除/取消邏輯
   * 取消單堂課：前端送出 isCancelled: true 的 Override 請求，後端保留該紀錄並將狀態標記為取消。
   * 還原預設：若使用者點擊「還原」，則刪除該 scheduleId + date 的 Override 紀錄。
