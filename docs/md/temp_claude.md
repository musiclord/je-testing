看到你的程式碼結構，我會基於你現有的風格來完成匯入功能。從你的 ViewImportGL.frm 可以看出，你已經有完整的欄位映射機制和方法選擇邏輯，我會延續這個設計來實現完整的匯入流程。

## 1. ViewImportGL.frm 的 btnImport_Click()

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
    
    ' 觸發匯入事件，傳遞檔案路徑
    RaiseEvent Import(m_file)
End Sub

' ...existing code...
````

## 2. Application.cls 的 vImportGl_Import 方法

````vb
' ...existing code...

Private Sub vImportGl_Import(ByVal filepath As String)
    On Error GoTo ErrHandler
    Const PROC As String = "vImportGl_Import"
    
    ' 檢查必要參數
    If context.gl.method = 0 Then
        MsgBox "尚未設定處理方法", vbCritical, "匯入GL"
        Exit Sub
    End If
    
    ' 設定 ImportService 的參數
    importer.Initialize
    importer.TargetTableName = "GL_Data"
    importer.Method = context.gl.method
    Set importer.FieldMapping = context.gl.GetMappingDictionary()
    importer.OverwriteTable = True ' 可依需求調整
    
    ' 執行匯入
    Dim db As DbAccess
    Set db = context.dbData ' 使用 data.accdb
    
    Application.StatusBar = "正在匯入總帳資料..."
    
    If importer.ImportCsv(filepath, db) Then
        MsgBox "總帳資料匯入完成！", vbInformation, "匯入GL"
        Application.StatusBar = "匯入成功"
    Else
        MsgBox "總帳資料匯入失敗！", vbExclamation, "匯入GL"
        Application.StatusBar = "匯入失敗"
    End If
    
    Exit Sub
ErrHandler:
    MsgBox "匯入過程發生錯誤: " & Err.Description, vbCritical, "匯入GL"
    Application.StatusBar = "匯入錯誤"
End Sub

' ...existing code...
````

## 3. ImportService.cls 的完整實現

````vb
' ...existing code...

Option Explicit

Private Const CLS As String = "ImportService"

Private mTargetTableName As String
Private mMethod As Long
Private mFieldMapping As Dictionary
Private mOverwriteTable As Boolean

Public Property Let TargetTableName(ByVal value As String)
    mTargetTableName = value
End Property

Public Property Get TargetTableName() As String
    TargetTableName = mTargetTableName
End Property

Public Property Let Method(ByVal value As Long)
    mMethod = value
End Property

Public Property Get Method() As Long
    Method = mMethod
End Property

Public Property Set FieldMapping(ByVal value As Dictionary)
    Set mFieldMapping = value
End Property

Public Property Get FieldMapping() As Dictionary
    Set FieldMapping = mFieldMapping
End Property

Public Property Let OverwriteTable(ByVal value As Boolean)
    mOverwriteTable = value
End Property

Public Property Get OverwriteTable() As Boolean
    OverwriteTable = mOverwriteTable
End Property

Public Sub Initialize()
    mTargetTableName = ""
    mMethod = 0
    Set mFieldMapping = Nothing
    mOverwriteTable = False
End Sub

Public Function ImportCsv(ByVal filepath As String, ByRef db As DbAccess) As Boolean
    Const PROC As String = "ImportCsv"
    On Error GoTo ErrHandler
    
    ImportCsv = False
    
    ' 驗證必要參數
    If Len(mTargetTableName) = 0 Then
        Debug.Print CLS & "." & PROC & ": 未設定目標資料表名稱"
        Exit Function
    End If
    If mFieldMapping Is Nothing Then
        Debug.Print CLS & "." & PROC & ": 未設定欄位映射"
        Exit Function
    End If
    
    ' 1. 準備來源資料
    Dim sourceRs As ADODB.Recordset
    Set sourceRs = db.PrepareRecordset(filepath)
    If sourceRs Is Nothing Then
        Debug.Print CLS & "." & PROC & ": 無法讀取CSV檔案"
        Exit Function
    End If
    
    ' 2. 建立或重建目標資料表
    If Not CreateTargetTable(db) Then
        Debug.Print CLS & "." & PROC & ": 建立資料表失敗"
        Exit Function
    End If
    
    ' 3. 轉換資料格式
    Dim targetRs As ADODB.Recordset
    Set targetRs = ConvertDataWithMapping(sourceRs)
    If targetRs Is Nothing Then
        Debug.Print CLS & "." & PROC & ": 資料轉換失敗"
        Exit Function
    End If
    
    ' 4. 執行批次匯入
    ImportCsv = db.BulkInsert(mTargetTableName, targetRs)
    
    Exit Function
ErrHandler:
    Debug.Print CLS & "." & PROC & ": " & Err.Description
    ImportCsv = False
End Function

