Attribute VB_Name = "Utils"
Option Explicit

'===============================================================================
' Module: Utils
' Purpose: 通用工具函數集合
'
' Contains:
'   - File system operations (FileExists, FolderExists, CreateFolder)
'   - UI helpers (PickFile, PickFolder)
'   - String utilities (SanitizeString, SanitizeNumericField)
'   - Table detection (IsUserTable)
'===============================================================================

'===============================================================================
' File System Operations
'===============================================================================

Public Function FileExists(ByVal filePath As String) As Boolean
    '檢查檔案是否存在
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    FileExists = fso.FileExists(filePath)
    Set fso = Nothing
End Function

Public Function FolderExists(ByVal folderPath As String) As Boolean
    '檢查資料夾是否存在
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    FolderExists = fso.FolderExists(folderPath)
    Set fso = Nothing
End Function

Public Function CreateFolder(ByVal folderPath As String) As Boolean
    '建立資料夾
    On Error Resume Next
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    If Not fso.FolderExists(folderPath) Then
        fso.CreateFolder folderPath
    End If
    CreateFolder = fso.FolderExists(folderPath)
    Set fso = Nothing
    On Error GoTo 0
End Function

Public Function GetFileName(ByVal filePath As String) As String
    '從完整路徑取得檔案名稱
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    GetFileName = fso.GetFileName(filePath)
    Set fso = Nothing
End Function

Public Function GetBaseName(ByVal filePath As String) As String
    '從完整路徑取得不含副檔名的檔案名稱
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    GetBaseName = fso.GetBaseName(filePath)
    Set fso = Nothing
End Function

Public Function GetParentFolder(ByVal filePath As String) As String
    '從完整路徑取得父資料夾路徑
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    GetParentFolder = fso.GetParentFolderName(filePath)
    Set fso = Nothing
End Function

'===============================================================================
' UI Helpers
'===============================================================================

Public Function PickFile(ByVal Title As String, ByVal Filter As String) As String
    '顯示檔案選擇對話框
    Dim fd As FileDialog
    Set fd = Application.FileDialog(msoFileDialogFilePicker)
    
    With fd
        .Title = Title
        .Filters.Clear
        .Filters.Add "Files", Filter
        .AllowMultiSelect = False
        
        If .Show = -1 Then
            PickFile = .SelectedItems(1)
        Else
            PickFile = ""
        End If
    End With
    
    Set fd = Nothing
End Function

Public Function PickFolder(ByVal Title As String) As String
    '顯示資料夾選擇對話框
    Dim fd As FileDialog
    Set fd = Application.FileDialog(msoFileDialogFolderPicker)
    
    With fd
        .Title = Title
        If .Show = -1 Then
            PickFolder = .SelectedItems(1)
        Else
            PickFolder = ""
        End If
    End With
    
    Set fd = Nothing
End Function

'===============================================================================
' String Utilities
'===============================================================================

Public Function SanitizeString(ByVal inputStr As String) As String
    '移除檔案名稱或 SQL 中的無效字元
    Dim invalidChars As String
    invalidChars = "\/:*?""<>|"
    Dim i As Integer
    Dim result As String
    result = inputStr
    
    For i = 1 To Len(invalidChars)
        result = Replace(result, Mid(invalidChars, i, 1), "_")
    Next i
    
    SanitizeString = result
End Function

Public Function SanitizeNumericField(ByVal fieldName As String) As String
    '清理數值欄位的 NULL 處理
    '將 NULL 視為 0，確保數值計算正確
    SanitizeNumericField = "IIF(ISNULL([" & fieldName & "]), 0, [" & fieldName & "])"
End Function

Public Function Nz(ByVal fieldName As String, Optional ByVal defaultValue As Variant = 0) As String
    '模擬 Access Nz 函數：將 NULL 替換為預設值
    If IsMissing(defaultValue) Then defaultValue = 0
    Nz = "IIF(ISNULL([" & fieldName & "]), " & defaultValue & ", [" & fieldName & "])"
End Function

'===============================================================================
' Database Utilities
'===============================================================================

Public Function IsUserTable(ByVal tableName As String) As Boolean
    '檢查是否為使用者資料表（非系統表或臨時表）
    IsUserTable = Not (tableName Like "MSys*" Or _
                       tableName Like "~TMPCLP*" Or _
                       tableName Like "~*")
End Function

'===============================================================================
' Date Utilities
'===============================================================================

Public Function FormatDateForSql(ByVal dateValue As Date) As String
    '格式化日期為 SQL 使用的格式
    FormatDateForSql = "#" & Format(dateValue, "yyyy-mm-dd") & "#"
End Function

Public Function ParseDate(ByVal dateStr As String) As Date
    '解析日期字串
    On Error Resume Next
    ParseDate = CDate(dateStr)
    If Err.Number <> 0 Then
        ParseDate = Date  ' 預設為今天
        Err.Clear
    End If
    On Error GoTo 0
End Function

'===============================================================================
' Validation Helpers
'===============================================================================

Public Function IsValidPath(ByVal Path As String) As Boolean
    '驗證路徑是否有效
    On Error Resume Next
    Dim fso As Object
    Set fso = CreateObject("Scripting.FileSystemObject")
    
    ' Check if path contains invalid characters
    If Path Like "*[<>:|?*]*" Then
        IsValidPath = False
        Exit Function
    End If
    
    ' Check if parent folder exists
    If InStr(Path, "\") > 0 Then
        Dim parentFolder As String
        parentFolder = fso.GetParentFolderName(Path)
        IsValidPath = fso.FolderExists(parentFolder)
    Else
        IsValidPath = False
    End If
    
    Set fso = Nothing
    On Error GoTo 0
End Function

Public Function IsNumericString(ByVal str As String) As Boolean
    '檢查字串是否為數值
    IsNumericString = IsNumeric(str)
End Function

'===============================================================================
' Collection/Array Utilities
'===============================================================================

Public Function JoinArray(ByVal arr As Variant, ByVal delimiter As String) As String
    '將陣列元素串接為字串
    Dim i As Long
    Dim result As String
    
    If Not IsArray(arr) Then
        JoinArray = ""
        Exit Function
    End If
    
    For i = LBound(arr) To UBound(arr)
        If i > LBound(arr) Then result = result & delimiter
        result = result & CStr(arr(i))
    Next i
    
    JoinArray = result
End Function

Public Function ArrayContains(ByVal arr As Variant, ByVal value As Variant) As Boolean
    '檢查陣列是否包含指定值
    Dim i As Long
    ArrayContains = False
    
    If Not IsArray(arr) Then Exit Function
    
    For i = LBound(arr) To UBound(arr)
        If arr(i) = value Then
            ArrayContains = True
            Exit Function
        End If
    Next i
End Function

'===============================================================================
' Debug Helpers
'===============================================================================

Public Sub DebugPrintLine(Optional ByVal char As String = "-", Optional ByVal length As Long = 60)
    '輸出分隔線到立即視窗
    Debug.Print String(length, char)
End Sub

Public Sub DebugPrintHeader(ByVal Title As String)
    '輸出標題到立即視窗
    Call DebugPrintLine
    Debug.Print Title
    Call DebugPrintLine
End Sub
