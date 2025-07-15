VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "i_dal"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     i_dal
' Purpose:  資料庫操作的標準介面，應支援 Access 和的 SQL Server
'===============================================================================
Private Const MODULE_NAME As String = "i_dal"



' ----- 連線管理 -----
Public Property Get path() As String
End Property
Public Property Let path(ByVal p_path As String)
End Property
Public Property Get IsConnected() As Boolean
End Property
Public Sub Connect()
End Sub
Public Sub Disconnect()
End Sub



' ----- 資料定義 DDL (Data Definition Language) -----
Public Function CreateTable(ByVal tableName As String, ByVal rs As ADODB.Recordset, Optional ByVal dropIfExists As Boolean = True) As Boolean
End Function
Public Function DropTable(ByVal tableName As String) As Boolean
End Function
Public Function TableExists(ByVal tableName As String) As Boolean
End Function



' ----- 資料操作 DML (Data Manipulation Language) -----
Public Function ExecuteQuery(ByVal sql$) As ADODB.Recordset
End Function
Public Function ExecuteNonQuery(ByVal sql$) As Long
End Function
Public Function GetScalar(ByVal sql$) As Variant
End Function



' ----- 批次操作 (Bulk Operations) -----

Public Function BulkInsert(ByVal dataSource As Variant, ByVal tableName As String)
End Function



' ----- 查詢輔助 (Query Helpers) -----
Public Function GetTableSchema(ByVal tableName As String) As ADODB.Recordset
End Function
Public Function GetTableList() As ADODB.Recordset
End Function



' ---- 事務管理 -----
Public Sub BeginTransaction()
End Sub
Public Sub CommitTransaction()
End Sub
Public Sub RollbackTransaction()
End Sub

