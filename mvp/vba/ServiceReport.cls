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
' Class:    ServiceReport
' Purpose:  定義產出報表所需資料之服務
' Methods:
'===============================================================================
Private m_Db As DbAccess
Private m_Schema As DbSchema
Private m_Context As ContextManager

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbReport     '資料庫物件
    Set m_Schema = context.DbSchema '資料庫綱要
    Set m_Context = context
End Sub

Public Function GenerateEngagementOverview() As Boolean
    '---------------------------------------------------------------------------
    ' 方法: 產生專案總覽報表
    ' 欄位: 客戶, 財報準備期間開始日, 資料期間開始日, 資料期間結束日,
    '       報表生產人, 報表生產時間
    '---------------------------------------------------------------------------
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
          "FROM " & m_Schema.JE.Name & " IN '" & m_Context.DbInput.path & "';"
    m_Db.ExecuteNonQuery sql
    GenerateEngagementOverview = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateEngagementOverview(): " & Err.Number & " - " & Err.Description
End Function

Public Function GenerateDataOverview() As Boolean
    '---------------------------------------------------------------------------
    ' 方法
    ' 參數: 分錄檔案名稱,分錄借貸淨額,分錄借方合計金額,分錄貸方合計金額,
    '       分錄筆數,試算表檔案名稱,試算表科目數量
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    GenerateDataOverview = False
    '指定欄位名稱常數
    '//
    '//TODO: 這裡的常數應該刪掉，並歸給 DbSchema
    '//
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
    Dim JeName As String
    Dim JeNetAmount As Double
    Dim JeDebitSum As Double
    Dim JeCreditSum As Double
    Dim JeRecordCount As Long
    Dim TbName As String
    Dim TbAccountCount As Long
    JeName = m_Context.DbSchema.JE.Name
    JeNetAmount = m_Context.DbInput.GetTotal(m_Schema.JE.Name, m_Schema.JE.K_Amount, "NetValue")
    JeDebitSum = m_Context.DbInput.GetTotal(m_Schema.JE.Name, m_Schema.JE.K_Amount, "PositiveValue")
    JeCreditSum = m_Context.DbInput.GetTotal(m_Schema.JE.Name, m_Schema.JE.K_Amount, "NegativeValue")
    JeRecordCount = m_Context.DbInput.GetTotal(m_Schema.JE.Name, "", "DBCount")
    TbName = m_Schema.TB.Name
    TbAccountCount = m_Context.DbInput.GetTotal(m_Schema.TB.Name, "", "DBCount")
    '處理資料庫查詢
    Dim sql As String
    sql = "SELECT TOP 1 " & vbCrLf & _
          "    '" & JeName & "' AS [" & FLD_JE_NAME & "], " & vbCrLf & _
          "    '" & JeNetAmount & "' AS [" & FLD_JE_NET_AMOUNT & "], " & vbCrLf & _
          "    '" & JeDebitSum & "' AS [" & FLD_JE_DEBIT_SUM & "], " & vbCrLf & _
          "    '" & JeCreditSum & "' AS [" & FLD_JE_CREDIT_SUM & "], " & vbCrLf & _
          "    '" & JeRecordCount & "' AS [" & FLD_JE_RECORD_COUNT & "], " & vbCrLf & _
          "    '" & TbName & "' AS [" & FLD_TB_NAME & "], " & vbCrLf & _
          "    '" & TbAccountCount & "' AS [" & FLD_TB_ACCOUNT_COUNT & "] " & vbCrLf & _
          "INTO " & tableName & " IN '" & m_Db.path & "' " & vbCrLf & _
          "FROM " & m_Schema.JE.Name & " IN '" & m_Context.DbInput.path & "';"
    m_Db.ExecuteNonQuery sql
    GenerateDataOverview = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateDataOverview(): " & Err.Number & " - " & Err.Description
End Function

