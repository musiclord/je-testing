# 模組 03: Step2 輔助輸入資料

## 角色

這個模組處理 Step2 的外部輔助檔案與設定，包括：

- Account Mapping
- Weekend 定義
- Holiday 檔
- Make-Up Day 檔

它本身不做 prescreen，但會決定後續 R3、R7、R8、Step4 等條件是否能成立。

## 來源

- `UploadExcelFile_Dlg` 10567-10730
- `Step2_Upload_AccountMapping_File` 4948-5069
- `initialWeekend_Dlg` 5070-5170
- `X_Create_Weekend_Table` 5171-5197
- `X_Append_Weekend` 5198-5228
- `Step2_Upload_Holiday_File` 5229-5362
- `Step2_Upload_MakeUpday_File` 5363-5496
- `Step2_Check_Required` 5497-5593

## 讀寫資產

### 輸入

- `AccountMapping.xlsx`
- `Holiday.xlsx`
- `Make-Up_Day.xlsx`
- 使用者在 weekend dialog 的勾選

### 輸出

- `#AccountMapping#-AccountMapping.IDM`
- `#AccountMapping.IDM`
- `#AccountMapping_Sum.IDM`
- `#AccountMapping_R.IDM`
- `#AccountMapping_C.IDM`
- `#Weekend.IDM`
- `#Holiday#-Holiday.IDM`
- `#MakeUpDay#-Make-Up_Day.IDM`

## 流程

```yaml
module: step2-auxiliary-inputs
account-mapping:
  - 先檢查 worksheet 名稱是否為 AccountMapping
  - 檢查欄位是否為 GL_Number / GL_Name / Standardized Account Name*
  - 匯入後補空白 STANDARDIZED_ACCOUNT_NAME = Others
  - 產出 #AccountMapping.IDM
  - 再拆出 Revenue 與 Cash/Receivables/Receipt in advance 類別
weekend:
  - 使用者勾選哪些 DayOfWeek 視為非工作日
  - 寫入 #Weekend.IDM
holiday:
  - 驗證 worksheet 與欄位名稱
  - 驗證日期型態與日期值
  - 匯入 #Holiday#-Holiday.IDM
makeup-day:
  - 驗證 worksheet 與欄位名稱
  - 驗證日期型態與日期值
  - 匯入 #MakeUpDay#-Make-Up_Day.IDM
step-gating:
  - 上傳 Account Mapping 成功後，STEP_2 -> 0, STEP_3 -> 1
```

## Step2_Check_Required 的真實目的

`Step2_Check_Required` 不只是檢查檔案有沒有上傳，而是檢查 account mapping 是否滿足 legacy 對 R3 的必要條件：

- 至少有 `Revenue`
- 至少有 `Cash` / `Receivables` / `Receipt in advance` 類別

它也會：

- 把空白 `STANDARDIZED_ACCOUNT_NAME` 補成 `Others`
- 產出 `#AccountMapping_R.IDM` 與 `#AccountMapping_C.IDM`

也就是說，Step2 其實是在幫 Step3 建立「可做借貸組合異常判斷」的基礎資料。

## 與後續步驟的關係

```text
#AccountMapping.IDM
 -> Step3 R3
 -> Step3 A3
 -> Step4 account pairing / numeric+account filters
 -> Step5 附錄輸出

#Weekend.IDM + #Holiday#-Holiday.IDM + #MakeUpDay#-Make-Up_Day.IDM
 -> Step3 weekend / holiday tag
 -> Step4 排除補班日 / 結帳日
 -> Step5 附錄輸出
```

## 邊界

- legacy 用 Excel 檢查 worksheet 名與欄位名，這是保守但合理的輸入防呆。
- `Weekend` 不是從外部檔案來，而是 UI 內建設定。
- `Account Mapping` 在 legacy 中不只是 lookup table，而是 prescreen 與 criteria 的上游語意資料。
