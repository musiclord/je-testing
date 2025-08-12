VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "PreviewService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Model: Preview Service
'Description: Load maximum 1000 records of selected table to worksheet, let user preview data without opening Access.

Private Const MODULE_NAME As String = "PreviewService"
Private Const adDate As Long = 7 ' ADODB Date type constant


Public Function GetAccessTableNames(ByVal accessDbPath As String) As Variant
    ' Service: Retrieves a list of table names from the specified Access database.
    Const METHOD_NAME As String = "GetAccessTableNames"
    Dim dal As AccessDAL
    Dim tableNames As Variant

    On Error GoTo ErrorHandler
    GetAccessTableNames = Empty ' Default return value

    Set dal = New AccessDAL
    dal.DatabasePath = accessDbPath
    tableNames = dal.GetTableNames ' Delegate to DAL

    GetAccessTableNames = tableNames ' Return the variant array

Cleanup:
    Set dal = Nothing
    Exit Function

ErrorHandler:
    Debug.Print "--- " & MODULE_NAME & "." & METHOD_NAME & " Error ---"
    Debug.Print "Error Number: " & Err.Number
    Debug.Print "Error Source: " & Err.Source
    Debug.Print "Error Description: " & Err.Description
    ' Let the caller (cApplication) handle the error message to the user
    ' Return Empty to indicate failure
    GetAccessTableNames = Empty
    GoTo Cleanup
End Function

Private Function FindOrCreatePreviewSheet() As Worksheet
    ' 輔助函數：尋找 CodeName 為 "Preview" 的工作表，若不存在則創建並嘗試設定 CodeName。
    Const PREVIEW_CODENAME As String = "Preview"
    Dim ws As Worksheet
    Dim comp As Object ' VBComponent

    On Error Resume Next ' 暫時忽略錯誤，以便檢查 CodeName
    Set FindOrCreatePreviewSheet = Nothing ' 預設傳回值

    ' 1. 嘗試透過 CodeName 尋找現有工作表
    For Each ws In ThisWorkbook.Worksheets
        If StrComp(ws.CodeName, PREVIEW_CODENAME, vbTextCompare) = 0 Then
            Set FindOrCreatePreviewSheet = ws
            Exit Function ' 找到即返回
        End If
    Next ws
    On Error GoTo 0 ' 恢復預設錯誤處理

    ' 2. 如果找不到，則創建新工作表
    Debug.Print "Worksheet with CodeName '" & PREVIEW_CODENAME & "' not found. Creating a new one."
    Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))

    ' 3. 嘗試設定新工作表的 CodeName (需要啟用 "信任 VBA 專案物件模型存取")
    On Error Resume Next ' 捕捉設定 CodeName 可能發生的錯誤
    Set comp = ThisWorkbook.VBProject.VBComponents(ws.CodeName)
    comp.Name = PREVIEW_CODENAME
    If Err.Number <> 0 Then
        Debug.Print "Warning: Could not set CodeName for the new preview sheet '" & ws.Name & "' to '" & PREVIEW_CODENAME & "'." & _
                    " Please ensure 'Trust access to the VBA project object model' is enabled in Excel Options," & _
                    " or manually set the CodeName in the VBE Properties window."
        Err.Clear
        ' 即使無法設定 CodeName，仍然傳回新建立的工作表供本次使用
    Else
        Debug.Print "Successfully set CodeName for sheet '" & ws.Name & "' to '" & PREVIEW_CODENAME & "'."
    End If
    On Error GoTo 0 ' 恢復預設錯誤處理

    Set FindOrCreatePreviewSheet = ws ' 傳回新建立的工作表

End Function

