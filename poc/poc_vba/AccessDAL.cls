VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "AccessDAL"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const MODULE_NAME As String = "AccessDAL"
Private Const DB_PROVIDER As String = "Microsoft.ACE.OLEDB.12.0"
Private m_conn As Object ' - Late binding
Private m_DbPath As String
Private m_EnableDebugPrinting As Boolean

' --- Public Properties ---

Public Property Get DatabasePath() As String
    DatabasePath = m_DbPath
End Property

Public Property Let DatabasePath(ByVal value As String)
    If m_conn Is Nothing Then
        m_DbPath = value
    ElseIf IsConnected() Then
        Err.Raise vbObjectError + 513, MODULE_NAME & ".DatabasePath", "Cannot change DatabasePath while connection is open."
    Else
        m_DbPath = value
    End If
End Property

' 新增屬性來控制 Debug.Print
Public Property Get EnableDebugPrinting() As Boolean
    EnableDebugPrinting = m_EnableDebugPrinting
End Property

Public Property Let EnableDebugPrinting(ByVal value As Boolean)
    m_EnableDebugPrinting = value
End Property

' --- Connection Management ---

Public Function Connect() As Boolean
    Const METHOD_NAME As String = "Connect"
    Dim fso As Object ' Scripting.FileSystemObject - Late Binding
    Dim dbCreated As Boolean
    dbCreated = False ' 標記資料庫是否在此次呼叫中被建立

    On Error GoTo ErrorHandler ' 設定錯誤處理

    ' --- 1. 檢查資料庫路徑 ---
    If m_DbPath = "" Then
         Err.Raise vbObjectError + 514, MODULE_NAME & "." & METHOD_NAME, "DatabasePath is not set." ' 資料庫路徑未設定
    End If

    ' --- 2. 檢查資料庫檔案是否存在 ---
    Set fso = CreateObject("Scripting.FileSystemObject") ' 建立檔案系統物件
    If Not fso.FileExists(m_DbPath) Then
        ' --- 3. 如果資料庫不存在則建立 (使用 ADOX - 後期綁定) ---
        Dim cat As Object ' ADOX.Catalog - Late Binding
        Dim createConnStr As String

        On Error Resume Next ' 暫時停用 CreateObject 的錯誤處理
        Set cat = CreateObject("ADOX.Catalog") ' 建立 ADOX Catalog 物件
        If Err.Number <> 0 Then
            Set fso = Nothing
            Err.Raise vbObjectError + 518, MODULE_NAME & "." & METHOD_NAME, "Failed to create ADOX.Catalog object. Ensure 'Microsoft ADO Ext. for DDL and Security' components are available or registered." ' 建立 ADOX Catalog 物件失敗
            GoTo Cleanup ' 若 ADOX 物件建立失敗則離開
        End If
        On Error GoTo ErrorHandler ' 恢復預設錯誤處理

        ' 用於建立資料庫的連接字串
        createConnStr = "Provider=" & DB_PROVIDER & ";" & _
                        "Data Source=" & m_DbPath & ";"
                        ' 建立時不需要 Persist Security Info

        On Error Resume Next ' 處理資料庫建立過程中可能發生的錯誤
        cat.Create createConnStr ' 執行建立資料庫的動作
        If Err.Number <> 0 Then
            Dim createErrorDesc As String
            createErrorDesc = Err.Description ' 擷取錯誤描述
            Set cat = Nothing
            Set fso = Nothing
            Err.Clear ' 清除錯誤後再引發新錯誤
            Err.Raise vbObjectError + 519, MODULE_NAME & "." & METHOD_NAME, "Failed to create new database file at '" & m_DbPath & "'. Error: " & createErrorDesc ' 建立新資料庫檔案失敗
            GoTo Cleanup ' 若建立失敗則離開
        End If
        On Error GoTo ErrorHandler ' 恢復預設錯誤處理

        Set cat = Nothing ' 釋放 ADOX 物件
        dbCreated = True ' 標記資料庫已建立
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Successfully created new database file: " & m_DbPath ' 成功建立新資料庫檔案
    End If
    Set fso = Nothing ' 釋放 FileSystemObject

    ' --- 4. 初始化並開啟連線 ---
    If m_conn Is Nothing Then
        Set m_conn = CreateObject("ADODB.Connection") ' 後期綁定，建立 ADODB Connection 物件
    End If

    If Not IsConnected() Then ' 如果尚未連線
        Dim connStr As String
        ' 設定連接字串
        connStr = "Provider=" & DB_PROVIDER & ";" & _
                  "Data Source=" & m_DbPath & ";" & _
                  "Persist Security Info=False;"
        m_conn.ConnectionString = connStr ' 設定連線物件的連接字串
        m_conn.Open ' 開啟連線
        If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Connection opened successfully to: " & m_DbPath ' 成功開啟連線
    Else
        If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Connection was already open to: " & m_DbPath ' 連線已開啟
    End If

    Connect = IsConnected() ' 設定函數回傳值為目前的連線狀態

    ' 可選：如果資料庫剛被建立，通知使用者
    If dbCreated Then
        ' MsgBox "已成功建立新的資料庫檔案：" & vbCrLf & m_dbPath, vbInformation, "資料庫建立"
        ' 考慮此處是否適合使用 MsgBox，或僅記錄日誌。記錄日誌的侵入性較小。
    End If

