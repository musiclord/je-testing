Attribute VB_Name = "util_Global"
Option Explicit

'===============================================================================
' Name:     util_Global
' Purpose:  公開模組，列有通用工具庫供所有方法使用。
'===============================================================================
Private Const MODULE_NAME = "util_Global"

Public Sub PreviewTable(ByRef dal As i_dal, ByVal tableName As String)
    Const METHOD_NAME = "PreviewTable"
    '初始化
    Dim sql As String
    Dim rs As Object
    Dim ws As Worksheet
    Dim i As Integer
    '連線資料
    sql = "SELECT TOP 1000 * FROM [" & tableName & "]"
    rs = dal.ExecuteQuery(sql)
    '準備工作表
    Set ws = ActiveSheet
    ws.Cells.ClearContents
    '寫入欄位
    For i = 1 To rs.fields.Count
        ws.Cells(1, i).Value = rs.fields(i - 1).name
    Next i
    '寫入資料
    ws.Range("A2").CopyFromRecordset rs
    
End Sub
