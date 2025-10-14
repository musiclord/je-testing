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
Private Sub RenderTablesToWorksheet(ByVal ws As Worksheet, _
                                    ByVal tableNames As Variant, _
                                    ByVal sectionTitles As Variant, _
                                    Optional ByVal startRow As Long = 1)
    On Error GoTo ErrorHandler
    Dim idx As Long
    Dim currentRow As Long
    Dim rs As DAO.Recordset
    Dim rowsCopied As Long
    
    currentRow = startRow
    ws.Cells.Clear
    
    For idx = LBound(tableNames) To UBound(tableNames)
        Dim tableName As String
        tableName = CStr(tableNames(idx))
        
        If Not m_Db.TableExists(tableName) Then
            ws.Cells(currentRow, 1).Value = "資料表 [" & tableName & "] 不存在"
            ws.Cells(currentRow, 1).Font.Color = vbRed
            currentRow = currentRow + 2
        Else
            Set rs = m_Db.ExecuteQuery("SELECT * FROM [" & tableName & "];")
            rowsCopied = 0
            '寫入標題列
            ws.Cells(currentRow, 1).Value = CStr(sectionTitles(idx))
            ws.Cells(currentRow, 1).Font.Bold = True
            currentRow = currentRow + 1
            
            Dim col As Long
            For col = 0 To rs.Fields.Count - 1
                ws.Cells(currentRow, col + 1).Value = rs.Fields(col).name
            Next col
            
            With ws.Range(ws.Cells(currentRow, 1), ws.Cells(currentRow, rs.Fields.Count))
                .Font.Bold = True
                .Interior.Color = RGB(245, 241, 222)
            End With
            
            currentRow = currentRow + 1
            
            If rs.BOF And rs.EOF Then
                ws.Cells(currentRow, 1).Value = "(無資料)"
                currentRow = currentRow + 2
            Else
                '寫入資料
                If rs.RecordCount = -1 Then
                    rs.MoveLast
                End If
                rowsCopied = rs.RecordCount
                If rowsCopied < 0 Then rowsCopied = 0
                rs.MoveFirst
                ws.Cells(currentRow, 1).CopyFromRecordset rs
                currentRow = currentRow + rowsCopied + 2
            End If
            
            rs.Close
            Set rs = Nothing
        End If
    Next idx
    '自動調整欄寬
    ws.Columns.AutoFit
    ws.Activate
    Exit Sub
ErrorHandler:
    Debug.Print "RenderTablesToWorksheet(): " & Err.Number & " - " & Err.Description
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
    On Error GoTo ErrorHandler
    ShowEngagementOverview = False
    '設置資料表名稱
    Dim tableNames As Variant
    tableNames = Array(RPT_ENGAGEMENT_OVERVIEW)
    '設置報表名稱
    Dim sectionTitles As Variant
    sectionTitles = Array("資料預先整理說明")
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-1 預先整理說明"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tableNames, sectionTitles)
    
    ShowEngagementOverview = True
    Exit Function
ErrorHandler:
    Debug.Print "ShowEngagementOverview(): " & Err.Number & " - " & Err.Description
End Function

Public Function ShowWorkingPaperSummary() As Boolean
    ' JE底稿說明
    ' = 0
End Function

Public Function ShowValidationReport() As Boolean
    ' ============================================================================
    ' 驗證測試報告
    ' = ENGAGEMENT_OVERVIEW + VALIDATION_OVERVIEW + DATA_OVERVIEW
    ' ============================================================================
    On Error GoTo ErrorHandler
    ShowValidationReport = False
    '設置資料表名稱
    Dim tableNames As Variant
    tableNames = Array(RPT_ENGAGEMENT_OVERVIEW, RPT_VALIDATION_OVERVIEW, RPT_DATA_OVERVIEW)
    '設置報表名稱
    Dim sectionTitles As Variant
    sectionTitles = Array("專案總覽", "驗證測試彙總", "資料輸入概況")
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step1-0 驗證測試報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tableNames, sectionTitles)
    
    ShowValidationReport = True
    Exit Function
ErrorHandler:
    Debug.Print "ShowValidationReport(): " & Err.Number & " - " & Err.Description
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
