VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceExport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ServiceExport
' Purpose: 管理資料匯出與報表生成
'===============================================================================

Private m_Context As Object
Private m_Db As Object
Private m_Schema As Object

Public Sub Initialize(ByVal context As Object)
    Set m_Context = context
    Set m_Db = context.DbAccess
    Set m_Schema = context.DbSchema
End Sub

Public Function ExportTableToSheet(ByVal tableName As String, ByVal targetSheet As Worksheet) As Boolean
    '---------------------------------------------------------------------------
    ' 匯出資料表到工作表
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ExportTableToSheet = False
    
    '檢查表是否存在
    If Not m_Db.TableExists(tableName) Then
        m_Context.Logger.LogError "Table does not exist: " & tableName
        Exit Function
    End If
    
    '查詢資料
    Dim rs As DAO.Recordset
    Dim builder As New SqlBuilder
    Dim sql As String
    sql = builder.SelectAll().FromTable(tableName).Build()
    Set rs = m_Db.ExecuteQuery(sql)
    
    If rs.EOF And rs.BOF Then
        m_Context.Logger.LogInfo "Table is empty: " & tableName
        ExportTableToSheet = True
        Exit Function
    End If
    
    '清除目標工作表
    targetSheet.Cells.Clear
    
    '寫入欄位名稱
    Dim col As Long
    For col = 0 To rs.Fields.Count - 1
        targetSheet.Cells(1, col + 1).Value = rs.Fields(col).Name
    Next col
    
    '格式化標題列
    With targetSheet.Range(targetSheet.Cells(1, 1), targetSheet.Cells(1, rs.Fields.Count))
        .Font.Bold = True
        .Interior.Color = RGB(220, 230, 241)
    End With
    
    '寫入資料
    targetSheet.Range("A2").CopyFromRecordset rs
    
    '自動調整欄寬
    targetSheet.Columns.AutoFit
    
    rs.Close
    
    m_Context.Logger.LogInfo "Table exported: " & tableName
    ExportTableToSheet = True
    Exit Function
    
ErrorHandler:
    If Not rs Is Nothing Then rs.Close
    m_Context.Logger.LogError "ExportTableToSheet failed", Err.Number
    ExportTableToSheet = False
End Function

Public Function ExportReport(ByVal reportName As String, ByVal outputPath As String) As Boolean
    '---------------------------------------------------------------------------
    ' 匯出報表到新的 Excel 檔案
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ExportReport = False
    
    '建立新的工作簿
    Dim wb As Workbook
    Set wb = Workbooks.Add
    
    '匯出報表資料
    Call ExportTableToSheet(reportName, wb.Worksheets(1))
    wb.Worksheets(1).Name = Left(reportName, 31)  ' Excel 工作表名稱限制
    
    '儲存檔案
    wb.SaveAs outputPath
    wb.Close False
    
    m_Context.Logger.LogInfo "Report exported: " & outputPath
    ExportReport = True
    Exit Function
    
ErrorHandler:
    If Not wb Is Nothing Then wb.Close False
    m_Context.Logger.LogError "ExportReport failed", Err.Number
    ExportReport = False
End Function

Private Sub Class_Terminate()
    Set m_Context = Nothing
    Set m_Db = Nothing
    Set m_Schema = Nothing
End Sub