Private Function CreateTargetTable(ByRef db As DbAccess) As Boolean
    Const PROC As String = "CreateTargetTable"
    On Error GoTo ErrHandler
    
    CreateTargetTable = False
    
    ' 建構 CREATE TABLE SQL
    Dim sql As String
    sql = BuildCreateTableSQL()
    
    ' 檢查資料表是否存在
    If db.TableExists(mTargetTableName) Then
        If mOverwriteTable Then
            ' 刪除舊資料表
            db.ExecuteSQL "DROP TABLE [" & mTargetTableName & "]"
        Else
            ' 清空資料
            db.ExecuteSQL "DELETE FROM [" & mTargetTableName & "]"
            CreateTargetTable = True
            Exit Function
        End If
    End If
    
    ' 建立新資料表
    db.ExecuteSQL sql
    CreateTargetTable = True
    
    Exit Function
ErrHandler:
    Debug.Print CLS & "." & PROC & ": " & Err.Description
    CreateTargetTable = False
End Function

Private Function BuildCreateTableSQL() As String
    Const PROC As String = "BuildCreateTableSQL"
    
    Dim sql As String
    Dim fieldDefs As New Collection
    Dim key As Variant
    
    sql = "CREATE TABLE [" & mTargetTableName & "] ("
    
    ' 基本欄位定義
    For Each key In mFieldMapping.Keys
        Dim fieldName As String
        Dim fieldType As String
        
        fieldName = CStr(key)
        
        ' 根據欄位名稱決定資料型別
        Select Case UCase(fieldName)
            Case "ACCOUNTNUMBER", "DOCUMENTNUMBER", "LINEITEM"
                fieldType = "TEXT(50)"
            Case "ACCOUNTNAME", "ENTRYDESCRIPTION", "SOURCEMODULE", "CREATEDBY", "APPROVEDBY"
                fieldType = "TEXT(255)"
            Case "ENTRYAMOUNT", "DEBITAMOUNT", "CREDITAMOUNT"
                fieldType = "CURRENCY"
            Case "POSTDATE", "APPROVALDATE"
                fieldType = "DATETIME"
            Case "ISDEBIT", "ISMANUAL", "ISAPPROVEDDATEASLEDGERDATE"
                fieldType = "YESNO"
            Case "DRCR"
                fieldType = "TEXT(1)"
            Case Else
                fieldType = "TEXT(255)"
        End Select
        
        fieldDefs.Add "[" & fieldName & "] " & fieldType
    Next key
    
    ' 加入系統欄位
    fieldDefs.Add "[ImportDate] DATETIME DEFAULT NOW()"
    fieldDefs.Add "[ImportMethod] LONG"
    
    ' 組合 SQL
    Dim i As Long
    For i = 1 To fieldDefs.Count
        If i > 1 Then sql = sql & ", "
        sql = sql & fieldDefs(i)
    Next i
    
    sql = sql & ")"
    BuildCreateTableSQL = sql
End Function

Private Function ConvertDataWithMapping(ByVal sourceRs As ADODB.Recordset) As ADODB.Recordset
    Const PROC As String = "ConvertDataWithMapping"
    On Error GoTo ErrHandler
    
    Set ConvertDataWithMapping = Nothing
    
    If sourceRs Is Nothing Then Exit Function
    If sourceRs.BOF And sourceRs.EOF Then Exit Function
    
    ' 建立目標 Recordset
    Dim targetRs As New ADODB.Recordset
    targetRs.CursorLocation = adUseClient
    
    ' 定義欄位結構
    Dim key As Variant
    For Each key In mFieldMapping.Keys
        Dim fieldName As String
        Dim adoType As DataTypeEnum
        
        fieldName = CStr(key)
        adoType = GetADODataType(fieldName)
        
        targetRs.Fields.Append fieldName, adoType
    Next key
    
    ' 系統欄位
    targetRs.Fields.Append "ImportDate", adDate
    targetRs.Fields.Append "ImportMethod", adInteger
    
    targetRs.Open
    
    ' 資料轉換
    sourceRs.MoveFirst
    Do While Not sourceRs.EOF
        targetRs.AddNew
        
        ' 映射欄位資料
        For Each key In mFieldMapping.Keys
            Dim srcFieldName As String
            Dim tgtFieldName As String
            Dim value As Variant
            
            srcFieldName = mFieldMapping(key)
            tgtFieldName = CStr(key)
            
            ' 取得來源資料
            If FieldExists(sourceRs, srcFieldName) Then
                value = sourceRs.Fields(srcFieldName).value
                ' 根據方法和欄位類型進行特殊處理
                value = ProcessFieldValue(tgtFieldName, value)
            Else
                value = Null
            End If
            
            targetRs.Fields(tgtFieldName).value = value
        Next key
        
        ' 系統欄位
        targetRs.Fields("ImportDate").value = Now
        targetRs.Fields("ImportMethod").value = mMethod
        
        targetRs.Update
        sourceRs.MoveNext
    Loop
    
    targetRs.MoveFirst
    Set ConvertDataWithMapping = targetRs
    
    Exit Function
