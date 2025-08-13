VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Dal_Access"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Dal_Access"
'===============================================================================
' Module:   Dal_Access
' Purpose:  Access 資料庫的資料存取實作，提供 CRUD 操作和批次處理功能
' Layer:    Data Access Layer
' Domain:   Database Access
'===============================================================================
'額外註記:
'- 這裡使用 Microsoft Office 16.0 Access Database Engine Object Library 庫
'- Excel VBA 環境的限制（無法直接使用 DoCmd）

'--類別成員
Private Const CHUNK_SIZE As Long = 100000
Private Const DO_EVENTS_INTERVAL As Double = 2#
Private m_path As String
Private m_ws As DAO.Workspace
Private m_db As DAO.Database
Private m_conn As DAO.Connection
Private m_isConnected As Boolean
Private m_inTransaction As Boolean

'-- 類別事件
Private Sub Class_Initialize()
    m_isConnected = False
    m_inTransaction = False
End Sub

Private Sub Class_Terminate()
    On Error Resume Next
    If m_inTransaction Then RollbackTransaction
    If m_isConnected Then Disconnect
End Sub



'===============================================================================
' 連線管理
'===============================================================================
Public Property Get path() As String
     path = m_path
End Property
Public Property Let path(ByVal value As String)
    m_path = value
End Property

Public Property Get IsConnected() As Boolean
     IsConnected = m_isConnected
End Property

Public Sub Connect()
    Const METHOD_NAME As String = "Connect"
    On Error GoTo ErrorHandler
    '檢查是否已連線
    If m_isConnected Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已經連線"
        Exit Sub
    '驗證資料庫路徑
    ElseIf Len(m_path) = 0 Then
        Err.Raise vbObjectError + 1001, MODULE_NAME & "." & METHOD_NAME, "資料庫路徑未設定"
    '檢查資料庫檔案
    ElseIf Len(Dir(m_path)) = 0 Then
        Err.Raise vbObjectError + 1002, MODULE_NAME & "." & METHOD_NAME, "資料庫檔案不存在: " & m_path
    End If
    '建立私有容器
    Dim wsName As String
    wsName = "DAL_WS_" & Format(Now(), "yyyymmddhhnnss") & "_" & Rnd()
    Set m_ws = DBEngine.CreateWorkspace(wsName, "admin", "", dbUseJet)
    '建立全局容器
    'Set m_ws = DBEngine.Workspaces(0)
    
    Set m_db = m_ws.OpenDatabase(m_path, False, False)
    m_isConnected = True
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 連線至 " & m_path
    Exit Sub

ErrorHandler:
    m_isConnected = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Number & ": " & Err.Description
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description
End Sub

Public Sub Disconnect()
    Const METHOD_NAME As String = "Disconnect"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & m_db.name
    On Error GoTo ErrorHandler
    
    ' 檢查未完成的事務
    If m_inTransaction Then
         RollbackTransaction
    End If
    ' 紀錄工作區名稱
    Dim wsName As String
    If Not m_ws Is Nothing Then wsName = m_ws.name
    ' 關閉資料庫連線
    If Not m_db Is Nothing Then
        m_db.Close
        Set m_db = Nothing
    End If
    '關閉並移除工作區
    If Not m_ws Is Nothing Then
        m_ws.Close
        Set m_ws = Nothing
    End If
    m_isConnected = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已斷開連線"
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub



'===============================================================================
' 資料定義 DDL (Data Definition Language)
'===============================================================================

