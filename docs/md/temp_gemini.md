好的，我將根據你的需求和現有的程式碼結構，完成這五個關鍵部分的匯入功能。

這個實作流程如下：
1.  **ViewImportGL.frm**：使用者在介面設定欄位如何對應、目標資料表名稱，然後點擊「匯入」按鈕。
2.  **`btnImport_Click`**：觸發事件，收集介面上的設定（欄位對應、目標表名），並呼叫 `Application` 層的匯入方法。
3.  **`Application.cls`**：作為協調者，它接收來自 View 的請求，建立 `ImportService`，執行匯入，並在完成後向使用者顯示成功或失敗的訊息。
4.  **`ImportService.cls`**：這是核心業務邏輯。它會根據傳入的欄位對應關係，動態產生 `CREATE TABLE` 的 SQL 語法。接著，它呼叫 `DbAccess` 讀取 CSV，並將讀取到的資料轉換成符合目標資料表結構的格式。
5.  **`DbAccess.cls`**：負責底層資料庫操作。`PrepareRecordset` 使用 Text IISAM 驅動程式將 CSV 檔案當作資料表讀取。`BulkInsert` 則使用參數化的 `INSERT` 查詢和資料庫交易，將資料高效且安全地寫入 Access 資料庫。

請將以下程式碼片段複製到對應的檔案中。

### 1. ViewImportGL.frm

這段程式碼假設你的表單上有一個 `ListView` 控制項（名稱為 `lvMapping`）用來設定欄位對應，一個 `TextBox`（`txtTargetTable`）用來輸入目標資料表名稱，以及一個 `CheckBox`（`chkOverwrite`）決定是否要覆蓋已存在的資料表。

````vb
' ...existing code...
Private Sub btnImport_Click()
    On Error GoTo EH
    Dim f As FileDialog
    Dim filePath As String
    Dim mappings As Collection
    Dim targetTable As String
    Dim overwrite As Boolean

    ' 1. 從表單收集設定
    targetTable = Trim$(Me.txtTargetTable.Value) ' 假設文字方塊名稱為 txtTargetTable
    If Len(targetTable) = 0 Then
        MsgBox "請輸入目標資料表名稱。", vbExclamation
        Exit Sub
    End If
    overwrite = (Me.chkOverwrite.Value = vbChecked) ' 假設核取方塊名稱為 chkOverwrite

    ' 2. 收集欄位映射資訊
    Set mappings = CollectFieldMapping()
    If mappings Is Nothing Or mappings.Count = 0 Then
        MsgBox "請設定有效的欄位映射。", vbExclamation
        Exit Sub
    End If

    ' 3. 讓使用者選取 CSV 檔案
    Set f = Application.FileDialog(msoFileDialogFilePicker)
    With f
        .AllowMultiSelect = False
        .Title = "請選取要匯入的總帳(GL) CSV 檔案"
        .Filters.Clear
        .Filters.Add "CSV 檔案", "*.csv"
        If .Show <> -1 Then Exit Sub ' 使用者取消
        filePath = .SelectedItems(1)
    End With

    ' 4. 將設定傳遞給 Application 層並觸發匯入
    '    假設你的專案中有一個全域可存取的 gApp 物件
    If gApp Is Nothing Then
        MsgBox "應用程式物件尚未初始化。", vbCritical
        Exit Sub
    End If

    gApp.ImportTargetTable = targetTable
    Set gApp.ImportMapping = mappings
    gApp.ImportOverwrite = overwrite

    gApp.vImportGl_Import filePath
    Exit Sub
EH:
    MsgBox "匯入程序發生未預期的錯誤：" & vbCrLf & Err.Description, vbCritical
End Sub

