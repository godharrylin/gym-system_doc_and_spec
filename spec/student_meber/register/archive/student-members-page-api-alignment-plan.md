# 會員列表 API 與註冊後刷新實作計畫

> 封存日期：2026-10-02。本文件為已被新版取代的早期規劃，供追溯；請依 [現行學員列表規格](../../search_studentList/current/student-member-list-spec.md) 與 [實作狀態](../../search_studentList/current/student-member-list-implementation-status.md) 判斷當前功能及待辦。

> 2026-09-23：本文件保留早期規劃脈絡；本階段已依 [學員列表原實作計畫（現已封存）](../../search_studentList/archive/01-student-member-list-implementation-plan.md) 實作，以下舊 contract、每頁 20 筆與待確認條目不再作為現行依據。完成與延後範圍見 [實作狀態](../../search_studentList/current/student-member-list-implementation-status.md)。新會員高亮另列後續，不保證新會員出現在第 1 頁。

整理日期：2026-09-19。

來源：由 `current/registration-implementation-status.md` 的會員列表串接相關未完成項目提取。

## 1. 目標

完成 Students & Members 頁面的正式資料串接，使註冊成功後回到會員列表時，可以從後端重新取得會員資料，並能看到剛註冊的會員。

本計畫處理的是註冊流程完成後的列表顯示問題，不改變註冊 API 本身。

## 2. 範圍

本次實作範圍：

- 建立後端會員列表查詢 API 規格與實作。
- 定義會員列表 response contract。
- 支援 Students & Members 頁面目前需要的基本欄位。
- 前端 `StudentListPage` / `useStudentListViewModel` 改接後端 API。
- 註冊成功導回 Students & Members 後，重新載入正式會員列表。
- 評估並實作新註冊會員的高亮提示。

本次不處理：

- 註冊成功後導到新會員詳細頁。
- 多會員註冊 UI。
- 家庭或多受益者購票流程。
- 操作者 audit。
- 後台登入密碼、OTP 或完整權限模型。
- 獨立手機查重 API。

## 3. 後端 API 建議

建議新增：

```http
GET /api/v1/students
```

授權：

- 需登入。
- 第一階段建議限制 `Admin` role。

查詢參數建議：

```text
page
pageSize
keyword
status
ticketStatus
```

第一版可以先支援 `page`、`pageSize`、`keyword`，其餘篩選可保留 contract 或延後實作。

## 4. Response Contract 建議

建議回傳分頁格式：

```json
{
  "items": [
    {
      "studentId": "string",
      "name": "string",
      "phone": "string",
      "membershipStatus": "Active",
      "ticketSummary": "string",
      "lastVisitAt": "2026-09-19T10:30:00",
      "createdAt": "2026-09-19T09:00:00"
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalCount": 1
}
```

欄位注意事項：

- `studentId` 應使用前端選取會員詳細頁需要的 ID。
- `name` 與 `phone` 為列表基本顯示欄位。
- `membershipStatus` 需先確認目前資料表與現有 UI 的狀態命名是否一致。
- `ticketSummary` 第一版可用後端整理好的顯示字串，或改由前端依 pass 資料組合；實作前需確認。
- 時間欄位若用於 UI 顯示，應維持後端目前時間格式策略。

## 5. 前端調整

前端需要調整：

- 新增會員列表 API client，例如 `studentsApi.ts`。
- 新增後端 response 對應型別。
- 將 `useStudentListViewModel` 從 Mock / dashboard data 改成呼叫正式 API。
- 保留現有搜尋與篩選 UI，但資料來源改為後端或依第一版策略處理。
- 註冊成功回到 Students & Members 時觸發列表重新載入。
- 若實作新會員高亮，從註冊 response 的第一個 `memberId` 傳回列表頁並短暫標示。

## 6. 註冊成功後刷新策略

建議流程：

```text
註冊成功
→ 顯示「註冊成功」彈窗
→ 使用者關閉彈窗
→ 導到 Students & Members
→ StudentListPage 重新呼叫 GET /api/v1/students
→ 顯示最新會員列表
```

若實作高亮：

```text
註冊成功 response 取得 memberIds[0]
→ 導到 Students & Members 時帶入 recentlyCreatedStudentId
→ 列表載入後高亮該會員列
→ 高亮一段時間後自動取消，或使用者操作後取消
```

## 7. 待確認事項

- 會員列表第一版是否需要後端分頁，還是先回傳全部開發資料。
- 搜尋與篩選要由後端處理，或第一版由前端在已載入資料上處理。
- `membershipStatus` 要如何從目前票券 / pass / role 資料推導。
- `ticketSummary` 要由後端組字串，還是前端組 UI。
- 註冊成功後是否一定要高亮新會員，或第一版只要重新載入並顯示即可。
- 列表是否需要顯示未付款訂單或未啟用票券狀態。

## 8. 驗收條件

- Students & Members 不再依賴 Mock 會員資料。
- Admin 登入後可成功載入會員列表。
- 未登入或非 Admin 無法呼叫會員列表 API。
- 搜尋或分頁行為符合本階段確認的 contract。
- 完成註冊後關閉成功彈窗，畫面導到 Students & Members。
- 導回 Students & Members 後會重新載入會員列表。
- 剛註冊的會員可在列表中看到。
- 若本階段決定實作高亮，新會員列會被明確標示，且不影響一般列表操作。
