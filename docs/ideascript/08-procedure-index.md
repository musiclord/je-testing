# ideascript 程序索引

這份索引只做一件事：讓你不用重新掃過 11,379 行原檔，也能快速找到某個函式落在哪個模組。

## 01 Shell 與案件狀態

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `Main` | 161-227 | 啟動工具、初始化案件環境 |
| `Intro_Dlg` | 228-409 | 首頁路由與步驟入口 |
| `Routine_Dlg` | 1100-1141 | Step3 對話框入口 |
| `ReRun_Dlg` | 1142-1311 | 回退與刪除舊產物 |
| `X_Create_Project_Info_Table` | 4038-4113 | 建立 SQL CE 控制表 |
| `X_Get_Project_Info` | 4114-4148 | 讀取案件狀態 |
| `X_Update_Project_Info*` | 4149-4267 | 更新案件/步驟/criteria/routine 狀態 |
| `X_Update_Criteria_Log` | 4268-4283 | 寫 Step4 log |
| `Introduction_Button_*` | 4284-4311 | 首頁按鈕控制 |
| `X_Get_Routines_Info` | 4312-4363 | 讀取 Step3 結果 |
| `Criteria_Dialog_Control` | 4364-4387 | Step4 UI 啟閉控制 |
| `X_Get_Criteria_Info` | 4388-4416 | 讀取 Step4 / Step5 狀態 |
| `StepN_Excel_File_Check` | 5757-5870 | 範本與開啟檔案檢查 |

## 02 Step1 匯入與驗證

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `TBDetail_Dlg` | 410-683 | TB 基本資訊與欄位配對 |
| `GLDetail_Dlg` | 684-1099 | GL 欄位配對、Step1 主流程 |
| `Step1_Export_Excel` | 3535-3966 | Validation report 輸出 |
| `Step1_Export_AccountMapFile` | 4417-4469 | Account Mapping template 輸出 |
| `Step1_Validation` | 4470-4691 | 完整性與傳票平衡檢查 |
| `Sort_FieldName` | 4692-4751 | GL 欄位排序 |
| `Step1_Export_INFFile` | 4752-4781 | INF 隨機樣本 |
| `Step1_Export_INF_Report` | 4782-4947 | INF 報表輸出 |
| `DealSheetAmount_Dlg` | 10731-11005 | TB 金額模式決策 |
| `DealAmount_Dlg` | 11018-11176 | GL 金額模式決策 |
| `Step1_GL_Amount_Append_2/3` | 11177-11241 | GL 金額推導 |
| `Step1_TB_Amount_Append_2/3/4` | 11242-11303 | TB 金額推導 |
| `VaildDialog_Dlg` | 11304-11365 | 額外 valid/filter dialog |
| `Step1_Approval_Date_Append` | 11366-11379 | 用總帳日期補核准日 |

## 03 Step2 輔助輸入

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `UploadExcelFile_Dlg` | 10567-10730 | Step2 主入口 |
| `Step2_Upload_AccountMapping_File` | 4948-5069 | 匯入 account mapping |
| `initialWeekend_Dlg` | 5070-5170 | 設定非工作日週末 |
| `X_Create_Weekend_Table` | 5171-5197 | 建立 weekend table |
| `X_Append_Weekend` | 5198-5228 | 寫入 weekend row |
| `Step2_Upload_Holiday_File` | 5229-5362 | 匯入 holiday |
| `Step2_Upload_MakeUpday_File` | 5363-5496 | 匯入 makeup day |
| `Step2_Check_Required` | 5497-5593 | 檢查 R3 必要 account mapping 類別 |

## 04 Step3 預篩選

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `Step3_Routines` | 5897-7731 | R1-R8/A2-A4 執行器 |
| `Step3_Export_Excel` | 7732-8001 | Pre-screening report |
| `Step3_Routines_Info_Reset` | 8012-8034 | 清空 Step3 狀態 |
| `GetTagFieldName` | 8035-8099 | 讀 tag 欄位名稱 |
| `CriteriaDlg_Arry` | 8100-8114 | Step4 基礎陣列 |
| `AddAccPairing_DC` | 8115-8147 | account pairing options |

