VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceFilter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ServiceFilter
' Purpose: 執行風險篩選與標記 (Routines & Criteria)
'
' Routines:
'   - R1: 期後核准 (Approval Date > Period End)
'   - R2: 關鍵字篩選 (Keywords in Description)
'   - R3: 異常借貸組合 (Unexpected Account/Amount)
'   - R4: 整數金額 (Round Numbers)
'   - R7: 週末分錄 (Weekend Posting)
'===============================================================================

Private m_Context As Object      ' ContextManager
Private m_DbTarget As Object    ' DbAccess - valid.accdb
Private m_Schema As Object      ' DbSchema
Private m_Builder As Object     ' SqlBuilder
Private m_EtlBuilder As Object  ' SqlEtlBuilder

'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize(ByVal context As Object, ByVal dbTarget As Object)
    Set m_Context = context
    Set m_DbTarget = dbTarget
    Set m_Schema = context.DbSchema
    Set m_Builder = New SqlBuilder
    Set m_EtlBuilder = New SqlEtlBuilder
End Sub

'===============================================================================
' Main Execution
'===============================================================================

Public Sub RunAllRoutines()
    '執行所有標準篩選程序
    On Error GoTo ErrorHandler
    
    m_Context.Logger.LogInfo "Starting Risk Routines..."
    
    '1. 準備標記欄位
    PrepareTagColumns
    
    '2. 執行各項篩選
    ApplyR1_PostPeriodApproval
    ApplyR2_Keywords
    ApplyR3_UnexpectedAccounts
    ApplyR4_RoundNumbers
    ApplyR7_WeekendPosting
    
    m_Context.Logger.LogInfo "Risk Routines completed."
    Exit Sub
    
ErrorHandler:
    m_Context.Logger.LogError "RunAllRoutines failed", Err.Number
End Sub

'===============================================================================
' Routine Implementations
'===============================================================================

Private Sub PrepareTagColumns()
    '新增標記欄位到 JE_IN_PERIOD
    Dim tags As Variant
    tags = Array("Tag_R1", "Tag_R2", "Tag_R3", "Tag_R4", "Tag_R7", "Tag_A2", "Tag_A3")
    
    Dim i As Long
    For i = LBound(tags) To UBound(tags)
        Dim colName As String
        colName = tags(i)
        
        '檢查欄位是否存在，不存在則新增
        If Not m_DbTarget.FieldExists("JE_IN_PERIOD", colName) Then
            Dim sql As String
            sql = "ALTER TABLE JE_IN_PERIOD ADD COLUMN [" & colName & "] TEXT(1);"
            m_DbTarget.ExecuteNonQuery sql
        End If
        
        '重置為空
        m_DbTarget.ExecuteNonQuery "UPDATE JE_IN_PERIOD SET [" & colName & "] = NULL;"
    Next i
End Sub

' ... (R1-R7 methods remain unchanged) ...

Public Sub ApplyA2_CriteriaKeywords(ByVal keywords As String)
    'A2: 使用者自訂關鍵字篩選
    On Error GoTo ErrorHandler
    m_Context.Logger.LogInfo "Running A2: Criteria Keywords"
    
    If keywords = "" Then Exit Sub
    
    '關鍵字格式: "A,B,C" -> LIKE '*A*' OR LIKE '*B*'
    Dim keywordArray As Variant
    keywordArray = Split(keywords, ",")
    
    Dim whereClause As String
    Dim i As Long
    
    For i = LBound(keywordArray) To UBound(keywordArray)
        Dim k As String
        k = Trim(keywordArray(i))
        If k <> "" Then
            If whereClause <> "" Then whereClause = whereClause & " OR "
            whereClause = whereClause & "[" & m_Schema.JE.EntryDescription & "] LIKE '*" & k & "*'"
        End If
    Next i
    
    If whereClause = "" Then Exit Sub
    
    Dim sql As String
    sql = "UPDATE JE_IN_PERIOD " & _
          "SET [Tag_A2] = 'Y' " & _
          "WHERE " & whereClause & ";"
          
    m_DbTarget.ExecuteNonQuery sql
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyA2 failed", Err.Number
End Sub