Public Function ShowPreview(ByVal accessDbPath As String, ByVal tableName As String, ByVal worksheetName As String, ByVal maxRowsToShow As Long) As Boolean
    Const METHOD_NAME As String = "ShowPreview"
    Dim dal As AccessDAL
    Dim rs As Object   ' ADODB.Recordset
    Dim ws As Worksheet
    Dim sql As String
    Dim i As Long
    Dim fieldCount As Long
    Dim recordCount As Long
    Dim previewSheetName As String

    On Error GoTo ErrorHandler
    ShowPreview = False ' Default to failure

    ' --- Excel Worksheet Handling ---
    Application.ScreenUpdating = False
    Application.DisplayAlerts = False
    Application.Wait Now + TimeValue("00:00:02")
    
    ' 1. 為每個資料表創建獨立的工作表
    Set ws = FindOrCreateSpecificPreviewSheet(tableName)
    If ws Is Nothing Then
        Err.Raise vbObjectError + 518, MODULE_NAME & "." & METHOD_NAME, "Failed to find or create worksheet for table: " & tableName
    End If

    ' 2. 清空工作表並設定顯示名稱
    ws.Cells.Clear
    previewSheetName = "#" & tableName
    On Error Resume Next
    ws.Name = previewSheetName
    If Err.Number <> 0 Then
        Debug.Print "Warning: Could not rename worksheet to '" & previewSheetName & "'. Error: " & Err.Description
        Err.Clear
    End If
    On Error GoTo ErrorHandler
    ws.Activate
    Debug.Print "Using worksheet '" & ws.Name & "' (CodeName: " & ws.CodeName & ") for preview."

    ' --- 詳細的資料庫診斷 ---
    Set dal = New AccessDAL
    dal.DatabasePath = accessDbPath
    dal.EnableDebugPrinting = True

    ' 檢查資料庫檔案是否存在
    If Dir(accessDbPath) = "" Then
        Debug.Print METHOD_NAME & " - 錯誤: 資料庫檔案不存在: " & accessDbPath
        ws.Cells(1, 1).value = "錯誤: 資料庫檔案不存在"
        GoTo Cleanup
    End If

    ' 嘗試連接資料庫
    If Not dal.Connect() Then
        Debug.Print METHOD_NAME & " - 錯誤: 無法連接資料庫: " & accessDbPath
        ws.Cells(1, 1).value = "錯誤: 無法連接資料庫"
        GoTo Cleanup
    End If

    ' 檢查資料表是否存在
    If Not dal.tableExists(tableName) Then
        Debug.Print METHOD_NAME & " - 錯誤: 資料表 [" & tableName & "] 不存在於資料庫中"
        ws.Cells(1, 1).value = "錯誤: 資料表 [" & tableName & "] 不存在"
        GoTo Cleanup
    End If

    ' 檢查資料表記錄數
    Dim tableRecordCount As Variant
    tableRecordCount = dal.GetScalar("SELECT COUNT(*) FROM [" & tableName & "]")
    Debug.Print METHOD_NAME & " - 資料表 [" & tableName & "] 總記錄數: " & tableRecordCount

    If IsNull(tableRecordCount) Or Not IsNumeric(tableRecordCount) Then
        Debug.Print METHOD_NAME & " - 警告: 無法取得資料表記錄數"
        ws.Cells(1, 1).value = "警告: 無法取得資料表記錄數"
        GoTo Cleanup
    End If

    If CLng(tableRecordCount) = 0 Then
        Debug.Print METHOD_NAME & " - 資料表 [" & tableName & "] 是空的"
        
        ' 即使沒有資料，也要顯示欄位結構
        sql = "SELECT * FROM [" & tableName & "] WHERE 1=0" ' 只取得結構，不取得資料
        Set rs = dal.GetRecordset(sql, disconnectRecordset:=True)
        
        If Not rs Is Nothing And rs.fields.Count > 0 Then
            For i = 0 To rs.fields.Count - 1
                ws.Cells(1, i + 1).value = rs.fields(i).Name
            Next i
            ws.Cells(2, 1).value = "（此資料表沒有資料記錄）"
            ws.Columns.AutoFit
        Else
            ws.Cells(1, 1).value = "資料表 [" & tableName & "] 沒有欄位結構"
        End If
        
        Debug.Print "No data to load from Access table [" & tableName & "]."
        ShowPreview = True ' 雖然沒有資料，但成功顯示了結構
        GoTo Cleanup
    End If

    ' --- 建立 SQL 語句並取得資料 ---
    If maxRowsToShow > 0 And CLng(tableRecordCount) > maxRowsToShow Then
        sql = "SELECT TOP " & maxRowsToShow & " * FROM [" & tableName & "]"
        Debug.Print METHOD_NAME & " - 使用 TOP 限制，只取前 " & maxRowsToShow & " 筆記錄"
    Else
        sql = "SELECT * FROM [" & tableName & "]"
        Debug.Print METHOD_NAME & " - 取得所有記錄"
    End If

    Debug.Print METHOD_NAME & " - 執行 SQL: " & sql

    ' 取得 Recordset
    Set rs = dal.GetRecordset(sql, disconnectRecordset:=True)

    If rs Is Nothing Then
        Debug.Print METHOD_NAME & " - 錯誤: 無法取得 Recordset"
        ws.Cells(1, 1).value = "錯誤: 無法從資料表取得資料"
        GoTo Cleanup
    End If

    ' --- 詳細的 Recordset 診斷 ---
    Debug.Print METHOD_NAME & " - Recordset 狀態檢查:"
    Debug.Print "  - rs Is Nothing: " & (rs Is Nothing)
    
    If Not rs Is Nothing Then
        Debug.Print "  - rs.EOF: " & rs.EOF
        Debug.Print "  - rs.BOF: " & rs.BOF
        Debug.Print "  - rs.Fields.Count: " & rs.fields.Count
        
        ' 檢查 Recordset 狀態
        On Error Resume Next
        Dim rsState As Long
        rsState = rs.State
        If Err.Number = 0 Then
            Debug.Print "  - rs.State: " & rsState & " (1=Open, 0=Closed)"
        Else
            Debug.Print "  - rs.State: 無法取得 (" & Err.Description & ")"
            Err.Clear
        End If
        On Error GoTo ErrorHandler
        
        If Not (rs.EOF And rs.BOF) Then
            On Error Resume Next
            Dim rsRecordCount As Long
            rsRecordCount = rs.recordCount
            If Err.Number = 0 Then
                Debug.Print "  - rs.RecordCount: " & rsRecordCount
            Else
                Debug.Print "  - rs.RecordCount: 無法取得 (" & Err.Description & ")"
                Err.Clear
            End If
            On Error GoTo ErrorHandler
        End If
    End If

    ' --- 將資料寫入 Excel ---
    If Not (rs.EOF And rs.BOF) Then ' 有資料
        rs.MoveFirst
        fieldCount = rs.fields.Count
        
        ' 安全取得記錄數
        On Error Resume Next
        recordCount = rs.recordCount
        If Err.Number <> 0 Then
            Debug.Print METHOD_NAME & " - 警告: 無法取得 RecordCount，改用計數方式"
            Err.Clear
            recordCount = 0
            rs.MoveFirst
            Do While Not rs.EOF
                recordCount = recordCount + 1
                rs.MoveNext
            Loop
            rs.MoveFirst
        End If
        On Error GoTo ErrorHandler

        Debug.Print METHOD_NAME & " - 開始寫入資料: " & recordCount & " 筆記錄, " & fieldCount & " 個欄位"

        ' 寫入標題行
        For i = 0 To fieldCount - 1
            ws.Cells(1, i + 1).value = rs.fields(i).Name
            Debug.Print "  - 欄位 " & (i + 1) & ": " & rs.fields(i).Name & " (類型: " & rs.fields(i).Type & ")"
        Next i

        ' 複製資料 - 使用更安全的方法
        If recordCount > 0 Then
            Debug.Print METHOD_NAME & " - 嘗試使用 CopyFromRecordset 複製資料"
            
            On Error Resume Next
            ws.Range("A2").CopyFromRecordset rs, recordCount
            If Err.Number <> 0 Then
                Debug.Print METHOD_NAME & " - CopyFromRecordset 失敗: " & Err.Description
                Err.Clear
                
                ' 改用逐筆複製的方法
                Debug.Print METHOD_NAME & " - 改用逐筆複製方法"
                rs.MoveFirst
                Dim rowIndex As Long
                Dim colIndex As Long
                Dim cellValue As Variant
                
                rowIndex = 2
                Do While Not rs.EOF And rowIndex <= recordCount + 1
                    For colIndex = 0 To fieldCount - 1
                        ' 安全取得欄位值
                        On Error Resume Next
                        cellValue = rs.fields(colIndex).value
                        If Err.Number <> 0 Then
                            cellValue = "(錯誤: " & Err.Description & ")"
                            Err.Clear
                        End If
                        ws.Cells(rowIndex, colIndex + 1).value = cellValue
                        On Error GoTo ManualCopyError
                    Next colIndex
                    rs.MoveNext
                    rowIndex = rowIndex + 1
                Loop
                Debug.Print METHOD_NAME & " - 逐筆複製完成，共複製 " & (rowIndex - 2) & " 筆記錄"
            Else
                Debug.Print METHOD_NAME & " - CopyFromRecordset 成功"
            End If
            On Error GoTo ErrorHandler
        End If

        ' 格式化日期欄位
        For i = 0 To fieldCount - 1
            If rs.fields(i).Type = adDate Then
                If recordCount > 0 Then
                    ws.Range("A2").Offset(0, i).Resize(recordCount, 1).NumberFormat = "yyyy/mm/dd"
                End If
            End If
        Next i

        ' 自動調整欄寬
        ws.Columns.AutoFit
        
        Debug.Print METHOD_NAME & " - 資料寫入完成"
        
        ' 驗證資料是否真的寫入了
        Dim actualDataRows As Long
        actualDataRows = ws.UsedRange.rows.Count - 1 ' 減去標題行
        Debug.Print METHOD_NAME & " - 實際寫入的資料行數: " & actualDataRows
        
    Else
        ' 處理空 Recordset 但有欄位結構的情況
        Debug.Print METHOD_NAME & " - Recordset 是空的，但嘗試寫入欄位標題"
        If rs.fields.Count > 0 Then
            For i = 0 To rs.fields.Count - 1
                ws.Cells(1, i + 1).value = rs.fields(i).Name
            Next i
            ws.Columns.AutoFit
            ws.Cells(2, 1).value = "（此資料表沒有資料記錄）"
        Else
            ws.Cells(1, 1).value = "資料表 [" & tableName & "] 沒有欄位或無法讀取"
        End If
        Debug.Print "No data to load from Access table [" & tableName & "]."
    End If

    ShowPreview = True

