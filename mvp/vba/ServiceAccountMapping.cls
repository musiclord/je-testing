VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceAccountMapping"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: ServiceAccountMapping
' Purpose: 管理科目配對的服務
'
' Description:
'   負責從驗證結果（COMPLETENESS_DETAIL）提取科目清單,
'   匯出至 AccountMappingSheet 供審計人員標註,
'   並將標註結果匯入至資料庫以供後續分析使用。
'
' Dependencies:
'   - ServiceValidation: 需先執行 CheckCompleteness() 產生 COMPLETENESS_DETAIL
'   - AccountMappingSheet: Excel 工作表物件
'
' Workflow:
'   1. ExportTemplate()
'       ↓ 從 COMPLETENESS_DETAIL 匯出科目清單至 AccountMappingSheet
'
'   2. [使用者手動標註]
'       ↓ 審計人員在 Excel 中填寫 "Standardized Account Name"
'
'   3. ImportAccountMapping()
'       ↓ 讀取 AccountMappingSheet 並儲存至 ACCOUNT_MAPPING 表
'
'   4. ValidateAccountMapping()
'         驗證對應關係的完整性
'
'
' [標準化科目分類選項]:
'     - STANDARDIZED_ACCOUNT_NAME
'         (1)Cash
'         (2)Revenue
'         (3)Receipt in advance
'         (4)Receivables
'         (5)Others
'
' Fields
'     1. GL Number,   原始科目代號（文字或數字）
'     2. GL Name,     標準化科目名稱，如果沒有就填 "Not in TB"
'     3. Standardized Account Name
'
' Data
'     - TBL_COMPLETENESS_DETAIL, 經過完整性測試的資料已經由科目代號(TB的)分組過
'
' Example
'-------------------------------------------------------------------------------
'     GL_Number |   GL_Name            |  Standardized Account Name*
'     1101**    |   Not in TB          |  Cash
'     1102A*    |   [銀存]支票存款     |  Cash
'     1102C*    |   [銀存]外匯活期存款 |  Cash
'     1103**    |   定期存款           |  Cash
'-------------------------------------------------------------------------------
'
'===============================================================================
Private m_Context As ContextManager
Private m_DbValid As DbAccess
Private m_Db As DbAccess
Private m_Schema As DbSchema

Public Sub Initialize(context As ContextManager)
    Set m_Context = context
    Set m_Db = context.DbInput
    Set m_Schema = context.DbSchema
    Set m_DbValid = context.DbValid
End Sub

'-------------------------------------------------------------------------------
' Method: ExportTemplate
' Purpose: 從 COMPLETENESS_DETAIL 匯出科目清單至 AccountMappingSheet
' Returns: Boolean - 成功回傳 True
'-------------------------------------------------------------------------------
Public Function ExportTemplate() As Boolean
    On Error GoTo ErrorHandler
    ExportTemplate = False
    
    Debug.Print "********** 開始匯出科目配對範本 **********"
    
    '-- 檢查前置條件
    If Not m_DbValid.TableExists(m_Schema.Tables.CompletenessDetail) Then
        Debug.Print "  - 錯誤: COMPLETENESS_DETAIL 表不存在"
        MsgBox "請先執行完整性測試以產生科目清單", vbExclamation, "科目配對"
        Exit Function
    End If
    
    '-- 建立查詢 SQL
    Dim sql As String
    sql = "SELECT " & vbCrLf & _
          "    [" & m_Schema.Fields.AccountMerged & "] AS [GL_Number], " & vbCrLf & _
          "    [" & m_Schema.TB.AccountName & "] AS [GL_Name], " & vbCrLf & _
          "    [" & m_Schema.Fields.TbAmount & "] AS [TB_Amount], " & vbCrLf & _
          "    [" & m_Schema.Fields.JeAmountSum & "] AS [JE_Amount], " & vbCrLf & _
          "    [" & m_Schema.Fields.TbJeDiff & "] AS [TB_JE_Diff], " & vbCrLf & _
          "    '' AS [Standardized_Account_Name]" & vbCrLf & _
          "FROM [" & m_Schema.Tables.CompletenessDetail & "]" & vbCrLf & _
          "ORDER BY [" & m_Schema.Fields.AccountMerged & "];"
    
    Debug.Print "  - 執行查詢"
    
    '-- 執行查詢
    Dim rs As DAO.Recordset
    Set rs = m_DbValid.ExecuteQuery(sql)
    
    If rs.EOF Then
        Debug.Print "  - 警告: 無科目資料可匯出"
        MsgBox "完整性測試結果沒有科目資料", vbInformation, "科目配對"
        rs.Close
        Exit Function
    End If
    
    '-- 取得目標工作表
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets(SHT_ACCOUNT_MAPPING)
    
    '-- 清空工作表
    ws.Cells.Clear
    
    '-- 寫入欄位標題
    ws.Range("A1").Value = "GL_Number"
    ws.Range("B1").Value = "GL_Name"
    ws.Range("C1").Value = "TB_Amount"
    ws.Range("D1").Value = "JE_Amount"
    ws.Range("E1").Value = "TB_JE_Diff"
    ws.Range("F1").Value = "Standardized_Account_Name"
    
    '-- 格式化標題列
    With ws.Range("A1:F1")
        .Font.Bold = True
        .Interior.Color = RGB(217, 217, 217)
        .HorizontalAlignment = xlCenter
    End With
    
    '-- 設定欄位格式
    ws.Columns("A:B").NumberFormat = "@"           ' 文字格式
    ws.Columns("C:E").NumberFormat = "#,##0.00"    ' 金額格式
    ws.Columns("F:F").NumberFormat = "@"           ' 文字格式
    
    '-- 寫入資料 (從 A2 開始)
    Debug.Print "  - 開始寫入資料"
    ws.Range("A2").CopyFromRecordset rs
    
    rs.Close
    Set rs = Nothing
    
    '-- 取得實際資料範圍
    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
    
    '-- 設定資料驗證 (F欄: 標準化科目分類)
    If lastRow > 1 Then
        With ws.Range("F2:F" & lastRow).Validation
            .Delete
            .Add Type:=xlValidateList, _
                 AlertStyle:=xlValidAlertStop, _
                 Operator:=xlBetween, _
                 Formula1:="Cash,Revenue,Receipt in advance,Receivables,Others"
            .IgnoreBlank = True
            .InCellDropdown = True
            .ShowInput = True
            .ShowError = True
        End With
    End If
    
    '-- 自動調整欄寬
    ws.Columns("A:F").AutoFit
    
    '-- 凍結首列
    ws.Rows("2:2").Select
    ActiveWindow.FreezePanes = True
    ws.Range("A2").Select
    
    Debug.Print "  - 成功匯出 " & (lastRow - 1) & " 筆科目資料"
    Debug.Print "********** 科目配對範本匯出完成 **********"
    
    ExportTemplate = True
    Exit Function
    
