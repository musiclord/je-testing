# 模組 05: Step4 Criteria 與進階篩選

## 角色

這個模組把 Step3 的 prescreen tag 與使用者在 UI 勾選的日期、文字、金額、人工分錄、借貸方向、補班日排除、科目配對等條件組裝成可保存的 `CriteriaSelect` 結果集。

## 來源

- `Criteria_Dlg` 1325-2346
- `Step4_TW1` 2347-2364
- `Step4_TW2` 2365-2381
- `AddDateArray` 2382-2402
- `SpeDateSelect_Dlg` 2403-2518
- `X_Date_Select_Function` 2519-2610
- `SpeCharSelect_Dlg` 2611-2624
- `X_Char_Select_Function` 2625-2642
- `Step4` 8148-8417
- `Step4_Check_Select` 8418-8482
- `Step4_Check_Select_TW` 8483-8547
- `Step4_Reset_CheckBox` 8548-8578
- `GetSelectChar` 8579-8590
- `Step4_JoinDatabase` 8591-8667
- `Step4_Summarization` 8668-8680
- `Step4_Summarization_Line` 8681-8695
- `CriteriaLogSum_Dlg` 8736-8795
- `Step4_Export_Excel` 8796-8927
- `X_Step4_Drop_Log_Table` 8928-8948
- `Step4_Button_Disable/Enable` 8949-8986
- `Step4_Routines_Tag` 10200-10251
- `Step4_Tag_Collection` 10252-10299
- `Step4_Num_Acc_Select` 10378-10394
- `Step4_JoinDatabase_NoMatch` 10501-10532
- `Step4_JoinDatabase_NoMatch1` 10533-10566

## 讀寫資產

### 主要輸入

- 更新後的 `#GL#.IDM`
- `#PreScr-*-All.IDM`
- `#Null-GL_Description_Criteria.IDM`
- `#MakeUpDay#-Make-Up_Day.IDM`
- `JE_Criteria`
- `JE_Criteria_Log`

### 主要輸出

- `#CriteriaSelect1.IDM` ... `#CriteriaSelect10.IDM`
- `#Temp.IDM`, `#Temp1.IDM`, `#Temp2.IDM`, `#Temp_Account.IDM`
- `FINAL_TAG`, `C*_TAG`
- `JE_Criteria_Log` 新增紀錄

## 流程

```yaml
module: step4-criteria-advanced-filter
ui-setup:
  - 根據 Step3 結果決定哪些 checkbox 可用
  - 顯示每個 prescreen 的筆數
  - 顯示自訂 A2/A3/A4 memo
validation:
  - 先檢查有沒有至少選一個條件
  - 再檢查互斥條件與重複欄位
  - 再檢查被勾選的 prescreen 是否真的有結果
criteria-build:
  - 先把 prescreen / weekend / holiday / manual / debit / credit 組成第一層條件
  - 再把日期條件、數字條件、文字條件與科目配對條件附加上去
  - 透過 Step4_JoinDatabase / NoMatch 持續縮小 #Temp.IDM
tw-pass:
  - Step4_TW1 / Step4_TW2 依 tag 組數整理 FINAL_TAG
persist:
  - 使用者確認後，將 #Temp.IDM 改名為 #CriteriaSelectN.IDM
  - 寫入 JE_Criteria 與 JE_Criteria_Log
```

## 條件系統的真實形狀

legacy 的 Step4 不是單一 WHERE clause，而是分三層：

1. `sTemp1`: 普通條件字串，例如 prescreen / 日期 / 金額 / 文字
2. `sTemp2`: 與科目配對或額外 account select 有關的第二層條件
3. `sLog` / `sLogMemo`: 要寫回 `JE_Criteria_Log` 的說明與 tag 計算式

也就是說，Step4 本質上是「條件建構器 + 逐次 join/filter 管線」。

## A/B/C 配對模式

`Step4(Test As String, sPairType As String)` 透露出 legacy 對 account pairing 有三種語意：

- `A`: 精確 debit 類別 + credit 類別配對
- `B`: 先以 debit 類別錨定傳票，再抓該傳票內所有 credit
- `C`: 先以 credit 類別錨定傳票，再抓該傳票內所有 debit

這不是 UI 細節，而是 advanced filter 的核心模型。

## 互斥與防呆規則

`Step4_Check_Select_TW` 保存了大量真實限制，代表 legacy 認為這些組合會造成語意衝突：

- `R2` 不能和「摘要為空白」一起勾
- `R2` 不能和 `A2` 一起勾
- `R4` 不能和 `A4` 一起勾
- `R3` 不能和「數字條件下再限定科目類別」一起勾
- `Debit only` 與 `Credit only` 不能一起勾
- 摘要欄位的自訂文字篩選，不能再和 `R2` / `A2` / `摘要為空白` 並用

這些規則應被視為 legacy domain 邊界，而不是單純 UI validation。

## 保存結果的形狀

每次成功保存條件時，legacy 會做三件事：

1. 產生 `#CriteriaSelectN.IDM`
2. 更新 `JE_Criteria.WN = 1`
3. 寫入 `JE_Criteria_Log`，記錄：
   - 條件說明
   - 傳票數
   - 明細數
   - 符合所有條件的筆數

因此 Step4 的輸出不是單一結果，而是最多 10 組可被 Step5 挑選的「候選母體」。

## 邊界

- Step4 是 legacy 最複雜的 UI-driven rule composition 模組，不適合逐行移植。
- 但它的條件互斥、CriteriaLog 與 `#CriteriaSelectN.IDM` 概念非常重要，因為這些就是 Step5 的輸入契約。
- `FINAL_TAG` 與 `C*_TAG` 的存在代表 legacy 區分「進到 CriteriaSelect」與「符合所有條件的最終明細」。
