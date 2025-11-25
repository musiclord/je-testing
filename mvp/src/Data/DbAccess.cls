VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DbAccess"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: DbAccess
' Purpose: DAO-based database access layer for Access databases
'
' Responsibilities:
'   - Manage DAO database connection lifecycle
'   - Execute SQL queries and non-query commands
'   - Provide transaction support (BeginTrans, CommitTrans, Rollback)
'   - Schema operations (TableExists, FieldExists, GetTableFields)
'   - Database maintenance (Refresh, CompactAndRepair)
'
' Dependencies:
'   - Microsoft DAO 3.6 Object Library
'   - Logger.cls for logging
'===============================================================================

'-- Private Members
Private m_Db As DAO.Database
Private m_Ws As DAO.Workspace
Private m_Path As String
Private m_Logger As Object  ' Logger
Private m_IsConnected As Boolean
Private m_InTransaction As Boolean
Private m_Fso As Object     ' Scripting.FileSystemObject

'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize(ByVal dbPath As String, ByVal logger As Object)
    m_Path = dbPath
    Set m_Logger = logger
    Set m_Fso = CreateObject("Scripting.FileSystemObject")
    m_IsConnected = False
    m_InTransaction = False
End Sub

'===============================================================================
' Connection Management
'===============================================================================

Public Sub Connect()
    '連線到 Access 資料庫
    If m_IsConnected Then Exit Sub
    
    On Error GoTo ErrorHandler
    
    '建立或取得工作區
    If m_Ws Is Nothing Then
        Set m_Ws =DAO.DBEngine.Workspaces(0)
    End If
    
    '開啟資料庫
    Set m_Db = m_Ws.OpenDatabase(m_Path)
    m_IsConnected = True
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogInfo "Connected to database: " & m_Path
    End If
    
    Exit Sub
    
ErrorHandler:
    If Not m_Logger Is Nothing Then
        m_Logger.LogError "Failed to connect to database: " & m_Path, Err.Number
    End If
    m_IsConnected = False
End Sub

Public Sub Disconnect()
    '斷開資料庫連線
    On Error Resume Next
    
    If m_InTransaction Then
        m_Ws.Rollback
        m_InTransaction = False
    End If
    
    If Not m_Db Is Nothing Then
        m_Db.Close
        Set m_Db = Nothing
    End If
    
    m_IsConnected = False
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogInfo "Disconnected from database"
    End If
    
    On Error GoTo 0
End Sub

'===============================================================================
' Transaction Management
'===============================================================================

Public Sub BeginTrans()
    '開始交易
    If Not m_IsConnected Then Connect
    If m_InTransaction Then Exit Sub
    
    m_Ws.BeginTrans
    m_InTransaction = True
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogDebug "Transaction started"
    End If
End Sub

Public Sub CommitTrans()
    '提交交易
    If Not m_InTransaction Then Exit Sub
    
    m_Ws.CommitTrans
    m_InTransaction = False
    Call Refresh
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogDebug "Transaction committed"
    End If
End Sub

Public Sub RollbackTrans()
    '回滾交易
    If Not m_InTransaction Then Exit Sub
    
    m_Ws.Rollback
    m_InTransaction = False
    Call Refresh
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogDebug "Transaction rolled back"
    End If
End Sub

'===============================================================================
' Query Execution
'===============================================================================

Public Function ExecuteQuery(ByVal sql As String) As DAO.Recordset
    '執行 SELECT 查詢並回傳 Recordset
    On Error GoTo ErrorHandler
    
    If Not m_IsConnected Then Connect
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogDebug "Executing Query: " & sql
    End If
    
    'Refresh cache before query
    Call Refresh
    
    'Open snapshot recordset (read-only)
    Set ExecuteQuery = m_Db.OpenRecordset(sql, dbOpenSnapshot)
    
    Exit Function
    
ErrorHandler:
    If Not m_Logger Is Nothing Then
        m_Logger.LogError "ExecuteQuery Failed: " & sql, Err.Number
    End If
    Set ExecuteQuery = Nothing
End Function

Public Function ExecuteNonQuery(ByVal sql As String, Optional ByVal logging As Boolean = True) As Long
    '執行 INSERT, UPDATE, DELETE, CREATE TABLE 等非查詢 SQL
    On Error GoTo ErrorHandler
    
    If Not m_IsConnected Then Connect
    
    If logging And Not m_Logger Is Nothing Then
        m_Logger.LogDebug "Executing NonQuery: " & sql
    End If
    
    m_Db.Execute sql, dbFailOnError
    
    'Get affected records count
    ExecuteNonQuery = m_Db.RecordsAffected
    
    'Refresh cache after DDL/DML
    Call Refresh
    
    Exit Function
    
ErrorHandler:
    If Not m_Logger Is Nothing Then
        m_Logger.LogError "ExecuteNonQuery Failed: " & sql, Err.Number
    End If
    ExecuteNonQuery = -1
End Function

'===============================================================================
' Schema Operations
'===============================================================================

Public Function TableExists(ByVal tableName As String) As Boolean
    '檢查資料表是否存在
    On Error Resume Next
    
    If Not m_IsConnected Then Connect
    
    Dim tdf As DAO.TableDef
    Set tdf = m_Db.TableDefs(tableName)
    
    '檢查是否為用戶表（非系統表）
    If Err.Number = 0 Then
        TableExists = ((tdf.Attributes And dbSystemObject) = 0)
    Else
        TableExists = False
    End If
    
    Err.Clear
    On Error GoTo 0
