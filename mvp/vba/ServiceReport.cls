VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceReport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: ServiceReport
' Purpose: 定義產出報表所需資料之服務
'===============================================================================
Private m_Db As DbAccess
Private m_Context As ContextManager

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbReport
    Set m_Context = context
End Sub

Public Function GenerateEngagementOverview() As Boolean
    ' ============================================================================
    ' 方法: 產生專案總覽報表
    ' 欄位: 客戶, 財報準備期間開始日, 資料期間開始日, 資料期間結束日, 報表生產人, 報表生產時間
    ' ============================================================================
    On Error GoTo ErrorHandler
    GenerateEngagementOverview = False
    '指定常數欄位名稱
    Const FLD_CLIENT As String = "客戶"
    Const FLD_PREP_START_DATE As String = "財報準備期間開始日"
    Const FLD_PERIOD_START As String = "資料期間開始日"
    Const FLD_PERIOD_END As String = "資料期間結束日"
    Const FLD_PREPARED_BY As String = "報表生產人"
    Const FLD_PREPARED_DATE As String = "報表生產時間"
    '指定資料表名稱至全域常數
    Dim tableName As String
    tableName = RPT_ENGAGEMENT_OVERVIEW
    '檢查已存在資料表
    If m_Db.TableExists(tableName) Then
        Call m_Db.DropTable(tableName)
    End If
    '處理資料庫查詢
    Dim sql As String
    sql = "SELECT TOP 1 " & vbCrLf & _
          "    '" & m_Context.info.CompanyName & "' AS [" & FLD_CLIENT & "], " & vbCrLf & _
          "    '" & m_Context.info.UserName & "' AS [" & FLD_PREPARED_BY & "], " & vbCrLf & _
          "    #" & m_Context.info.PrepStartDate & "# AS [" & FLD_PREP_START_DATE & "], " & vbCrLf & _
          "    #" & m_Context.info.PeriodStart & "# AS [" & FLD_PERIOD_START & "], " & vbCrLf & _
          "    #" & m_Context.info.PeriodEnd & "# AS [" & FLD_PERIOD_END & "], " & vbCrLf & _
          "    #" & Date & "# AS [" & FLD_PREPARED_DATE & "] " & vbCrLf & _
          "INTO " & tableName & " IN '" & m_Db.path & "' " & vbCrLf & _
          "FROM " & m_Context.je.name & " IN '" & m_Context.DbInput.path & "';"
    m_Db.ExecuteNonQuery sql
    
    GenerateEngagementOverview = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateEngagementOverview(): " & Err.Number & " - " & Err.Description
End Function

Public Function GenerateDataOverview() As Boolean
    ' ============================================================================
    ' 方法
    ' 參數: 分錄檔案名稱,分錄借貸淨額,分錄借方合計金額,分錄貸方合計金額,分錄筆數,試算表檔案名稱,試算表科目數量
    ' ============================================================================
    On Error GoTo ErrorHandler
    GenerateDataOverview = False
    '指定欄位名稱常數
    Const FLD_JE_NAME As String = "分錄檔案名稱"
    Const FLD_JE_NET_AMOUNT As String = "分錄借貸淨額"
    Const FLD_JE_DEBIT_SUM As String = "分錄借方合計金額"
    Const FLD_JE_CREDIT_SUM As String = "分錄貸方合計金額"
    Const FLD_JE_RECORD_COUNT As String = "分錄筆數"
    Const FLD_TB_NAME As String = "試算表檔案名稱"
    Const FLD_TB_ACCOUNT_COUNT As String = "試算表科目數量"
    '指定資料表名稱至全域常數
    Dim tableName As String
    tableName = RPT_DATA_OVERVIEW
    '檢查已存在資料表
    If m_Db.TableExists(tableName) Then
        Call m_Db.DropTable(tableName)
    End If
    '取得報表所需資料
    Dim jeName As String
    Dim jeNetAmount As Double
    Dim jeDebitSum As Double
    Dim jeCreditSum As Double
    Dim jeRecordCount As Long
    Dim tbName As String
    Dim tbAccountCount As Long
    jeName = m_Context.je.name
    jeNetAmount = m_Context.DbInput.GetTotal(m_Context.je.name, m_Context.je.K_Amount, "NetValue")
    jeDebitSum = m_Context.DbInput.GetTotal(m_Context.je.name, m_Context.je.K_Amount, "PositiveValue")
    jeCreditSum = m_Context.DbInput.GetTotal(m_Context.je.name, m_Context.je.K_Amount, "NegativeValue")
    jeRecordCount = m_Context.DbInput.GetTotal(m_Context.je.name, "", "DBCount")
    tbName = m_Context.tb.name
    tbAccountCount = m_Context.DbInput.GetTotal(m_Context.tb.name, "", "DBCount")
    '處理資料庫查詢
    Dim sql As String
    sql = "SELECT TOP 1 " & vbCrLf & _
          "    '" & jeName & "' AS [" & FLD_JE_NAME & "], " & vbCrLf & _
          "    '" & jeNetAmount & "' AS [" & FLD_JE_NET_AMOUNT & "], " & vbCrLf & _
          "    '" & jeDebitSum & "' AS [" & FLD_JE_DEBIT_SUM & "], " & vbCrLf & _
          "    '" & jeCreditSum & "' AS [" & FLD_JE_CREDIT_SUM & "], " & vbCrLf & _
          "    '" & jeRecordCount & "' AS [" & FLD_JE_RECORD_COUNT & "], " & vbCrLf & _
          "    '" & tbName & "' AS [" & FLD_TB_NAME & "], " & vbCrLf & _
          "    '" & tbAccountCount & "' AS [" & FLD_TB_ACCOUNT_COUNT & "] " & vbCrLf & _
          "INTO " & tableName & " IN '" & m_Db.path & "' " & vbCrLf & _
          "FROM " & m_Context.je.name & " IN '" & m_Context.DbInput.path & "';"
    m_Db.ExecuteNonQuery sql
    
    GenerateDataOverview = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateDataOverview(): " & Err.Number & " - " & Err.Description
End Function

Public Function GenerateValidationOverview() As Boolean
    ' ============================================================================
    ' 方法
    ' 參數: 無會計科目編號筆數,無傳票號碼筆數,無傳票摘要筆數,完整性差異筆數,借貸不平差異筆數
    ' ============================================================================
    On Error GoTo ErrorHandler
    GenerateValidationOverview = False
    '指定欄位名稱常數
    Const FLD_NULL_ACCOUNT_RECORD_COUNT As String = "無會計科目編號筆數"
    Const FLD_NULL_DOCUMENT_RECORD_COUNT As String = "無傳票號碼筆數"
    Const FLD_NULL_DESCRIPTION_RECORD_COUNT As String = "無傳票摘要筆數"
    Const FLD_COMEPLETENESS_DIFF_COUNT As String = "完整性差異筆數"
    Const FLD_DOCUMENT_NOT_BALANCE_COUNT As String = "借貸不平差異筆數"
    '指定資料表名稱至全域常數
    Dim tableName As String
    tableName = RPT_VALIDATION_OVERVIEW
    '檢查已存在資料表
    If m_Context.DbReport.TableExists(tableName) Then
        Call m_Context.DbReport.DropTable(tableName)
    End If
    '取得報表所需資料
    
    '處理資料庫查詢
    Dim sql As String
    sql = ""
    Exit Function
ErrorHandler:
    Debug.Print "GenerateValidationOverview(): " & Err.Number & " - " & Err.Description
End Function


