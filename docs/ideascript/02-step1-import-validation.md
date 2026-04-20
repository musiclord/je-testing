# 模組 02: Step1 匯入、欄位配對與完整性驗證

## 角色

這個模組把原始 TB / GL 匯入資料轉成 JET 的標準欄位模型，並在同一步驟完成 null 檢查、核准日期檢查、完整性測試、傳票平衡檢查，以及 Validation / Account Mapping / INF 報表輸出。

## 來源

- `TBDetail_Dlg` 410-683
- `GLDetail_Dlg` 684-1099
- `Step1_Export_Excel` 3535-3966
- `Step1_Export_AccountMapFile` 4417-4469
- `Step1_Validation` 4470-4691
- `Sort_FieldName` 4692-4751
- `Step1_Export_INFFile` 4752-4781
- `Step1_Export_INF_Report` 4782-4947
- `UploadExcelFile_Dlg` 10567-10730
- `DealSheetAmount_Dlg` 10731-11005
- `DealAmount_Dlg` 11018-11176
- `Step1_GL_Amount_Append_2/3` 11177-11241
- `Step1_TB_Amount_Append_2/3/4` 11242-11303
- `VaildDialog_Dlg` 11304-11365
- `Step1_Approval_Date_Append` 11366-11379
- `Step1_Append_IsManual` 5629-5645
- `Step1_Check_User_Defind_Manual` 5646-5698

## 讀寫資產

### 主要輸入

- 使用者選擇的 TB/GL 原始檔
- `JE_PROJECT_INFO`
- Validation / AccountMapping / INF Excel template

### 主要輸出

- `#TB#.IDM`
- `#GL#.IDM`
- `#Null-GL_Account.IDM`
- `#Null-GL_Number.IDM`
- `#Null-GL_Description.IDM`
- `#NotinPeriod-ApprovalDate.IDM`
- `#Completeness_calculate.IDM`
- `#Completeness_Check.IDM`
- `#List_of_accounts_with_variance.IDM`
- `#GL_#Doc_not_Balance.IDM`
- `#GL_#Doc_not_Balance_Sum.IDM`
- `#INF Report#.IDM`
- `#INF Report#Sort.IDM`
- `Exports.ILB/*.xlsx`

## 流程

```yaml
module: step1-import-validation
tb-side:
  - TBDetail_Dlg 收集案件基本資訊
  - 使用者配對 TB 科目編號 / 科目名稱 / 金額欄位
  - DealSheetAmount_Dlg 決定 TB 金額模式
  - 建立 #TB#.IDM
  - 會計科目編號若是數字，先轉字串後再標準化為 會計科目編號_TB
  - 依金額模式產出 試算表變動金額_TB
gl-side:
  - GLDetail_Dlg 先篩出查核期間內的 GL 明細到 #GL#.IDM
  - 使用者配對核心欄位並統一改名為 *_JE / *_JE_S
  - DealAmount_Dlg 決定 GL 金額模式
  - 必要時由借方/貸方欄位或借貸別欄位推導 傳票金額_JE
  - 可選擇追加 人工傳票否_JE_S 與 傳票核准日_JE
validation:
  - 檢查會計科目編號 / 傳票號碼 / 摘要空值
  - 若有核准日欄位，抽出 不在查核期間內的核准日
  - Step1_Validation 執行完整性與傳票平衡檢查
exports:
  - ValidationReport.xlsx
  - AccountMapping.xlsx
  - INF_Report.xlsx (可選)
```

## 金額模式是 Step1 的核心

### TB 金額模式

- `status_SA = 1`：直接使用期間變動金額欄位
- `status_SA = 2`：用期末減期初
- `status_SA = 3`：用借方減貸方
- `status_SA = 4`：用 `(期末借-期末貸) - (期初借-期初貸)`

### GL 金額模式

- `status_Amount = 1`：直接使用單一金額欄位
- `status_Amount = 2`：借方金額減貸方金額
- `status_Amount = 3`：依借貸別欄位決定正負號

這一層是 legacy 真正的資料標準化入口，新系統不能跳過。

## Step1_Validation 的真實邏輯

```text
1. 先將 #GL#.IDM 依 會計科目編號_JE 做彙總
2. 與 #TB#.IDM 依科目編號做 join
3. 以 試算表變動金額_TB - 傳票金額_JE_SUM 計算 DIFF
4. 抽出 #Completeness_Check.IDM
5. 再依 傳票號碼_JE 做彙總，找 傳票金額_JE_SUM <> 0 的傳票
6. 將不平衡傳票回接到原始 GL，形成 #GL_#Doc_not_Balance.IDM
7. 若缺少借貸拆分欄位，另外補出 DEBIT_傳票金額_JE_T / CREDIT_傳票金額_JE_T
```

## 舊版驗證項目邊界

Step1 在 legacy 中不只做新版 `V1-V4` 的概念，還包含：

- 空白科目編號
- 空白傳票號碼
- 空白摘要
- 核准日期不在查核期間
- 完整性差異
- 傳票借貸不平
- INF 樣本

也就是說，legacy 的 Step1 範圍比新 guide 的 Validation 更寬。

## 輸出關係

```text
TBDetail_Dlg
 -> #TB#.IDM

GLDetail_Dlg
 -> #GL#.IDM
 -> #Null-GL_*.IDM
 -> #NotinPeriod-ApprovalDate.IDM
 -> Step1_Validation
    -> #Completeness_Check.IDM
    -> #List_of_accounts_with_variance.IDM
    -> #GL_#Doc_not_Balance.IDM
 -> Step1_Export_Excel
 -> Step1_Export_AccountMapFile
 -> Step1_Export_INFFile / Step1_Export_INF_Report
```

## 邊界

- `GLDetail_Dlg` 與 `TBDetail_Dlg` 很髒，但它們清楚揭露了「標準欄位長什麼樣」。
- Step1 不是單純 import，而是 import + normalize + validate + export。
- 如果新系統只做匯入，沒做標準欄位與 validation parity，就還沒真的替代 legacy Step1。