Cleanup:
    On Error Resume Next
    If Not rs Is Nothing Then
        If rs.State = 1 Then rs.Close
    End If
    Set rs = Nothing
    If Not dal Is Nothing Then
        dal.Disconnect
    End If
    Set dal = Nothing
    Set ws = Nothing
    Application.ScreenUpdating = True
    Application.DisplayAlerts = True
    Exit Function

ManualCopyError:
    Debug.Print METHOD_NAME & " - 逐筆複製時發生錯誤，行: " & rowIndex & ", 列: " & (colIndex + 1) & ", 錯誤: " & Err.Description
    Resume Next ' 繼續下一個欄位

ErrorHandler:
    ShowPreview = False
    Debug.Print "--- " & MODULE_NAME & "." & METHOD_NAME & " Error ---"
    Debug.Print "Error Number: " & Err.Number
    Debug.Print "Error Source: " & Err.Source
    Debug.Print "Error Description: " & Err.Description
    
    ' 顯示錯誤資訊到工作表
    If Not ws Is Nothing Then
        ws.Cells(1, 1).value = "錯誤: " & Err.Description
    End If
    
    Application.DisplayAlerts = True
    Application.ScreenUpdating = True
    GoTo Cleanup
End Function

' 新增方法：為特定資料表尋找或創建專用的工作表
Private Function FindOrCreateSpecificPreviewSheet(ByVal tableName As String) As Worksheet
    Dim ws As Worksheet
    Dim targetCodeName As String
    Dim comp As Object ' VBComponent
    
    ' 為每個資料表設定唯一的 CodeName
    targetCodeName = "Preview_" & Replace(tableName, " ", "_") ' 移除空格避免 CodeName 問題
    targetCodeName = Left(targetCodeName, 31) ' CodeName 限制在 31 字元內
    
    On Error Resume Next ' 暫時忽略錯誤，以便檢查 CodeName
    Set FindOrCreateSpecificPreviewSheet = Nothing ' 預設傳回值

    ' 1. 嘗試透過 CodeName 尋找現有工作表
    For Each ws In ThisWorkbook.Worksheets
        If StrComp(ws.CodeName, targetCodeName, vbTextCompare) = 0 Then
            Set FindOrCreateSpecificPreviewSheet = ws
            Debug.Print "Found existing worksheet with CodeName: " & targetCodeName
            Exit Function ' 找到即返回
        End If
    Next ws
    On Error GoTo 0 ' 恢復預設錯誤處理

    ' 2. 如果找不到，則創建新工作表
    Debug.Print "Worksheet with CodeName '" & targetCodeName & "' not found. Creating a new one."
    Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))

    ' 3. 嘗試設定新工作表的 CodeName
    On Error Resume Next ' 捕捉設定 CodeName 可能發生的錯誤
    Set comp = ThisWorkbook.VBProject.VBComponents(ws.CodeName)
    comp.Name = targetCodeName
    If Err.Number <> 0 Then
        Debug.Print "Warning: Could not set CodeName for the new preview sheet '" & ws.Name & "' to '" & targetCodeName & "'." & _
                    " Please ensure 'Trust access to the VBA project object model' is enabled in Excel Options."
        Err.Clear
        ' 即使無法設定 CodeName，仍然傳回新建立的工作表供本次使用
    Else
        Debug.Print "Successfully set CodeName for sheet '" & ws.Name & "' to '" & targetCodeName & "'."
    End If
    On Error GoTo 0 ' 恢復預設錯誤處理

    Set FindOrCreateSpecificPreviewSheet = ws ' 傳回新建立的工作表
End Function

