# Students & Members 現行規格

整理日期：2026-10-02。規則依 2026-09-23 已確認且已實作的列表／編輯範圍整理；本次僅整理文件。

- 完成、測試及未完成清單：[實作狀態](student-member-list-implementation-status.md)。
- 原始實作脈絡：[封存計畫](../archive/01-student-member-list-implementation-plan.md)。
- 後續排程：[待確認計畫](../implement_plan/02-ticket-pass-lifecycle-scheduler-plan.md)。

## 1. 功能範圍與資料來源

本階段支援 Admin 操作學員列表、姓名／電話搜尋、狀態篩選、分頁與姓名／電話編輯。

| 資訊 | 來源／規則 |
| --- | --- |
| 學員範圍 | sdt_profile 有資料，且 EXISTS 確認同一使用者具有 Student 角色 |
| 姓名／電話 | users.usr_name、users.usr_phone |
| 顯示票券 | 從 sdt_ticket_pass 依下述規則選一張 |
| 方案名稱 | ticket_plan_kind.ticket_plan_kind_cname |
| 原始狀態／到期日 | 所選票券的 valid_status、valid_edate |
| 付款狀態 | 所選票券的 order_items_sn 對應 order_items.order_items_payment_state |

不額外排除停用使用者、停用角色、刪除或黑名單。只有 Admin／Instructor 角色者不列出；同時有 Student 角色且有 profile 者列出。角色資格使用 EXISTS，避免多角色關聯使列表重複。

本階段沒有新增資料表、欄位、索引或約束。StudentMemberListItem 是查詢 Model，不是資料表。電話不可重複，沿用 GymDB 已存在的 UQ_users_phone 作為併發防線。

## 2. Current Plan 選票

1. 有效 Active：valid_status = Active，且 valid_edate 為 null 或其台灣日期不早於台灣今天。
2. 有多張有效 Active 時，按 create_dt ASC、pass_sn ASC 選第一張。
3. 沒有有效 Active 時，按 create_dt DESC、pass_sn DESC 從全部票券選最新一張，包含 Cancelled。
4. 不直接使用 valid_status 字串自然排序決定選票優先順序。
5. 同一列的方案名稱、原始狀態、顯示狀態、到期日與付款狀態都來自同一張所選票券。
6. 完全沒有票券時，票券相关欄位回傳 null；前端依 currentPassId 是否存在判斷 No Ticket，VALID STATE／PAYMENT STATE 顯示「-」。名稱缺漏不等於沒有票券。

列表讀取票券狀態，不以查詢觸發下一張票啟用；單堂票的啟用讓位屬既有生命週期流程，不由本列表另行改變。

## 3. Valid State 與台灣日期

- validStatus 保留 DB 原值；displayValidState 為後端整理的顯示值。
- Expiring 條件：valid_status = Active、valid_edate 不為 null，且台灣今天 <= 到期日期 <= 台灣今天 + 7 天。
- 到期當天仍可顯示 Expiring。Expiring 本質仍是 Active，不寫入 DB。
- Active 篩選涵蓋 Active 與 Expiring；Expiring 篩選只取該子集合。
- DB 仍為 Active，但到期日期早於台灣今天時，displayValidState = Expire，且該票不作為有效 Active 選票。
- 其餘 displayValidState 使用原狀態：UnActive、Active、Expire、Depleted、Cancelled。
- 沒有到期日的單堂票不因日期顯示 Expiring；剩餘堂數 <= 2 不作為 Expiring 條件。
- 無票券不歸類為 Expire。
- 列表唯讀，不更新生命週期。排程尚未實作時，接受過期顯示已修正但下一張票可能仍為 UnActive 的過渡行為。

## 4. Payment State

- 只讀取所選 pass 對應的 order item；其他未付款訂單不影響這一列。
- 未付款訂單只建立 order／order item，付款後才建立 pass。一筆 order item 可對應多張 pass。
- 正常流程列表通常沒有 UnPaid；仍保留 UnPaid 篩選與排序，不改變建票流程以呈現未付款。
- Cancelled pass 對應 Paid 明細時照實顯示。取消票券使用權不等於退款，不因取消單張 pass 就取消整筆明細。
- 未付款訂單資訊屬詳細頁範圍。
- 沒有 order item 的 pass 屬資料異常，不猜測為 UnPaid，也不借用其他訂單的付款狀態。

## 5. 搜尋、篩選、排序與分頁

