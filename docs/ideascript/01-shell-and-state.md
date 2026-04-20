# 模組 01: Shell 與案件狀態

## 角色

這個模組負責把整個 JE 工具跑起來，管理案件狀態、步驟開關、重跑清理與入口導頁。它不是業務規則本身，但它決定所有 Step1~Step5 何時可以執行。

## 來源

- `Main` 161-227
- `Intro_Dlg` 228-409
- `Routine_Dlg` 1100-1141
- `ReRun_Dlg` 1142-1311
- `X_Create_Project_Info_Table` 4038-4113
- `X_Get_Project_Info` 4114-4148
- `X_Update_Project_Info*` 4149-4267
- `X_Update_Criteria_Log` 4268-4283
- `Introduction_Button_Control` 4284-4299
- `Introduction_Button_DisableALL` 4300-4311
- `X_Get_Routines_Info` 4312-4363
- `Criteria_Dialog_Control` 4364-4387
- `X_Get_Criteria_Info` 4388-4416
- `StepN_Excel_File_Check` 5757-5870

## 讀寫資產

### SQL CE tables

- `JE_PROJECT_INFO`
- `JE_Routines`
- `JE_Criteria`
- `JE_Criteria_Log`
- `JE_STEP_USER`

### 代表性 `.IDM`

- `#GL#.IDM`
- `#TB#.IDM`
- `#CriteriaSelect1..10.IDM`
- `#PreScr-*`
- `#To_WP.IDM`

## 流程

```yaml
module: shell-and-state
startup:
  - Main 讀取工作目錄與使用者資訊
  - 檢查 ProjectOverview.sdf 是否存在
  - 建立或初始化 JE_PROJECT_INFO / JE_Routines / JE_Criteria / JE_Criteria_Log / JE_STEP_USER
  - 開啟 Introduction dialog
entry-routing:
  BtnDataMap:
    - 先檢查 Step1 範本與 Excel 是否被佔用
    - 若 TB 尚未完成，先進 TBDetail_Dlg
    - 再進 GLDetail_Dlg
  BtnLoadfile:
    - 進 UploadExcelFile_Dlg
  BtnRoutine:
    - 進 Routine_Dlg
  BtnCriteria:
    - 進 Criteria_Dlg
  BtnExport:
    - 進 ExpWorkPaper_Dlg
rerun:
  - ReRun_Dlg 依使用者選擇回退到 Step1/2/3/4
  - 同步重設 JE_PROJECT_INFO 的 STEP_* 狀態
  - 刪除對應暫存表與輸出表
template-guard:
  - StepN_Excel_File_Check 先驗證範本檔存在
  - 再檢查對應 Excel 是否仍開啟
```

## 案件狀態模型

`JE_PROJECT_INFO` 是 legacy 的案件中樞，核心欄位包含：

- 基本資訊：`Engagement_Info`, `Period_Start_Date`, `Period_End_Date`, `Last_Accounting_Period_Date`, `Industry`
- 進度旗標：`STEP_1..STEP_6`
- 匯入旗標：`GL_Finsh`, `TB_Finsh`
- 檔名：`GL_File`, `TB_File`
- 其他：`Population`

`JE_Routines` 保存 R1-R8 / A2-A4 的開關、狀態與備註。

`JE_Criteria` 保存 Step4 已保留的 10 組條件槽位 `W1..W10` 與 `SEQ_Num`。

`JE_Criteria_Log` 保存每一組 criteria 的自然語言說明、傳票數、明細數與符合條件筆數。

## 重跑的真正語意

`ReRun_Dlg` 不是單純 UI reset，而是有明確的資料回滾邊界：

- 重跑 Step1：重設整個案件資訊，刪掉 GL/TB 與 validation 產物
- 重跑 Step2：刪掉 account mapping 與 holiday/makeup 依賴
- 重跑 Step3：刪掉 prescreen 產物與加在 `#GL#.IDM` 上的 prescreen/tag 欄位
- 重跑 Step4：刪掉 `#CriteriaSelect1..10.IDM`、criteria log 與 `#To_WP*`

這代表 legacy 的步驟不是鬆散的，而是有嚴格「前一步會覆蓋後一步的依賴」關係。

## 關係

```text
Main
 -> Intro_Dlg
    -> TBDetail_Dlg / GLDetail_Dlg
    -> UploadExcelFile_Dlg
    -> Routine_Dlg
    -> Criteria_Dlg
    -> ExpWorkPaper_Dlg
    -> ReRun_Dlg

X_* / Introduction_* / StepN_Excel_File_Check
 -> 為所有步驟提供狀態、按鈕啟閉、重跑與 template guard
```

## 邊界

- 這個模組把 SQL CE 當成「案件控制平面」，不是業務分析引擎。
- `STEP_*` 與 `.IDM` 清理策略是 legacy 事實，值得保留其語意，但不必在新系統保留同樣的 UI 驅動方式。
- `ReRun_Dlg` 的刪除清單非常有價值，因為它間接揭露了每一步驟的輸出依賴。
