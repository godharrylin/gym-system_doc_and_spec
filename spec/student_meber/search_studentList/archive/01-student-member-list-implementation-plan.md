# Students & Members 列表實作規劃

> 封存日期：2026-10-02。本文件保留原始規劃與當時實作狀態，供追溯；現行依據為 [列表規格](../current/student-member-list-spec.md) 與 [實作狀態](../current/student-member-list-implementation-status.md)。後續排程已提取至 [待確認計畫](../implement_plan/02-ticket-pass-lifecycle-scheduler-plan.md)，不再依本歷史計畫啟動新工作。

- 日期：2026-09-23
- 狀態：本階段列表／編輯已實作並通過自動測試與 HTTP 驗證；瀏覽器人工驗收及最後階段排程另列。詳見 [實作狀態](../current/student-member-list-implementation-status.md)。
- 範圍：學員列表、搜尋、篩選、分頁、姓名／電話編輯與刷新。
- 本文件整合本次討論；既有註冊文件中的會員列表規劃需於實作時對齊，避免維護兩套互相衝突的規則。

## 1. 資料表與架構

本階段依已檢查的程式與資料表文件，不需要新增或修改業務資料表。StudentMemberListItem 與分頁結果是查詢 Model，不是資料表；Expiring 不寫入資料庫。

| 資訊 | 來源 |
| --- | --- |
| 學員範圍 | sdt_profile，使用 EXISTS 確認具備 Student 角色 |
| 姓名／電話 | users.usr_name、users.usr_phone |
| 票券 | sdt_ticket_pass |
| 方案名稱 | 關聯方案資料，實作時確認名稱欄位與關聯 |
| 原始狀態／到期日 | valid_status、valid_edate |
| 付款狀態 | 所選 pass.order_items_sn → order_items.order_items_payment_state |

不額外套用停用、刪除或黑名單過濾。只有 Admin／Instructor 角色者不列出；同時具備 Student 角色且有 profile 者符合條件。EXISTS 用來檢查資格，避免角色關聯造成列表重複。

實作前確認既有索引、電話唯一性約束及實際關聯。若需新增索引／約束，先提出確切缺口，不將其視為已確認的 DB 改動。電話查重必須考慮同時更新的競態。

OperatorId 在應用流程保留，暫用 admin；這不等於永久保存異動歷史。若需要持久化操作者或修改前後值，另行確認既有欄位與稽核設計。

## 2. 已確認的列表規則

### 2.1 選票

1. 優先選有效 Active 票券：valid_status = Active，且 valid_edate 為 null 或不早於台灣今天。
2. 多張符合時以 create_dt ASC、pass_sn ASC 選一張。
3. 沒有有效 Active 時，從全部票券以 create_dt DESC、pass_sn DESC 選最新一張，包含 Cancelled。
4. 不直接用 valid_status 字串自然排序代替上述業務順序。
5. 沒有票券時，票券 ID、名稱、狀態、日期與付款狀態回傳 null。前端以票券不存在判斷 No Ticket；VALID STATE 與 PAYMENT STATE 顯示「-」。
6. 同一列的方案、效期、狀態與付款狀態必須來自同一張所選票券。

### 2.2 狀態與台灣日期

- 回傳 validStatus（DB 原值）與 displayValidState（顯示值）。
- Expiring 條件：valid_status = Active，valid_edate 不為 null，且台灣今天 <= valid_edate <= 台灣今天 + 7 天。
- 到期當天包含於 Expiring；Expiring 本質仍是 Active，不存入 DB。
- Active 篩選包含 Expiring；Expiring 篩選只取該子集合。
- DB 仍為 Active，但到期日早於台灣今天時，displayValidState 顯示 Expire，選票時不列為有效 Active。
- 原始狀態名稱使用現有 enum：UnActive、Active、Expire、Depleted、Cancelled；不要誤用 Expired 作為 DB 值。
- 沒有到期日的单堂票不因日期顯示 Expiring；移除前端「剩餘堂數 <= 2 即 Expiring」的判斷。
- 列表查詢維持唯讀，不觸發生命週期更新。使用者接受排程完成前只修正顯示、不保證下一張票已立即啟用的過渡行為。

### 2.3 付款狀態

