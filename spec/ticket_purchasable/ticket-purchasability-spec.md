# 可購買票券資格規格

## 適用範圍

本文件描述「學生是否可以購買某票券方案」的目前後端邏輯。範圍包含既有會員購買、註冊時購買、未付款訂單付款時重驗，以及 NEW_ONLY/RENEWAL 規則。

## 基本資格

購買流程會先檢查購買者與受益者：

- 購買者不可為空。
- 目前家庭購買暫停，所以受益者必須剛好 1 人。
- 購買者必須包含在受益者清單中。
- 學生必須存在。
- 使用者必須啟用。
- 使用者必須具有 Student 角色。
- 學生 profile 必須存在。
- 方案必須存在且啟用。
- 付款方式目前只接受 Cash。
- `SINGLE` 可購買數量為 1 到 5，其他方案數量只能為 1。

## 共用 Eligibility Context

目錄查詢到方案後，後端會建立共用資格 Context。Context 目前包含：

- 正規化後的 `studentId`。
- 學生 profile。
- 是否為有效學生。
- 目前時間 `Now`，由 Taipei clock 取得。

若無法建立 Context，個人化可購買清單會回傳空清單。

## 規則檢查流程

每個方案會帶有 `EligibilityRuleCodes`。後端依序檢查每個 code：

- 若沒有任何 eligibility rule code，表示通過資格檢查。
- 若找不到對應 rule handler，視為不通過。
- 若 rule handler 的 `AppliesTo` 回傳 false，視為不通過。
- 若 rule handler 的 `IsSatisfiedAsync` 回傳 false，視為不通過。
- 所有規則皆通過才可購買。

目前已實作的購買資格規則為：

- `NEW_ONLY`
- `RENEWAL`

## NEW_ONLY 規則

目前 NEW_ONLY 條件：

- 學生必須有 `AssignedAt`。
- `AssignedAt` 不得早於 `Now.AddDays(-30)`。
- 學生不可曾經購買同一個方案 SKU。

購買歷史判斷目前查詢：

- `sdt_ticket_pass`
- 對應 `order_items`
- 擁有者為同一學生。
- item type 為 Ticket。
- ref id 等於同一個方案 id。
- order item payment state 不為 Cancel。

目前程式碼沒有明確排除已取消的 pass，所以「買過後取消」是否仍擋 NEW_ONLY，要依目前查詢結果看待為已購買紀錄。

## RENEWAL 規則

RENEWAL 用來判斷學生是否有同家族票券的續約資格。主要條件：

- 學生與方案家族不可為空。
- 找最新一張同家族、已開始、非取消的來源票券。
- 來源票券必須有開始日。
- 方案家族必須與來源票券一致。
- 若來源票券開始日在未來，不可續約。
- 若已有非取消的 successor，不可續約。
- 若來源票券已用完，以 `endedAt` 作為有效結束日。
- 若未用完，以 `validEndDate` 作為有效結束日。
- 台灣今天若超過有效結束日加 9 天，不可續約。
- 若已有排隊中票券，通常不可續約。
- 若存在已取消的續約，且最後取消日為今天，允許同日重試。
- `today <= effectiveEndDate` 視為提前續約。

符合續約資格時，使用者可以買續約方案，也仍可買標準方案。標準方案不因符合續約資格而被排除。

## 註冊可購買清單

註冊可購買 API 目前在目錄查詢後額外排除 `RENEWAL` 方案。這表示註冊流程不會顯示續約方案。

目前註冊流程若帶票券購買，最後仍會走共用 `TicketPurchaseService`，所以後端購買檢查仍是最終權威。

## 未付款訂單付款時重驗

建立未付款訂單時不建立 pass，也不占用續約來源。之後付款時會重新驗證：

- 訂單仍必須是未付款狀態。
- 學生仍必須有效。
- 方案仍必須有效。
- 儲存的單價、總價、實收金額需與目前方案價格一致。
- 目錄查詢仍需找得到該方案。
- eligibility 規則需重新通過。
- 若為續約方案，續約資格需加鎖後重新通過。

若價格已變動，付款會回傳 `TICKET_PLAN_PRICE_CHANGED`。

## 需要考慮的案例

- 新客在 30 天內，且未買過同 SKU：可買 NEW_ONLY。
- 新客超過 30 天：不可買 NEW_ONLY。
- 新客買過同 SKU 後取消：目前仍可能因購買歷史被視為不可再買，需要產品規格確認。
- 有同家族有效來源票券且在到期後 9 天內：可買 RENEWAL。
- 已超過到期後 9 天：不可買 RENEWAL。
- 已有排隊票券：不可再買 RENEWAL，除非符合同日取消重試例外。
- 符合 RENEWAL 時仍要能買標準方案。
- 家庭多受益者購買：目前不可購買。
- 方案在建立未付款訂單後下架或改價：付款時不可成立。
- 目錄 SQL 未輸出某限制規則 code：購買資格服務不會檢查該規則，這是目前規則擴充缺口。

## 台灣日曆缺口

目前已使用 Taipei clock 取得 `Now` 與 `Today`。但 NEW_ONLY 仍使用 `Now.AddDays(-30)` 的 rolling timestamp 判斷，不是純 DateOnly 日曆日。

若規格要求「台灣日曆 30 天」，建議調整為：

- 使用 `IClock.Today` 或以 Taipei time 轉成 `DateOnly`。
- 將 `AssignedAt` 轉成台灣日期。
- 比較 `assignedDate >= today.AddDays(-30)`。
- 補邊界測試：台灣 00:00 前後、UTC 跨日、剛好第 30 天、超過第 30 天。
