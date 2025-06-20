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


' === 屬性管理 ===
Public Property Get DbPath() As String
End Property

Public Property Let DbPath(ByVal value As String)
End Property

' === 連線管理 ===
Public Function Connect() As Boolean
    ' 建立連線
End Function

Public Sub Disconnect()
    ' 中斷連線
End Sub

Public Property Get IsConnected() As Boolean
    ' 檢查連線狀態
End Property

' === 基本 SQL 執行 ===
Public Function ExecuteNonQuery(ByVal sql As String, Optional ByVal transacted As Boolean = False) As Long
    ' 執行修改型SQL 語句 ( INSERT、UPDATE、DELETE、CREATE TABLE 等 )
    ' 返回受影響的記錄數
End Function

Public Function ExecuteQuery(ByVal sql As String, Optional ByVal offline As Boolean = False) As Object
    ' 執行查詢型SQL 語句 ( SELECT )
    ' 返回實際資料結果
End Function

Public Function GetScalar(ByVal sql As String) As Variant
    ' 執行單一值查詢，返回第一行第一列的值
    ' 用於 COUNT(*), SUM() 等聚合查詢
End Function

' === 資料表管理 ===
Public Function TableExists(ByVal tableName As String) As Boolean
    ' 檢查資料表是否存在
End Function

Public Sub DropTable(ByVal tableName As String)
    ' 刪除指定資料表
End Sub