End Function

Public Function FieldExists(ByVal tableName As String, ByVal fieldName As String) As Boolean
    '檢查欄位是否存在於指定資料表中
    On Error Resume Next
    
    If Not m_IsConnected Then Connect
    
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    
    Set tdf = m_Db.TableDefs(tableName)
    If Err.Number <> 0 Then
        FieldExists = False
        Err.Clear
        Exit Function
    End If
    
    Set fld = tdf.Fields(fieldName)
    FieldExists = (Err.Number = 0)
    
    Err.Clear
    On Error GoTo 0
End Function

Public Function GetTableFields(ByVal tableName As String) As Collection
    '取得資料表的所有欄位名稱
    On Error GoTo ErrorHandler
    
    If Not m_IsConnected Then Connect
    
    Dim fields As New Collection
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    
    Set tdf = m_Db.TableDefs(tableName)
    
    For Each fld In tdf.Fields
        fields.Add fld.Name
    Next fld
    
    Set GetTableFields = fields
    Exit Function
    
ErrorHandler:
    If Not m_Logger Is Nothing Then
        m_Logger.LogError "GetTableFields Failed for table: " & tableName, Err.Number
    End If
    Set GetTableFields = Nothing
End Function

Public Function DropTable(ByVal tableName As String) As Boolean
    '刪除資料表
    On Error GoTo ErrorHandler
    
    If Not m_IsConnected Then Connect
    
    If Not TableExists(tableName) Then
        DropTable = False
        Exit Function
    End If
    
    m_Db.TableDefs.Delete tableName
    Call Refresh
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogInfo "Table dropped: " & tableName
    End If
    
    DropTable = True
    Exit Function
    
ErrorHandler:
    If Not m_Logger Is Nothing Then
        m_Logger.LogError "DropTable Failed: " & tableName, Err.Number
    End If
    DropTable = False
End Function

'===============================================================================
' Database Maintenance
'===============================================================================

Public Sub Refresh(Optional ByVal forceDeep As Boolean = False)
    '刷新資料庫快取
    '參數:
    '  forceDeep: True = 深度刷新所有資料表欄位結構
    '             False = 僅刷新 TableDefs (預設)
    
    On Error Resume Next
    
    If Not m_IsConnected Then Exit Sub
    
    'Refresh DBEngine cache
    DAO.DBEngine.Idle dbRefreshCache
    
    'Refresh TableDefs collection
    m_Db.TableDefs.Refresh
    
    'Deep refresh if requested
    If forceDeep Then
        Dim tdf As DAO.TableDef
        For Each tdf In m_Db.TableDefs
            'Skip system and temp tables
            If Not (tdf.Name Like "MSys*" Or tdf.Name Like "~TMPCLP*") Then
                tdf.Fields.Refresh
                If Err.Number <> 0 Then
                    If Not m_Logger Is Nothing Then
                        m_Logger.LogDebug "Warning: Cannot refresh fields for table: " & tdf.Name
                    End If
                    Err.Clear
                End If
            End If
        Next tdf
    End If
    
    On Error GoTo 0
End Sub

Public Function CompactAndRepair() As Boolean
    '壓縮與修復資料庫
    On Error GoTo ErrorHandler
    
    CompactAndRepair = False
    
    If Not m_IsConnected Then Connect
    
    '檢查路徑有效性
    If m_Path = "" Or Dir(m_Path) = "" Then
        If Not m_Logger Is Nothing Then
            m_Logger.LogError "CompactAndRepair: Invalid path: " & m_Path
        End If
        Exit Function
    End If
    
    '儲存當前交易狀態
    Dim wasTx As Boolean
    wasTx = m_InTransaction
    
    '產生臨時檔案路徑
    Dim tempPath As String
    tempPath = m_Fso.GetParentFolderName(m_Path) & "\" & _
               m_Fso.GetBaseName(m_Path) & "_temp_" & _
               Format(Now, "yyyymmddhhnnss") & ".accdb"
    
    '關閉連線
    Call Disconnect
    
    '執行壓縮與修復
    If Not m_Logger Is Nothing Then
        m_Logger.LogInfo "Compacting database: " & m_Path
    End If
    
    DAO.DBEngine.CompactDatabase m_Path, tempPath
    
    '刪除原始檔案並重新命名
    Kill m_Path
    Name tempPath As m_Path
    
    '重新連線
    Call Connect
    
    '恢復交易狀態
    If wasTx Then Call BeginTrans
    
    '深度刷新
    Call Refresh(True)
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogInfo "Database compacted successfully"
    End If
    
    CompactAndRepair = True
    Exit Function
    
ErrorHandler:
    If Not m_Logger Is Nothing Then
        m_Logger.LogError "CompactAndRepair Failed", Err.Number
    End If
    CompactAndRepair = False
End Function

'===============================================================================
' Properties
'===============================================================================

Public Property Get Path() As String
    Path = m_Path
End Property

Public Property Get Database() As DAO.Database
    Set Database = m_Db
End Property

Public Property Get IsConnected() As Boolean
    IsConnected = m_IsConnected
End Property

'===============================================================================
' Helper Functions
'===============================================================================

Public Function EscapeString(ByVal str As String) As String
    'Escape single quotes for SQL strings
    EscapeString = Replace(str, "'", "''")
End Function

'===============================================================================
' Cleanup
'===============================================================================

Private Sub Class_Terminate()
    Call Disconnect
    Set m_Fso = Nothing
    Set m_Logger = Nothing
End Sub