' 輔助函式：從 ListView 收集欄位映射
' 假設 ListView (lvMapping) 欄位: 1:勾選, 2:來源欄位, 3:目標欄位, 4:資料型別, 5:長度(選填)
Private Function CollectFieldMapping() As Collection
    On Error GoTo EH
    Dim result As New Collection
    Dim i As Long

    ' 檢查是否存在名為 lvMapping 的 ListView 控制項
    Dim ctrl As MSComctlLib.ListItem
    If Me.lvMapping.ListItems.Count = 0 Then Exit Function

    For Each ctrl In Me.lvMapping.ListItems
        If ctrl.Checked Then
            Dim mapping As Object 'Scripting.Dictionary
            Set mapping = CreateObject("Scripting.Dictionary")
            mapping("source") = ctrl.SubItems(1) ' 來源欄位
            mapping("target") = ctrl.SubItems(2) ' 目標欄位
            mapping("type") = UCase$(Trim$(ctrl.SubItems(3))) ' 資料型別
            If Len(Trim$(ctrl.SubItems(4))) > 0 Then
                mapping("length") = CLng(ctrl.SubItems(4)) ' 長度
            End If
            result.Add mapping
        End If
    Next
    Set CollectFieldMapping = result
    Exit Function
EH:
    MsgBox "讀取欄位映射時發生錯誤：" & Err.Description, vbExclamation
    Set CollectFieldMapping = Nothing
End Function
' ...existing code...
````

### 2. `Application.cls`

這裡新增了三個屬性來接收 View 傳來的設定，並實作 `vImportGl_Import` 來協調整個匯入流程。

````vb
' ...existing code...
' --- 匯入功能所需屬性 ---
Private m_ImportTargetTable As String
Private m_ImportMapping As Collection
Private m_ImportOverwrite As Boolean

Public Property Let ImportTargetTable(ByVal value As String): m_ImportTargetTable = value: End Property
Public Property Set ImportMapping(ByVal value As Collection): Set m_ImportMapping = value: End Property
Public Property Let ImportOverwrite(ByVal value As Boolean): m_ImportOverwrite = value: End Property
' -------------------------

Public Sub vImportGl_Import(ByVal filePath As String)
    On Error GoTo EH
    Dim db As DbAccess
    Dim importer As ImportService
    Dim success As Boolean
    Dim dbPath As String

    ' 取得資料庫路徑 (可依需求改為從設定檔讀取)
    dbPath = ThisWorkbook.Path & "\ooo\data.accdb"

    ' 建立相依物件
    Set db = New DbAccess
    db.Open dbPath

    Set importer = New ImportService
    importer.TargetTableName = m_ImportTargetTable
    Set importer.Mapping = m_ImportMapping
    importer.OverwriteTable = m_ImportOverwrite

    ' 執行匯入
    success = importer.ImportCsv(filePath, db)

    ' 顯示結果
    If success Then
        MsgBox "總帳(GL)資料已成功匯入至資料表 '" & m_ImportTargetTable & "'。", vbInformation
    Else
        MsgBox "總帳(GL)資料匯入失敗。", vbExclamation
    End If

    Set db = Nothing
    Set importer = Nothing
    Exit Sub
EH:
    MsgBox "執行匯入時發生嚴重錯誤：" & vbCrLf & Err.Description, vbCritical
End Sub
' ...existing code...
````

### 3. `ImportService.cls`

這是匯入的核心，負責建表、讀取、轉換資料。

````vb
' ...existing code...
Option Explicit

Public TargetTableName As String
Public Mapping As Collection ' 每個 item 都是一個 Dictionary: "source", "target", "type", "length"
Public OverwriteTable As Boolean

Public Function ImportCsv(ByVal filePath As String, ByRef db As DbAccess) As Boolean
    On Error GoTo EH
    Dim cn As ADODB.Connection
    Dim sourceRs As ADODB.Recordset
    Dim mappedRs As ADODB.Recordset

    ' 1. 準備資料庫連線與資料表
    Set cn = db.EnsureConnection()
    PrepareTable cn

    ' 2. 從 CSV 讀取原始資料
    Set sourceRs = db.PrepareRecordset(filePath)
    If sourceRs Is Nothing Then Err.Raise 513, "ImportService", "無法從 CSV 檔案讀取資料。"

    ' 3. 將原始資料依據映射轉換為結構化 Recordset
    Set mappedRs = BuildMappedRecordset(sourceRs, Me.Mapping)

    ' 4. 執行批次匯入
    ImportCsv = db.BulkInsert(Me.TargetTableName, mappedRs)

    sourceRs.Close
    mappedRs.Close
    Exit Function
EH:
    ImportCsv = False
    ' 可在此處加入錯誤日誌記錄
End Function