Public Sub ApplyA3_AccountPairing(ByVal debitAcc As String, _
                                 ByVal creditAcc As String, _
                                 Optional ByVal logicType As Long = 0)
    'A3: 科目配對篩選
    'logicType: 0=(D=X & C=Y), 1=(D=X & C!=Y), 2=(D!=X & C=Y)
    
    On Error GoTo ErrorHandler
    m_Context.Logger.LogInfo "Running A3: Account Pairing"
    
    If debitAcc = "" Or creditAcc = "" Then Exit Sub
    
    '1. 找出有借方科目的傳票
    Dim sqlDebit As String
    Dim opDebit As String
    opDebit = IIf(logicType = 2, "<>", "=")
    
    sqlDebit = m_Builder.Reset() _
        .SelectFields("[" & m_Schema.JE.DocumentNumber & "]") _
        .FromTable("JE_IN_PERIOD") _
        .WhereCondition("[" & m_Schema.JE.AccountNumber & "] " & opDebit & " '" & debitAcc & "'") _
        .AndWhere("[" & m_Schema.Fields.JeAmount & "] > 0") _
        .Build()
        
    '2. 找出有貸方科目的傳票
    Dim sqlCredit As String
    Dim opCredit As String
    opCredit = IIf(logicType = 1, "<>", "=")
    
    sqlCredit = m_Builder.Reset() _
        .SelectFields("[" & m_Schema.JE.DocumentNumber & "]") _
        .FromTable("JE_IN_PERIOD") _
        .WhereCondition("[" & m_Schema.JE.AccountNumber & "] " & opCredit & " '" & creditAcc & "'") _
        .AndWhere("[" & m_Schema.Fields.JeAmount & "] < 0") _
        .Build()
        
    '3. 找出交集 (同時符合條件的傳票)
    'Access SQL 不支援 INTERSECT，改用 INNER JOIN
    Dim sqlDocs As String
    sqlDocs = "SELECT D.[" & m_Schema.JE.DocumentNumber & "] " & _
              "FROM (" & sqlDebit & ") AS D " & _
              "INNER JOIN (" & sqlCredit & ") AS C " & _
              "ON D.[" & m_Schema.JE.DocumentNumber & "] = C.[" & m_Schema.JE.DocumentNumber & "]"
              
    '4. 標記這些傳票的所有分錄
    Dim sqlUpdate As String
    sqlUpdate = "UPDATE JE_IN_PERIOD " & _
                "SET [Tag_A3] = 'Y' " & _
                "WHERE [" & m_Schema.JE.DocumentNumber & "] IN (" & sqlDocs & ");"
                
    m_DbTarget.ExecuteNonQuery sqlUpdate
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyA3 failed", Err.Number
End Sub

Public Sub ApplyR1_PostPeriodApproval()
    'R1: 傳票核准日 >= 財務報表準備日 (通常是期末)
    '假設: 比較基準日為 PeriodEnd (或需另外設定)
    On Error GoTo ErrorHandler
    
    m_Context.Logger.LogInfo "Running R1: Post Period Approval"
    
    Dim approvalField As String
    approvalField = "傳票核准日_JE" '需確認 Schema 對應
    
    '如果 Schema 中沒有定義核准日，則跳過
    '這裡假設 JE Schema 有擴充或動態欄位
    '暫時使用硬編碼欄位名，實際應從 Schema 獲取
    
    Dim sql As String
    sql = "UPDATE JE_IN_PERIOD " & _
          "SET [Tag_R1] = 'Y' " & _
          "WHERE [" & approvalField & "] > " & FormatDateForSql(m_Context.PeriodEnd) & ";"
          
    '注意: 如果欄位不存在，ExecuteNonQuery 會報錯，需處理
    On Error Resume Next
    m_DbTarget.ExecuteNonQuery sql
    If Err.Number <> 0 Then
        m_Context.Logger.LogWarn "R1 skipped: Field '" & approvalField & "' not found or error."
        Err.Clear
    End If
    On Error GoTo ErrorHandler
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyR1 failed", Err.Number
End Sub

Public Sub ApplyR2_Keywords(Optional ByVal extraKeywords As String = "")
    'R2: 摘要包含特定關鍵字
    On Error GoTo ErrorHandler
    
    m_Context.Logger.LogInfo "Running R2: Keywords"
    
    Dim keywords As Variant
    keywords = Array("ADJ", "REV", "RECLASS", "SUSPENSE", "ERROR", "WRONG", _
                    "調整", "迴轉", "沖銷", "重分類", "避險", "重編", "錯誤", "計畫外", "預算外")
    
    Dim whereClause As String
    Dim i As Long
    
    '建構 LIKE 條件
    For i = LBound(keywords) To UBound(keywords)
        If whereClause <> "" Then whereClause = whereClause & " OR "
        whereClause = whereClause & "[" & m_Schema.JE.EntryDescription & "] LIKE '*" & keywords(i) & "*'"
    Next i
    
    '加入額外關鍵字
    If extraKeywords <> "" Then
        whereClause = whereClause & " OR [" & m_Schema.JE.EntryDescription & "] LIKE '*" & extraKeywords & "*'"
    End If
    
    Dim sql As String
    sql = "UPDATE JE_IN_PERIOD " & _
          "SET [Tag_R2] = 'Y' " & _
          "WHERE " & whereClause & ";"
          
    m_DbTarget.ExecuteNonQuery sql
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyR2 failed", Err.Number
End Sub

