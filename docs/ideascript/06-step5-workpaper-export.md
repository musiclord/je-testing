# 模組 06: Step5 工作底稿輸出

## 角色

這個模組把 Step4 已保存的 `#CriteriaSelect1..10.IDM` 再整併成最終工作底稿母體，補上 criteria tag、彙總資訊、rationale 與附件工作表，然後輸出 Excel 工作底稿。

## 來源

- `ExpWorkPaper_Dlg` 2643-2901
- `Step5_Button_Disable` 2902-2918
- `Step5_Button_Enable` 2919-2938
- `Step5_Export_Excel_TW` 8987-9794
- `Step5_ToWP_Sum` 9795-9868
- `Step5_WPdata_Collection` 9869-10055
- `RationaleForWP_DisplayIT` 10125-10142
- `X_Get_Routines_Memo` 10143-10161
- `Step5_rationale_Check` 10162-10186
- `Step5_ToWP_ReDo` 10395-10431
- `Step5_ToWP_ReDo_Sort` 10432-10454

## 讀寫資產

### 主要輸入

- `#CriteriaSelect1..10.IDM`
- `JE_Criteria`
- `JE_Criteria_Log`
- `#GL#.IDM`
- `#AccountMapping.IDM`
- `#Holiday#-Holiday.IDM`
- `#MakeUpDay#-Make-Up_Day.IDM`
- `WorkingPaper.xlsx` template

### 主要輸出

- `#To_WP.IDM`
- `#To_WP_Sum.IDM`
- `Exports.ILB/WorkingPaper.xlsx`

## 流程

```yaml
module: step5-workpaper-export
selection:
  - ExpWorkPaper_Dlg 讀出 W1..W10 是否可選
  - 使用者決定哪些 CriteriaSelect 要進工作底稿
collection:
  - Step5_WPdata_Collection 逐一讀取 #CriteriaSelectN.IDM
  - 先依 傳票號碼_JE 做 summary，建立 C1..C10 欄位
  - 再回接 #GL#.IDM，形成 #To_WP.IDM
  - 若有 line-level tag，再加上 C1_TAG..C10_TAG
  - 補 Count_Doc / Count_Tag 並排序
summary:
  - Step5_ToWP_Sum 產生傳票層級摘要 #To_WP_Sum.IDM
export:
  - Step5_Export_Excel_TW 寫入 WorkingPaper workbook
  - 同步輸出 holiday / makeup day / account mapping 等附錄
```

## Step5_WPdata_Collection 的真實意義

這個函式不是單純 append，而是把 10 組 criteria 轉成「可追蹤命中的工作底稿母體」：

- `C1..C10`：哪一組 criteria 命中該傳票
- `C1_TAG..C10_TAG`：哪一筆明細符合該 criteria 的 final tag
- `Count_Doc`：某明細同時被多少個 criteria 命中
- `Count_Tag`：某明細同時符合多少個 final tag

這讓 Step5 可以同時保留：

- 傳票是否進入母體
- 明細是否真的符合全部條件
- 多條 criteria 的重疊程度

## 工作底稿不是只有母體

`Step5_Export_Excel_TW` 還會把下列資訊放進 workbook：

- Step1 validation 結果
- Step3 / Step4 的 criteria log
- `#To_WP` 與 `#To_WP_Sum`
- Holiday / Make-Up Day 設定
- Account Mapping 資訊

所以 Step5 是一個完整的 dossier export，不只是 `SELECT * INTO Excel`。

## 與 Step4 的關係

```text
#CriteriaSelect1..10.IDM
 -> Step5_WPdata_Collection
 -> #To_WP.IDM
 -> Step5_ToWP_Sum
 -> #To_WP_Sum.IDM
 -> Step5_Export_Excel_TW
 -> WorkingPaper.xlsx
```

## 邊界

- `WPselect(10)` 是 legacy 對「最多 10 組 criteria」的硬限制。
- Step5 不是重新判斷規則，而是消化 Step4 已保存的結果。
- `Count_Doc` / `Count_Tag` 這種欄位非常值得保留其語意，因為它們反映 criteria overlap 與最終母體排序邏輯。
