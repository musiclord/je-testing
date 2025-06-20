Option Explicit

' 測試模組：Power Query -> ADO Recordset -> DAO Access
' 處理百萬筆資料的高效能匯入測試

Private Const MODULE_NAME As String = "TestPowerQueryToAccess"

' =================== 主要測試方法 ===================
Public Sub TestImportFlow()
    ' 測試參數
    Dim csvPath As String: csvPath = "C:\Users\rlfang\Documents\JET\test_access\test.csv"
    Dim accessPath As String: accessPath = "C:\Users\rlfang\Documents\JET\test_access\test.accdb"
    Dim tableName As String: tableName = "data"
    
    Dim startTime As Double
    startTime = Timer
    
    Debug.Print "=== 開始測試 Power Query -> Access 匯入流程 ==="
    Debug.Print "CSV 檔案: " & csvPath
    Debug.Print "Access 資料庫: " & accessPath
    Debug.Print "目標資料表: " & tableName
    Debug.Print "開始時間: " & Now
    Debug.Print ""
    
    If ExecuteImportFlow(csvPath, accessPath, tableName) Then
        Debug.Print "=== 測試完成 ==="
        Debug.Print "總執行時間: " & Format(Timer - startTime, "0.00") & " 秒"
        Debug.Print "測試結果: 成功"
    Else
        Debug.Print "=== 測試失敗 ==="
        Debug.Print "總執行時間: " & Format(Timer - startTime, "0.00") & " 秒"
    End If
End Sub

' =================== 主要執行流程 ===================
Private Function ExecuteImportFlow(csvPath As String, accessPath As String, tableName As String) As Boolean
    On Error GoTo ErrorHandler
    ExecuteImportFlow = False
    
    Debug.Print "步驟 1: 建立 Power Query 查詢..."
    Dim queryTable As queryTable
    Set queryTable = CreatePowerQueryFromCSV(csvPath)
    If queryTable Is Nothing Then GoTo Cleanup
    
    Debug.Print "步驟 2: 讀取 Power Query 結果為 ADO Recordset..."
    Dim sourceRS As ADODB.Recordset
    Set sourceRS = GetRecordsetFromCSV(csvPath)
    If sourceRS Is Nothing Then GoTo Cleanup
    
    Debug.Print "步驟 3: 使用 DAO 批次寫入 Access..."
    If Not WriteAdoToDaoInBatches(sourceRS, accessPath, tableName) Then GoTo Cleanup
    
    ExecuteImportFlow = True

Cleanup:
    On Error Resume Next
    If Not sourceRS Is Nothing Then
        sourceRS.Close
        Set sourceRS = Nothing
    End If
    If Not queryTable Is Nothing Then
        queryTable.Delete
        Set queryTable = Nothing
    End If
    Exit Function

ErrorHandler:
    Debug.Print "錯誤發生在 ExecuteImportFlow: " & Err.Description
    GoTo Cleanup
End Function

' =================== Power Query 建立方法 ===================
Private Function CreatePowerQueryFromCSV(csvPath As String) As queryTable
    On Error GoTo ErrorHandler
    Set CreatePowerQueryFromCSV = Nothing
    
    Dim ws As Worksheet
    Dim qt As queryTable
    
    ' 建立臨時工作表（僅用於建立連線，不實際載入資料）
    Set ws = ThisWorkbook.Worksheets.Add
    ws.Name = "TempQuery_" & Format(Now, "hhmmss")
    
    ' 建立 QueryTable 但不重新整理
    Set qt = ws.QueryTables.Add( _
        Connection:="TEXT;" & csvPath, _
        Destination:=ws.Range("A1"))
    
    With qt
        .TextFileCommaDelimiter = True
        .TextFileParseType = xlDelimited
        .TextFileTextQualifier = xlTextQualifierDoubleQuote
        .TextFileConsecutiveDelimiter = False
        .TextFileTabDelimiter = False
        .TextFileSemicolonDelimiter = False
        .TextFileSpaceDelimiter = False
        .TextFileOtherDelimiter = False
        .TextFileTrailingMinusNumbers = True
        .RefreshOnFileOpen = False
        .BackgroundQuery = False
        .SaveData = False
    End With
    
    Debug.Print "Power Query 連線已建立（未載入資料）"
    Set CreatePowerQueryFromCSV = qt
    Exit Function

