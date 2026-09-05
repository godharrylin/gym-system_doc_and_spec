# Student Ticket Plan Purchasable API Plan

## 目標

提供一支 API，在學員載入畫面時，依照學員目前資格回傳「可顯示且可購買」的票券方案。

目前已確認的規則：

- `NEW_ONLY` 方案：學員加入學生身份超過 30 天後，不可顯示、不可購買。
- 符合續約資格時，會員仍可自願購買同家族或其他家族的標準價方案。

目前 API 入口已存在：

- `GET /api/v1/students/{studentId}/ticket-plans/purchasable`


## 目前專案現況

### 已有的部分

- `StudentTicketPlansController`
  - 提供學生可購買票券 API 入口。
- `GetPurchasableTicketPlansForStudentHandler`
  - 會取得所有票券後，逐張呼叫 eligibility service 判斷。
- `ITicketPlanEligibilityService` / `TicketPlanEligibilityService`
  - 已有第一版資格檢查。
- `DapperTicketPlanCatalogQueryService`
  - 會查詢 `ticket_plan_kind`、`ticket_plan_kind_rule`、`plan_rule`。
- `NEW_ONLY` 30 天規則
  - 已存在於 `TicketPlanEligibilityService` 中。

### 目前的問題

1. `Tags` 和後端資格規則耦合
   - `DapperTicketPlanCatalogQueryService` 把 `plan_rule_code` 聚合到 `Tags`。
   - `TicketPlanEligibilityService` 再用 `Tags` 判斷 `NEW_ONLY`。
   - 這會讓前端顯示用途和後端業務規則混在一起。

2. Eligibility 結構還不夠正式
   - 目前只有 `bool CanPurchaseAsync(...)`。
   - 還沒有 `EligibilityContext`、`EligibilityRule`、`EligibilityResult` 等可擴充結構。

3. 逐張票重複判斷，未來容易產生 N+1 類型問題
   - 現在每張票都各自執行 eligibility service。
   - 未來規則增加後，會重複查詢相同學生資訊。

4. 交易流程尚未重用同一套資格檢查
   - `RegisterMemberHandler` 目前只驗證票券是否存在且上架。
   - 尚未在真正建立訂單前驗證 eligibility。

5. 規則類型尚未分類
   - `NEW_ONLY`、`RENEWAL`、`HIDDEN`、`FAMILY_ELIGIBLE` 並不是同一種類規則。
   - 若全部平放處理，後續邏輯會越來越亂。


## 需求定義

### 本階段目標

後端依據 `studentId` 回傳可顯示且可購買的票券方案。

### `NEW_ONLY` 規則定義

- 適用對象：有 `NEW_ONLY` eligibility rule 的票券。
- 判斷方式：
  - 學員必須有啟用中的學生角色。
  - `AssignedAt >= Now - 30 days`
- 若超過 30 天：
  - 該票券不應出現在可購買清單中。


## 建議責任分界

### 1. 顯示資訊

提供前端顯示用資料，例如：

- 名稱
- 價格
- 票種
- 畫面標籤 `Tags`

### 2. 資格規則

提供後端 eligibility 判斷用資料，例如：

- `NEW_ONLY`
- `RENEWAL`
- `NO_ACTIVE_MONTHLY`

這兩者必須分開，不應再用同一個 `Tags` 欄位同時承擔。


## 建議重構方向

### 一、保留現有 API 路徑，不重做入口

保留：

- `StudentTicketPlansController`
- `GetPurchasableTicketPlansForStudentHandler`

這條線已經符合「學生載入畫面查可購買票券」的目標，應該在既有路徑上重構內部實作。


### 二、調整 `TicketPlanResult`

目前 `TicketPlanResult` 只有：

- `Tags`

建議拆成：

- `Tags`
  - 純前端顯示用途
- `EligibilityRuleCodes`
  - 純後端資格判斷用途

建議概念：

```csharp
public sealed class TicketPlanResult
{
    public required string Id { get; set; }
    public required string Type { get; set; }
    public required string Name { get; set; }
    public required decimal Price { get; set; }
    public int Days { get; set; }
    public int Sessions { get; set; }
    public string[] Tags { get; set; } = [];
    public string[] EligibilityRuleCodes { get; set; } = [];
    public string? Description { get; set; }
}
```


### 三、修改 `DapperTicketPlanCatalogQueryService`

目前做法：

- 將 `plan_rule_code` 聚合成 `Tags`

建議改成：

- `Tags`：若未來有獨立 tag 來源，從真正 tag 來源查
- `EligibilityRuleCodes`：由 `plan_rule_code` 聚合

短期若資料表尚未拆出獨立 tag：

- 可以先讓前端暫時繼續吃 `Tags`
- 但後端 eligibility 必須改用 `EligibilityRuleCodes`