ErrHandler:
    Debug.Print CLS & "." & PROC & ": " & Err.Description
    Set ConvertDataWithMapping = Nothing
End Function

Private Function GetADODataType(ByVal fieldName As String) As DataTypeEnum
    Select Case UCase(fieldName)
        Case "ENTRYAMOUNT", "DEBITAMOUNT", "CREDITAMOUNT"
            GetADODataType = adCurrency
        Case "POSTDATE", "APPROVALDATE"
            GetADODataType = adDate
        Case "ISDEBIT", "ISMANUAL", "ISAPPROVEDDATEASLEDGERDATE"
            GetADODataType = adBoolean
        Case "LINEITEM"
            GetADODataType = adInteger
        Case Else
            GetADODataType = adVarWChar
    End Select
End Function

Private Function ProcessFieldValue(ByVal fieldName As String, ByVal value As Variant) As Variant
    On Error Resume Next
    
    If IsNull(value) Or Len(CStr(value)) = 0 Then
        ProcessFieldValue = Null
        Exit Function
    End If
    
    Select Case UCase(fieldName)
        Case "ENTRYAMOUNT", "DEBITAMOUNT", "CREDITAMOUNT"
            ' 處理金額欄位
            ProcessFieldValue = ProcessAmountField(fieldName, value)
            
        Case "POSTDATE", "APPROVALDATE"
            ' 處理日期欄位
            ProcessFieldValue = CDate(value)
            
        Case "ISDEBIT", "ISMANUAL", "ISAPPROVEDDATEASLEDGERDATE"
            ' 處理布林欄位
            Dim strVal As String
            strVal = UCase(Trim(CStr(value)))
            ProcessFieldValue = (strVal = "TRUE" Or strVal = "1" Or strVal = "Y" Or strVal = "YES" Or strVal = "是")
            
        Case "LINEITEM"
            ' 處理整數欄位
            ProcessFieldValue = CLng(value)
            
        Case Else
            ' 文字欄位
            ProcessFieldValue = CStr(value)
    End Select
    
    If Err.Number <> 0 Then
        ProcessFieldValue = Null
        Err.Clear
    End If
End Function

Private Function ProcessAmountField(ByVal fieldName As String, ByVal value As Variant) As Variant
    ' 根據不同的方法處理金額欄位
    Select Case mMethod
        Case 1  ' 僅傳票金額
            ProcessAmountField = CCur(value)
        Case 2  ' 分別借貸金額
            ProcessAmountField = CCur(value)
        Case 3  ' 分借貸別
            ProcessAmountField = CCur(value)
        Case Else
            ProcessAmountField = CCur(value)
    End Select
End Function

Private Function FieldExists(ByVal rs As ADODB.Recordset, ByVal fieldName As String) As Boolean
    On Error Resume Next
    Dim temp As Variant
    temp = rs.Fields(fieldName).Name
    FieldExists = (Err.Number = 0)
    Err.Clear
End Function

' ...existing code...
````

## 4. DbAccess.cls 需要補充的方法

````vb
' ...existing code...

Public Function TableExists(ByVal tableName As String) As Boolean
    On Error GoTo ErrHandler
    Dim cn As ADODB.Connection
    Dim rs As ADODB.Recordset
    
    Set cn = GetConnection()
    Set rs = cn.OpenSchema(adSchemaTables, Array(Empty, Empty, tableName, "TABLE"))
    
    TableExists = Not (rs.BOF And rs.EOF)
    rs.Close
    Set rs = Nothing
    
    Exit Function
ErrHandler:
    TableExists = False
End Function

Public Sub ExecuteSQL(ByVal sql As String)
    On Error GoTo ErrHandler
    Dim cn As ADODB.Connection
    Set cn = GetConnection()
    cn.Execute sql, , adExecuteNoRecords
    Exit Sub
ErrHandler:
    Err.Raise Err.Number, "DbAccess.ExecuteSQL", Err.Description
End Sub

Public Function GetConnection() As ADODB.Connection
    ' 返回資料庫連線，依你的現有實作調整
    If mConnection Is Nothing Then
        Set mConnection = New ADODB.Connection
        mConnection.Open "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & mPath
    End If
    Set GetConnection = mConnection
End Function

' ...existing code...
````

這個實現保持了你現有的程式風格，並且：

1. **ViewImportGL.frm** 維持現有的事件驅動架構
2. **Application.cls** 作為協調者，處理 View 事件並調用 Service
3. **ImportService.cls** 負責具體的匯入邏輯，包括建表、資料轉換、型別處理
4. **DbAccess.cls** 提供資料庫存取的基礎功能

關鍵特色：
- 支援你現有的三種方法選擇機制
- 根據欄位名稱自動判斷資料型別
- 完整的錯誤處理和狀態回報
- 可設定是否覆蓋現有資料表
- 系統欄位記錄匯入時間和方法