Private Sub PrepareTable(ByVal cn As ADODB.Connection)
    On Error GoTo EH
    Dim rs As ADODB.Recordset
    Dim tableExists As Boolean

    ' 檢查資料表是否存在
    Set rs = cn.OpenSchema(adSchemaTables, Array(Empty, Empty, Me.TargetTableName, "TABLE"))
    tableExists = Not rs.EOF
    rs.Close

    If tableExists Then
        If Me.OverwriteTable Then
            cn.Execute "DROP TABLE [" & Me.TargetTableName & "]", , adExecuteNoRecords
            cn.Execute BuildCreateTableSql(), , adExecuteNoRecords
        Else
            ' 若不覆蓋，則清空現有資料
            cn.Execute "DELETE FROM [" & Me.TargetTableName & "]", , adExecuteNoRecords
        End If
    Else
        ' 資料表不存在，直接建立
        cn.Execute BuildCreateTableSql(), , adExecuteNoRecords
    End If
    Exit Sub
EH:
    Err.Raise Err.Number, "PrepareTable", "準備資料表 '" & Me.TargetTableName & "' 失敗: " & Err.Description
End Sub

Private Function BuildCreateTableSql() As String
    Dim sql As String
    Dim colDefs As String
    Dim item As Object
    For Each item In Me.Mapping
        colDefs = colDefs & ", [" & item("target") & "] " & MapToAccessType(item)
    Next
    sql = "CREATE TABLE [" & Me.TargetTableName & "] (" & Mid$(colDefs, 3) & ")"
    BuildCreateTableSql = sql
End Function

Private Function MapToAccessType(ByVal mapItem As Object) As String
    Select Case mapItem("type")
        Case "TEXT": MapToAccessType = "TEXT(" & mapItem.Item("length") & ")"
        Case "LONG": MapToAccessType = "LONG"
        Case "DOUBLE": MapToAccessType = "DOUBLE"
        Case "CURRENCY": MapToAccessType = "CURRENCY"
        Case "DATETIME": MapToAccessType = "DATETIME"
        Case "YESNO": MapToAccessType = "YESNO"
        Case "MEMO": MapToAccessType = "MEMO"
        Case Else: MapToAccessType = "TEXT(255)" ' 預設型別
    End Select
End Function

Private Function BuildMappedRecordset(ByVal sourceRs As ADODB.Recordset, ByVal mappings As Collection) As ADODB.Recordset
    ' 建立一個符合目標結構的離線 Recordset
    Dim rs As New ADODB.Recordset
    Dim item As Object
    For Each item In mappings
        rs.Fields.Append item("target"), MapToAdoType(item("type")), IIf(item.Exists("length"), item("length"), 255)
    Next
    rs.Open

    ' 逐筆轉換資料
    If Not sourceRs.EOF Then sourceRs.MoveFirst
    Do While Not sourceRs.EOF
        rs.AddNew
        For Each item In mappings
            Dim rawValue As Variant
            On Error Resume Next ' 來源欄位可能不存在
            rawValue = sourceRs.Fields(item("source")).value
            On Error GoTo 0
            rs.Fields(item("target")).value = ConvertValue(rawValue, item("type"))
        Next
        rs.Update
        sourceRs.MoveNext
    Loop

    Set BuildMappedRecordset = rs
End Function

Private Function MapToAdoType(ByVal typeName As String) As ADODB.DataTypeEnum
    Select Case typeName
        Case "TEXT", "MEMO": MapToAdoType = adVarWChar
        Case "LONG": MapToAdoType = adInteger
        Case "DOUBLE": MapToAdoType = adDouble
        Case "CURRENCY": MapToAdoType = adCurrency
        Case "DATETIME": MapToAdoType = adDate
        Case "YESNO": MapToAdoType = adBoolean
        Case Else: MapToAdoType = adVarWChar
    End Select
End Function

Private Function ConvertValue(ByVal value As Variant, ByVal targetType As String) As Variant
    If IsNull(value) Or value = "" Then
        ConvertValue = Null
        Exit Function
    End If
    On Error Resume Next
    Select Case targetType
        Case "LONG": ConvertValue = CLng(value)
        Case "DOUBLE": ConvertValue = CDbl(value)
        Case "CURRENCY": ConvertValue = CCur(value)
        Case "DATETIME": ConvertValue = CDate(value)
        Case "YESNO": ConvertValue = CBool(value)
        Case Else: ConvertValue = CStr(value)
    End Select
    If Err.Number <> 0 Then ConvertValue = Null ' 轉換失敗則設為 Null
    On Error GoTo 0
