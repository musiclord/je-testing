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
'Class:DbAccess
Private Const CHUNK_SIZE As Long = 100000
Private Const DO_EVENTS_INTERVAL As Double = 2#
Private m_Ws As DAO.Workspace
Private m_Db As DAO.Database
Private m_Conn As DAO.Connection
Private m_Path As String
Private m_IsConnected As Boolean
Private m_Tx As Boolean

'***** 屬性
Public Property Get Database() As DAO.Database
    Set Database = m_Db
End Property
Public Property Get Workspace() As DAO.Workspace
    Set Workspace = m_Ws
End Property
Public Property Get path() As String
    path = m_Path
End Property
Public Property Let path(ByVal Value As String)
    m_Path = Value
End Property

'***** 方法
Public Sub Connect()
    If m_IsConnected Then
        Exit Sub
    Else
        Dim wsName As String
        wsName = "WS_" & format(Now(), "yyyymmddnnss") & "_" & Rnd()
        Set m_Ws = DAO.DBEngine.CreateWorkspace(wsName, "admin", "")
        Set m_Db = m_Ws.OpenDatabase(m_Path, False, False)
        m_IsConnected = True
    End If
End Sub

Public Sub Disconnect()
    If m_Tx Then
        Call RollbackTx
    End If
    Dim wsName As String
    If Not m_Ws Is Nothing Then wsName = m_Ws.Name
    If Not m_Db Is Nothing Then
        m_Db.Close
        Set m_Db = Nothing
    End If
    If Not m_Ws Is Nothing Then
        m_Ws.Close
        Set m_Ws = Nothing
    End If
    m_IsConnected = False
End Sub

Public Sub RefreshSchema()
    On Error Resume Next
    If Not m_IsConnected Then Exit Sub
    '刷新 Jet/ACE 引擎快取
    DAO.DBEngine.Idle dbRefreshCache
    '刷新連線的結構快取
    m_Db.TableDefs.Refresh
    '刷新所有資料表的欄位快取
    Dim tdf As DAO.TableDef
    For Each tdf In m_Db.TableDefs
        tdf.Fields.Refresh
    Next
    On Error GoTo 0
End Sub

Public Sub BeginTx()
    If Not m_IsConnected Then Connect
    If m_Tx Then
        '已在事務中
        Exit Sub
    End If
    m_Ws.BeginTrans
    m_Tx = True
End Sub

Public Sub CommitTx()
    If Not m_Tx Then
        '沒有進行中的事務
        Exit Sub
    End If
    m_Ws.CommitTrans
    m_Tx = False
End Sub

Public Sub RollbackTx()
    If Not m_Tx Then
        '沒有進行中的事務
        Exit Sub
    End If
    m_Ws.Rollback
    m_Tx = False
End Sub

Public Function CreateTable() As Boolean
    '創建資料表
    If Not m_IsConnected Then Connect
    
End Function

Public Function DropTable(ByVal tableName As String) As Boolean
    '刪除資料表
    If Not m_IsConnected Then Connect
    If Not TableExists(tableName) Then
        DropTable = False
        Exit Function
    End If
    Call ExecuteNonQuery("DROP TABLE [" & tableName & "]")
    DropTable = True
End Function

Public Function TableExists(ByVal tableName As String) As Boolean
    '檢查資料表
    If Not m_IsConnected Then Connect
    Dim dummyTdf As DAO.TableDef
    On Error Resume Next
    Set dummyTdf = m_Db.TableDefs(tableName)
    If Err.Number = 0 Then
        TableExists = ((dummyTdf.Attributes And dbSystemObject) = 0)
    Else
        TableExists = False
    End If
    Err.Clear
    On Error GoTo 0
End Function

Public Function CreateField(ByVal fieldName As String) As Boolean

End Function


Public Function FieldExists(ByVal tdf As DAO.TableDef, ByVal fieldName As String) As Boolean
    '檢查欄位是否存在
    Dim dummyFld As DAO.Field
    On Error Resume Next
    Set dummyFld = tdf.Fields(fieldName)
    FieldExists = (Err.Number = 0)
    Err.Clear
    On Error GoTo 0
End Function

Public Function ExecuteQuery(ByVal sql As String, Optional pause As Integer = 1) As DAO.Recordset
    If Not m_IsConnected Then Connect
    Debug.Print "********** SQL **********" & vbCrLf & sql
    '靜候
    If pause > 0 Then
        Application.wait Now + TimeSerial(0, 0, pause)
    End If
    '回傳記錄集
    Set ExecuteQuery = m_Db.OpenRecordset(sql, dbOpenSnapshot)
End Function

Public Function ExecuteNonQuery(ByVal sql As String, Optional pause As Integer = 1) As Long
    If Not m_IsConnected Then Connect
    Debug.Print "********** SQL **********" & vbCrLf & sql
    m_Db.Execute sql, dbFailOnError
    '靜候
    If pause > 0 Then
        Application.wait Now + TimeSerial(0, 0, pause)
    End If
    '回傳受影響筆數
    ExecuteNonQuery = m_Db.RecordsAffected
End Function

Public Function Summarization(ByVal tableName As String, fieldToSum As String, fieldToGroup As String)
    '負責資料彙總的功能，對資料按某些維度進行分組，並加總指定的數值欄位。
    'tableName:     要彙總的資料表
    'fieldToSum:    要加總的數值欄位
    'fieldToGroup:  要分組的屬性欄位
    '...
    Dim sql As String
    Dim newTable As String
    Dim newField As String
    newTable = tableName & "_SUM"
    newField = fieldToSum & "_SUM"
    sql = "SELECT " & _
          "  [" & fieldToGroup & "]," & _
          "  SUM([" & fieldToSum & "]) AS [" & newField & "]" & _
          "INTO " & newTable & " " & _
          "FROM " & tableName & " " & _
          "GROUP BY [" & fieldToGroup & "];"
    Call ExecuteNonQuery(sql, 1)
End Function

Public Function GetTableFields(ByVal tableName As String) As Collection
    '取得指定資料表的欄位
    If Not m_IsConnected Then Connect
    Dim Fields As New Collection
    Dim fld As DAO.Field
    Dim rs As DAO.Recordset
    Set rs = m_Db.OpenRecordset(Name:=tableName, Type:=dbOpenDynaset)
    '遍歷 RS 的欄位
    For Each fld In rs.Fields
        Fields.Add fld.Name
    Next fld
    rs.Close
    Set rs = Nothing
    Set GetTableFields = Fields
End Function