## 05 Step4 進階篩選

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `Criteria_Dlg` | 1325-2346 | Step4 主控制器 |
| `Step4_TW1` / `Step4_TW2` | 2347-2381 | 台灣版 tag 整理 |
| `SpeDateSelect_Dlg` | 2403-2518 | 日期條件 UI |
| `X_Date_Select_Function` | 2519-2610 | 日期條件字串 |
| `SpeCharSelect_Dlg` | 2611-2624 | 文字條件 UI |
| `X_Char_Select_Function` | 2625-2642 | 文字條件字串 |
| `Step4` | 8148-8417 | A/B/C 配對與 account selection |
| `Step4_Check_Select` | 8418-8482 | 至少選一項條件 |
| `Step4_Check_Select_TW` | 8483-8547 | 互斥規則與空結果檢查 |
| `Step4_Reset_CheckBox` | 8548-8578 | Step4 UI reset |
| `GetSelectChar` | 8579-8590 | 文字條件公式 |
| `Step4_JoinDatabase*` | 8591-8667, 10501-10566 | join / exclude join |
| `Step4_Summarization*` | 8668-8695 | summary helper |
| `CriteriaLogSum_Dlg` | 8736-8795 | criteria log display |
| `Step4_Export_Excel` | 8796-8927 | criteria summary report |
| `X_Step4_Drop_Log_Table` | 8928-8948 | 刪 Step4 log |
| `Step4_Button_*` | 8949-8986 | Step4 button state |
| `Step4_Routines_Tag` | 10200-10251 | tag 欄位處理 |
| `Step4_Tag_Collection` | 10252-10299 | FINAL_TAG 整理 |
| `Step4_Num_Acc_Select` | 10378-10394 | 數字條件 + 科目類別 |

## 06 Step5 工作底稿

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `ExpWorkPaper_Dlg` | 2643-2901 | Step5 主入口 |
| `Step5_Button_*` | 2902-2938 | Step5 button state |
| `Step5_Export_Excel_TW` | 8987-9794 | Working paper 輸出 |
| `Step5_ToWP_Sum` | 9795-9868 | 工作底稿摘要表 |
| `Step5_WPdata_Collection` | 9869-10055 | 彙整 CriteriaSelect |
| `RationaleForWP_DisplayIT` | 10125-10142 | 顯示 WP rationale |
| `X_Get_Routines_Memo` | 10143-10161 | 讀 Step3 memo |
| `Step5_rationale_Check` | 10162-10186 | rationale 檢查 |
| `Step5_ToWP_ReDo` | 10395-10431 | 重整 #To_WP |
| `Step5_ToWP_ReDo_Sort` | 10432-10454 | 重排 #To_WP |

## 07 共用 helper

| 函式 | 行號 | 模組責任 |
| --- | --- | --- |
| `Z_Delete_File` | 1312-1324 | 刪 `.IDM` |
| `GetFile` | 3268-3275 | 挑檔 |
| `GetFieldName` | 3276-3338 | 掃描欄位 |
| `Z_DirectExtractionTable` | 3339-3359 | extraction wrapper |
| `Z_renameFields` | 3360-3491 | 改欄位名 |
| `GetTotal` | 3492-3524 | aggregate helper |
| `Z_Get_Char_NumBlanks` | 3525-3534 | 字串空白數計算 |
| `GetNulls` | 3967-3994 | null extractor |
| `Z_Field_Info` | 3995-4037 | 欄位型別反射 |
| `Z_Modidy_Field_Num_to_Char` | 5594-5628 | 數字轉字串 |
| `Step1_Append_IsManual` | 5629-5645 | 補人工分錄欄位 |
| `Step1_Check_User_Defind_Manual` | 5646-5698 | 驗證人工分錄欄位 |
| `Z_WorkbookOpen` | 5699-5756 | 檢查 Excel 開啟 |
| `FindField` | 5871-5896 | 查欄位是否存在 |
| `Z_ExportDatabaseXLSX` | 8002-8011 | `.IDM` 匯出 xlsx |
| `Z_Rename_DB` | 8696-8707 | 資料表改名 |
| `Z_File_Exist` | 8708-8722 | 檔案存在檢查 |
| `X_Char_Category` | 8723-8735 | 類別數量統計 |
| `X_AppendField*` | 10056-10124 | 動態補欄位 |
| `Z_DataField_Check` | 10187-10199 | 欄位資料檢查 |
| `X_SendMail*` | 10300-10377, 10455-10500 | 郵件通知 |
