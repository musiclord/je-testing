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
'Class:ServiceExport
Private db_Input As DbAccess
Private db_Valid As DbAccess
Private m_Info As EntityInfo
Private m_Ace As New Access.Application

Public Sub Initialize(context As ContextManager)
    Set db_Input = context.DbInput
    Set db_Valid = context.DbValid
    Set m_Info = context.info
End Sub

Public Function PreviewTable(ByVal sheetName As String, ByVal tableName As String, ByVal targetDb As DbAccess) As Boolean
    '將資料表預覽於當前工作表
    On Error GoTo ErrorHandler
    
    Dim sql As String
    sql = "SELECT * FROM [" & tableName & "];"
    
    Dim rs As DAO.Recordset
    Set rs = targetDb.ExecuteQuery(sql)
    
    Call CreateWorksheet(rs, sheetName)
    
ErrorHandler:
    Debug.Print "PreviewTable(): "; Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
End Function

Public Function PreviewWp() As Boolean
    '將處理好的底稿預覽於當前工作表
    '清空之前操作軌跡所臨時產出的報告
    '並重新彙總所有軌跡的報告並預覽於工作表顯示
End Function

Public Function ExportWp() As Boolean
    '將處理好的底稿輸出至本機目錄
    '彙總所有軌跡的報告並輸出 .xlsx 檔案至專案木錄
End Function

'***** 工作表管理
Private Sub CreateWorksheet(ByVal rs As DAO.Recordset, ByVal name As String, Optional IsFirst As Boolean = True)
    '將紀錄集顯示於指定名稱的工作表
    Const MAX_ROWS As Long = 1000 '上限筆數為 1000 筆
    Const MAX_COLS As Long = 100  '上限欄位為 100 個
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets(name)
    If ws Is Nothing Then
        If IsFirst Then
            '新增為第一個工作表
            Set ws = ThisWorkbook.Worksheets.Add(Before:=ThisWorkbook.Worksheets(1))
        Else
            '新增為最後一個工作表
            Set ws = ThisWorkbook.Worksheets.Add(After:=ThisWorkbook.Worksheets(ThisWorkbook.Worksheets.Count))
        End If
    End If
    
    ws.Activate
    ws.Cells.Clear
    
    Dim i As Long
    For i = 0 To rs.Fields.Count - 1
        ws.Cells(1, i + 1).Value = rs.Fields(i).name
    Next i
    
    With ws.Range(ws.Cells(1, 1), ws.Cells(1, rs.Fields.Count))
        .Font.Bold = True
        .Interior.Color = vbYellow
    End With
    
    If Not rs.EOF Then
        ws.Range("A2").CopyFromRecordset rs, MAX_ROWS, MAX_COLS
    End If
    
End Sub

'***** 產出指定報告
Private Function PreparationSummary() As Boolean
    '資料預先整理之說明
    
End Function

Private Function WorkingPaperSummary() As Boolean
    'JE Working Paper 說明
End Function

Private Function CompletenessReport() As Boolean
    'Step1 - 完整性測試報告
End Function

Private Function DocumentBalanceReport() As Boolean
    'Step1-1 借貸不平測試報告
End Function

Private Function PreparerSummary() As Boolean
    'Step1-2 分錄編制人員說明
End Function

Private Function CompletenessDifferenceSummary() As Boolean
    'Step1-3 完整性測試之差異說明
End Function

Private Function CompletenessReconciliationReport() As Boolean
    'Step1-3-1 完整性差異調節報告
End Function

Private Function INFReport() As Boolean
    'Step2 INF可靠性測試
End Function

Private Function HRCSummary() As Boolean
    'Step3 高風險條件 (HRC) 說明
End Function

Private Function HRCReport() As Boolean
    'Step4 符合高風險條件傳票報告
End Function

Private Function HRCDetails() As Boolean
    'Step4-1 符合高風險條件傳票之明細
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