- 完全依所選 pass 對應的 order item 取得，不混入學員其他未付款訂單。
- 現況：未付款只建立 order／order item；付款後才建立 pass。一筆 order item 可以對應多張 pass。
- 因此正常流程列表通常沒有 UnPaid；保留 UnPaid 篩選與優先排序，不為呈現未付款而改變建票流程。
- Cancelled pass 仍可能對應 Paid 明細，照實顯示；取消使用權不等於退款，不同步取消整筆可能對應多張 pass 的明細。
- 未付款訂單明細屬於學生詳細資訊範圍。
- 正常 pass 應有 order item；缺失屬資料異常，不應猜成 UnPaid 或用其他訂單補值。

### 2.4 搜尋、篩選與分頁

- 姓名或電話包含關鍵字即可；後端對搜尋值 Trim，使用參數化 SQL，將 SQL LIKE 萬用字元按一般輸入文字處理。
- 空白搜尋回傳全部符合範圍的學員，但仍分頁；每頁預設 15 筆。
- 後端先搜尋／篩選、再排序、最後分頁，TotalCount 為分頁前符合條件的學員數。
- 排序已確認：VALID STATE 優先，其次 PAYMENT STATE；Expiring 優先，同一狀態內 UnPaid 優先，再加穩定的學員 ID 次序。
- 完整順序已確認：Expiring → Active → UnActive → Expire → Depleted → Cancelled → 無票券。
- 同類篩選 OR、不同類別 AND，沿用現有前端語意。
- 無票券不歸類為 Expire。

## 3. 分層與 Model

建議 Application 目錄：

```text
src/gym-system.Application/MembersUseCase/Queries/GetStudentMemberList/
  StudentMemberListItem.cs
  StudentMemberListResult.cs
  GetStudentMemberListQuery.cs
  GetStudentMemberListHandler.cs
  IStudentMemberListQueryService.cs
```

- StudentMemberListItem 包含 id（users.usr_id）、name、phone、currentPassId、currentPlanName、validStatus、displayValidState、validEndDate、paymentState。票券相關欄位 nullable；validEndDate 為台灣日期 yyyy-MM-dd，不是 timestamp。
- StudentMemberListResult 包含 Items、Page、PageSize、TotalCount。
- SQL 查詢實作放 Infrastructure；對外契約依專案慣例放 Api/Contracts/Students。
- 列表 GET /api/v1/students，編輯 PATCH /api/v1/students/{studentId}，兩者限 Admin。
- 查詢參數：keyword、page、pageSize、validStates、paymentStates；多選使用重複 query key。page 預設 1，pageSize 預設 15、允許 1–100，keyword 最多 100 字。
- validStates 可用 Active、Expiring、UnActive、Expire、Depleted、Cancelled；paymentStates 可用 Paid、UnPaid、Cancel。前端目前保留 Active／Expiring／Expired（送出 Expire）與 Paid／Unpaid 按鈕。
- 編輯 request 為 name、phone，成功回 204；重複電話 409，學員不存在 404，非法輸入 400。應用層保留預設 admin 的 OperatorId，不接受前端冒充操作者。

前端資料流：StudentListPage → useStudentListViewModel → 查詢 UseCase → API Repository → 後端。列表直接使用後端投影，不再以完整 tickets 陣列自行選票或重新計算狀態。

## 4. 搜尋互動與刷新

1. 輸入框立即更新；連續 400ms 無新输入才更新正式查詢條件並呼叫 API。
2. 新輸入重新計時，立即使舊請求失效；API Repository 接收 AbortSignal。
3. 使用請求序號／版本檢查，只允許最新結果更新資料、錯誤與 loading，避免取消失敗或回應競態。
4. 搜尋改變回第 1 頁；清空也依 400ms 規則查全部的第 1 頁。
5. 翻頁與篩選直接查詢，不套用輸入 debounce；篩選改變回第 1 頁。
6. 已確認：輸入尚未穩定的 400ms 及查詢載入期間停用翻頁，避免使用舊關鍵字翻頁。
7. 元件離開時清除計時並取消請求。
8. 編輯成功重新查詢列表；註冊成功導入 Students & Members 後載入最新資料。
9. 明確處理載入、API 失敗、查無資料；不要將失敗顯示成查無學員。

## 5. 編輯姓名／電話

