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
'===============================================================================

' === 實作介面 ===
Implements i_dal

' === 常數 ===
Private Const MODULE_NAME As String = "dal_Access"

' === 私有成員 ===
Private m_database As DAO.Database
Private m_workspace As DAO.Workspace
Private m_dbPath As String

' === 類別初始化 ===
Private Sub Class_Initialize()
    Set m_database = Nothing
    Set m_workspace = Nothing
    m_dbPath = ""
    m_enableDebugPrinting = False
End Sub
Private Sub Class_Terminate()
    i_dal_Disconnect
    Set m_database = Nothing
    Set m_workspace = Nothing
End Sub

' === 屬性管理 ===
Private Property Let i_dal_DbPath(ByVal path As String)
    m_dbPath = path
End Property
Private Property Get i_dal_DbPath() As String
    i_dal_DbPath = m_dbPath
End Property

' === 連線管理 ===
Private Function i_dal_Connect() As Boolean
    ' 建立連線
    
End Function

Private Sub i_dal_Disconnect()
    ' 中斷連線
End Sub

Private Property Get i_dal_IsConnected() As Boolean
    ' 檢查連線狀態
End Property

' === 基本 SQL 執行 ===
Private Function i_dal_ExecuteNonQuery(ByVal sql As String, Optional ByVal transacted As Boolean = False) As Long
    ' 執行修改型SQL 語句 ( INSERT、UPDATE、DELETE、CREATE TABLE 等 )
    ' 返回受影響的記錄數
End Function

Private Function i_dal_ExecuteQuery(ByVal sql As String, Optional ByVal offline As Boolean = False) As Object
    ' 執行查詢型SQL 語句 ( SELECT )
    ' 返回實際資料結果
End Function

Private Function i_dal_GetScalar(ByVal sql As String) As Variant
    ' 執行單一值查詢，返回第一行第一列的值
    ' 用於 COUNT(*), SUM() 等聚合查詢
End Function

' === 資料表管理 ===
Private Function i_dal_TableExists(ByVal tableName As String) As Boolean
    ' 檢查資料表是否存在
End Function

Private Sub i_dal_DropTable(ByVal tableName As String)
    ' 刪除指定資料表
End Sub
