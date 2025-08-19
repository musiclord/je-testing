我是 GitHub Copilot。

已依你現有結構與風格補齊匯入流程，沿用你的事件驅動與 DAO/ADO 寫法。重點改動：
- View：在 btnImport_Click 補上防呆並沿用 RaiseEvent。
- Application：在 vImportGl_ApplyFields 將欄位映射與匯入方法傳入 ImportService；在 vImportGl_Import 設定目標表名並呼叫 ImportCsv。
- ImportService：根據欄位映射建立 Access 資料表（DAO DDL），以映射產生離線 ADODB.Recordset 做型別轉換與常數欄位填入，再交由 DbAccess.BulkInsert。
- DbAccess：沿用你現有 PrepareRecordset 與 BulkInsert（無破壞性修改）。

檔案
- [mvp/vba/ViewImportGL.frm](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\ViewImportGL.frm)
- [mvp/vba/Application.cls](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\Application.cls)
- [mvp/vba/ImportService.cls](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\ImportService.cls)
- [mvp/vba/DbAccess.cls](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\DbAccess.cls)

變更如下。

````vb
' ...existing code...
Private Sub btnImport_Click()
    If m_file = "" Then
        MsgBox "尚未選取檔案路徑", vbCritical, "選取檔案"
        Exit Sub
    End If
    If m_fields Is Nothing Then
        MsgBox "尚未套用欄位設定", vbCritical, "套用欄位"
        Exit Sub
    End If
    If m_method = 0 Then
        MsgBox "尚未選擇金額處理方式", vbCritical, "金額欄位"
        Exit Sub
    End If
    RaiseEvent Import(m_file)
End Sub
' ...existing code...
````

````vb
' ...existing code...
Private Sub vImportGl_ApplyFields(ByVal method As Long, ByVal fields As Dictionary)
    context.gl.method = method
    
    Dim key As Variant
    For Each key In fields.Keys
        context.gl.SetMapping key, fields(key)
    Next key
    context.gl.PrintFields
    
    ' 將映射與方法同步到 ImportService
    importer.SetGlMapping method, fields
End Sub

Private Sub vImportGl_Import(ByVal filepath As String)
    '--If Not context.dbPbc.BulkInsert()
    Dim db As DbAccess
    Set db = context.dbPbc
    ' 指定目標表名（如需變更可抽到 Context）
    importer.TargetTable = "gl_import"
    
    Application.StatusBar = "正在匯入總帳資料..."
    If Not importer.ImportCsv(filepath, db) Then
        MsgBox "總帳資料匯入失敗！", vbExclamation, "匯入GL"
        Application.StatusBar = "匯入失敗"
    Else
        '匯入GL成功
        MsgBox "總帳資料匯入完成！", vbInformation, "匯入GL"
        Application.StatusBar = "匯入成功"
    End If
End Sub
' ...existing code...
````

````vb
' ...existing code...
Option Explicit

Private Const CLS As String = "ImportService"

Private m_method As Long
Private m_fields As Dictionary           ' 由 View 傳入之欄位映射：key 為目標欄位(如 AccountNumber)，value 可能是來源欄名或常數/布林
Private m_targetTable As String

Public Sub Initialize()
    ' 保留
End Sub

Public Sub SetGlMapping(ByVal method As Long, ByVal fields As Dictionary)
    Set m_fields = fields
    m_method = method
End Sub

Public Property Let TargetTable(ByVal value As String)
    m_targetTable = value
End Property
Public Property Get TargetTable() As String
    If Len(m_targetTable) = 0 Then
        TargetTable = "gl_import"
    Else
        TargetTable = m_targetTable
    End If
End Property

Public Function ImportCsv(ByVal filepath As String, ByRef db As DbAccess) As Boolean
    Const PROC As String = "ImportCsv"
    On Error GoTo ErrorHandler
    Dim sourceRs As ADODB.Recordset
    Dim mappedRs As ADODB.Recordset
    
    If m_fields Is Nothing Then Err.Raise 5, CLS & "." & PROC, "未設定欄位映射"
    If m_method = 0 Then Err.Raise 5, CLS & "." & PROC, "未設定金額處理方式"
    
    ' 1) 讀入 CSV
    Set sourceRs = db.PrepareRecordset(filepath)
    If sourceRs Is Nothing Then Err.Raise 5, CLS & "." & PROC, "CSV 讀取失敗"
    
    ' 2) 依映射建立資料表（DAO DDL）
    Call EnsureTargetTable(db.path, TargetTable, m_fields, m_method)
    
    ' 3) 依映射建立離線 Recordset（欄位順序需與 CREATE TABLE 一致）
    Set mappedRs = BuildMappedRecordset(sourceRs, m_fields, m_method)
    
    ' 4) 寫入
    ImportCsv = db.BulkInsert(TargetTable, mappedRs)
    
    ' 清理
    On Error Resume Next
    If Not sourceRs Is Nothing Then If sourceRs.State = adStateOpen Then sourceRs.Close
    If Not mappedRs Is Nothing Then If mappedRs.State = adStateOpen Then mappedRs.Close
    Set sourceRs = Nothing
    Set mappedRs = Nothing
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
    ImportCsv = False
