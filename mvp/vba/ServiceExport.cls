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
                                    ByVal tables As Variant, _
                                    Optional ByVal startRow As Long = 1)
    ' ============================================================================
    ' 方法: 將多個資料表依序渲染至指定工作表
    ' 參數:
    '     - ws: 目標工作表物件
    '     - tables: 資料表名稱陣列 (Variant Array)
    '     - startRow: 起始列位置 (預設為 1)
    ' ============================================================================
    On Error GoTo ErrorHandler
    Dim idx As Long
    Dim currentRow As Long
    Dim rs As DAO.Recordset
    Dim rowsCopied As Long
    
    currentRow = startRow
    ws.Cells.Clear
    '遍歷所有資料表
    For idx = LBound(tables) To UBound(tables)
        Dim tableName As String
        tableName = CStr(tables(idx))
        '檢查資料表是否存在
        If Not m_Db.TableExists(tableName) Then
            ws.Cells(currentRow, 1).Value = "資料表 [" & tableName & "] 不存在"
            ws.Cells(currentRow, 1).Font.Color = vbRed
            currentRow = currentRow + 2
        Else
            Set rs = m_Db.ExecuteQuery("SELECT * FROM [" & tableName & "];")
            rowsCopied = 0
            '寫入區塊標題列
            ws.Cells(currentRow, 1).Value = tableName
            ws.Cells(currentRow, 1).Font.Bold = True
            currentRow = currentRow + 1
            '寫入欄位名稱列
            Dim col As Long
            For col = 0 To rs.Fields.Count - 1
                ws.Cells(currentRow, col + 1).Value = rs.Fields(col).name
            Next col
            '格式化欄位名稱列
            With ws.Range(ws.Cells(currentRow, 1), ws.Cells(currentRow, rs.Fields.Count))
                .Font.Bold = True
                .Interior.Color = RGB(245, 241, 222)
            End With
            
            currentRow = currentRow + 1
            '處理資料
            If rs.BOF And rs.EOF Then
                '無資料情形
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
            '釋放資源
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
    '============================================================================
    ' 資料預先整理之說明 = ENGAGEMENT_OVERVIEW
    '============================================================================
    ShowEngagementOverview = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array(RPT_ENGAGEMENT_OVERVIEW)
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-1-1|資料預先整理之說明"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowEngagementOverview = True
End Function

Public Function ShowWorkingPaperSummary() As Boolean
    ' JE底稿說明 = 0
End Function

Public Function ShowValidationReport() As Boolean
    '============================================================================
    ' 驗證測試報告 = ENGAGEMENT_OVERVIEW + DATA_OVERVIEW + VALIDATION_OVERVIEW
    '============================================================================
    ShowValidationReport = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array(RPT_ENGAGEMENT_OVERVIEW, RPT_DATA_OVERVIEW, RPT_VALIDATION_OVERVIEW)
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-2-1|驗證測試報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowValidationReport = True
End Function

Public Function ShowCompletenessReport() As Boolean
    '============================================================================
    ' 完整性測試報告 = ENGAGEMENT_OVERVIEW + COMPLETENESS_DETAIL
    '============================================================================
    ShowCompletenessReport = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array(RPT_ENGAGEMENT_OVERVIEW, RPT_COMPLETENESS_DETAIL)
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-2-2|完整性測試報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowCompletenessReport = True
End Function

Public Function ShowDocumentBalanceReport() As Boolean
    '============================================================================
    ' 借貸不平測試報告 = ENGAGEMENT_OVERVIEW + DOCUMENT_BALANCE_DETAIL
    '============================================================================
    ShowDocumentBalanceReport = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array(RPT_ENGAGEMENT_OVERVIEW, RPT_DOCUMENT_BALANCE_DETAIL)
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-2-3|借貸不平測試報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowDocumentBalanceReport = True
End Function

Public Function ShowPreparerSummary() As Boolean
    '============================================================================
    ' 分錄編制人員說明 = ENGAGEMENT_OVERVIEW + ???
    ' 原始資料位於 #PreScr-R5-Sum 為預篩選步驟
    '============================================================================
    ShowPreparerSummary = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-2-4|分錄編制人員說明"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    'Call RenderTablesToWorksheet(ws, tables)
    ShowPreparerSummary = True
End Function

Public Function ShowCompletenessDifferenceSummary() As Boolean
    '============================================================================
    ' 完整性測試之差異說明 =
    '============================================================================
    ShowCompletenessDifferenceSummary = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-2-5|完整性測試之差異說明"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowCompletenessDifferenceSummary = True
End Function

Public Function ShowCompletenessReconciliationReport() As Boolean
    '============================================================================
    ' 完整性差異調節報告
    '============================================================================
    ShowCompletenessReconciliationReport = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-2-6|完整性差異調節報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowCompletenessReconciliationReport = True
End Function

Public Function ShowINFReport() As Boolean
    '============================================================================
    ' INF可靠性測試 =
    '============================================================================
    ShowINFReport = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-3-1|INF可靠性測試"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowINFReport = True
End Function

Public Function ShowHRCSummary() As Boolean
    '============================================================================
    ' 高風險條件 (HRC) 說明
    '============================================================================
    ShowHRCSummary = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-4-1|高風險條件 (HRC) 說明"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowHRCSummary = True
    '...
End Function

Public Function ShowHRCReport() As Boolean
    '============================================================================
    ' 符合高風險條件傳票報告 =
    '============================================================================
    ShowHRCReport = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-4-2|符合高風險條件傳票報告"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowHRCReport = True
End Function

Public Function ShowHRCDetails() As Boolean
    '============================================================================
    ' 符合高風險條件傳票之明細
    '============================================================================
    ShowHRCDetails = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-4-3|符合高風險條件傳票之明細"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    ShowHRCDetails = True
End Function

Public Function PostClosingEntries() As Boolean
    '============================================================================
    '財務報表關帳後調整之分錄
    '============================================================================
    PostClosingEntries = False
    '設置資料表陣列
    Dim tables As Variant
    tables = Array()
    '設置工作表名稱
    Dim sheetName As String
    sheetName = "Step-5-1|財務報表關帳後調整之分錄"
    '設置工作表物件
    Dim ws As Worksheet
    Set ws = PreviewSheet
    ws.name = sheetName
    '預覽記錄集於工作表
    Call RenderTablesToWorksheet(ws, tables)
    PostClosingEntries = True
End Function

Public Function FieldInfo() As Boolean
    '============================================================================
    ' 自動化工具-檔案欄位資訊
    '============================================================================
End Function

Public Function HolidyInfo() As Boolean
    '============================================================================
    ' 自動化工具-假期假日資訊
    '============================================================================
End Function

Public Function AccountMappingInfo() As Boolean
    '============================================================================
    ' 自動化工具-科目配對資訊
    '============================================================================
End Function

Public Function ExportWp() As Boolean
    ' ============================================================================
    ' 將處理好的底稿輸出至本機目錄
    ' 彙總所有軌跡的報告並輸出 .xlsx 檔案至專案木錄
    ' ============================================================================
End Function