ErrorHandler:
    Debug.Print "建立 Power Query 時發生錯誤: " & Err.Description
    If Not ws Is Nothing Then Application.DisplayAlerts = False: ws.Delete: Application.DisplayAlerts = True
    Set CreatePowerQueryFromCSV = Nothing
End Function

' =================== 建立 ADO Recordset 方法 ===================
Private Function GetRecordsetFromCSV(csvPath As String) As ADODB.Recordset
    On Error GoTo ErrorHandler
    Set GetRecordsetFromCSV = Nothing
    
    Dim conn As ADODB.Connection
    Dim rs As ADODB.Recordset
    Dim connectionString As String
    Dim sql As String
    
    ' 建立 ADO 連線到 CSV 檔案
    Set conn = New ADODB.Connection
    
    connectionString = "Provider=Microsoft.ACE.OLEDB.12.0;" & _
                      "Data Source=" & Left(csvPath, InStrRev(csvPath, "\")) & ";" & _
                      "Extended Properties=""Text;HDR=Yes;FMT=Delimited;IMEX=1;CharacterSet=65001"""
    
    conn.Open connectionString
    
    ' 取得 CSV 檔案名稱
    Dim fileName As String
    fileName = Mid(csvPath, InStrRev(csvPath, "\") + 1)
    
    ' 建立 Recordset
    Set rs = New ADODB.Recordset
    sql = "SELECT * FROM [" & fileName & "]"
    
    rs.Open sql, conn, adOpenStatic, adLockReadOnly
    
    Debug.Print "ADO Recordset 已建立，記錄數: " & rs.RecordCount & " 筆"
    Debug.Print "欄位數: " & rs.Fields.Count
    
    ' 顯示前幾個欄位名稱
    Dim i As Integer
    Dim fieldNames As String
    For i = 0 To rs.Fields.Count - 1
        If i > 0 Then fieldNames = fieldNames & ", "
        fieldNames = fieldNames & rs.Fields(i).Name
        If i >= 4 Then fieldNames = fieldNames & "...": Exit For
    Next i
    Debug.Print "欄位名稱: " & fieldNames
    
    Set GetRecordsetFromCSV = rs
    Exit Function

ErrorHandler:
    Debug.Print "建立 CSV Recordset 時發生錯誤: " & Err.Description
    Debug.Print "連線字串: " & connectionString
    Set GetRecordsetFromCSV = Nothing
End Function

' =================== 修正的 DAO 批次寫入方法 ===================
Private Function WriteAdoToDaoInBatches(sourceRS As ADODB.Recordset, dbPath As String, tableName As String) As Boolean
    Dim ws As DAO.Workspace
    Dim db As DAO.Database
    Dim targetRS As DAO.Recordset
    Dim dataChunkArray As Variant
    Dim chunkSize As Long
    Dim rowsFetched As Long
    Dim totalRows As Long
    Dim batchCount As Long
    Dim i As Long, j As Long
    Dim startTime As Double
    
    On Error GoTo ErrorHandler
    WriteAdoToDaoInBatches = False
    startTime = Timer
    
    ' 設定批次大小
    chunkSize = 50000
    totalRows = 0
    batchCount = 0
    
    ' 建立 DAO Workspace 和 Database（修正事務處理）
    Set ws = DBEngine.Workspaces(0)
    Set db = ws.OpenDatabase(dbPath)
    
    ' 檢查並重建資料表
    If Not PrepareAccessTable(db, tableName, sourceRS) Then GoTo Cleanup
    
    ' 開啟目標資料表
    Set targetRS = db.OpenRecordset(tableName, dbOpenTable)
    
    Debug.Print "開始批次寫入，批次大小: " & chunkSize
    Debug.Print "總記錄數: " & sourceRS.RecordCount & " 筆"
    
    ' 分批處理資料
    Do While Not sourceRS.EOF
        batchCount = batchCount + 1
        
        ' 使用 GetRows 快速讀取一批資料
        dataChunkArray = sourceRS.GetRows(chunkSize)
        
        ' GetRows 回傳陣列格式: (欄位索引, 記錄索引)
        If IsArray(dataChunkArray) Then
            ' 處理單筆記錄的情況（GetRows 可能回傳一維陣列）
            If UBound(dataChunkArray, 1) >= 0 Then
                If UBound(dataChunkArray, 2) >= 0 Then
                    rowsFetched = UBound(dataChunkArray, 2) + 1
                Else
                    rowsFetched = 1 ' 只有一筆記錄
                End If
            Else
                rowsFetched = 0
            End If
            
            If rowsFetched > 0 Then
                ' 開始事務（正確的 DAO 語法）
                ws.BeginTrans
                
                ' 高速寫入記憶體陣列資料
                If rowsFetched = 1 And UBound(dataChunkArray, 2) < 0 Then
                    ' 處理單筆記錄（一維陣列）
                    targetRS.AddNew
                    For j = 0 To UBound(dataChunkArray, 1)
                        targetRS.Fields(j).Value = dataChunkArray(j)
                    Next j
                    targetRS.Update
                Else
                    ' 處理多筆記錄（二維陣列）
                    For i = 0 To rowsFetched - 1
                        targetRS.AddNew
                        For j = 0 To UBound(dataChunkArray, 1)
                            ' 檢查空值
                            If IsNull(dataChunkArray(j, i)) Then
                                targetRS.Fields(j).Value = ""
                            Else
                                targetRS.Fields(j).Value = dataChunkArray(j, i)
                            End If
                        Next j
                        targetRS.Update
                    Next i
                End If
                
                ' 提交事務（正確的 DAO 語法）
                ws.CommitTrans
                
                totalRows = totalRows + rowsFetched
                Debug.Print "批次 " & batchCount & " 完成，本批次: " & rowsFetched & " 筆，累計: " & totalRows & " 筆，進度: " & Format(totalRows / sourceRS.RecordCount * 100, "0.0") & "%"
            End If
        End If
        
        ' 每 10 個批次顯示一次時間資訊
        If batchCount Mod 10 = 0 Then
            Debug.Print "已處理 " & batchCount & " 批次，耗時: " & Format(Timer - startTime, "0.0") & " 秒"
        End If
    Loop
    
    Debug.Print "資料寫入完成！總計: " & totalRows & " 筆記錄"
    Debug.Print "總耗時: " & Format(Timer - startTime, "0.00") & " 秒"
    Debug.Print "平均速度: " & Format(totalRows / (Timer - startTime), "0") & " 筆/秒"
    WriteAdoToDaoInBatches = True

Cleanup:
    On Error Resume Next
    If Not targetRS Is Nothing Then targetRS.Close
    If Not db Is Nothing Then db.Close
    Set targetRS = Nothing
    Set db = Nothing
    Set ws = Nothing
    Exit Function

ErrorHandler:
    Debug.Print "DAO 寫入時發生錯誤: " & Err.Description
    Debug.Print "錯誤發生在批次: " & batchCount & "，累計已處理: " & totalRows & " 筆"
    
    ' 回滾事務（正確的 DAO 語法）
    On Error Resume Next
    If Not ws Is Nothing Then ws.Rollback
    On Error GoTo 0
    
    GoTo Cleanup
End Function


' =================== 輔助方法（保持不變）===================
Private Function PrepareAccessTable(db As DAO.Database, tableName As String, sampleRS As ADODB.Recordset) As Boolean
    On Error GoTo ErrorHandler
    PrepareAccessTable = False
    
    ' 刪除舊資料表
    On Error Resume Next
    db.Execute "DROP TABLE [" & tableName & "]"
    On Error GoTo ErrorHandler
    
    ' 根據 Recordset 結構建立新資料表
    Dim sql As String
    Dim i As Long
    
    sql = "CREATE TABLE [" & tableName & "] ("
    For i = 0 To sampleRS.Fields.Count - 1
        If i > 0 Then sql = sql & ", "
        sql = sql & "[" & sampleRS.Fields(i).Name & "] TEXT"
    Next i
    sql = sql & ")"
    
    db.Execute sql
    Debug.Print "資料表已重建: " & tableName
    PrepareAccessTable = True
    Exit Function

ErrorHandler:
    Debug.Print "準備 Access 資料表時發生錯誤: " & Err.Description
    PrepareAccessTable = False
End Function