ErrorHandler:
    Debug.Print "ExportTemplate(): " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    MsgBox "匯出科目配對範本時發生錯誤:" & vbCrLf & Err.Description, vbCritical, "科目配對"
End Function

'-------------------------------------------------------------------------------
' Method: ImportAccountMapping
' Purpose: 讀取 AccountMappingSheet 並儲存至 ACCOUNT_MAPPING 表
' Returns: Boolean - 成功回傳 True
'-------------------------------------------------------------------------------
Public Function ImportAccountMapping() As Boolean
    On Error GoTo ErrorHandler
    ImportAccountMapping = False
    
    Debug.Print "********** 開始匯入科目配對資料 **********"
    
    '-- 取得來源工作表
    Dim ws As Worksheet
    Set ws = ThisWorkbook.Worksheets(SHT_ACCOUNT_MAPPING)
    
    '-- 驗證表頭
    If ws.Range("A1").Value <> "GL_Number" Or _
       ws.Range("F1").Value <> "Standardized_Account_Name" Then
        Debug.Print "  - 錯誤: 工作表格式不正確"
        MsgBox "工作表格式不正確，請重新匯出範本", vbExclamation, "科目配對"
        Exit Function
    End If
    
    '-- 取得資料範圍
    Dim lastRow As Long
    lastRow = ws.Cells(ws.Rows.Count, 1).End(xlUp).row
    
    If lastRow < 2 Then
        Debug.Print "  - 警告: 無資料可匯入"
        MsgBox "工作表中沒有資料", vbInformation, "科目配對"
        Exit Function
    End If
    
    Debug.Print "  - 共 " & (lastRow - 1) & " 筆資料待匯入"
    
    '-- 驗證必填欄位
    Dim i As Long
    Dim missingCount As Long
    
    For i = 2 To lastRow
        If Trim(ws.Cells(i, 1).Value & "") = "" Or _
           Trim(ws.Cells(i, 6).Value & "") = "" Then
            missingCount = missingCount + 1
        End If
    Next i
    
    If missingCount > 0 Then
        Debug.Print "  - 錯誤: 發現 " & missingCount & " 筆必填欄位未填寫"
        MsgBox "發現 " & missingCount & " 筆資料的 GL_Number 或 Standardized_Account_Name 未填寫", _
               vbExclamation, "科目配對"
        Exit Function
    End If
    
    '-- 清空並重建 ACCOUNT_MAPPING 表
    Debug.Print "  - 清空並重建 ACCOUNT_MAPPING 表"
    If m_Db.TableExists(m_Schema.AccountMapping.Name) Then
        Call m_Db.DropTable(m_Schema.AccountMapping.Name)
    End If
    
    Dim sqlCreate As String
    sqlCreate = "CREATE TABLE [" & m_Schema.AccountMapping.Name & "] (" & vbCrLf & _
                "    [" & m_Schema.AccountMapping.AccountNumber & "] TEXT(50) NOT NULL, " & vbCrLf & _
                "    [" & m_Schema.AccountMapping.AccountName & "] TEXT(255), " & vbCrLf & _
                "    [" & m_Schema.AccountMapping.AccountStandardized & "] TEXT(50) NOT NULL" & vbCrLf & _
                ");"
    
    m_Db.ExecuteNonQuery sqlCreate
    
    '-- 開始交易
    m_Db.BeginTx
    
    '-- 匯入資料
    Debug.Print "  - 開始匯入資料"
    Dim rs As DAO.Recordset
    Set rs = m_Db.Database.OpenRecordset( _
                m_Schema.AccountMapping.Name, _
                dbOpenDynaset _
             )
    
    Dim importCount As Long
    importCount = 0
    
    For i = 2 To lastRow
        rs.AddNew
        rs(m_Schema.AccountMapping.AccountNumber) = Trim(ws.Cells(i, 1).Value & "")
        rs(m_Schema.AccountMapping.AccountName) = Trim(ws.Cells(i, 2).Value & "")
        rs(m_Schema.AccountMapping.AccountStandardized) = Trim(ws.Cells(i, 6).Value & "")
        rs.Update
        importCount = importCount + 1
    Next i
    
    rs.Close
    Set rs = Nothing
    
    '-- 提交交易
    m_Db.CommitTx
    m_Db.Refresh
    
    Debug.Print "  - 成功匯入 " & importCount & " 筆科目配對資料"
    Debug.Print "********** 科目配對資料匯入完成 **********"
    
    MsgBox "成功匯入 " & importCount & " 筆科目配對資料", vbInformation, "科目配對"
    
    ImportAccountMapping = True
    Exit Function
    
