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

Public Sub Initialize(context As ContextManager)
    Set m_Context = context
    Set m_Info = context.info
    Set m_Db = context.DbReport 'DEFAULT-DB
End Sub

'***** 資料預覽方法
Private Sub RecordsetToSheet(ByVal rs As DAO.Recordset, ByVal ws As Worksheet)
    ' ============================================================================
    ' 方法:將資料庫記錄集預覽於工作表
    ' 參數:
    '    - rs: 資料庫記錄集物件
    '    - ws: 工作表物件
    ' ============================================================================
    On Error GoTo ErrorHandler
    If (rs Is Nothing) Or (rs.BOF And rs.EOF) Then Exit Sub
    ws.Cells.Clear
    '寫入標題列
    Dim i As Long
    For i = 0 To rs.Fields.Count - 1
        ws.Cells(1, i + 1).Value = rs.Fields(i).name
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
    Debug.Print "RecordsetToSheet(): " & Err.Number & " - " & Err.Description
End Sub

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
Public Function ShowEngagementOverview() As Boolean
    ' ============================================================================
    ' 資料預先整理之說明
    ' = ENGAGEMENT_OVERVIEW
    ' ============================================================================
    '設置資料表名稱
    Dim tableName As String
    tableName = RPT_ENGAGEMENT_OVERVIEW
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "資料預先整理說明"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '設置記錄集物件
    Dim rs As DAO.Recordset
    Set rs = m_Db.ExecuteQuery("SELECT * FROM [" & tableName & "];")
    '預覽記錄集於工作表
    Call RecordsetToSheet(rs, ws)
    '釋放資源
    rs.Close
    Set rs = Nothing
End Function

Public Function ShowWorkingPaperSummary() As Boolean
    ' JE底稿說明
    ' = 0
End Function

Public Function ShowValidationReport() As Boolean
    ' ============================================================================
    ' Step1-0 - 驗證測試報告
    ' = ENGAGEMENT_OVERVIEW + VALIDATION_OVERVIEW + DATA_OVERVIEW
    ' ============================================================================
    '設置資料表名稱
    Dim tableName As String
    tableName = RPT_DATA_OVERVIEW
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "驗證測試報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '設置記錄集物件
    Dim rs As DAO.Recordset
    Set rs = m_Db.ExecuteQuery("SELECT * FROM [" & tableName & "];")
    '預覽記錄集於工作表
    Call RecordsetToSheet(rs, ws)
    '釋放資源
    rs.Close
    Set rs = Nothing
End Function

Public Function ShowCompletenessReport() As Boolean
    'Step1-1 - 完整性測試報告
    ' = ENGAGEMENT_OVERVIEW + COMPLETENESS_DETAIL
End Function

Public Function ShowDocumentBalanceReport() As Boolean
    'Step1-2 借貸不平測試報告
    ' = ENGAGEMENT_OVERVIEW + DOCUMENT_BALANCE_DETAIL
End Function

Public Function ShowPreparerSummary() As Boolean
    'Step1-3 分錄編制人員說明
End Function

Public Function ShowCompletenessDifferenceSummary() As Boolean
    'Step1-4 完整性測試之差異說明
End Function

Public Function ShowCompletenessReconciliationReport() As Boolean
    'Step1-4-1 完整性差異調節報告
End Function

Public Function ShowINFReport() As Boolean
    'Step2 INF可靠性測試
End Function

Public Function ShowHRCSummary() As Boolean
    'Step3 高風險條件 (HRC) 說明
    '...
    '設定該報告使用的資料庫
    Set m_Db = m_Context.DbCriteria
    '...
End Function

Public Function ShowHRCReport() As Boolean
    'Step4 符合高風險條件傳票報告
    '...
    '設定該報告使用的資料庫
    Set m_Db = m_Context.DbCriteria
    '...
End Function

Public Function ShowHRCDetails() As Boolean
    'Step4-1 符合高風險條件傳票之明細
    '...
    '設定該報告使用的資料庫
    Set m_Db = m_Context.DbCriteria
    '...
End Function

Public Function PostClosingEntries() As Boolean
    'Step5 財務報表關帳後調整之分錄
End Function

Public Function FieldInfo() As Boolean
    '自動化工具-檔案欄位資訊
End Function

Public Function HolidyInfo() As Boolean
    '自動化工具-假期假日資訊
End Function

Public Function AccountMappingInfo() As Boolean
    '自動化工具-科目配對資訊
End Function

Public Function ExportWp() As Boolean
    ' ============================================================================
    ' 將處理好的底稿輸出至本機目錄
    ' 彙總所有軌跡的報告並輸出 .xlsx 檔案至專案木錄
    ' ============================================================================
End Function
