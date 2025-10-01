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
' Purpose: 定義資料輸出的服務，專門將資料庫內的資料表輸出於 Excel 工作表
'===============================================================================
Private m_Db As DbAccess
Private m_Info As EntityInfo
Private m_Ace As New Access.Application

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbValid
    Set m_Info = context.info
End Sub

Public Function PreviewTable(ByVal sheetName As String, _
                             ByVal tableName As String, _
                             ByVal targetDb As DbAccess) As Boolean
    '------------------------------------------------------------
    '方法:將資料表預覽於當前工作表
    '參數:
    '   - sheetName: 工作表名稱
    '   - tableName: 資料表名稱
    '   - targetDb:
    '------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    Dim sql As String
    sql = "SELECT * FROM [" & tableName & "];"
    
    Dim rs As DAO.Recordset
    Set rs = targetDb.ExecuteQuery(sql)
    
    Call ShowRecordsetInSheet(rs, sheetName)
    
ErrorHandler:
    Debug.Print "PreviewTable(): "; Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
End Function

Public Function PreviewWp() As Boolean
    '------------------------------------------------------------
    '將處理好的底稿預覽於當前工作表
    '清空之前操作軌跡所臨時產出的報告
    '並重新彙總所有軌跡的報告並預覽於工作表顯示
    '------------------------------------------------------------
End Function

Public Function ExportWp() As Boolean
    '------------------------------------------------------------
    '將處理好的底稿輸出至本機目錄
    '彙總所有軌跡的報告並輸出 .xlsx 檔案至專案木錄
    '------------------------------------------------------------
End Function

'***** 工作表管理
Private Sub ShowRecordsetInSheet(ByVal rs As DAO.Recordset, _
                                 ByVal name As String, _
                                 Optional IsFirst As Boolean = True)
    '------------------------------------------------------------
    '方法:將紀錄集顯示於指定名稱的工作表
    '參數:
    '   - rs: 欲顯示的資料庫紀錄集
    '   - name: 工作表名稱
    '   - IsFirst: 工作表插入位置為最前面，默認為是
    '------------------------------------------------------------
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
    '寫入標題欄位
    Dim i As Long
    For i = 0 To rs.Fields.Count - 1
        ws.Cells(1, i + 1).Value = rs.Fields(i).name
    Next i
    '格式化標題列
    With ws.Range(ws.Cells(1, 1), ws.Cells(1, rs.Fields.Count))
        .Font.Bold = True
        .Interior.Color = vbYellow
    End With
    '寫入資料
    If Not rs.EOF Then
        ws.Range("A2").CopyFromRecordset rs, MAX_ROWS, MAX_COLS
    End If
    
End Sub

'***** 產出指定報告
Private Function PreparationSummary() As Boolean
    'Step0 - 資料預先整理之說明
End Function

Private Function WorkingPaperSummary() As Boolean
    'Step0 - JE Working Paper 說明
End Function

Private Function ValidationReport() As Boolean
    'Step1 - 驗證報告
    Dim i As Long, j As Long
    
End Function

Private Function CompletenessReport() As Boolean
    'Step1-1 - 完整性測試報告
End Function

Private Function DocumentBalanceReport() As Boolean
    'Step1-2 借貸不平測試報告
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