- 只修改 users.usr_name、users.usr_phone；目前 sdt_profile 沒有姓名／電話欄位需同步。
- 重用 IUserRepository.UpdateBasicProfileAsync 與 ExistsPhoneForOtherUserAsync。
- 原 UserValidationService 的「電話不存在」驗證適用註冊，保留原语意。編輯需排除本人，不得將原電話判為重複。
- 若集中至 Validation Service，新增明確的編輯驗證方法，內部使用既有 ExistsPhoneForOtherUserAsync，不必重寫 SQL。
- 後端驗證目標學員範圍、Trim 後的姓名／電話、重複電話、交易與錯誤回應；不能只依賴前端驗證。
- 應用流程保留 OperatorId，暫用 admin。編輯成功刷新列表。

## 6. 實作規劃表

| 順序 | 項目 | 完成條件 |
| --- | --- | --- |
| 1 | Model 與 API 契約 | 列表、分頁、搜尋與篩選契約明確；預設 15 筆 |
| 2 | 後端列表查詢 | profile + EXISTS Student、姓名／電話搜尋，不重複列出 |
| 3 | 選票與狀態 | 有效 Active 最早、否則最新含 Cancelled；無票券 null |
| 4 | 日期、篩選、排序、分頁 | 台灣日期；Expiring 為 Active 子集合；全量篩選後分頁 |
| 5 | 學員編輯 API | 重用更新／查重，排除本人，Admin 限制，錯誤可辨識 |
| 6 | 前端列表串接 | 取代列表 mock；依後端狀態、方案名稱與付款狀態顯示 |
| 7 | 搜尋與分頁互動 | 400ms、取消舊請求、最新回應防線、條件改變重設頁码 |
| 8 | 篩選與刷新 | 後端篩選；編輯與註冊後取得最新資料 |
| 9 | 驗證與文件對齊 | 通過下列驗收；更新完成／未完成狀態，不先宣告完成 |
| 最後階段 | 生命週期排程 | 另行細化排程設計後實作，不混入列表查詢副作用 |

## 7. 驗收重點

- 有／無 Student 角色與 profile 的組合；多角色不重複列出。
- 多張 Active 的建立時間順序；無有效 Active 時最新 Cancelled 仍顯示；同時間排序穩定。
- 無票券顯示 No Ticket／-，不歸入過期。
- 到期日為今天、+7、+8、昨天，以及 null；以台灣日期計算。Active 篩選包含 Expiring。
- Active pass 的 Paid 不受其他 UnPaid 訂單影響；Cancelled + Paid 照實顯示。
- 搜尋 Trim、空白、姓名／電話子字串、LIKE 特殊字元；結果超過 15 筆時搜尋／篩選及總數正確。
- 快速連續輸入、舊回應較慢、清空、翻頁、卸載：舊資料與舊 loading 不覆蓋新狀態。
- 編輯只改姓名、保留自己的電話成功；改用他人電話失敗；成功刷新、失敗保留可修正輸入。
- Admin 授權、非法輸入、API 失敗與空結果分別處理。
- 不因開啟列表而修改票券狀態或啟用下一張票。

## 8. 延後事項與排程方向

- LAST VISIT、Visited Today、手動進場延後。Visited Today 指台灣今天曾成功入場，不能直接以「目前在館內」isCheckedIn 代替。已確認：Visited Today 與手動進場按鈕保留但 disabled，不觸發動作；LAST VISIT 顯示「-」。
- 購票／付款按鈕、點姓名進詳細頁保持現況，記錄為之後需要討論的功能。
- 未付款訂單詳細資訊、退款／部分取消、操作者異動歷史不納入本次列表規劃。
- 排程使用者已要求最後處理。建議台灣跨日後執行、每 30 分鐘補查、服務啟動補查；具體頻率與部署機制尚待排程階段定案。
- 補查查所有已需處理的票券，不能只查昨天；以學員為交易單位，沿用鎖定與可重複執行的生命週期流程，完成結束／啟用／單堂票讓位／profile 更新。
- 保留購買、付款、取消等既有即時更新；扣堂後是否有完整即時串接需另查，不宣稱已完成。
- 既有其他查詢的生命週期副作用不在本次自動移除；新的學員列表維持唯讀。