End Function

' 建立/重建資料表
Private Sub EnsureTargetTable(ByVal dbPath As String, ByVal tableName As String, ByVal fields As Dictionary, ByVal method As Long)
    Dim dbe As New DAO.DBEngine
    Dim tdb As DAO.Database
    Dim ddl As String
    Set tdb = dbe.OpenDatabase(dbPath, False, False)
    
    If DaoTableExists(tdb, tableName) Then
        tdb.Execute "DROP TABLE [" & tableName & "]", dbFailOnError
    End If
    ddl = BuildCreateTableSql(tableName, fields, method)
    tdb.Execute ddl, dbFailOnError
    tdb.Close
    Set tdb = Nothing
End Sub

Private Function DaoTableExists(ByVal db As DAO.Database, ByVal tableName As String) As Boolean
    On Error GoTo NOT_FOUND
    Dim t As DAO.TableDef
    Set t = db.TableDefs(tableName)
    DaoTableExists = True
    Exit Function
NOT_FOUND:
    DaoTableExists = False
End Function

Private Function BuildCreateTableSql(ByVal tableName As String, ByVal fields As Dictionary, ByVal method As Long) As String
    Dim colNames As Collection: Set colNames = OrderedTargetColumns(fields, method)
    Dim sb As String, i As Long
    For i = 1 To colNames.Count
        Dim colName As String: colName = CStr(colNames(i))
        sb = sb & ", [" & colName & "] " & AccessTypeFor(colName)
    Next
    BuildCreateTableSql = "CREATE TABLE [" & tableName & "] (" & Mid$(sb, 3) & ")"
End Function

' 依 GL 欄位語意回傳 Access DDL 型別
Private Function AccessTypeFor(ByVal colName As String) As String
    Select Case colName
        Case "LineItem": AccessTypeFor = "LONG"
        Case "PostDate", "ApprovalDate": AccessTypeFor = "DATETIME"
        Case "IsManual", "IsApprovedDateAsLedgerDate", "IsDebit": AccessTypeFor = "YESNO"
        Case "EntryAmount", "DebitAmount", "CreditAmount": AccessTypeFor = "CURRENCY"
        Case "DrCr": AccessTypeFor = "TEXT(8)"
        Case "DocumentNumber", "AccountNumber", "ApprovedBy", "CreatedBy", "SourceModule": AccessTypeFor = "TEXT(64)"
        Case "EntryDescription": AccessTypeFor = "TEXT(255)"
        Case "AccountName": AccessTypeFor = "TEXT(255)"
        Case Else: AccessTypeFor = "TEXT(255)"
    End Select
End Function

' 依建立順序建離線 ADODB.Recordset
Private Function BuildMappedRecordset(ByVal sourceRs As ADODB.Recordset, ByVal fields As Dictionary, ByVal method As Long) As ADODB.Recordset
    Dim rs As New ADODB.Recordset
    Dim cols As Collection: Set cols = OrderedTargetColumns(fields, method)
    Dim i As Long, col As String, adoType As DataTypeEnum, maxLen As Long
    
    rs.CursorLocation = adUseClient
    For i = 1 To cols.Count
        col = cols(i)
        adoType = AdoTypeFor(col, maxLen)
        If maxLen > 0 Then
            rs.Fields.Append col, adoType, maxLen
        Else
            rs.Fields.Append col, adoType
        End If
    Next
    rs.Open
    
    If Not (sourceRs.BOF And sourceRs.EOF) Then sourceRs.MoveFirst
    Do While Not sourceRs.EOF
        rs.AddNew
        For i = 1 To cols.Count
            col = cols(i)
            rs.Fields(col).Value = ResolveValue(sourceRs, fields, col, method)
        Next
        rs.Update
        sourceRs.MoveNext
    Loop
    rs.MoveFirst
    Set BuildMappedRecordset = rs
End Function

Private Function AdoTypeFor(ByVal colName As String, ByRef maxLen As Long) As DataTypeEnum
    maxLen = 0
    Select Case AccessTypeFor(colName)
        Case "LONG": AdoTypeFor = adInteger
        Case "DATETIME": AdoTypeFor = adDate
        Case "YESNO": AdoTypeFor = adBoolean
        Case "CURRENCY": AdoTypeFor = adCurrency
        Case Else
            Dim t As String: t = AccessTypeFor(colName)
            If Left$(t, 5) = "TEXT(" Then
                maxLen = CLng(Replace(Replace(Mid$(t, 6), ")", ""), " ", ""))
                If maxLen > 255 Then
                    AdoTypeFor = adLongVarWChar
                    maxLen = 0
                Else
                    AdoTypeFor = adVarWChar
                End If
            Else
                AdoTypeFor = adVarWChar
                maxLen = 255
            End If
    End Select
End Function

