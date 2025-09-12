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
'Class:ServiceValidation
Private dbSource As DbAccess
Private dbTarget As DbAccess
Private je As EntityJe
Private tb As EntityTb
Private info As EntityInfo

Public Sub Initialize(ByRef context As ContextManager)
    Set dbSource = context.DbInput
    Set dbTarget = context.DbValid
    Set je = context.je
    Set tb = context.tb
    Set info = context.info
End Sub

Public Function Completeness() As Boolean
    ' ------------------------------------------------------------
    ' 原始資料:JE
    '  ↓
    ' 期間內分錄:JE_IN_PERIOD
    '  ↓
    ' 會計科目彙總:JE_ACCOUNT_SUM
    '  ↓
    ' 完整性計算:COMPLETENESS_CALCULATED
    '  ↓
    ' 完整性結果:COMPLETENESS_RESULT
    ' ------------------------------------------------------------
    On Error GoTo ErrorHandler
    Dim sql As String
    Dim JE_IN_PERIOD As String
    Dim JE_ACCOUNT_SUM As String
    Dim COMPLETENESS_CALCULATED As String
    Dim COMPLETENESS_RESULT As String
    JE_IN_PERIOD = "JE_IN_PERIOD"
    JE_ACCOUNT_SUM = "JE_ACCOUNT_SUM"
    COMPLETENESS_CALCULATED = "COMPLETENESS_CALCULATED"
    COMPLETENESS_RESULT = "COMPLETENESS_RESULT"
    
    ' ------------------------------------------------------------
    ' - 篩選期間內資料
    ' 功能: 跨資料庫查詢 JE 中指定期間內的分錄
    ' 輸入: JE
    ' 輸出: JE_IN_PERIOD
    ' 邏輯: @BetweenDate(je.[PostDate], info.PeriodStart, info.PeriodEnd)
    ' ------------------------------------------------------------
    sql = "SELECT * " & vbCrLf & _
          "INTO " & JE_IN_PERIOD & " IN '" & dbTarget.path & "' " & vbCrLf & _
          "FROM " & je.Name & " IN '" & dbSource.path & "' " & vbCrLf & _
          "WHERE [" & je.PostDate & "] " & vbCrLf & _
          "BETWEEN #" & info.PeriodStart & "# AND #" & info.PeriodEnd & "#;"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 依會計科目彙總
    ' 功能: 將期間內的分錄依科目編號彙總，並計算各科目總金額
    ' 輸入: JE_IN_PERIOD
    ' 輸出: JE_ACCOUNT_SUM
    ' 邏輯: SUM je.[Amount], GROUPBY je.[AccountNumber]
    ' ------------------------------------------------------------
    '@TODO: je.K_Amount_Sum 需要先新增欄位 tdf.Fields.Append fld
    sql = "SELECT " & vbCrLf & _
          "  [" & je.AccountNumber & "], " & vbCrLf & _
          "  SUM([" & je.Amount & "]) AS [" & je.K_Amount_Sum & "] " & vbCrLf & _
          "INTO " & JE_ACCOUNT_SUM & " " & vbCrLf & _
          "FROM " & JE_IN_PERIOD & " " & vbCrLf & _
          "GROUP BY [" & je.AccountNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 資料比對連結
    ' 功能: 將 JE 彙總結果與 TB 進行全外部連結，找出差異
    ' 主要輸入: JE_ACCOUNT_SUM
    ' 次要輸入: TB
    ' 輸出: COMPLETENESS_CALCULATED
    ' 邏輯: FULL OUTER JOIN [je.AccountNumber] <-> [tb.AccountNumber]
    ' ------------------------------------------------------------
    sql = "SELECT " & _
          "  P.*, S.* " & vbCrLf & _
          "FROM " & vbCrLf & _
          "  " & JE_ACCOUNT_SUM & " AS P " & vbCrLf & _
          "  LEFT JOIN " & vbCrLf & _
          "  " & tb.Name & " AS S " & vbCrLf & _
          "ON P.[" & je.AccountNumber & "] = S.[" & tb.AccountNumber & "] " & vbCrLf & _
          "UNION" & vbCrLf & _
          "SELECT " & vbCrLf & _
          "  P.*, S.* " & vbCrLf & _
          "FROM" & vbCrLf & _
          "  " & JE_ACCOUNT_SUM & " AS P " & vbCrLf & _
          "  RIGHT JOIN " & vbCrLf & _
          "  " & tb.Name & " AS S " & vbCrLf & _
          "ON P.[" & je.AccountNumber & "] = S.[" & tb.AccountNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 差異計算
    ' 功能: 新增計算欄位，計算試算表與分錄彙總的差異金額
    ' 輸入: COMPLETENESS_CALCULATED
    ' 輸出: COMPLETENESS_CALCULATED
    ' 邏輯: [DIFF] = [tb.ChangeAmount] - [je.K_Amount_Sum]
    ' ------------------------------------------------------------
    'tdf.Append fld, fld = "DIFF"
    
    sql = "UPDATE " & _
          "SET [] = " & _
          "CDbl() - CDbl();"
    ' ------------------------------------------------------------
    ' - 結果匯出
    ' 功能: 匯出完整性檢查所需的關鍵欄位，產生最終報告
    ' 輸入: COMPLETENESS_CALCULATED
    ' 輸出: COMPLETENESS_RESULT
    ' 邏輯: 匯出 [ACCOUNT_NUM_ALL], [tb.AccountName], [tb.ChangeAmount], [je.Amount_SUM], [DIFF]
    ' ------------------------------------------------------------
    '...
    
    Exit Function
ErrorHandler:
    Debug.Print "Completeness(): "; Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
End Function
    
Public Function DocumentBalance() As Boolean
    '...
    On Error GoTo ErrorHandler
    '#GL -> #GL_In_Period
    'WHERE [DATE] BETWEEN [START] AND [END]
    
    '#GL_In_Period -> #GL_In_Period_Doc_Sum
    'SUM([傳票金額_JE]) GROUP BY [傳票號碼_JE]
    
    '#GL_In_Period_Doc_Sum -> #GL_In_Period_Doc_Sum_Diff
    '[變動金額_TB] - [傳票金額_JE_SUM]
    
    '#GL_In_Period_Doc_Sum_Diff -> #GL_Doc_Not_Balance
    Exit Function
ErrorHandler:
    Debug.Print "DocumentBalance(): "; Err.Number
    Debug.Print "  - 錯誤描述: "; Err.Description
End Function

Public Function INF() As Boolean
    '...
End Function