ErrorHandler:
    Debug.Print "ImportAccountMapping(): " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    MsgBox "匯入科目配對資料時發生錯誤:" & vbCrLf & Err.Description, vbCritical, "科目配對"
End Function

'-------------------------------------------------------------------------------
' Method: ValidateAccountMapping
' Purpose: 驗證科目配對的完整性
' Returns: Boolean - 驗證通過回傳 True
'-------------------------------------------------------------------------------
Public Function ValidateAccountMapping() As Boolean
    On Error GoTo ErrorHandler
    ValidateAccountMapping = False
    
    Debug.Print "********** 開始驗證科目配對 **********"
    
    '-- 檢查 ACCOUNT_MAPPING 表是否存在
    If Not m_Db.TableExists(m_Schema.AccountMapping.Name) Then
        Debug.Print "  - 錯誤: ACCOUNT_MAPPING 表不存在"
        MsgBox "請先匯入科目配對資料", vbExclamation, "科目配對驗證"
        Exit Function
    End If
    
    '-- 檢查記錄數量
    Dim recordCount As Long
    recordCount = CLng(m_Db.GetTotal(m_Schema.AccountMapping.Name, "", "DBCount"))
    
    If recordCount = 0 Then
        Debug.Print "  - 警告: ACCOUNT_MAPPING 表為空"
        MsgBox "科目配對表沒有資料", vbInformation, "科目配對驗證"
        Exit Function
    End If
    
    '-- 檢查是否有重複的科目代號
    Dim sqlDuplicate As String
    sqlDuplicate = "SELECT [" & m_Schema.AccountMapping.AccountNumber & "], COUNT(*) AS [Count] " & _
                   "FROM [" & m_Schema.AccountMapping.Name & "] " & _
                   "GROUP BY [" & m_Schema.AccountMapping.AccountNumber & "] " & _
                   "HAVING COUNT(*) > 1;"
    
    Dim rsDup As DAO.Recordset
    Set rsDup = m_Db.ExecuteQuery(sqlDuplicate)
    
    If Not rsDup.EOF Then
        Debug.Print "  - 警告: 發現重複的科目代號"
        Dim dupList As String
        Do While Not rsDup.EOF
            dupList = dupList & rsDup(0) & " (" & rsDup(1) & "次), "
            rsDup.MoveNext
        Loop
        rsDup.Close
        MsgBox "發現重複的科目代號:" & vbCrLf & Left(dupList, Len(dupList) - 2), _
               vbExclamation, "科目配對驗證"
        Exit Function
    End If
    rsDup.Close
    
    Debug.Print "  - 驗證通過 (共 " & recordCount & " 筆)"
    Debug.Print "********** 科目配對驗證完成 **********"
    
    ValidateAccountMapping = True
    Exit Function
    
ErrorHandler:
    Debug.Print "ValidateAccountMapping(): " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    MsgBox "驗證科目配對時發生錯誤:" & vbCrLf & Err.Description, vbCritical, "科目配對驗證"
End Function
