VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "dal_Access"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     dal_Access
' Purpose:  實作 Access 資料庫的具體操作
' Description:  可以參考 https://www.hosp.ncku.edu.tw/~cww/oldguy/oldguy.htm
'===============================================================================
Private Const MODULE_NAME As String = "dal_Access"
' ----- 實作 -----
Implements i_dal
' ----- 成員 -----
Private m_database As DAO.Database
Private m_workspace As DAO.Workspace
Private m_recordset As DAO.Recordset
Private m_dbPath As String
' ----- 屬性 -----
Private Property Get i_dal_dbPath() As String
    i_dal_dbPath = m_dbPath
End Property

Private Property Let i_dal_dbPath(ByVal value As String)
    m_dbPath = value
End Property


Private Sub Class_Initialize()
    Set m_database = Nothing
    Set m_workspace = Nothing
    m_dbPath = ""
End Sub
Private Sub Class_Terminate()
    i_dal_Disconnect
    Set m_database = Nothing
    Set m_workspace = Nothing
End Sub

' ----- 連線管理 -----
Private Function i_dal_Connect() As Boolean
    i_dal_Connect = False
End Function
Private Sub i_dal_Disconnect()
End Sub

Private Property Get i_dal_IsConnected() As Boolean
    i_dal_IsConnected = False
End Property

' ----- 基本 SQL 執行 -----
Private Function i_dal_ExecuteNonQuery(ByVal sql As String, Optional ByVal transacted As Boolean = False) As Long
    i_dal_ExecuteNonQuery = Nothing
End Function

Private Function i_dal_ExecuteQuery(ByVal sql As String, Optional ByVal offline As Boolean = False) As Object
    i_dal_ExecuteQuery = Nothing
End Function

Private Function i_dal_GetScalar(ByVal sql As String) As Variant
    i_dal_GetScalar = Nothing
End Function

' ----- 資料表管理 -----
Private Function i_dal_TableExists(ByVal tableName As String) As Boolean
    i_dal_TableExists = False
End Function

Private Sub i_dal_DropTable(ByVal tableName As String)
End Sub