Public Function CreateTable(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "CreateTable"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sourceRs.Source & ", " & tableName
    On Error GoTo ErrorHandler
    
    CreateTable = False
    If Not m_isConnected Then Connect
    ' 刪除現有資料表
    If TableExists(tableName) Then
         DropTable tableName
    End If
    ' 建構 CREATE TABLE
    Dim field As String
    Dim logicalField As String
    Dim fieldType As String
    Dim sql As String
    Dim i As Long
    Dim gl As Ent_GL
    Dim tb As Ent_TB
    ' 根據資料表名稱決定使用哪個實體類別
    If UCase(tableName) = "GL" Then
        Set gl = New Ent_GL
    ElseIf UCase(tableName) = "TB" Then
        Set tb = New Ent_TB
    End If
    ' HEAD
    sql = "CREATE TABLE [" & tableName & "] ("
    ' BODY with TYPE
    For i = 0 To sourceRs.fields.count - 1
        If i > 0 Then sql = sql & ", "
        field = sourceRs.fields(i).name
        ' 進行欄位映射的反向查找，取得邏輯欄位名稱
        logicalField = GetLogicalFieldName(field, tableName)
        ' 根據邏輯欄位名稱取得資料型別
        If Not gl Is Nothing Then
            fieldType = gl.GetType(logicalField)
        ElseIf Not tb Is Nothing Then
            fieldType = tb.GetType(logicalField)
        Else
            fieldType = ""
        End If
        ' 如果 GetType 返回空值，使用預設類型
        If Len(Trim(fieldType)) = 0 Then
            fieldType = "TEXT(255)"
        End If
        sql = sql & "[" & field & "] " & fieldType
        ' 除錯輸出
        Debug.Print "Field: " & field & " -> " & logicalField & ", Type: " & fieldType
    Next i
    ' TAIL
    sql = sql & ")"
    ' 輸出完整的 SQL 語句用於除錯
    Debug.Print "CREATE TABLE SQL: " & sql
    ' 使用 DAO 執行 DDL
    m_db.Execute sql, dbFailOnError
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 資料表已建立 [" & tableName & "], " & sourceRs.fields.count & "欄位"
    CreateTable = True
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
    Debug.Print "Failed SQL: " & sql
End Function

Public Function DropTable(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "DropTable"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & tableName & ")"
    On Error GoTo ErrorHandler
    
     DropTable = False
    If Not m_isConnected Then Connect
    '檢查資料表
    If Not TableExists(tableName) Then
        DropTable = True
    Else
        '刪除資料表
        m_db.Execute "DROP TABLE [" & tableName & "]", dbFailOnError
        Debug.Print "已刪除資料表 [" & tableName & "]"
        DropTable = True
    End If
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function TableExists(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "TableExists"
    On Error GoTo ErrorHandler
    
    TableExists = False
    If Not m_isConnected Then Connect
    Dim tbl As DAO.tableDef
    '檢查資料表
    For Each tbl In m_db.TableDefs
        If UCase(tbl.name) = UCase(tableName) Then
            TableExists = True
            Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 資料表 [" & tableName & "] 存在"
            Exit For
        End If
    Next tbl
    
    If Not TableExists Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 資料表 [" & tableName & "] 不存在"
    End If
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--資料操作 DML (Data Manipulation Language)
Public Function ExecuteQuery(ByVal sql As String) As DAO.Recordset
    Const METHOD_NAME As String = "ExecuteQuery"
    On Error GoTo ErrorHandler
    If Not m_isConnected Then Connect
    Set ExecuteQuery = m_db.OpenRecordset(sql, dbOpenSnapshot)
    Exit Function
ErrorHandler:
    Set ExecuteQuery = Nothing
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

Public Function ExecuteNonQuery(ByVal sql As String) As Long
    Const METHOD_NAME As String = "ExecuteNonQuery"
    On Error GoTo ErrorHandler
    If Not m_isConnected Then Connect
    m_db.Execute sql, dbFailOnError
    ExecuteNonQuery = m_db.recordsAffected
    Exit Function
ErrorHandler:
    ExecuteNonQuery = -1
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

Public Function GetScalar(ByVal sql As String) As Variant
    Const METHOD_NAME As String = " GetScalar"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sql
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function GetRecordCount(ByVal tableName As String) As Long
    Const METHOD_NAME As String = "GetRecordCount"
    On Error GoTo ErrorHandler
    GetRecordCount = 0
    If Not m_isConnected Then Connect
    If Not TableExists(tableName) Then Exit Function
    Dim rs As DAO.Recordset
    Set rs = m_db.OpenRecordset("SELECT COUNT(*) AS C FROM [" & tableName & "];", dbOpenSnapshot)
    If Not rs.EOF Then GetRecordCount = rs.fields(0).value
    rs.Close
    Set rs = Nothing
    Exit Function
ErrorHandler:
    GetRecordCount = -1
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

'--批次操作 (Bulk Operations)
Public Function BulkInsert(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
    '將標準化 Recordset 進行大量插入
    Const METHOD_NAME As String = "BulkInsert"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & " --> " & sourceRs.Source & "; [" & tableName & "]"
    On Error GoTo ErrorHandler
    
    BulkInsert = False
    If Not m_isConnected Then Connect
    
    Dim targetRs As DAO.Recordset
    Dim dataChunk As Variant
    Dim fetched As Long, total As Long, batchCount As Long
    Dim i As Long, j As Long, v As Variant
    Dim startTime As Double, lastTime As Double
    
    '初始化
    Call PreventFreeze
    startTime = Timer
    lastTime = Timer
    total = 0
    batchCount = 0
    '檢查資料表
    If Not CreateTable(sourceRs, tableName) Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 建立 [" & tableName & "] 失敗"
        Exit Function
    End If
    '開啟資料表
    Set targetRs = m_db.OpenRecordset(tableName, dbOpenTable)
    sourceRs.MoveFirst
    '分批處理資料
    Do While Not sourceRs.EOF
        batchCount = batchCount + 1
        '使用 GetRows 快速讀取一批資料：(欄位索引, 記錄索引)
        dataChunk = sourceRs.GetRows(CHUNK_SIZE)
        If IsArray(dataChunk) Then
            '處理單筆記錄
            If UBound(dataChunk, 1) >= 0 Then
                If UBound(dataChunk, 2) >= 0 Then
                    fetched = UBound(dataChunk, 2) + 1
                Else
                    fetched = 1
                End If
            Else
                fetched = 0
            End If
            '批次筆數大於零
            If fetched > 0 Then
                '開始事務
                 BeginTransaction
                '寫入批次資料
                If fetched = 1 And UBound(dataChunk, 2) < 0 Then
                    '單筆記錄 (一維陣列)
                    targetRs.AddNew
                    For j = 0 To UBound(dataChunk, 1)
                        targetRs.fields(j).value = dataChunk(j)
                    Next j
                    targetRs.Update
                Else
                    '多筆記錄 (二維陣列)
                    For i = 0 To (fetched - 1)
                        '插入資料
                        targetRs.AddNew
                        '檢查空值
                        For j = 0 To UBound(dataChunk, 1)
                            v = dataChunk(j, i)
                            If IsNull(v) Then
                                targetRs.fields(j).value = Null
                            Else
                                targetRs.fields(j).value = v
                            End If
                        Next j
                        '更新資料
                        targetRs.Update
                    Next i
                End If
                '提交事務
                 CommitTransaction
                '定期更新事件防止凍結
                If (Timer - lastTime) >= DO_EVENTS_INTERVAL Then
                    DoEvents
                    lastTime = Timer
                End If
                '加總已處理筆數
                total = total + fetched
                Debug.Print "批次 " & batchCount & " 完成，累計: " & total & " 筆"
            End If
        End If
        '釋放記憶體
        Erase dataChunk
    Loop
    '釋放資源
    targetRs.Close
    Set targetRs = Nothing
    
    Debug.Print "批次寫入完成，總計: " & total & " 筆"
    Call RestoreExcel
    Application.Wait Now + TimeValue("00:00:01")
    Debug.Print "寫入時間: " & Format(Timer - startTime, "0.00") & " 秒"
    
    If m_isConnected Then Disconnect
    BulkInsert = True
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
    On Error Resume Next
    '回滾事務
     RollbackTransaction
    If Not targetRs Is Nothing Then targetRs.Close
    Set targetRs = Nothing
    On Error GoTo 0
End Function



'--查詢輔助 (Query Helpers)
Public Function GetTableSchema(ByVal tableName As String) As Collection
    Const METHOD_NAME As String = "GetTableSchema"
    On Error GoTo ErrorHandler
    
    Dim tableDef As DAO.tableDef
    Dim field As DAO.field
    Dim fieldsArray As New Collection
    Set GetTableSchema = fieldsArray
    Debug.Print "資料庫路徑: " & m_path
    If Not m_isConnected Then Connect
    
    '先檢查表格是否存在
    If Not TableExists(tableName) Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 資料表 [" & tableName & "] 不存在"
        Exit Function
    End If
    '檢查欄位
    Set tableDef = m_db.TableDefs(tableName)
    If tableDef.fields.count = 0 Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 資料表 [" & tableName & "] 沒有欄位"
        Exit Function
    End If
    '收集欄位
    For Each field In tableDef.fields
        fieldsArray.Add field.name
    Next field
    
    Set GetTableSchema = fieldsArray
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function GetTableList(ByVal tableName As String) As Variant
    Const METHOD_NAME As String = "GetTableList"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--事務管理
Public Sub BeginTransaction()
    Const METHOD_NAME As String = "BeginTransaction"
    On Error GoTo ErrorHandler
    
    '確保連線
    If Not m_isConnected Then Connect
    '檢察事務
    If m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已在事務中"
        Exit Sub
    End If
    '開始事務
    m_ws.BeginTrans
    m_inTransaction = True
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已開始"
    Exit Sub
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub CommitTransaction()
    Const METHOD_NAME As String = "CommitTransaction"
    On Error GoTo ErrorHandler
    
    If Not m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 沒有進行中的事務"
        Exit Sub
    End If
    '提交事務
    m_ws.CommitTrans
    m_inTransaction = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已提交"
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub RollbackTransaction()
    Const METHOD_NAME As String = "RollbackTransaction"
    On Error GoTo ErrorHandler
    
    If Not m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 沒有進行中的事務"
        Exit Sub
    End If
    '回滾事務
    m_ws.Rollback
    m_inTransaction = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已回滾"
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

' 新增輔助方法：根據實體欄位名稱反向查找邏輯欄位名稱
Private Function GetLogicalFieldName(ByVal physicalField As String, ByVal tableName As String) As String
    Dim gl As Ent_GL
    Dim tb As Ent_TB
    Dim key As Variant
    
    If UCase(tableName) = "GL" Then
        Set gl = New Ent_GL
        ' 遍歷 GL 的欄位映射，找到對應的邏輯欄位名稱
        ' 這需要在 Ent_GL 中公開映射字典或提供反向查找方法
        GetLogicalFieldName = GetLogicalFieldFromGL(physicalField, gl)
    ElseIf UCase(tableName) = "TB" Then
        Set tb = New Ent_TB
        GetLogicalFieldName = GetLogicalFieldFromTB(physicalField, tb)
    Else
        GetLogicalFieldName = physicalField
    End If
End Function

Private Function GetLogicalFieldFromGL(ByVal physicalField As String, ByVal gl As Ent_GL) As String
    ' 根據已知的映射關係進行反向查找
    Select Case physicalField
        Case "本幣借方金額": GetLogicalFieldFromGL = "DebitAmount"
        Case "本幣貸方金額": GetLogicalFieldFromGL = "CreditAmount"
        Case "摘要": GetLogicalFieldFromGL = "EntryDescription"
        Case "傳票號碼": GetLogicalFieldFromGL = "DocumentNumber"
        Case "會計科目": GetLogicalFieldFromGL = "AccountName"
        Case "借貸": GetLogicalFieldFromGL = "IsDebit"
        Case "日期": GetLogicalFieldFromGL = "PostDate"
        Case Else: GetLogicalFieldFromGL = physicalField
    End Select
End Function

Private Function GetLogicalFieldFromTB(ByVal physicalField As String, ByVal tb As Ent_TB) As String
    ' 根據已知的映射關係進行反向查找
    Select Case physicalField
        Case "借-貸(本幣)": GetLogicalFieldFromTB = "ChangeAmount"
        Case "原幣借方金額": GetLogicalFieldFromTB = "DebitAmount"
        Case "原幣貸方金額": GetLogicalFieldFromTB = "CreditAmount"
        Case "會計項目": GetLogicalFieldFromTB = "AccountNumber"
        Case "項目名稱": GetLogicalFieldFromTB = "AccountName"
        Case "本幣借方金額": GetLogicalFieldFromTB = "OpeningDebitAmount"
        Case "本幣貸方金額": GetLogicalFieldFromTB = "OpeningCreditAmount"
        Case Else: GetLogicalFieldFromTB = physicalField
    End Select
End Function