Cleanup: ' 清理標籤
    Set fso = Nothing ' 確保 FSO 在離開或錯誤時被釋放
    ' Set cat = Nothing ' 確保 ADOX 物件被釋放 (上面已處理，但再次設定是安全的)
    Exit Function ' 離開函數

ErrorHandler: ' 錯誤處理程序
    If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Error: " & Err.Description
    Connect = False ' 設定函數回傳值為 False (連線失敗)
    ' 將錯誤引發給呼叫者
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description
    GoTo Cleanup ' 引發錯誤後跳至清理程序
End Function

Public Sub Disconnect()
    On Error Resume Next ' Ignore errors if already closed or not initialized
    If Not m_conn Is Nothing Then
        If IsConnected() Then
            m_conn.Close
        End If
        Set m_conn = Nothing
    End If
    On Error GoTo 0
End Sub

Public Function IsConnected() As Boolean
    On Error Resume Next
    If m_conn Is Nothing Then
        IsConnected = False
    Else
        IsConnected = (m_conn.State = 1) ' adStateOpen = 1
    End If
    On Error GoTo 0
End Function

' --- Data Manipulation (DML) & Data Definition (DDL) ---

Public Function ExecuteSQL(ByVal sql As String, Optional ByVal useTransaction As Boolean = False) As Long
    Const METHOD_NAME As String = "ExecuteSQL"
    Dim recordsAffected As Long
    Dim dbPathFromConn As String ' For verification
    ExecuteSQL = -1 ' Default to error

    If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & ".ExecuteSQL - Received SQL: " & sql

    On Error GoTo ErrorHandler

    ' --- Enhanced Connection Check ---
    ' Check if connection object exists and is open. If not, try to connect.
    If m_conn Is Nothing Then ' <-- Use m_conn
        If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & ".ExecuteSQL - Connection object is Nothing. Attempting to connect..."
        If Not Me.Connect Then ' Assumes Connect method uses m_DatabasePath
            Err.Raise vbObjectError + 514, MODULE_NAME & "." & METHOD_NAME, "Failed to establish database connection before executing SQL. Check DatabasePath property."
            GoTo Cleanup ' Exit if connection fails
        End If
    ElseIf Not IsConnected() Then ' <-- Use IsConnected() which checks m_conn.State
        If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & ".ExecuteSQL - Connection state is not open. Attempting to reconnect..."
        If Not Me.Connect Then ' Try to reconnect
             Err.Raise vbObjectError + 515, MODULE_NAME & "." & METHOD_NAME, "Failed to re-establish database connection before executing SQL. Check DatabasePath property."
             GoTo Cleanup ' Exit if reconnection fails
        End If
    End If
    ' --- End Enhanced Connection Check ---

    ' --- Verify Connection String and Path Existence (Optional but recommended) ---
    If m_EnableDebugPrinting Then
        Debug.Print MODULE_NAME & ".ExecuteSQL - Connection State before Execute: " & CStr(m_conn.State) ' <-- Use m_conn
        Debug.Print MODULE_NAME & ".ExecuteSQL - Connection String before Execute: " & m_conn.ConnectionString ' <-- Use m_conn
    End If

    ' Extract database path from the current connection string for verification
    On Error Resume Next ' In case connection string parsing fails or lacks "Data Source"
    dbPathFromConn = "" ' Reset path
    If InStr(1, m_conn.ConnectionString, "Data Source=", vbTextCompare) > 0 Then ' <-- Use m_conn
        dbPathFromConn = Mid(m_conn.ConnectionString, InStr(1, m_conn.ConnectionString, "Data Source=", vbTextCompare) + Len("Data Source=")) ' <-- Use m_conn
        If InStr(dbPathFromConn, ";") > 0 Then ' Check if there are more parts after the path
             dbPathFromConn = Split(dbPathFromConn, ";")(0)
        End If
        ' Trim potential quotes
         If Left(dbPathFromConn, 1) = """" And Right(dbPathFromConn, 1) = """" Then
             dbPathFromConn = Mid(dbPathFromConn, 2, Len(dbPathFromConn) - 2)
         End If
    End If
    On Error GoTo ErrorHandler ' Restore default error handling
    
    If dbPathFromConn = "" Then
        Debug.Print MODULE_NAME & ".ExecuteSQL - WARNING: Could not extract database path from connection string: " & m_conn.ConnectionString ' <-- Use m_conn
    Else
        If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & ".ExecuteSQL - Extracted DB Path from Connection: '" & dbPathFromConn & "'"
        ' Use FileSystemObject for a more robust check
        Dim fso As Object
        Set fso = CreateObject("Scripting.FileSystemObject")
        If Not fso.FileExists(dbPathFromConn) Then
            Debug.Print MODULE_NAME & ".ExecuteSQL - ERROR: Database file NOT FOUND at path from connection string: " & dbPathFromConn
            Set fso = Nothing ' Release before raising error
            Err.Raise vbObjectError + 516, MODULE_NAME & "." & METHOD_NAME, "Database file specified in connection string not found: " & dbPathFromConn
            GoTo Cleanup ' Should not be reached if Err.Raise works
        Else
            If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & ".ExecuteSQL - Database file confirmed FOUND at path from connection string."
        End If
        Set fso = Nothing
    End If
    ' --- End Verification ---
    
    If m_EnableDebugPrinting Then Debug.Print MODULE_NAME & ".ExecuteSQL - Executing SQL on connection..."
    If useTransaction Then m_conn.BeginTrans ' <-- Use m_conn
    
    m_conn.Execute sql, recordsAffected, 128 ' adExecuteNoRecords = 128 <-- Use m_conn
    
    If useTransaction Then m_conn.CommitTrans ' <-- Use m_conn
    
    ExecuteSQL = recordsAffected ' Success

