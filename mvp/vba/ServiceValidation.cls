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
    ' 完整性檢查流程:
    ' 1. TB 跨資料庫複製至目標資料庫
    ' 2. 篩選期間內分錄: JE_IN_PERIOD
    ' 3. 確保 K_AMOUNT 欄位存在並正確計算
    ' 4. 會計科目彙總: JE_ACCOUNT_SUM
    ' 5. 外部連結比對: COMPLETENESS_CALCULATED
    ' 6. 產生最終結果: COMPLETENESS_RESULT
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
    
    Debug.Print "========== 開始完整性檢查流程 =========="
    Debug.Print "檢查期間: " & info.PeriodStart & " ~ " & info.PeriodEnd
    Call CleanupTempTables(Array(JE_IN_PERIOD, JE_ACCOUNT_SUM, COMPLETENESS_CALCULATED, COMPLETENESS_RESULT))
    
    ' ------------------------------------------------------------
    ' - 篩選期間內資料
    ' 功能: 跨資料庫查詢 JE 中指定期間內的分錄
    ' 輸入: JE
    ' 輸出: JE_IN_PERIOD
    ' 邏輯: @BetweenDate(je.[PostDate], info.PeriodStart, info.PeriodEnd)
    ' ------------------------------------------------------------
    Debug.Print "========== 篩選期間內資料 =========="
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
    ' 邏輯: SUM K_Amount, GROUP BY AccountNumber
    ' ------------------------------------------------------------
    Debug.Print "========== 依會計科目彙總 =========="
    sql = "SELECT " & vbCrLf & _
          "  [" & je.AccountNumber & "], " & vbCrLf & _
          "  SUM([" & je.K_Amount & "]) AS [" & je.K_Amount_Sum & "] " & vbCrLf & _
          "INTO " & JE_ACCOUNT_SUM & " " & vbCrLf & _
          "FROM " & JE_IN_PERIOD & " " & vbCrLf & _
          "GROUP BY [" & je.AccountNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 資料比對連結 (FULL OUTER JOIN)
    ' 功能: 將 JE 彙總結果與 TB 進行全外部連結，找出差異
    ' 主要輸入: JE_ACCOUNT_SUM
    ' 次要輸入: TB
    ' 輸出: COMPLETENESS_CALCULATED
    ' 邏輯: FULL OUTER JOIN AccountNumber
    ' ------------------------------------------------------------
    Debug.Print "========== 資料比對連結 (FULL OUTER JOIN) =========="
    ' 執行 LEFT JOIN 並建立初始資料表
    sql = "SELECT P.*, S.* " & vbCrLf & _
          "INTO " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "FROM " & JE_ACCOUNT_SUM & " AS P " & vbCrLf & _
          "LEFT JOIN " & tb.Name & " IN '" & dbSource.path & "' AS S " & vbCrLf & _
          "ON P.[" & je.AccountNumber & "] = S.[" & tb.AccountNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    ' 將 RIGHT JOIN 的結果 (僅限不匹配的記錄) 插入到資料表中
    sql = "INSERT INTO " & COMPLETENESS_CALCULATED & " ([" & tb.AccountNumber & "], [" & tb.AccountName & "], [" & tb.K_Amount & "]) " & vbCrLf & _
          "SELECT S.[" & tb.AccountNumber & "], S.[" & tb.AccountName & "], S.[" & tb.K_Amount & "] " & vbCrLf & _
          "FROM " & JE_ACCOUNT_SUM & " AS P " & vbCrLf & _
          "RIGHT JOIN " & tb.Name & " IN '" & dbSource.path & "' AS S " & vbCrLf & _
          "ON P.[" & je.AccountNumber & "] = S.[" & tb.AccountNumber & "] " & vbCrLf & _
          "WHERE P.[" & je.AccountNumber & "] IS NULL;"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 新增差異計算欄位
    ' 功能: 新增用於計算差異的欄位
    ' 輸入: COMPLETENESS_CALCULATED
    ' 輸出: COMPLETENESS_CALCULATED (新增欄位)
    ' ------------------------------------------------------------
    Debug.Print "========== 新增差異計算欄位 =========="
    sql = "ALTER TABLE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ADD COLUMN [ACCOUNT_NUM_ALL] TEXT(50);"
    dbTarget.ExecuteNonQuery sql
    
    sql = "ALTER TABLE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ADD COLUMN [TB_AMOUNT] CURRENCY;"
    dbTarget.ExecuteNonQuery sql
    
    sql = "ALTER TABLE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ADD COLUMN [JE_AMOUNT_SUM] CURRENCY;"
    dbTarget.ExecuteNonQuery sql
    
    sql = "ALTER TABLE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ADD COLUMN [DIFF] CURRENCY;"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 計算統一科目編號
    ' 功能: 統一顯示科目編號 (JE 或 TB 中有值的)
    ' ------------------------------------------------------------
    Debug.Print "========== 計算統一科目編號 =========="
    sql = "UPDATE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "SET [ACCOUNT_NUM_ALL] = " & vbCrLf & _
          "    IIF(ISNULL([" & je.AccountNumber & "]), [" & tb.AccountNumber & "], [" & je.AccountNumber & "]);"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 計算標準化金額
    ' 功能: 將空值轉為 0，便於後續計算
    ' ------------------------------------------------------------
    Debug.Print "========== 計算標準化金額 =========="
    sql = "UPDATE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "SET [TB_AMOUNT] = Nz([" & tb.K_Amount & "], 0);"
    dbTarget.ExecuteNonQuery sql
    
    sql = "UPDATE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "SET [JE_AMOUNT_SUM] = Nz([" & je.K_Amount_Sum & "], 0);"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 計算差異金額
    ' 功能: 計算試算表與分錄彙總的差異金額
    ' 邏輯: DIFF = TB_AMOUNT - JE_AMOUNT_SUM
    ' ------------------------------------------------------------
    Debug.Print "========== 計算差異金額 =========="
    sql = "UPDATE " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "SET [DIFF] = [TB_AMOUNT] - [JE_AMOUNT_SUM];"
    dbTarget.ExecuteNonQuery sql
    
    ' ------------------------------------------------------------
    ' - 產生最終結果
    ' 功能: 匯出完整性檢查所需的關鍵欄位，產生最終報告
    ' 輸入: COMPLETENESS_CALCULATED
    ' 輸出: COMPLETENESS_RESULT
    ' 邏輯: 匯出關鍵欄位用於報告顯示
    ' ------------------------------------------------------------
    Debug.Print "========== 產生最終結果 =========="
    sql = "SELECT " & vbCrLf & _
          "  [ACCOUNT_NUM_ALL] AS [科目編號], " & vbCrLf & _
          "  [" & tb.AccountName & "] AS [科目名稱], " & vbCrLf & _
          "  [TB_AMOUNT] AS [試算表金額], " & vbCrLf & _
          "  [JE_AMOUNT_SUM] AS [分錄彙總金額], " & vbCrLf & _
          "  [DIFF] AS [差異金額] " & vbCrLf & _
          "INTO " & COMPLETENESS_RESULT & " " & vbCrLf & _
          "FROM " & COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ORDER BY [ACCOUNT_NUM_ALL];"
    dbTarget.ExecuteNonQuery sql
    
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


'--自訂方法
Private Sub CleanupTempTables(ByRef tableNames As Variant)
    ' 清理暫存資料表的輔助方法
    On Error Resume Next
    Dim i As Long
    For i = LBound(tableNames) To UBound(tableNames)
        If dbTarget.TableExists(CStr(tableNames(i))) Then
            dbTarget.DropTable CStr(tableNames(i))
            Debug.Print "已清理資料表: " & CStr(tableNames(i))
        End If
    Next i
    On Error GoTo 0
End Sub

