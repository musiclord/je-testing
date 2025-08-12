VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ImportService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Model: Import Service
'Description: Handle any data import logics and uses AccessDAL for database operation.

Private Const adDate As Long = 7 ' <-- 用於 LoadToExcel 的日期格式化
Private Const MODULE_NAME As String = "ImportService" ' <-- 加入模組名稱常數

Private Sub Class_Initialize()

End Sub

Public Function ImportToAccess(ByVal csvFilePath As String, ByVal accessDbPath As String, ByVal tableName As String, ByVal csvEncoding As Long) As Boolean
    Dim startTime As Double
    startTime = Timer

    Dim adoStream As ADODB.stream
    Dim conn As ADODB.Connection
    Dim sql As String
    Dim line As String
    Dim headers() As String
    Dim values() As String
    Dim i As Long
    Dim columnCount As Long
    Dim blnSuccess As Boolean
    Dim fso As Scripting.FileSystemObject ' Still needed for file checks

    On Error GoTo ErrorHandler
    ImportToAccess = False ' Default to failure

    ' --- 1. 設定物件 ---
    Set fso = New Scripting.FileSystemObject ' For file existence checks
    Set adoStream = New ADODB.stream
    Set conn = New ADODB.Connection

    ' --- 2. 檢查檔案是否存在 ---
    If Not fso.FileExists(csvFilePath) Then
        Err.Raise vbObjectError + 513, MODULE_NAME & ".ImportToAccess", "CSV 檔案未找到: " & csvFilePath
        GoTo Cleanup
    End If
    If Not fso.FileExists(accessDbPath) Then
        Err.Raise vbObjectError + 514, MODULE_NAME & ".ImportToAccess", "Access 資料庫未找到: " & accessDbPath
        GoTo Cleanup
    End If

    ' --- 3. 設定 ADODB.Stream ---
    adoStream.Type = adTypeText ' Read as text
    ' Set Charset based on detected encoding
    Select Case csvEncoding
        Case 65001 ' UTF-8
            adoStream.Charset = "utf-8"
            Debug.Print "ADODB.Stream: Setting Charset to utf-8"
        Case 950 ' Big5 (Traditional Chinese)
            adoStream.Charset = "big5" ' Or use "windows-950"
            Debug.Print "ADODB.Stream: Setting Charset to big5"
        Case Else ' Assume system default ANSI if unknown, though passing specific code is better
            adoStream.Charset = "ascii" ' Fallback, might be incorrect
            Debug.Print "ADODB.Stream: Warning - Unknown encoding " & csvEncoding & ", falling back to ascii."
    End Select
    adoStream.Charset = "utf-8"
    Debug.Print "ADODB.Stream: Setting Charset to utf-8"
    adoStream.LineSeparator = adCRLF ' Common line ending, adjust if needed (adCR, adLF)

    ' --- 4. 開啟並讀取 CSV 檔案 ---
    adoStream.Open
    adoStream.LoadFromFile csvFilePath
    Debug.Print "ADODB.Stream: Loaded file " & csvFilePath

    ' --- 5. 連接 Access 資料庫 ---
    conn.ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & accessDbPath & ";"
    conn.Open
    Debug.Print "ADODB Connection Opened to: " & accessDbPath

    ' --- 6. 準備 Access 表格 ---
    ' a. 嘗試刪除舊表格
    On Error Resume Next
    sql = "DROP TABLE [" & tableName & "];"
    Debug.Print "Attempting to drop table: " & tableName
    conn.Execute sql, , adExecuteNoRecords
    If Err.Number <> 0 Then
        Debug.Print "Warning: Could not drop table '" & tableName & "' (may not exist). Error: " & Err.Description
        Err.Clear
    End If
    On Error GoTo ErrorHandler

    ' b. 讀取 CSV 標頭
    If Not adoStream.EOS Then ' EOS = End Of Stream
        line = adoStream.ReadText(adReadLine) ' Read the header line
        headers = SplitCSVLine(line) ' Use robust Split function
        columnCount = UBound(headers) + 1
        Debug.Print "CSV Headers read (" & columnCount & " columns): " & Join(headers, "|")
    Else
        Err.Raise vbObjectError + 515, MODULE_NAME & ".ImportToAccess", "CSV 檔案為空或無法讀取標頭。"
        GoTo Cleanup
    End If

    ' c. 建立新表格 (所有欄位為 TEXT)
    sql = "CREATE TABLE [" & tableName & "] ("
    For i = 0 To UBound(headers)
        Dim colName As String
        colName = Trim(headers(i)) ' Trim spaces from header
        If Len(colName) = 0 Then colName = "Column" & (i + 1)
        colName = "[" & colName & "]" ' Enclose in brackets
        sql = sql & colName & " TEXT(255)"
        If i < UBound(headers) Then sql = sql & ", "
    Next i
    sql = sql & ");"
    Debug.Print "Creating table with SQL: " & sql
    conn.Execute sql, , adExecuteNoRecords
    Debug.Print "Table '" & tableName & "' created successfully."

    ' --- 7. 讀取資料行並插入 Access ---
    conn.BeginTrans

    Do While Not adoStream.EOS
        line = adoStream.ReadText(adReadLine) ' Read data line
        If Trim(line) <> "" Then
            values = SplitCSVLine(line) ' Use robust Split function

            If UBound(values) + 1 = columnCount Then
                sql = "INSERT INTO [" & tableName & "] ("
                ' Build column list for INSERT statement
                For i = 0 To UBound(headers)
                    Dim headerName As String
                    headerName = Trim(headers(i))
                    If Len(headerName) = 0 Then headerName = "Column" & (i + 1)
                    sql = sql & "[" & headerName & "]"
                    If i < UBound(headers) Then sql = sql & ", "
                Next i
                sql = sql & ") VALUES ("

                ' Build values list for INSERT statement
                For i = 0 To UBound(values)
                    Dim sqlValue As String
                    sqlValue = Replace(values(i), "'", "''") ' Escape single quotes
                    sql = sql & "'" & sqlValue & "'" ' Enclose in single quotes
                    If i < UBound(values) Then sql = sql & ", "
                Next i
                sql = sql & ");"
                ' Debug.Print "Executing Insert: " & sql ' Uncomment for detailed insert logging
                conn.Execute sql, , adExecuteNoRecords
            Else
                 Debug.Print "Warning: Skipping line due to column count mismatch (" & (UBound(values) + 1) & " vs " & columnCount & "). Line: " & line
            End If
        End If
    Loop

    conn.CommitTrans
    Debug.Print "Data insertion complete."

    ' --- 8. 完成 ---
    ImportToAccess = True

