VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "I_Dal"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "I_Dal"
'===============================================================================
' Module:   I_Dal
' Purpose:  資料存取層的介面定義，主要提供 CRUD 操作
' Layer:    Interface
' Domain:   Data Access
'===============================================================================
'額外註記:
'- 保留資料存取層的通用方法，未來可擴展至 SQL Server


'--連線管理
Public Property Get path() As String
End Property
Public Property Let path(ByVal value As String)
End Property
Public Property Get IsConnected() As Boolean
End Property
Public Sub Connect()
End Sub
Public Sub Disconnect()
End Sub



'--資料定義 DDL (Data Definition Language)
Public Function CreateTable(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
End Function
Public Function DropTable(ByVal tableName As String) As Boolean
End Function
Public Function TableExists(ByVal tableName As String) As Boolean
End Function



'--資料操作 DML (Data Manipulation Language)
Public Function ExecuteQuery(ByVal sql$) As ADODB.Recordset
End Function
Public Function ExecuteNonQuery(ByVal sql$) As Long
End Function
Public Function GetScalar(ByVal sql$) As Variant
End Function



'--批次操作 (Bulk Operations)
Public Function BulkInsert(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
End Function



'--查詢輔助 (Query Helpers)
Public Function GetTableSchema(ByVal tableName As String) As ADODB.Recordset
End Function
Public Function GetTableList() As ADODB.Recordset
End Function



'--事務管理
Public Sub BeginTransaction()
End Sub
Public Sub CommitTransaction()
End Sub
Public Sub RollbackTransaction()
End Sub