End Function
' ...existing code...
````

### 4. & 5. `DbAccess.cls`

最後，這是資料存取層的實作。

````vb
' ...existing code...
Option Explicit

Private m_Conn As ADODB.Connection
Private m_DbPath As String

Public Sub Open(ByVal dbPath As String)
    m_DbPath = dbPath
End Sub

Public Function EnsureConnection() As ADODB.Connection
    If m_Conn Is Nothing Then Set m_Conn = New ADODB.Connection
    If m_Conn.State = adStateClosed Then
        m_Conn.Open "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & m_DbPath & ";"
    End If
    Set EnsureConnection = m_Conn
End Function

Public Function PrepareRecordset(ByVal filePath As String) As ADODB.Recordset
    On Error GoTo EH
    Dim folderPath As String, fileName As String
    With CreateObject("Scripting.FileSystemObject")
        folderPath = .GetParentFolderName(filePath)
        fileName = .GetFileName(filePath)
    End With

    Dim cn As New ADODB.Connection
    Dim rs As New ADODB.Recordset
    
    ' 使用 Text IISAM provider 讀取 CSV
    cn.Open "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & folderPath & _
            ";Extended Properties=""Text;HDR=Yes;FMT=Delimited;IMEX=1"";"
            
    rs.Open "SELECT * FROM [" & fileName & "]", cn, adOpenForwardOnly, adLockReadOnly
    
    ' 複製到離線 Recordset 以便釋放檔案鎖
    Dim clientRs As New ADODB.Recordset
    clientRs.CursorLocation = adUseClient
    clientRs.Open rs
    
    Set PrepareRecordset = clientRs
    
    rs.Close
    cn.Close
    Exit Function
EH:
    Set PrepareRecordset = Nothing
End Function

Public Function BulkInsert(ByVal tableName As String, ByVal sourceRs As ADODB.Recordset) As Boolean
    On Error GoTo EH
    If sourceRs Is Nothing Or sourceRs.RecordCount = 0 Then
        BulkInsert = True ' 沒有資料也算成功
        Exit Function
    End If

    Dim cn As ADODB.Connection
    Set cn = Me.EnsureConnection()

    Dim cmd As New ADODB.Command
    Dim fld As ADODB.Field
    Dim fldList As String, paramList As String

    For Each fld In sourceRs.Fields
        fldList = fldList & ",[" & fld.Name & "]"
        paramList = paramList & ",?"
    Next
    fldList = Mid$(fldList, 2)
    paramList = Mid$(paramList, 2)

    cn.BeginTrans
    With cmd
        .ActiveConnection = cn
        .CommandText = "INSERT INTO [" & tableName & "] (" & fldList & ") VALUES (" & paramList & ")"
        .CommandType = adCmdText
    End With

    sourceRs.MoveFirst
    Do While Not sourceRs.EOF
        cmd.Execute , GetRecordValues(sourceRs), adExecuteNoRecords
        sourceRs.MoveNext
    Loop

    cn.CommitTrans
    BulkInsert = True
    Exit Function
EH:
    If Not cn Is Nothing Then
        If cn.State = adStateOpen Then cn.RollbackTrans
    End If
    BulkInsert = False
End Function

Private Function GetRecordValues(ByVal rs As ADODB.Recordset) As Variant
    Dim values() As Variant
    ReDim values(0 To rs.Fields.Count - 1)
    Dim i As Long
    For i = 0 To rs.Fields.Count - 1
        values(i) = rs.Fields(i).value
    Next
    GetRecordValues = values
End Function

Private Sub Class_Terminate()
    If Not m_Conn Is Nothing Then
        If m_Conn.State = adStateOpen Then m_Conn.Close
        Set m_Conn = Nothing
    End If
End Sub
' ...existing code...
````

在開始使用前，請確保你的 VBA 專案已經引用了 **Microsoft ActiveX Data Objects 6.1 Library** (或更新版本) 和 **Microsoft Scripting Runtime**。

我的名字是 GitHub Copilot，希望這能幫助你完成專案！