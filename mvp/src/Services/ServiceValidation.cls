VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ServiceValidation
' Purpose: 執行資料驗證測試
'
' Tests:
'   - Completeness: TB 與 JE 彙總比對
'   - Document Balance: 傳票借貸平衡檢查
'   - INF Sampling: 隨機抽樣 60 筆
'   - Null Records: 檢查空值記錄
'===============================================================================

Private m_Context As Object      ' ContextManager
Private m_DbSource As Object    ' DbAccess - input.accdb
Private m_DbTarget As Object    ' DbAccess - valid.accdb
Private m_Schema As Object      ' DbSchema
Private m_Builder As Object     ' SqlBuilder
Private m_EtlBuilder As Object  ' SqlEtlBuilder


'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize(ByVal context As Object, ByVal dbSource As Object, ByVal dbTarget As Object)
    '初始化驗證服務
    Set m_Context = context
    Set m_DbSource = dbSource
    Set m_DbTarget = dbTarget
    Set m_Schema = context.DbSchema
    Set m_Builder = New SqlBuilder
    Set m_EtlBuilder = New SqlEtlBuilder
End Sub

'===============================================================================
' Validation Tests
'===============================================================================

Public Function CheckCompleteness() As Boolean
    '---------------------------------------------------------------------------
    ' 完整性檢查 (Completeness/Roll-forward Test)
    ' 驗證 TB 變動金額與 JE 彙總金額是否一致
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    CheckCompleteness = False
    
    m_Context.Logger.LogInfo "Starting Completeness Check"
    m_Context.Logger.LogInfo "Period: " & m_Context.PeriodStart & " to " & m_Context.PeriodEnd
    
    '清理舊表
    Call CleanupTables(Array( _
        m_Schema.TB.Name, _
        "JE_IN_PERIOD", _
        "JE_NOT_IN_PERIOD", _
        "JE_ACCOUNT_SUM", _
        "COMPLETENESS_CALCULATED", _
        "COMPLETENESS_DIFF", _
        "COMPLETENESS_DETAIL" _
    ))
    
    '複製 TB 到目標資料庫
    Dim sql As String
    sql = m_Builder.Reset() _
        .SelectAll() _
        .FromTable(m_Schema.TB.Name, , m_DbSource.Path) _
        .IntoTable(m_Schema.TB.Name, m_DbTarget.Path) _
        .Build()
    m_DbTarget.ExecuteNonQuery sql
    
    '篩選期間內的 JE
    sql = m_EtlBuilder.ExtractWhere( _
        sourceTable:=m_Schema.JE.Name, _
        whereCondition:="[" & m_Schema.JE.PostDate & "] BETWEEN " & _
                        FormatDateForSql(m_Context.PeriodStart) & " AND " & _
                        FormatDateForSql(m_Context.PeriodEnd), _
        outputTable:="JE_IN_PERIOD", _
        sourceDb:=m_DbSource.Path, _
        outputDb:=m_DbTarget.Path _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '篩選期間外的 JE
    sql = m_EtlBuilder.ExtractWhere( _
        sourceTable:=m_Schema.JE.Name, _
        whereCondition:="[" & m_Schema.JE.PostDate & "] < " & FormatDateForSql(m_Context.PeriodStart) & _
                        " OR [" & m_Schema.JE.PostDate & "] > " & FormatDateForSql(m_Context.PeriodEnd), _
        outputTable:="JE_NOT_IN_PERIOD", _
        sourceDb:=m_DbSource.Path, _
        outputDb:=m_DbTarget.Path _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '依會計科目彙總 JE 金額
    sql = m_EtlBuilder.SummarizeBy( _
        sourceTable:="JE_IN_PERIOD", _
        groupFields:=Array(m_Schema.JE.AccountNumber), _
        aggregateFields:=Array(Array("SUM", m_Schema.Fields.JeAmount, m_Schema.Fields.JeAmountSum)), _
        outputTable:="JE_ACCOUNT_SUM" _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '全外部連接 TB 與 JE 彙總
    sql = m_EtlBuilder.FullOuterJoin( _
        primaryTable:="JE_ACCOUNT_SUM", _
        secondaryTable:=m_Schema.TB.Name, _
        matchFields:=Array(Array(m_Schema.JE.AccountNumber, m_Schema.TB.AccountNumber)), _
        outputTable:="COMPLETENESS_CALCULATED" _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '新增合併科目編號欄位
    sql = "ALTER TABLE COMPLETENESS_CALCULATED " & vbCrLf & _
          "ADD COLUMN [" & m_Schema.Fields.AccountMerged & "] TEXT(50);"
    m_DbTarget.ExecuteNonQuery sql
    
    '新增差異欄位
    sql = "ALTER TABLE COMPLETENESS_CALCULATED " & vbCrLf & _
          "ADD COLUMN [" & m_Schema.Fields.TbJeDiff & "] CURRENCY;"
    m_DbTarget.ExecuteNonQuery sql
    
    '合併科目編號
    sql = "UPDATE COMPLETENESS_CALCULATED " & vbCrLf & _
          "SET [" & m_Schema.Fields.AccountMerged & "] = " & vbCrLf & _
          "    IIF(ISNULL([" & m_Schema.JE.AccountNumber & "]), " & _
          "[" & m_Schema.TB.AccountNumber & "], " & _
          "[" & m_Schema.JE.AccountNumber & "]);"
    m_DbTarget.ExecuteNonQuery sql
    
    '計算差異金額
    sql = "UPDATE COMPLETENESS_CALCULATED " & vbCrLf & _
          "SET [" & m_Schema.Fields.TbJeDiff & "] = " & _
          Nz(m_Schema.Fields.TbAmount) & " - " & Nz(m_Schema.Fields.JeAmountSum) & ";"
    m_DbTarget.ExecuteNonQuery sql
    
    '產生差異清單
    sql = m_EtlBuilder.ExtractWhere( _
        sourceTable:="COMPLETENESS_CALCULATED", _
        whereCondition:="ABS([" & m_Schema.Fields.TbJeDiff & "]) > 0", _
        outputTable:="COMPLETENESS_DIFF" _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '產生完整性明細
    sql = m_Builder.Reset() _
        .SelectFields("[" & m_Schema.Fields.AccountMerged & "]", _
                     "[" & m_Schema.TB.AccountName & "]", _
                     "[" & m_Schema.Fields.TbAmount & "]", _
                     "[" & m_Schema.Fields.JeAmountSum & "]", _
                     "[" & m_Schema.Fields.TbJeDiff & "]") _
        .FromTable("COMPLETENESS_CALCULATED") _
        .IntoTable("COMPLETENESS_DETAIL") _
        .Build()
    m_DbTarget.ExecuteNonQuery sql
    
    m_Context.Logger.LogInfo "Completeness check completed"
    CheckCompleteness = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "CheckCompleteness failed", Err.Number
    CheckCompleteness = False
End Function

Public Function CheckDocumentBalance() As Boolean
    '---------------------------------------------------------------------------
    ' 傳票借貸平衡檢查 (Document Balance Test)
    ' 檢查每張傳票的借貸是否平衡
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    CheckDocumentBalance = False
    
    m_Context.Logger.LogInfo "Starting Document Balance Check"
    
    '清理舊表
    Call CleanupTables(Array( _
        "DOCUMENT_BALANCE_SUM", _
        "DOCUMENT_BALANCE_DIFF", _
        "DOCUMENT_BALANCE_DETAIL" _
    ))
    
    '依傳票號碼彙總 JE 金額
    Dim sql As String
    sql = m_EtlBuilder.SummarizeBy( _
        sourceTable:="JE_IN_PERIOD", _
        groupFields:=Array(m_Schema.JE.DocumentNumber), _
        aggregateFields:=Array(Array("SUM", m_Schema.Fields.JeAmount, m_Schema.Fields.JeAmountSum)), _
        outputTable:="DOCUMENT_BALANCE_SUM" _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '篩選借貸不平衡的傳票
    sql = m_EtlBuilder.ExtractWhere( _
        sourceTable:="DOCUMENT_BALANCE_SUM", _
        whereCondition:="[" & m_Schema.Fields.JeAmountSum & "] <> 0", _
        outputTable:="DOCUMENT_BALANCE_DIFF" _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    '展開不平衡傳票的明細
    sql = m_EtlBuilder.JoinTables( _
        primaryTable:="JE_IN_PERIOD", _
        secondaryTable:="DOCUMENT_BALANCE_DIFF", _
        matchFields:=Array(Array(m_Schema.JE.DocumentNumber, m_Schema.JE.DocumentNumber)), _
        outputTable:="DOCUMENT_BALANCE_DETAIL", _
        joinType:="INNER", _
        includePrimaryFields:=True, _
        secondaryFields:=Array(m_Schema.Fields.JeAmountSum) _
    )
    m_DbTarget.ExecuteNonQuery sql
    
    m_Context.Logger.LogInfo "Document balance check completed"
    CheckDocumentBalance = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "CheckDocumentBalance failed", Err.Number
    CheckDocumentBalance = False
End Function

Public Function CheckINF() As Boolean
    '---------------------------------------------------------------------------
    ' INF 可靠性抽樣 (INF Sampling)
    ' 從期間內的 JE 隨機抽取 60 筆樣本
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    CheckINF = False
    
    m_Context.Logger.LogInfo "Starting INF Sampling"
    
    '清理舊表
    Call CleanupTables(Array( _
        "INF_RANDOM", _
        "INF_SORTED" _
    ))
    
    '初始化隨機數種子
    Randomize
    
    '隨機抽取 60 筆
    Dim sql As String
    sql = m_Builder.Reset() _
        .SelectFields("TOP 60 *") _
        .FromTable("JE_IN_PERIOD") _
        .IntoTable("INF_RANDOM") _
        .OrderByFields("Rnd([ID])") _
        .Build()
    m_DbTarget.ExecuteNonQuery sql
    
    '依傳票號碼排序
    sql = m_Builder.Reset() _
        .SelectAll() _
        .FromTable("INF_RANDOM") _
        .IntoTable("INF_SORTED") _
        .OrderByFields("[" & m_Schema.JE.DocumentNumber & "] ASC") _
        .Build()
    m_DbTarget.ExecuteNonQuery sql
    
    m_Context.Logger.LogInfo "INF sampling completed"
    CheckINF = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "CheckINF failed", Err.Number
    CheckINF = False
End Function

Public Function CheckNullRecords() As Boolean
    '---------------------------------------------------------------------------
    ' 空值記錄檢查
    ' 檢查會計科目、傳票號碼、摘要是否有空值
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    CheckNullRecords = False
    
    m_Context.Logger.LogInfo "Starting Null Records Check"
    
    '清理舊表
    Call CleanupTables(Array( _
        "NULL_ACCOUNT_RECORDS", _
        "NULL_DOCUMENT_RECORDS", _
        "NULL_DESCRIPTION_RECORDS" _
    ))
    
    '檢查會計科目編號空值
    If Not ExtractNullRecords(m_Schema.JE.Name, m_Schema.JE.AccountNumber, "NULL_ACCOUNT_RECORDS") Then
        m_Context.Logger.LogError "Account number null check failed"
        Exit Function
    End If
    
    '檢查傳票號碼空值
    If Not ExtractNullRecords(m_Schema.JE.Name, m_Schema.JE.DocumentNumber, "NULL_DOCUMENT_RECORDS") Then
        m_Context.Logger.LogError "Document number null check failed"
        Exit Function
    End If
    
    '檢查傳票摘要空值
    If Not ExtractNullRecords(m_Schema.JE.Name, m_Schema.JE.EntryDescription, "NULL_DESCRIPTION_RECORDS") Then
        m_Context.Logger.LogError "Entry description null check failed"
        Exit Function
    End If
    
    m_Context.Logger.LogInfo "Null records check completed"
    CheckNullRecords = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "CheckNullRecords failed", Err.Number
    CheckNullRecords = False
End Function

'===============================================================================
' Helper Methods
'===============================================================================

Private Sub CleanupTables(ByVal tableNames As Variant)
    '清理暫存資料表
    On Error Resume Next
    
    Dim i As Long
    For i = LBound(tableNames) To UBound(tableNames)
        If m_DbTarget.TableExists(CStr(tableNames(i))) Then
            m_DbTarget.DropTable CStr(tableNames(i))
        End If
    Next i
    
    m_DbTarget.CompactAndRepair
    m_DbTarget.Refresh
    
    On Error GoTo 0
End Sub

Private Function ExtractNullRecords(ByVal tableName As String, _
                                   ByVal fieldName As String, _
                                   ByVal outputTable As String) As Boolean
    '提取空值記錄
    On Error GoTo ErrorHandler
    
    ExtractNullRecords = False
    
    Dim sql As String
    sql = m_EtlBuilder.ExtractWhere( _
        sourceTable:=tableName, _
        whereCondition:="ISNULL([" & fieldName & "]) OR [" & fieldName & "] = ''", _
        outputTable:=outputTable, _
        sourceDb:=m_DbSource.Path, _
        outputDb:=m_DbTarget.Path _
    )
    
    m_DbSource.ExecuteNonQuery sql
    
    ExtractNullRecords = True
    Exit Function
    
ErrorHandler:
    ExtractNullRecords = False
End Function

'===============================================================================
' Cleanup
'===============================================================================

Private Sub Class_Terminate()
    Set m_Context = Nothing
    Set m_DbSource = Nothing
    Set m_DbTarget = Nothing
    Set m_Schema = Nothing
    Set m_Builder = Nothing
    Set m_EtlBuilder = Nothing
End Sub
