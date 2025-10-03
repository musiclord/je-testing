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
' Purpose: 定義資料輸出的服務，將資料表輸出為 Excel 工作表
'          且預覽工作表固定設為 PreviewSheet
'===============================================================================
Private Const MAX_ROWS As Long = 1000
Private m_Context As ContextManager
Private m_Db As DbAccess
Private m_Info As EntityInfo
Private m_Ace As New Access.Application
Private je As EntityJe
Private tb As EntityTb

Public Sub Initialize(context As ContextManager)
    Set m_Context = context
    Set m_Db = context.DbValid 'DEFAULT
    Set m_Info = context.info
    Set je = context.je
    Set tb = context.tb
End Sub


Public Function ExportWp() As Boolean
    ' ============================================================================
    ' 將處理好的底稿輸出至本機目錄
    ' 彙總所有軌跡的報告並輸出 .xlsx 檔案至專案木錄
    ' ============================================================================
End Function

'***** 資料預覽方法
Private Sub PreviewSummary(ByVal col As Collection, ByVal sheetName As String)
    ' ============================================================================
    ' 方法:將摘要資訊預覽於工作表
    ' 參數:
    '    - dict: Collection物件, 以 Key-Value 摘要資訊
    '    - sheetName: 工作表名稱
    ' ============================================================================
    On Error GoTo ErrorHandler
    If col Is Nothing Then Exit Sub
    If col.Count = 0 Then Exit Sub
    '設置預覽用工作表
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.Name = sheetName
    ws.Cells.Clear
    '寫入摘要資訊
    Dim rowIdx As Long
    Dim element As Variant
    rowIdx = 1
    For Each element In col
        ws.Cells(rowIdx, 1).Value = element(0)
        ws.Cells(rowIdx, 1).Font.Bold = True
        ws.Cells(rowIdx, 1).Interior.Color = RGB(220, 230, 241)
        ws.Cells(rowIdx, 2).Value = element(1)
        rowIdx = rowIdx + 1
    Next element
    '調整欄寬
    ws.Columns.AutoFit
    ws.Activate
    Exit Sub
ErrorHandler:
    Debug.Print "PreviewSummary(): " & Err.Number & " - " & Err.Description
End Sub

Private Sub PreviewDetail(ByVal rs As DAO.Recordset, ByVal sheetName As String)
    ' ============================================================================
    ' 方法:將紀錄集以明細表方式預覽於工作表
    ' 參數:
    '    - rs: 欲顯示的資料庫紀錄集
    '    - sheetName: 工作表名稱
    ' ============================================================================
    On Error GoTo ErrorHandler
    If rs Is Nothing Then Exit Sub
    If rs.EOF And rs.BOF Then Exit Sub '無有效紀錄
    '設置預覽用工作表
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.Name = sheetName
    ws.Cells.Clear
    '寫入標題列
    Dim i As Long
    For i = 0 To rs.Fields.Count - 1
        ws.Cells(1, i + 1).Value = rs.Fields(i).Name
    Next i
    '格式化標題列
    With ws.Range(ws.Cells(1, 1), ws.Cells(1, rs.Fields.Count))
        .Font.Bold = True
        .Interior.Color = vbYellow
        .HorizontalAlignment = xlCenter
    End With
    '寫入資料
    rs.MoveFirst
    ws.Range("A2").CopyFromRecordset rs, MAX_ROWS
    '自動調整欄寬
    ws.Columns.AutoFit
    ws.Activate
    Exit Sub
ErrorHandler:
    Debug.Print "PreviewDetail(): " & Err.Number & " - " & Err.Description
End Sub

'***** 工作表管理
Private Function GetWorksheet() As Worksheet
    '...
End Function

Private Sub SetPassword(ByRef xlSheet As Excel.Worksheet)
    ' ============================================================================
    ' 方法: 設置工作表密碼，鎖住寫入控制權
    ' 參數:
    '     - xlSheet: 要鎖住的工作表物件
    ' ============================================================================
    Dim password As String
    password = "SetRandomPhraseHere" & "-" & format(Now, "yyyymmdd")
    xlSheet.Protect password:=password, _
                    DrawingObjects:=True, _
                    Contents:=True, _
                    Scenarios:=True
End Sub

'***** 產出指定報告
Private Function PreparationSummary() As Boolean
    Dim sheetName As String
    sheetName = "資料預先整理之說明"
    
    Dim summary As New Collection
    summary.Add "公司名稱", m_Info.CompanyName
    summary.Add "測試資料期間", CStr("" & m_Info.PeriodStart & " ~ " & m_Info.PeriodEnd)
End Function

Private Function WorkingPaperSummary() As Boolean
    Dim sheetName As String
    sheetName = "JE Working Paper 說明"
    
End Function

Private Function ValidationReport() As Boolean
    Dim sheetName As String
    sheetName = "step1-完整性測試"
    
    Dim summary As New Collection
    summary.Add "公司名稱", m_Info.CompanyName
    summary.Add "測試資料期間", CStr("" & m_Info.PeriodStart & " ~ " & m_Info.PeriodEnd)
    
    
End Function

Private Function CompletenessReport() As Boolean
    'Step1-1 - 完整性測試報告
    
    Dim summary As New Collection
    summary.Add "公司名稱", m_Info.CompanyName
    summary.Add "測試資料期間", CStr("" & m_Info.PeriodStart & " ~ " & m_Info.PeriodEnd)
    summary.Add "期末財務報表準備期間的開始日", CStr("" & m_Info.PrepStartDate)
End Function

Private Function DocumentBalanceReport() As Boolean
    'Step1-2 借貸不平測試報告
    
    Dim summary As New Collection
    summary.Add "公司名稱", m_Info.CompanyName
    summary.Add "測試資料期間", CStr("" & m_Info.PeriodStart & " ~ " & m_Info.PeriodEnd)
    summary.Add "期末財務報表準備期間的開始日", CStr("" & m_Info.PrepStartDate)
    
    Dim detail As DAO.Recordset
    Set detail = m_Db.ExecuteQuery("SELECT * FROM [" & TBL_DOCUMENT_NOT_BALANCE & "]")
    
End Function

Private Function PreparerSummary() As Boolean
    'Step1-3 分錄編制人員說明
End Function

Private Function CompletenessDifferenceSummary() As Boolean
    'Step1-4 完整性測試之差異說明
End Function

Private Function CompletenessReconciliationReport() As Boolean
    'Step1-4-1 完整性差異調節報告
End Function

Private Function INFReport() As Boolean
    'Step2 INF可靠性測試
End Function

Private Function HRCSummary() As Boolean
    'Step3 高風險條件 (HRC) 說明
    '...
    '設定該報告使用的資料庫
    Set m_Db = m_Context.DbCriteria
    '...
End Function

Private Function HRCReport() As Boolean
    'Step4 符合高風險條件傳票報告
    '...
    '設定該報告使用的資料庫
    Set m_Db = m_Context.DbCriteria
    '...
End Function

Private Function HRCDetails() As Boolean
    'Step4-1 符合高風險條件傳票之明細
    '...
    '設定該報告使用的資料庫
    Set m_Db = m_Context.DbCriteria
    '...
End Function

Private Function PostClosingEntries() As Boolean
    'Step5 財務報表關帳後調整之分錄
End Function

Private Function FieldInfo() As Boolean
    '自動化工具-檔案欄位資訊
End Function

Private Function HolidyInfo() As Boolean
    '自動化工具-假期假日資訊
End Function

Private Function AccountMappingInfo() As Boolean
    '自動化工具-科目配對資訊
End Function


