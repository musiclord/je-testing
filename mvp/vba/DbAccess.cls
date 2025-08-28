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

'--屬性
Public Property Get path() As String
    path = m_Path
End Property
Public Property Let path(ByVal Value As String)
    m_Path = Value
End Property

'--方法
Public Sub Connect()
    If m_IsConnected Then
        Exit Sub
    Else
        Dim wsName As String
        wsName = "WS_" & Format(Now(), "yyyymmddnnss") & "_" & Rnd()
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
    
End Function

Public Function DropTable() As Boolean
    
End Function

Public Function ExecuteQuery(ByVal sql As String) As DAO.Recordset
    If Not m_IsConnected Then Connect
    Debug.Print "Sql: " & sql
    Set ExecuteQuery = m_Db.OpenRecordset(sql, dbOpenSnapshot)
End Function

Public Function ExecuteNonQuery(ByVal sql As String) As Long
    If Not m_IsConnected Then Connect
    Debug.Print "Sql: " & sql
    m_Db.Execute sql, dbFailOnError
    ExecuteNonQuery = m_Db.RecordsAffected
End Function

Public Function GetTableFields(ByVal tableName As String) As Collection
    If Not m_IsConnected Then Connect
    Dim fields As New Collection
    Dim fld As DAO.Field
    Dim rs As DAO.Recordset
    Set rs = m_Db.OpenRecordset(Name:=tableName, Type:=dbOpenDynaset)
    
    For Each fld In rs.fields
        fields.Add fld.Name
    Next fld
    
    rs.Close
    Set rs = Nothing
    
    Set GetTableFields = fields
End Function
