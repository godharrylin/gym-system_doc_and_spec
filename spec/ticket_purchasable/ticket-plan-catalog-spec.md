# 票券方案目錄規格

## 目的

提供前端與購買流程可使用的票券方案清單，並把方案是否上架、是否套用資格規則、是否隱藏，集中由資料設定控制。

## 目前目錄查詢行為

目前學生可購買方案目錄由 `DapperTicketPlanCatalogQueryService` 查詢。主要行為如下：

- 只回傳啟用中的票券產品。
- 只帶出啟用中的規則關聯與啟用中的全域規則。
- `Tags` 保留啟用的原始規則標籤；由 `TicketPlanRulePolicy.BuildEligibilityRuleCodes()` 集中產生 `EligibilityRuleCodes`，排除 display／paused 規則，未知資格 code 保留並交由 service 在缺 handler 時拒絕。
- 若方案關聯到 `HIDDEN`，且該關聯與全域規則皆啟用，該方案不出現在目錄。
- 若方案關聯到資格限制規則，但關聯停用或全域規則停用，該方案不出現在目錄。SQL 的非資格排除集合與隱藏集合均由同一 policy 提供，不自行硬編碼分類。
- 輸出 DTO 會依方案資料推導票券類型，例如堂數券、月票。

## 資料開關語意

目前設計上有三層開關：

- 產品啟用：控制方案是否上架。
- 全域規則啟用：控制某個規則是否能被整體使用。
- 方案規則關聯啟用：控制某個方案是否套用某個規則。

對限制性規則而言，停用或設定不完整時應偏向不顯示或不可購買，以避免前端看到後端無法接受的方案。

## 方案家族

`familyCode` 用來描述方案家族，例如月票、半年票、年票、堂數包等。續約資格目前以同一個 `familyCode` 尋找來源票券。

舊計畫提到標準方案與續約方案的家族關係：

- 標準方案不應只限制「一生第一次購買」。
- 續約資格是依票券家族計算。
- 若會員符合續約資格，仍可購買同家族標準方案，也可購買其他家族標準方案。

## 資格與註冊情境

- HIDDEN 為目錄顯示規則；FAMILY_ELIGIBLE 為已知暫停規則，均不進資格 handler。
- 註冊清單與會員清單使用相同 catalog，並呼叫 `CanPurchaseAsync(context, plan, ct)`。
- 註冊情境要求每個 handler 明確支援 Registration，再執行適用性與條件驗證；預設不支援，NEW_ONLY／RENEWAL 目前均不開放。
- 未知資格規則沒有 handler 時拒絕；不能漏傳成無限制方案。

2026-09-07 此分類與共用驗證已實作並有單元測試；實際 SQL 的隱藏／停用組合尚待整合驗收，見 `implement_plan/05-remaining-alignment-plan.md`。

## 建議調整

- 把所有會影響購買資格的規則都輸出成 `EligibilityRuleCodes`，不要只限 `NEW_ONLY`、`RENEWAL`。
- `HIDDEN` 可以保留為目錄顯示規則，不一定交給購買資格服務。
- 註冊支援由 handler 的 `SupportsRegistration` 明確設定，仍須執行實際條件驗證。
- 若新增規則代碼，需同時補：
  - 規則資料。
  - 方案規則關聯。
  - 後端 rule handler。
  - 集中 policy 分類與停用防線的一致性。
  - 購買流程測試。
