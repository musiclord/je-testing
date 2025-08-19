以下依你現有結構做最小必要實作，完成 GL 匯入流程；延續你在表單的欄位映射與三種方法邏輯，避免過度設計。

重點
- View：補強 btnImport_Click 防呆（m_fields 與 m_method）。
- Application：沿用 context 設定，將 method/fields 同步到 ImportService，並呼叫 ImportCsv。
- ImportService：用 DAO 依映射動態建表，依方法建立離線 ADODB.Recordset 做型別轉換，再交由 DbAccess.BulkInsert。
- DbAccess：補上 DAO 開啟保證，避免 m_db/m_ws 尚未開啟時 BulkInsert 失敗。

變更

- 檔案: [mvp/vba/ViewImportGL.frm](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\ViewImportGL.frm)

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
    ' 觸發匯入事件，傳遞檔案路徑
    RaiseEvent Import(m_file)
End Sub
' ...existing code...
````

- 檔案: [mvp/vba/Application.cls](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\Application.cls)

````vb
' ...existing code...
Private Sub vImportGl_ApplyFields(ByVal method As Long, ByVal fields As Dictionary)
    context.gl.method = method
    
    Dim key As Variant
    For Each key In fields.Keys
        context.gl.SetMapping key, fields(key)
    Next key
    context.gl.PrintFields
    
    ' 同步到 ImportService（用於正式匯入）
    importer.SetGlMapping method, fields
End Sub

Private Sub vImportGl_Import(ByVal filepath As String)
    On Error GoTo ErrorHandler
    Dim db As DbAccess
    Set db = context.dbPbc  ' 依你現況：匯入至 pbc.accdb

    ' 指定目標資料表（可依需求調整）
    importer.TargetTable = "gl_import"

    Application.StatusBar = "正在匯入總帳資料..."
    If Not importer.ImportCsv(filepath, db) Then
        MsgBox "總帳資料匯入失敗！", vbExclamation, "匯入GL"
        Application.StatusBar = "匯入失敗"
    Else
        MsgBox "總帳資料匯入完成！", vbInformation, "匯入GL"
        Application.StatusBar = "匯入成功"
    End If
    Exit Sub
ErrorHandler:
    MsgBox "匯入過程發生錯誤: " & Err.Description, vbCritical, "匯入GL"
    Application.StatusBar = "匯入錯誤"
End Sub
' ...existing code...
````

- 檔案: [mvp/vba/ImportService.cls](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\ImportService.cls)

````vb
' ...existing code...
Option Explicit

Private Const CLS As String = "ImportService"

Private m_method As Long
Private m_fields As Dictionary           ' key=目標欄位, value=來源欄名或常數或布林
Private m_targetTable As String

Public Sub Initialize()
    m_method = 0
    Set m_fields = Nothing
    m_targetTable = ""
End Sub

Public Sub SetGlMapping(ByVal method As Long, ByVal fields As Dictionary)
    m_method = method
    Set m_fields = fields
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

    ImportCsv = False
    If m_fields Is Nothing Then Err.Raise 5, CLS & "." & PROC, "未設定欄位映射"
    If m_method = 0 Then Err.Raise 5, CLS & "." & PROC, "未設定金額處理方式"

    ' 1) 讀入 CSV
    Set sourceRs = db.PrepareRecordset(filepath)
    If sourceRs Is Nothing Then Err.Raise 5, CLS & "." & PROC, "CSV 讀取失敗"

    ' 2) 依映射建立/重建資料表（DAO DDL）
    Call EnsureTargetTable(db.path, TargetTable, m_fields, m_method)

    ' 3) 依映射建立離線 Recordset
    Set mappedRs = BuildMappedRecordset(sourceRs, m_fields, m_method)

    ' 4) 批次寫入
    ImportCsv = db.BulkInsert(TargetTable, mappedRs)

    ' 清理
    On Error Resume Next
    If sourceRs.State = adStateOpen Then sourceRs.Close
    If mappedRs.State = adStateOpen Then mappedRs.Close
    Set sourceRs = Nothing
    Set mappedRs = Nothing
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
    ImportCsv = False
End Function

' 建立/重建資料表（簡單、避免過度設計）
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

Private Function DaoTableExists(ByVal dbx As DAO.Database, ByVal tableName As String) As Boolean
    On Error GoTo NOT_FOUND
    Dim t As DAO.TableDef
    Set t = dbx.TableDefs(tableName)
    DaoTableExists = True
    Exit Function
NOT_FOUND:
    DaoTableExists = False
End Function

Private Function BuildCreateTableSql(ByVal tableName As String, ByVal fields As Dictionary, ByVal method As Long) As String
    Dim cols As Collection: Set cols = OrderedTargetColumns(fields, method)
    Dim sb As String, i As Long, name As String
    For i = 1 To cols.Count
        name = CStr(cols(i))
        sb = sb & ", [" & name & "] " & AccessTypeFor(name)
    Next
    BuildCreateTableSql = "CREATE TABLE [" & tableName & "] (" & Mid$(sb, 3) & ")"
