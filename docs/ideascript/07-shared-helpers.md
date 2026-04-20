# 模組 07: 共用 helper 與低階 IDEA 操作

## 角色

這個模組收斂 `ideascript.bas` 內大量與 IDEA API、欄位反射、檔案操作、Excel 輸出有關的 helper。它們不是核心業務規則，但構成了 legacy 的實作骨架。

## 來源

- `Z_Delete_File` 1312-1324
- `GetFile` 3268-3275
- `GetFieldName` 3276-3338
- `Z_DirectExtractionTable` 3339-3359
- `Z_renameFields` 3360-3491
- `GetTotal` 3492-3524
- `Z_Get_Char_NumBlanks` 3525-3534
- `GetNulls` 3967-3994
- `Z_Field_Info` 3995-4037
- `Z_Modidy_Field_Num_to_Char` 5594-5628
- `Z_WorkbookOpen` 5699-5756
- `FindField` 5871-5896
- `Z_ExportDatabaseXLSX` 8002-8011
- `Z_Rename_DB` 8696-8707
- `Z_File_Exist` 8708-8722
- `X_AppendField*` 10056-10124
- `Z_DataField_Check` 10187-10199
- `X_SendMail` 10300-10377
- `X_SendMail_Step` 10455-10500

## helper 分類

### 1. `.IDM` 生命週期

- `Z_Delete_File`
- `Z_Rename_DB`
- `Z_File_Exist`

這一組函式負責建立、刪除、改名與存在檢查，是 legacy dataflow 的底座。

### 2. 欄位反射與標準化

- `GetFieldName`
- `Z_Field_Info`
- `FindField`
- `Z_renameFields`
- `Z_Modidy_Field_Num_to_Char`

這一組揭露了 legacy 很重視「欄位型態與長度」，而不是直接靠欄位名稱硬做。

### 3. 篩選、彙總與 join 的低階包裝

- `Z_DirectExtractionTable`
- `GetNulls`
- `GetTotal`
- `Z_Get_Char_NumBlanks`
- `X_AppendField*`

這些函式實際上是：

- extraction wrapper
- null detector
- aggregate helper
- append field helper

也就是把 IDEA API 的重複樣板包起來。

### 4. Excel / 外部檔案衛生

- `GetFile`
- `Z_WorkbookOpen`
- `Z_ExportDatabaseXLSX`
- `StepN_Excel_File_Check` 在模組 01

這一層是 legacy 對 template、open workbook、輸出副檔名與匯出工作表的控制面。

## 共用 helper 的真實意義

這些函式雖然雜，但從遷移角度非常重要，因為它們說明了 legacy 真正常做的操作類型：

```text
Extraction by criteria
Rename field to canonical name
If numeric ID -> convert to char
Summarize by document or account
Join primary and secondary table
Append flag/tag field
Export current table to xlsx
```

這正是新系統 Infrastructure 層最應該吸收的「操作家族」。

## 不要直接照抄的部分

- `Z_*` 的價值在於語意，不在於 IDEA COM API 介面本身
- `GetObject`, `CreateObject`, `Excel.Application`, `Word.Application` 都屬於 legacy 宿主限制
- 新系統不需要保留 `IDM` 檔名，但應保留「每一步產物可追蹤」的能力