- 姓名或電話包含關鍵字即可；搜尋值先 Trim。
- 空白搜尋回傳全部符合範圍的學員，仍需分頁。
- SQL 參數化，LIKE 的特殊字元視為輸入文字，不作為使用者自訂萬用字元。
- 同類篩選 OR，不同類別 AND；後端先搜尋／篩選、再排序、最後分頁。
- 狀態順序：Expiring → Active → UnActive → Expire → Depleted → Cancelled → 無票券。
- 同一顯示狀態內，UnPaid 優先，其餘付款狀態同順位；最後以學員 ID 固定次序。
- 預設第 1 頁、每頁 15 筆。TotalCount 是分頁前符合條件的學員總數。
- 新會員依上述規則排序，不保證在第 1 頁；可用姓名／電話搜尋。

## 6. API 與 Model

兩支 API 均限 Admin。未登入回 401，非 Admin 回 403。

### 6.1 列表

GET /api/v1/students

| 參數 | 規格 |
| --- | --- |
| keyword | 選填，Trim 後最多 100 字 |
| page | 預設 1，必須 >= 1；拒絕造成 offset 溢位的值 |
| pageSize | 預設 15，允許 1–100 |
| validStates | 選填、多選；Active、Expiring、UnActive、Expire、Depleted、Cancelled |
| paymentStates | 選填、多選；Paid、UnPaid、Cancel |

多選使用重複 query key，例如 validStates=Active&validStates=Expire。非法參數回 400。

StudentMemberListResult 回傳 items、page、pageSize、totalCount。StudentMemberListItem 欄位：

| 欄位 | 語意 |
| --- | --- |
| id | users.usr_id |
| name、phone | 姓名、電話 |
| currentPassId | 所選票券 ID，可為 null |
| currentPlanName | 方案名稱，可為 null |
| validStatus | DB 原始票券狀態，可為 null |
| displayValidState | 顯示狀態，可為 null |
| validEndDate | yyyy-MM-dd 台灣日期，可為 null；不是 timestamp |
| paymentState | 同一張票的明細付款狀態，可為 null |

Application 查詢類別位於 MembersUseCase/Queries/GetStudentMemberList；SQL 實作位於 Infrastructure。前端資料流為 StudentListPage → useStudentListViewModel → StudentMemberListUseCase → ApiStudentMemberRepository → API。

### 6.2 編輯

PATCH /api/v1/students/{studentId}，body 為 name、phone。

- 目標需存在，且具備 Student 角色與 profile。
- 姓名／電話先 Trim，必填；姓名 1–50 字，電話 1–20 字。
- 只修改 users.usr_name、users.usr_phone；profile 沒有需同步的姓名／電話欄位。
- 查重排除自己；保留自己的電話可成功，使用其他人的電話則拒絕。
- 重用 UpdateBasicProfileAsync、ExistsPhoneForOtherUserAsync。註冊的「電話必須不存在」驗證保留原語意。
- 更新在交易內執行；DB unique 衝突轉為可辨識的重複電話錯誤。
- 成功 204，重複電話 409，找不到學員 404，非法輸入 400。
- 應用流程保留 OperatorId，預設 admin，不接受前端冒充操作者。永久稽核紀錄另行規劃。

## 7. 前端互動

- 輸入框立即更新，停止輸入 400ms 才呼叫搜尋 API；新輸入重計時，立即使舊請求失效。
- 取消舊請求並檢查版本，只有最新查詢可更新資料、錯誤與 loading。
- 搜尋／清空／篩選改變時回第 1 頁；翻頁與篩選直接查詢，不套用搜尋 debounce。
- 搜尋等待 400ms 及查詢載入期間停用翻頁；離頁清除計時與請求。
- 編輯成功刷新列表；失敗保留輸入並顯示原因，允許重試。
- 註冊成功關閉彈窗後導到 Students & Members；列表重新掛載並讀取 API。
- 載入、失敗、空結果分別處理，不把 API 失敗當作查無學員。
- 現有篩選按鈕為 Active、Expiring、Expired（送出 Expire）、Paid、Unpaid；Visited Today 保留但停用。
- LAST VISIT 顯示「-」；手動進場按鈕保留但停用。
- 購票／付款按鈕與姓名詳細頁入口保持現況，後續整合待討論。

## 8. 範圍外與驗收

生命週期排程、LAST VISIT、Visited Today、手動進場、詳細頁整合、新會員高亮、持久化稽核及退款／部分取消不在本階段已完成功能中。

自動測試與待人工驗收結果集中於實作狀態文件。核心驗收包括：Student/profile 範圍、選票排序與同時刻 tie-break、到期日今天／+7／+8／昨天／null、付款來源、全量篩選後分頁、特殊字元、搜尋競態、排除本人的電話查重、授權，以及列表不寫入票券狀態。
