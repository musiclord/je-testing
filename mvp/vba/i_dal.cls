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
    ' 建立資料庫連線
End Function

Public Sub Disconnect()
    ' 中斷資料庫連線
End Sub

Public Property Get IsConnected() As Boolean
    ' 檢查連線狀態
End Property

' === 基本 SQL 執行 ===
Public Function ExecuteSQL(ByVal sql As String, Optional ByVal useTransaction As Boolean = False) As Long
    ' 執行 INSERT, UPDATE, DELETE, CREATE TABLE 等操作
    ' 返回受影響的記錄數，失敗返回 -1
End Function

Public Function GetRecordset(ByVal sql As String, Optional ByVal disconnectRecordset As Boolean = False) As Object
    ' 執行 SELECT 查詢，返回 Recordset 物件
    ' disconnectRecordset: True 時返回離線的 Recordset
End Function

Public Function GetScalar(ByVal sql As String) As Variant
    ' 執行單一值查詢，返回第一行第一列的值
    ' 用於 COUNT(*), SUM() 等聚合查詢
End Function

' === 資料表管理 ===
Public Function TableExists(ByVal tableName As String) As Boolean
    ' 檢查指定資料表是否存在
End Function

Public Sub DropTable(ByVal tableName As String)
    ' 刪除指定資料表
End Sub

Public Function GetTableNames() As Variant
    ' 取得資料庫中所有使用者資料表的名稱陣列
    ' 返回 String 陣列，如果沒有資料表則返回 Empty
End Function

Public Function GetTableFieldNames(ByVal tableName As String) As Variant
    ' 取得指定資料表的所有欄位名稱
    ' 返回 String 陣列，如果資料表不存在則 Empty
End Function

' === 資料統計 ===
Public Function GetRecordCount(ByVal tableName As String) As Long
    ' 取得指定資料表的記錄數
    ' 返回記錄數，失敗為 -1，資料表不存在則 0
End Function