' 依映射與方法決定要輸出的目標欄位順序
Private Function OrderedTargetColumns(ByVal fields As Dictionary, ByVal method As Long) As Collection
    Dim order As Variant
    order = Array( _
        "AccountNumber", "AccountName", "DocumentNumber", "LineItem", _
        "PostDate", "EntryDescription", _
        "EntryAmount", "DebitAmount", "CreditAmount", "DrCr", "IsDebit", _
        "ApprovalDate", "ApprovedBy", "CreatedBy", "SourceModule", "IsManual", "IsApprovedDateAsLedgerDate")
    
    Dim cols As New Collection
    Dim i As Long, name As String
    For i = LBound(order) To UBound(order)
        name = CStr(order(i))
        ' 僅加入使用者有設定映射或常數的欄位
        If fields.Exists(name) Then
            If Not IsEmpty(fields(name)) Then
                If CStr(fields(name)) <> "" Or VarType(fields(name)) = vbBoolean Then
                    ' 金額方法：若 method=1 僅 EntryAmount；=2 僅 Debit/Credit；=3 可為 EntryAmount 或 DrCr/IsDebit
                    Select Case name
                        Case "EntryAmount"
                            If method = 1 Or method = 3 Then cols.Add name
                        Case "DebitAmount", "CreditAmount"
                            If method = 2 Then cols.Add name
                        Case "DrCr", "IsDebit"
                            If method = 3 Then cols.Add name
                        Case Else
                            cols.Add name
                    End Select
                End If
            End If
        End If
    Next
    Set OrderedTargetColumns = cols
End Function

' 解析每列欄位的值（來自來源欄位或常數），並做型別轉換
Private Function ResolveValue(ByVal src As ADODB.Recordset, ByVal fields As Dictionary, ByVal targetCol As String, ByVal method As Long) As Variant
    Dim mapping As Variant
    mapping = fields(targetCol)
    
    Dim raw As Variant
    If VarType(mapping) = vbBoolean Then
        raw = CBool(mapping)
    ElseIf Len(Trim$(CStr(mapping))) = 0 Then
        raw = Null
    ElseIf FieldExists(src, CStr(mapping)) Then
        raw = src.Fields(CStr(mapping)).Value
    Else
        ' 非來源欄位名，視為常數字串
        raw = mapping
    End If
    
    ResolveValue = ConvertByTarget(targetCol, raw)
End Function

Private Function FieldExists(ByVal rs As ADODB.Recordset, ByVal name As String) As Boolean
    On Error Resume Next
    Dim t As Variant
    t = rs.Fields(name).Type
    FieldExists = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
End Function

Private Function ConvertByTarget(ByVal targetCol As String, ByVal v As Variant) As Variant
    If IsNull(v) Or (VarType(v) = vbString And Trim$(CStr(v)) = "") Then
        ConvertByTarget = Null
        Exit Function
    End If
    On Error Resume Next
    Select Case AccessTypeFor(targetCol)
        Case "LONG": ConvertByTarget = CLng(v)
        Case "DATETIME": ConvertByTarget = CDate(v)
        Case "YESNO"
            Dim s As String: s = UCase$(Trim$(CStr(v)))
            If VarType(v) = vbBoolean Then
                ConvertByTarget = v
            ElseIf s = "Y" Or s = "YES" Or s = "TRUE" Or s = "1" Or s = "T" Then
                ConvertByTarget = True
            ElseIf s = "N" Or s = "NO" Or s = "FALSE" Or s = "0" Or s = "F" Then
                ConvertByTarget = False
            Else
                ConvertByTarget = Null
            End If
        Case "CURRENCY": ConvertByTarget = CCur(v)
        Case Else: ConvertByTarget = CStr(v)
    End Select
    If Err.Number <> 0 Then
        Err.Clear
        ConvertByTarget = Null
    End If
    On Error GoTo 0
End Function
' ...existing code...
````

DbAccess 兩個指定方法你已完成並相容目前流程。為了避免 CSV 檔鎖定，你可視需要在 PrepareRecordset 複製為 client-side Recordset 再關閉連線；若保持現狀也可正常運作，以下提供可選優化版本（不強制變更）。

````vb
// ...existing code...
Public Function PrepareRecordset(ByVal filepath As String) As ADODB.Recordset
    Const PROC As String = "PrepareRecordset"
    On Error GoTo ErrorHandler
    Dim conn As New ADODB.Connection
    Dim rs As New ADODB.Recordset
    Dim client As New ADODB.Recordset
    Dim connStr As String, folderpath As String, filename As String
    Dim sql As String, encoding As String
    encoding = "65001" 'utf-8
    folderpath = Left(filepath, InStrRev(filepath, "\") - 1)
    filename = Mid(filepath, InStrRev(filepath, "\") + 1)
    connStr = "Provider=Microsoft.ACE.OLEDB.12.0;" & _
            "Data Source=" & folderpath & ";" & _
            "Extended Properties=""Text;HDR=Yes;FMT=Delimited;IMEX=1;CharacterSet=" & encoding & """" 
    conn.Open