Cleanup:
    On Error Resume Next
    If Not adoStream Is Nothing Then
        If adoStream.State = adStateOpen Then adoStream.Close
        Set adoStream = Nothing
    End If
    If Not conn Is Nothing Then
        If conn.State = adStateOpen Then conn.Close
        Set conn = Nothing
    End If
    Set fso = Nothing
    On Error GoTo 0

    Debug.Print MODULE_NAME & ".ImportToAccess completed in " & Format(Timer - startTime, "0.00") & " seconds. Success: " & ImportToAccess
    Exit Function

ErrorHandler:
    Debug.Print "Error in " & MODULE_NAME & ".ImportToAccess:"
    Debug.Print "Error Number: " & Err.Number
    Debug.Print "Error Description: " & Err.Description
    Debug.Print "Source: " & Err.Source
    If Not conn Is Nothing Then
        If conn.State = adStateOpen Then
            On Error Resume Next
            conn.RollbackTrans
            On Error GoTo 0
        End If
    End If
    ImportToAccess = False
    GoTo Cleanup
End Function

' --- 輔助函數：更可靠地分割 CSV 行 (處理引號) ---
Private Function SplitCSVLine(ByVal TextLine As String, Optional ByVal Delimiter As String = ",") As String()
    Dim result() As String
    Dim CurrentField As String
    Dim InQuotes As Boolean
    Dim Char As String
    Dim i As Long, j As Long

    ReDim result(0 To 0)
    j = 0
    InQuotes = False
    CurrentField = ""

    If TextLine = "" Then
        SplitCSVLine = result ' Return array with one empty element for empty line
        Exit Function
    End If

    For i = 1 To Len(TextLine)
        Char = Mid$(TextLine, i, 1)

        If InQuotes Then
            If Char = """" Then
                ' Check for escaped quote ("")
                If i < Len(TextLine) And Mid$(TextLine, i + 1, 1) = """" Then
                    CurrentField = CurrentField & """"
                    i = i + 1 ' Skip next quote
                Else
                    InQuotes = False ' End of quoted field
                End If
            Else
                CurrentField = CurrentField & Char
            End If
        Else ' Not in quotes
            If Char = Delimiter Then
                ' End of field
                result(j) = CurrentField
                j = j + 1
                ReDim Preserve result(0 To j)
                CurrentField = ""
            ElseIf Char = """" And CurrentField = "" Then ' Allow quotes only at start of field
                InQuotes = True ' Start of quoted field
            Else
                CurrentField = CurrentField & Char
            End If
        End If
    Next i

    ' Add the last field
    result(j) = CurrentField
    SplitCSVLine = result
End Function

