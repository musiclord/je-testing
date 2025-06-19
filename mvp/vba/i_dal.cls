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

' === 常數 ===
Private Const MODULE_NAME As String = "i_dal"

' === 連線管理 ===
Public Function Connect(Optional connectionString As String = "") As Boolean
End Function

Public Sub Disconnect()
End Sub

Public Property Get IsConnected() As Boolean
End Property

' === 基本 SQL 執行 ===
Public Function ExecuteSQL(sql As String) As Long
    ' 返回受影響的記錄數
End Function

Public Function ExecuteQuery(sql As String) As Object
    ' 返回 Recordset 物件
End Function

' === 表格管理 ===
Public Function TableExists(tableName As String) As Boolean
End Function

Public Sub DropTable(tableName As String)
End Sub

' === 資料統計 ===
Public Function GetRecordCount(tableName As String) As Long
End Function