Public Function GenerateValidationOverview() As Boolean
    '---------------------------------------------------------------------------
    ' 方法
    ' 參數: 無會計科目編號筆數,無傳票號碼筆數,無傳票摘要筆數,
    '       完整性差異筆數,借貸不平差異筆數
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    GenerateValidationOverview = False
    '指定欄位名稱常數
    Const FLD_NULL_ACCOUNT_RECORD_COUNT As String = "無會計科目編號筆數"
    Const FLD_NULL_DOCUMENT_RECORD_COUNT As String = "無傳票號碼筆數"
    Const FLD_NULL_DESCRIPTION_RECORD_COUNT As String = "無傳票摘要筆數"
    Const FLD_NOT_IN_PERIOD_COUNT As String = "傳票核准日不在會計期間內筆數"
    Const FLD_COMEPLETENESS_DIFF_COUNT As String = "完整性差異筆數"
    Const FLD_DOCUMENT_BALANCE_DIFF_COUNT As String = "借貸不平差異筆數"
    '指定資料表名稱至全域常數
    Dim tableName As String
    '//
    '//TODO: 下面所有 RPT_ 的常數也要歸給 DbSchema，但還需要
    '//      看要怎麼設計，是否應該歸一為 m_Schema.Report 就好
    '//
    tableName = RPT_VALIDATION_OVERVIEW
    '檢查已存在資料表
    If m_Context.DbReport.TableExists(tableName) Then
        Call m_Context.DbReport.DropTable(tableName)
    End If
    '取得報表所需資料
    Dim nullAccountCount As Double
    Dim nullDocumentCount As Double
    Dim nullDescriptionCount As Double
    Dim NotInPeriodCount As Double
    Dim CompletenessDiffCount As Double
    Dim documentDiffCount As Double
    nullAccountCount = m_Context.DbValid.GetTotal(m_Schema.Tables.NullAccount, "", "DBCount")
    nullDocumentCount = m_Context.DbValid.GetTotal(m_Schema.Tables.NullDocument, "", "DBCount")
    nullDescriptionCount = m_Context.DbValid.GetTotal(m_Schema.Tables.NullDescription, "", "DBCount")
    NotInPeriodCount = m_Context.DbValid.GetTotal(m_Schema.Tables.JeNotInPeriod, "", "DBCount")
    CompletenessDiffCount = m_Context.DbValid.GetTotal(m_Schema.Tables.CompletenessDiff, "", "DBCount")
    documentDiffCount = m_Context.DbValid.GetTotal(m_Schema.Tables.DocumentBalanceDiff, "", "DBCount")
    '處理資料庫查詢
    Dim sql As String
    sql = "SELECT TOP 1 " & vbCrLf & _
          "    '" & nullAccountCount & "' AS [" & FLD_NULL_ACCOUNT_RECORD_COUNT & "], " & vbCrLf & _
          "    '" & nullDocumentCount & "' AS [" & FLD_NULL_DOCUMENT_RECORD_COUNT & "], " & vbCrLf & _
          "    '" & nullDescriptionCount & "' AS [" & FLD_NULL_DESCRIPTION_RECORD_COUNT & "], " & vbCrLf & _
          "    '" & NotInPeriodCount & "' AS [" & FLD_NOT_IN_PERIOD_COUNT & "], " & vbCrLf & _
          "    '" & CompletenessDiffCount & "' AS [" & FLD_COMEPLETENESS_DIFF_COUNT & "], " & vbCrLf & _
          "    '" & documentDiffCount & "' AS [" & FLD_DOCUMENT_BALANCE_DIFF_COUNT & "] " & vbCrLf & _
          "INTO " & tableName & " IN '" & m_Db.path & "' " & vbCrLf & _
          "FROM " & m_Schema.JE.Name & " IN '" & m_Context.DbInput.path & "';"
    m_Db.ExecuteNonQuery sql
    GenerateValidationOverview = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateValidationOverview(): " & Err.Number & " - " & Err.Description
End Function

Public Function GenerateCompletenessDetail() As Boolean
    '---------------------------------------------------------------------------
    ' 方法
    ' 參數:
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    GenerateCompletenessDetail = False
    '指定資料表名稱至全域常數
    Dim tableName As String
    tableName = RPT_COMPLETENESS_DETAIL
    '檢查已存在資料表
    If m_Context.DbReport.TableExists(tableName) Then
        Call m_Context.DbReport.DropTable(tableName)
    End If
    '處理資料庫查詢
    Dim sql As String
    sql = "SELECT * " & vbCrLf & _
          "INTO " & tableName & " IN '" & m_Db.path & "' " & vbCrLf & _
          "FROM " & m_Schema.Tables.CompletenessDetail & " IN '" & m_Context.DbValid.path & "';"
    m_Db.ExecuteNonQuery sql
    GenerateCompletenessDetail = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateCompletenessDetail(): " & Err.Number & " - " & Err.Description
End Function

Public Function GenerateDocumentBalanceDetail() As Boolean
    '---------------------------------------------------------------------------
    ' 方法
    ' 參數:
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    GenerateDocumentBalanceDetail = False
    '指定資料表名稱至全域常數
    Dim tableName As String
    tableName = m_Schema.ReportDocumentBalanceDetail.Name
    '檢查已存在資料表
    If m_Context.DbReport.TableExists(tableName) Then
        Call m_Context.DbReport.DropTable(tableName)
    End If
    '處理資料庫查詢
    Dim sql As String
    sql = "SELECT * " & vbCrLf & _
          "INTO " & tableName & " IN '" & m_Db.path & "' " & vbCrLf & _
          "FROM " & TBL_DOCUMENT_BALANCE_DETAIL & " IN '" & m_Context.DbValid.path & "';"
    m_Db.ExecuteNonQuery sql
    GenerateDocumentBalanceDetail = True
    Exit Function
ErrorHandler:
    Debug.Print "GenerateDocumentBalanceDetail(): " & Err.Number & " - " & Err.Description
End Function