Cleanup:
    ' Optional: Decide if connection should be closed here or managed elsewhere
    Exit Function

ErrorHandler:
    If useTransaction And Not m_conn Is Nothing Then ' <-- Use m_conn
        If IsConnected() Then ' <-- Use IsConnected() which checks m_conn
            On Error Resume Next ' Avoid error during rollback if connection lost
            m_conn.RollbackTrans ' <-- Use m_conn
            On Error GoTo 0
        End If
    End If
    ExecuteSQL = -1 ' Indicate error
    Dim errorDesc As String
    errorDesc = "Error executing SQL: " & sql & " - " & Err.Description
    Debug.Print "--- " & MODULE_NAME & "." & METHOD_NAME & " Error ---"
    Debug.Print "Error Number: " & Err.Number
    Debug.Print "Error Source: " & Err.Source & " (Original Error: " & Err.Description & ")"
    ' Raise a more informative error, including the original description
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, errorDesc
    GoTo Cleanup ' Should not be reached if Err.Raise works
End Function

' --- Data Query (DQL) ---

Public Function GetRecordset(ByVal sql As String, Optional ByVal disconnectRecordset As Boolean = False) As Object ' ADODB.Recordset - Late binding
    Const METHOD_NAME As String = "GetRecordset"
    Dim rs As Object ' ADODB.Recordset
    On Error GoTo ErrorHandler
    
    If Not Connect() Then
        Err.Raise vbObjectError + 515, MODULE_NAME & "." & METHOD_NAME, "Failed to connect to database."
    End If
    
    Set rs = CreateObject("ADODB.Recordset") ' Late binding
    rs.CursorLocation = 3 ' adUseClient = 3
    rs.Open sql, m_conn, 3, 1 ' adOpenStatic = 3, adLockReadOnly = 1

    If disconnectRecordset Then
        Set rs.ActiveConnection = Nothing ' Disconnect the recordset
        ' Note: Connection can be closed here if ONLY disconnected recordsets are needed by the caller
        ' Disconnect ' Uncomment if appropriate
    End If
    
    Set GetRecordset = rs
    Set rs = Nothing ' Release local variable
    Exit Function