也就是說，至少在程式 DTO 層先完成責任分離。


### 四、引入 `StudentTicketPlanEligibilityContext`

建立一次學生資格 context，避免每張票重複查一樣的資料。

本階段最小版本只需要：

```csharp
public sealed class StudentTicketPlanEligibilityContext
{
    public string StudentId { get; init; } = default!;
    public bool IsActiveStudent { get; init; }
    public DateTime? StudentAssignedAt { get; init; }
    public DateTime Now { get; init; }
}
```

本階段資料來源：

- `IStudentProfileRepository`
- `IUserRoleRepository`
- `IClock`

未來若要擴充：

- 是否買過特定票券
- 是否有啟用中月票
- 最近月票是否剛過期

再把 `orders`、`order_items`、`sdt_ticket_pass` 的摘要放進 context。


### 五、將 eligibility service 改成 rule-based 結構

目前：

- `TicketPlanEligibilityService` 內直接用 `if` 判斷 `NEW_ONLY`

建議改成：

- `ITicketPlanEligibilityService`
- `ITicketPlanEligibilityRule`
- `NewOnlyTicketPlanEligibilityRule`

由 `TicketPlanEligibilityService` 負責：

1. 基本前置檢查
2. 組 eligibility context
3. 執行適用的 rules

建議概念：

```csharp
public interface ITicketPlanEligibilityRule
{
    bool AppliesTo(TicketPlanResult ticketPlan);
    Task<bool> IsSatisfiedAsync(
        StudentTicketPlanEligibilityContext context,
        TicketPlanResult ticketPlan,
        CancellationToken ct);
}
```

`NEW_ONLY` 第一條 rule：

- 只套用在 `EligibilityRuleCodes` 包含 `NEW_ONLY` 的票券
- 判斷 `AssignedAt >= Now.AddDays(-30)`


### 六、重構 `GetPurchasableTicketPlansForStudentHandler`

目前：

- 逐張票呼叫 `CanPurchaseAsync(studentId, ticketPlan, ct)`

建議：

1. 先取得票券清單
2. 先取得學生 eligibility context
3. 在記憶體中逐張票過濾

這樣做的好處：

- 學生資料只查一次
- 規則增加時不會每張票都重複查詢
- 後續容易擴充更多 rules


### 七、交易流程未來要接同一套 eligibility

目前 `RegisterMemberHandler` 只驗證：

- 票券存在
- 票券上架

未來若此流程也涉及學生購票，建議在建立訂單前加上：

- 同一套 eligibility 驗證

這樣可以確保：

- 畫面顯示規則
- 真正下單規則

兩者一致。


## 建議調整檔案

### 優先重構

- `src/gym-system.Application/TicketPlansUseCase/Queries/TicketPlanResult.cs`
- `src/gym-system.Infrastructures/Queries/TicketPlans/DapperTicketPlanCatalogQueryService.cs`
- `src/gym-system.Application/TicketPlansUseCase/Queries/ITicketPlanEligibilityService.cs`
- `src/gym-system.Application/TicketPlansUseCase/Queries/GetPurchasableTicketPlansForStudentHandler.cs`

### 第二階段

- `src/gym-system.Application/MembersUseCase/Commands/RegisterMember/RegisterMemberHandler.cs`
- `src/gym-system.Domain/Entities/Tickets/TicketPlanRule.cs`


## 建議實作順序

### 第一階段：完成目前需求

1. 將 `ITicketPlanEligibilityService` 與 `TicketPlanEligibilityService` 拆成不同檔案。
2. 在 `TicketPlanResult` 新增 `EligibilityRuleCodes`。
3. 修改 `DapperTicketPlanCatalogQueryService`，讓 eligibility rule 不再混用 `Tags`。
4. 新增 `StudentTicketPlanEligibilityContext`。
5. 新增 `ITicketPlanEligibilityRule` 與 `NewOnlyTicketPlanEligibilityRule`。
6. 重構 `TicketPlanEligibilityService` 改為 rule-based。
7. 更新 `GetPurchasableTicketPlansForStudentHandler`，改成先建 context 再過濾票券。
8. 補上對應單元測試。

### 第二階段：補齊交易一致性

1. 將購票流程接上 eligibility 驗證。
2. 規劃 `RENEWAL` 等後續 rule。
3. 視需要將 `TicketPlanRule` 正式落到 domain 或 application model。


## 本階段完成條件

達成以下結果即可視為第一階段完成：

- 載入學生票券畫面時，API 只回傳可顯示、可購買票券。
- `NEW_ONLY` 方案對超過 30 天的學生不會回傳。
- 後端 eligibility 不再依賴 `Tags` 欄位。
- 結構已可擴充更多票券資格規則。