End Function

' 決定要輸出的目標欄位順序（含三種方法）
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
        If fields.Exists(name) Then
            If VarType(fields(name)) = vbBoolean Or Len(Trim$(CStr(fields(name)))) > 0 Then
                Select Case name
                    Case "EntryAmount": If method = 1 Or method = 3 Then cols.Add name
                    Case "DebitAmount", "CreditAmount": If method = 2 Then cols.Add name
                    Case "DrCr", "IsDebit": If method = 3 Then cols.Add name
                    Case Else: cols.Add name
                End Select
            End If
        End If
    Next
    Set OrderedTargetColumns = cols
End Function

' Access 欄位型別（簡化規則）
Private Function AccessTypeFor(ByVal colName As String) As String
    Select Case colName
        Case "LineItem": AccessTypeFor = "LONG"
        Case "PostDate", "ApprovalDate": AccessTypeFor = "DATETIME"
        Case "IsManual", "IsApprovedDateAsLedgerDate", "IsDebit": AccessTypeFor = "YESNO"
        Case "EntryAmount", "DebitAmount", "CreditAmount": AccessTypeFor = "CURRENCY"
        Case "DrCr": AccessTypeFor = "TEXT(8)"
        Case "DocumentNumber", "AccountNumber": AccessTypeFor = "TEXT(64)"
        Case "ApprovedBy", "CreatedBy", "SourceModule": AccessTypeFor = "TEXT(64)"
        Case "EntryDescription", "AccountName": AccessTypeFor = "TEXT(255)"
        Case Else: AccessTypeFor = "TEXT(255)"
    End Select
End Function

' 依欄位型別建立離線 ADODB.Recordset 並填值
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
            rs.Fields(col).Value = ResolveValue(sourceRs, fields, col)
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
                    AdoTypeFor = adLongVarWChar: maxLen = 0
                Else
                    AdoTypeFor = adVarWChar
                End If
            Else
                AdoTypeFor = adVarWChar: maxLen = 255
            End If
    End Select
End Function

Private Function ResolveValue(ByVal src As ADODB.Recordset, ByVal fields As Dictionary, ByVal targetCol As String) As Variant
    Dim mapping As Variant: mapping = fields(targetCol)
    Dim raw As Variant

    If VarType(mapping) = vbBoolean Then
        raw = CBool(mapping)
    ElseIf Len(Trim$(CStr(mapping))) = 0 Then
        raw = Null
    ElseIf FieldExists(src, CStr(mapping)) Then
        raw = src.Fields(CStr(mapping)).Value
    Else
        raw = mapping ' 常數
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
            ElseIf s = "Y" Or s = "YES" Or s = "TRUE" Or s = "1" Or s = "T" Or s = "是" Then
                ConvertByTarget = True
            ElseIf s = "N" Or s = "NO" Or s = "FALSE" Or s = "0" Or s = "F" Or s = "否" Then
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

- 檔案: [mvp/vba/DbAccess.cls](c:\Users\rich2\Documents\GitHub\jet-vba\mvp\vba\DbAccess.cls)

````vb
' ...existing code...
' 保證 DAO 已開啟（避免 BulkInsert 使用 m_db 時為 Nothing）
Private Sub EnsureDaoOpen()
    If m_ws Is Nothing Then Set m_ws = DBEngine.Workspaces(0)
    If m_db Is Nothing Then
        If Len(m_path) = 0 Then Err.Raise 5, "DbAccess.EnsureDaoOpen", "未設定資料庫路徑"
        Set m_db = DBEngine.OpenDatabase(m_path, False, False)
    End If
End Sub

Public Function BulkInsert(ByVal tableName As String, ByVal sourceRs As ADODB.Recordset) As Boolean
    Const PROC As String = "BulkInsert"
    On Error GoTo ErrorHandler
    
    Call EnsureDaoOpen

    Dim targetRs As DAO.Recordset
    Dim dataChunk As Variant
    Dim fetched As Long, total As Long, batch As Long
    Dim i As Long, j As Long, v As Variant
    Dim startTime As Double, lastTime As Double
    Call PreventFreeze
    
    BulkInsert = False
    startTime = Timer
    lastTime = Timer
    total = 0
    batch = 0
    Set targetRs = m_db.OpenRecordset(tableName, dbOpenTable)
    ' ...existing code...
End Function
' ...existing code...
````

如何使用
- 在表單選好欄位與方法後，按「套用」會觸發 `Application.vImportGl_ApplyFields`，同步到 ImportService。
- 按「匯入」會觸發 `Application.vImportGl_Import`，以 `DbAccess.PrepareRecordset` 讀 CSV，交由 `ImportService.ImportCsv` 產生目標表與型別轉換，再呼叫 `DbAccess.BulkInsert`。

注意
- 需參考 Microsoft DAO 和 ADODB；你專案已在用 DAO/ADODB，無需額外變更。
- 目標表預設 gl_import，可在 `Application.vImportGl_Import` 調整。