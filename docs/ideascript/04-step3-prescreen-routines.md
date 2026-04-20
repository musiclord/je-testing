# 模組 04: Step3 預篩選 Routines

## 角色

這個模組是 legacy JET 的規則引擎中心。它先把 `#GL#.IDM` 整理成 document-level / line-level 的暫存表，再依 R1-R8 與 A2-A4 逐步加上 prescreen 欄位與 line tag，最後把結果合併回 `#GL#.IDM`。

## 來源

- `Routine_Dlg` 1100-1141
- `Step3_Routines` 5897-7731
- `Step3_Export_Excel` 7732-8001
- `Step3_Routines_Info_Reset` 8012-8034
- `GetTagFieldName` 8035-8099
- `CriteriaDlg_Arry` 8100-8114
- `AddAccPairing_DC` 8115-8147

## 讀寫資產

### 主要輸入

- `#GL#.IDM`
- `#GL#DESC.IDM`
- `#AccountMapping.IDM`
- `#AccountMapping_R.IDM`
- `#AccountMapping_C.IDM`
- `#Weekend.IDM`
- `#Holiday#-Holiday.IDM`
- `JE_Routines`

### 主要輸出

- `#GL#Sum_By_Doc.IDM`
- `#GL#Sum_By_Doc_Line.IDM`
- `#PreScr-R1-All.IDM`
- `#PreScr-R2-All.IDM`
- `#PreScr-R3-All.IDM`
- `#PreScr-R4-All.IDM`
- `#PreScr-R5-Sum.IDM`
- `#PreScr-R6-Sum.IDM`
- `#PreScr-A2-All.IDM`
- `#PreScr-A3-All.IDM`
- `#PreScr-A4-All.IDM`
- `#GL#Critial.IDM`
- 更新後的 `#GL#.IDM`

## 流程

```yaml
module: step3-prescreen-routines
phase-1-prep:
  - 清空 JE_Routines 狀態
  - 驗證 A4 尾數輸入只能是數字與逗號
  - 若缺少空白摘要資料表，先建立 #Null-GL_Description_Criteria.IDM
  - 若 GL 尚無 DEBIT/CREDIT 拆分欄位，先補出
phase-2-doc-views:
  - 依 傳票號碼_JE 建 #GL#Sum_By_Doc.IDM
  - 依 傳票號碼_JE + 傳票文件項次_JE_S 建 #GL#Sum_By_Doc_Line.IDM
  - 補 weekday / holiday 所需欄位
phase-3-rules:
  - R1: 核准日 >= 期末財報準備期間開始日
  - R2: 摘要匹配預設關鍵字 regex
  - R3: 非預期借貸組合
  - R4: 金額尾數連續 0
  - R5: 依建立人員做摘要
  - R6: 低頻使用科目摘要
  - R7: 非工作日週末
  - R8: 國定假日
  - A2/A3/A4: 使用者自訂規則
phase-4-merge-back:
  - 將各 rule 的 PRESCR_* 欄位 join 回 #GL#Sum_By_Doc.IDM
  - 將各 rule 的 *_TAG 欄位 join 回 #GL#Sum_By_Doc_Line.IDM
  - 再把 doc / line 層結果合併成 #GL#Critial.IDM
  - 最後把 #GL#Critial.IDM 改名回 #GL#.IDM
```

## legacy 的規則資料形狀

每一條 rule 在 legacy 不是只有一份結果，而是通常有三層：

1. 明細萃取表，例如 `#PreScr-R2.IDM`
2. 保留版輸出表，例如 `#PreScr-R2-All.IDM`
3. 回寫到主流程的 tag / prescreen 欄位，例如 `PRESCR_R2`、`R2_TAG`

這代表 Step3 的真實責任不是只找出結果，而是「建立可供 Step4 再組合的標記系統」。

## R3 / A3 的關鍵語意

R3 與 A3 都依賴 `#AccountMapping.IDM`，且使用借貸方向 + 標準化科目類別來抓取傳票群。

核心形狀是：

```text
#GL#.IDM
 -> join #AccountMapping.IDM
 -> #GL#Account_Mapping.IDM
 -> 依傳票號碼與借貸方向挑出 debit side / credit side
 -> 再用 join / summarization 找出特定配對或非預期配對
```

也因此，若 Step2 沒有滿足必要的 standardized category，R3 會被禁用或退化成 N/A。

## R7 / R8 的關鍵語意

R7 / R8 不是直接看原始 GL 行，而是先在 `#GL#Sum_By_Doc.IDM` 的 document 層補上：

- `DOCDATE_WEEK`
- `POSTDATE_WEEK`
- `DOC_WEEKEND_JE_T`
- `POST_WEEKEND_JE_T`
- `DOC_HOLIDAY_JE_T`
- `POST_HOLIDAY_JE_T`

這些欄位之後也會變成 Step4 可複選的條件來源。

## 輸出關係

```text
#GL#.IDM
 -> #GL#Sum_By_Doc.IDM
 -> #GL#Sum_By_Doc_Line.IDM
 -> 各 PreScr-* / PreScr-*-All
 -> #GL#Critial.IDM
 -> rename -> #GL#.IDM
```

## 邊界

- Step3 是 legacy 的規則執行器，不是單一規則函式集合。
- 規則之間共享 `#GL#Sum_By_Doc*` 與 `PRESCR_* / *_TAG`，所以它的順序與資料形狀很重要。
- R5 / R6 在 legacy 更偏 summary report，而不是純布林條件；這與 R1/R2/R3/R4/A2/A3/A4 的型態不同。