Public Sub ApplyR3_UnexpectedAccounts()
    'R3: 異常借貸組合 (需配合 AccountMapping)
    '邏輯: 
    ' 1. Revenue (收入) 且 借方 (Amount > 0 ? 需確認正負號邏輯)
    '    通常: 收入為貸方(Credit, <0), 若 >0 則為借方(Debit)異常
    ' 2. Cash/Receivables (資產) 且 貸方 (Amount < 0 ?)
    '    通常: 資產為借方(Debit, >0), 若 <0 則為貸方(Credit)異常
    
    '假設: Amount > 0 是 Debit, Amount < 0 是 Credit
    
    On Error GoTo ErrorHandler
    m_Context.Logger.LogInfo "Running R3: Unexpected Accounts"
    
    '需要先確保 AccountMapping 表存在於 Target DB (或從 Source 連結)
    '這裡假設 AccountMapping 已經導入到 Target DB
    
    '使用 UPDATE ... INNER JOIN
    Dim sql As String
    
    '條件1: Revenue 且 Amount > 0 (Debit)
    Dim criteria1 As String
    criteria1 = "(M.[StandardizedName] = 'Revenue' AND J.[" & m_Schema.Fields.JeAmount & "] > 0)"
    
    '條件2: Assets 且 Amount < 0 (Credit)
    Dim criteria2 As String
    criteria2 = "(M.[StandardizedName] IN ('Cash', 'Receivables', 'Receipt in advance') AND J.[" & m_Schema.Fields.JeAmount & "] < 0)"
    
    sql = "UPDATE JE_IN_PERIOD AS J " & _
          "INNER JOIN [AccountMapping] AS M ON J.[" & m_Schema.JE.AccountNumber & "] = M.[" & m_Schema.TB.AccountNumber & "] " & _
          "SET J.[Tag_R3] = 'Y' " & _
          "WHERE " & criteria1 & " OR " & criteria2 & ";"
          
    On Error Resume Next
    m_DbTarget.ExecuteNonQuery sql
    If Err.Number <> 0 Then
        m_Context.Logger.LogWarn "R3 skipped: AccountMapping table or fields missing."
        Err.Clear
    End If
    On Error GoTo ErrorHandler
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyR3 failed", Err.Number
End Sub

Public Sub ApplyR4_RoundNumbers(Optional ByVal divisor As Double = 10000)
    'R4: 整數金額 (例如能被 10,000 整除)
    On Error GoTo ErrorHandler
    m_Context.Logger.LogInfo "Running R4: Round Numbers"
    
    Dim sql As String
    sql = "UPDATE JE_IN_PERIOD " & _
          "SET [Tag_R4] = 'Y' " & _
          "WHERE [" & m_Schema.Fields.JeAmount & "] MOD " & divisor & " = 0 " & _
          "AND [" & m_Schema.Fields.JeAmount & "] <> 0;"
          
    m_DbTarget.ExecuteNonQuery sql
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyR4 failed", Err.Number
End Sub

Public Sub ApplyR7_WeekendPosting()
    'R7: 週末分錄 (週六=7, 週日=1)
    On Error GoTo ErrorHandler
    m_Context.Logger.LogInfo "Running R7: Weekend Posting"
    
    Dim sql As String
    sql = "UPDATE JE_IN_PERIOD " & _
          "SET [Tag_R7] = 'Y' " & _
          "WHERE Weekday([" & m_Schema.JE.PostDate & "]) IN (1, 7);"
          
    m_DbTarget.ExecuteNonQuery sql
    
    Exit Sub
ErrorHandler:
    m_Context.Logger.LogError "ApplyR7 failed", Err.Number
End Sub

'===============================================================================
' Helper Methods
'===============================================================================

Private Function FormatDateForSql(ByVal dt As Date) As String
    FormatDateForSql = "#" & Format(dt, "yyyy-mm-dd") & "#"
End Function

Private Sub Class_Terminate()
    Set m_Context = Nothing
    Set m_DbTarget = Nothing
    Set m_Schema = Nothing
    Set m_Builder = Nothing
    Set m_EtlBuilder = Nothing
End Sub