ErrorHandler:
    Set GetRecordset = Nothing
    If Not rs Is Nothing Then
        If rs.State = 1 Then rs.Close ' adStateOpen = 1
        Set rs = Nothing
    End If
    ' Log error details if needed
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, "Error getting Recordset for SQL: " & sql & " - " & Err.Description
End Function

' --- Schema Operations ---

Public Function tableExists(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "TableExists"
    Dim rs As Object ' ADODB.Recordset
    On Error GoTo ErrorHandler
    
    If Not Connect() Then
         Err.Raise vbObjectError + 515, MODULE_NAME & "." & METHOD_NAME, "Failed to connect to database."
    End If
    
    ' adSchemaTables = 20
    Set rs = m_conn.OpenSchema(20, Array(Empty, Empty, tableName, "TABLE"))
    tableExists = Not rs.EOF
    rs.Close
    Set rs = Nothing
    Exit Function

ErrorHandler:
    tableExists = False ' Assume false on error
    If Not rs Is Nothing Then
        If rs.State = 1 Then rs.Close ' adStateOpen = 1
        Set rs = Nothing
    End If
    ' Log error details if needed, but might just return False
    ' Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description
End Function

Public Sub DropTable(ByVal tableName As String)
    Const METHOD_NAME As String = "DropTable"
    Dim sql As String
    On Error GoTo ErrorHandler
    
    If tableExists(tableName) Then
        sql = "DROP TABLE [" & EscapeTableNameForSQL(tableName) & "]" ' Modified to use EscapeTableNameForSQL
        ExecuteSQL sql
    End If
    Exit Sub

ErrorHandler:
    ' Log error details if needed
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, "Error dropping table: " & tableName & " - " & Err.Description
End Sub

Public Function GetTableNames() As Variant ' Returns array of table names or Empty if none/error
    Const METHOD_NAME As String = "GetTableNames"
    Dim rs As Object ' ADODB.Recordset
    Dim tblList As Collection ' Changed type hint for clarity
    Dim tblName As String
    Dim result() As String
    Dim i As Long
    On Error GoTo ErrorHandler
    
    If Not Connect() Then
        Err.Raise vbObjectError + 515, MODULE_NAME & "." & METHOD_NAME, "Failed to connect to database."
    End If
    
    Set tblList = New Collection ' Use VBA's built-in Collection
    
    Set rs = m_conn.OpenSchema(20, Array(Empty, Empty, Empty, "TABLE"))
    Do While Not rs.EOF
        tblName = rs.fields("TABLE_NAME").value ' Use Fields collection by name
        ' Filter out system tables (MSys*) and temporary tables (~*)
        If Not (Left$(tblName, 4) = "MSys" Or Left$(tblName, 1) = "~") Then
            tblList.Add tblName
        End If
        rs.MoveNext
    Loop
    rs.Close
    Set rs = Nothing
    
    If tblList.Count > 0 Then
        ReDim result(1 To tblList.Count)
        For i = 1 To tblList.Count
            result(i) = tblList(i)
        Next i
        GetTableNames = result
    Else
        GetTableNames = Empty ' Return Empty if no user tables found
    End If
    
    Set tblList = Nothing
    Exit Function
    
ErrorHandler:
    GetTableNames = Empty ' Return Empty on error
    If Not rs Is Nothing Then
        If rs.State = 1 Then rs.Close ' adStateOpen = 1
        Set rs = Nothing
    End If
    Set tblList = Nothing
    ' Log error details if needed
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description
End Function

Public Function GetScalar(ByVal sql As String) As Variant
    Const METHOD_NAME As String = "GetScalar"
    Dim rs As Object ' ADODB.Recordset - 後期綁定
    
    On Error GoTo ErrorHandler
    GetScalar = Null ' 預設返回 Null (如果查詢無結果)
    
    ' --- 1. 確保資料庫已連接 ---
    If Not Me.IsConnected() Then
         If Not Me.Connect Then
             Err.Raise vbObjectError + 515, MODULE_NAME & "." & METHOD_NAME, "無法連接到資料庫。"
             GoTo Cleanup ' 如果 Err.Raise 正常工作，則不應到達此處
         End If
    End If
    
    ' --- 2. 創建並打開 Recordset ---
    Set rs = CreateObject("ADODB.Recordset")
    rs.Open sql, m_conn, 0, 1 ' adOpenForwardOnly, adLockReadOnly
    
    ' --- 3. 檢查是否有結果並獲取值 ---
    If Not rs.EOF Then
        If Not IsNull(rs.fields(0).value) Then
            GetScalar = rs.fields(0).value
        End If
    End If
    
Cleanup: ' 清理資源
    On Error Resume Next ' 清理階段忽略錯誤
    If Not rs Is Nothing Then
        If rs.State = 1 Then rs.Close ' 1 = adStateOpen
        Set rs = Nothing
    End If
    Exit Function ' 正常退出

ErrorHandler: ' 錯誤處理
    GetScalar = CVErr(xlErrValue) ' 發生錯誤時返回 Error 值
    Debug.Print "--- " & MODULE_NAME & "." & METHOD_NAME & " 錯誤 ---"
    Debug.Print "SQL: " & sql
    Debug.Print "錯誤: " & Err.Description & " (" & Err.Number & ")"
    ' 將錯誤向上拋給呼叫者
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, "GetScalar 中發生錯誤: " & Err.Description
    GoTo Cleanup ' 不應到達此處
End Function

' 獲取指定資料表的記錄數
Public Function GetRecordCount(ByVal tableName As String) As Long
    Const METHOD_NAME As String = "GetRecordCount"
    Dim sql As String
    Dim result As Variant

    On Error GoTo ErrorHandler
    GetRecordCount = -1 ' 預設為錯誤

    If Trim$(tableName) = "" Then
        Err.Raise vbObjectError + 501, MODULE_NAME & "." & METHOD_NAME, "資料表名稱不可為空。"
        GoTo Cleanup
    End If

    ' --- 1. 確保連接 ---
    If Not Me.IsConnected() Then
        If Not Me.Connect() Then
            Err.Raise vbObjectError + 502, MODULE_NAME & "." & METHOD_NAME, "無法連接到資料庫。"
            GoTo Cleanup
        End If
    End If

    ' --- 2. 在嘗試計數之前檢查資料表是否存在 ---
    '    如果 GetScalar 本身不檢查，這可以防止 GetScalar 因資料表不存在而失敗。
    If Not Me.tableExists(tableName) Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料表 '" & tableName & "' 不存在。返回 0 筆記錄。"
        GetRecordCount = 0 ' 資料表不存在，因此記錄數為 0。
        GoTo Cleanup
    End If

    ' --- 3. 建構 SQL 並獲取計數 ---
    sql = "SELECT COUNT(*) FROM [" & EscapeTableNameForSQL(tableName) & "]" ' EscapeTableNameForSQL is correctly called here
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - SQL: " & sql
    
    result = Me.GetScalar(sql)

    If IsError(result) Then ' 檢查 GetScalar 是否返回錯誤值
        ' GetScalar 已記錄錯誤，重新引發並附加上下文
        Err.Raise vbObjectError + 503, MODULE_NAME & "." & METHOD_NAME, "GetScalar 在計算資料表 '" & tableName & "' 的記錄數時失敗。"
    ElseIf IsNull(result) Then
        ' 對於現有資料表的 COUNT(*)，理想情況下不應發生此情況，
        ' 但如果發生，則視為 0 或錯誤。
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - GetScalar 為 COUNT(*) 返回 Null，假設資料表 '" & tableName & "' 的記錄數為 0。"
        GetRecordCount = 0
    Else
        GetRecordCount = CLng(result)
    End If

Cleanup: ' 清理標籤
    Exit Function

ErrorHandler: ' 錯誤處理程序
    GetRecordCount = -1 ' 確保返回錯誤
    Debug.Print "--- " & MODULE_NAME & "." & METHOD_NAME & " 錯誤 ---"
    Debug.Print "資料表: " & tableName
    Debug.Print "錯誤: " & Err.Description & " (" & Err.Number & ")"
    ' 將錯誤向上拋給呼叫者
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, "GetRecordCount 中發生錯誤: " & Err.Description
    GoTo Cleanup ' 不應到達此處
End Function

Private Function EscapeTableNameForSQL(ByVal rawName As String) As String
    ' Escapes a raw table name for safe inclusion INSIDE SQL brackets [ ].
    ' The main character to escape for content within brackets is the closing bracket itself.
    If rawName = "" Then
        EscapeTableNameForSQL = ""
    Else
        ' Replace any closing square bracket ] with a double closing square bracket ]]
        EscapeTableNameForSQL = Replace(rawName, "]", "]]")
    End If
End Function

Public Function GetTableFieldNames(ByVal tableName As String) As Variant ' Returns array or Empty
    Const METHOD_NAME As String = "GetTableFieldNames_Schema" ' Renamed slightly for clarity
    Dim rsSchema As Object ' ADODB.Recordset for schema
    Dim fieldNamesList As Object ' Using VBA Collection
    Dim fieldName As Variant
    Dim result() As String
    Dim i As Long
    Const adSchemaColumns = 4 ' From ADO constants

    On Error GoTo ErrorHandler
    Debug.Print vbCrLf & "--- Entering " & MODULE_NAME & "." & METHOD_NAME & " ---"
    Debug.Print "Parameter tableName: """ & tableName & """"

    If Not Me.IsConnected Then
        If Not Me.Connect Then
            GetTableFieldNames = Empty
            GoTo Cleanup
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Connection successful."
        End If
    Else
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Already connected."
    End If

    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Attempting to open schema for columns..."
    ' Open schema for columns of the specific table
    ' Arguments: SchemaEnum, Restrictions array (TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME)
    Set rsSchema = m_conn.OpenSchema(adSchemaColumns, Array(Empty, Empty, tableName, Empty))
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Schema recordset opened."

    If rsSchema.EOF Then ' Table might not exist or has no columns
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - No columns found in schema for table: " & tableName
        GetTableFieldNames = Empty
    Else
        Set fieldNamesList = New Collection ' Use VBA's built-in Collection
        Do While Not rsSchema.EOF
            fieldName = rsSchema.fields("COLUMN_NAME").value
            fieldNamesList.Add fieldName ' Add to collection
            rsSchema.MoveNext
        Loop

        If fieldNamesList.Count > 0 Then
            ReDim result(1 To fieldNamesList.Count) ' VBA Collection is 1-based
            For i = 1 To fieldNamesList.Count
                result(i) = fieldNamesList(i) ' Assign from collection
            Next i
            GetTableFieldNames = result
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Successfully retrieved " & fieldNamesList.Count & " field names via schema."
        Else
             Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Collection is empty after reading schema (unexpected)."
             GetTableFieldNames = Empty
        End If
        Set fieldNamesList = Nothing
    End If

Cleanup:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Entering CleanUp phase..."
    If Not rsSchema Is Nothing Then
        If rsSchema.State = 1 Then rsSchema.Close ' adStateOpen = 1
        Set rsSchema = Nothing
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Schema Recordset object cleaned up."
    End If
    Set fieldNamesList = Nothing ' Ensure collection is released
    Debug.Print "--- Exiting " & MODULE_NAME & "." & METHOD_NAME & " ---" & vbCrLf
    Exit Function

ErrorHandler:
    Debug.Print "!!! ERROR in " & MODULE_NAME & "." & METHOD_NAME & " for table: """ & tableName & """ !!!"
    Debug.Print "Error Number: " & Err.Number
    Debug.Print "Error Source: " & Err.Source
    Debug.Print "Error Description: " & Err.Description
    GetTableFieldNames = Empty
    GoTo Cleanup
End Function


' --- Initialization / Termination ---

Private Sub Class_Initialize()
    ' Set default database path, or leave empty to force setting it
    On Error Resume Next ' Avoid error if ThisWorkbook is not available (e.g., during compilation)
    m_DbPath = ThisWorkbook.Path & "\default.accdb"
    If Err.Number <> 0 Then m_DbPath = "" ' Reset if error occurred
    On Error GoTo 0
End Sub

Private Sub Class_Terminate()
    Disconnect ' Ensure connection is closed when object is destroyed
End Sub

