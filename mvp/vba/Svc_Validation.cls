VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Svc_Validation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Svc_Validation"
'===============================================================================
' Module:   Svc_Validation
' Purpose:  驗證業務服務，提供資料完整性檢查和業務規則驗證
' Layer:    Service
' Domain:   Data Validation
'===============================================================================



'--類別成員
Private m_ctx As Mgr_Context
Private dal As Dal_Access
Private gl As Ent_GL
Private tb As Ent_TB

'--類別成員
Private m_ctx As Mgr_Context
Private dal As Dal_Access
Private gl As Ent_GL
Private tb As Ent_TB

'--Svc_Validation
Public Sub Initialize(ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ctx = Context
    Set dal = Context.DalData
    Set gl = Context.gl
    Set tb = Context.tb
End Sub

Public Function TestCompleteness(ByVal startDate As Date, ByVal endDate As Date) As Boolean
    ' 完整性測試:
    ' 1) 期間內 GL 依科目代碼彙總 (借方-貸方)
    ' 2) 與 TB by 會計項目 進行 LEFT/RIGHT JOIN + UNION
    ' 3) DIFF = TB.[借-貸(本幣)] - GL_SUM，產生 Completeness_Check 與 List_of_accounts_with_variance
    Const METHOD_NAME As String = "TestCompleteness"
    On Error GoTo ErrorHandler
    Dim sStart As String, sEnd As String
    Dim sql As String, affected As Long
    Dim diffCount As Long
    
    TestCompleteness = False
    If Not dal.IsConnected Then dal.Connect
    
    ' 期間格式 (#YYYY-MM-DD#)
    sStart = Format(startDate, "\#yyyy\-mm\-dd\#")
    sEnd = Format(endDate, "\#yyyy\-mm\-dd\#")
    
    ' 工作用資料表名稱
    Dim T_GL As String: T_GL = "GL"
    Dim T_TB As String: T_TB = "TB"
    Dim T_GL_IN As String: T_GL_IN = "GL_In_Period"
    Dim T_GL_SUM As String: T_GL_SUM = "GL_Account_Sum"
    Dim T_LEFT As String: T_LEFT = "temp_Left"
    Dim T_RIGHT As String: T_RIGHT = "temp_Right"
    Dim T_CALC As String: T_CALC = "Completeness_calculate"
    Dim T_CHECK As String: T_CHECK = "Completeness_Check"
    Dim T_DIFF As String: T_DIFF = "List_of_accounts_with_variance"
    
    ' 欄位（採用實際匯入欄位名）
    Dim F_PostDate As String:      F_PostDate = "日期"
    Dim F_GL_AccNo As String:      F_GL_AccNo = "科目代碼"
    Dim F_GL_Debit As String:      F_GL_Debit = "本幣借方金額"
    Dim F_GL_Credit As String:     F_GL_Credit = "本幣貸方金額"
    Dim F_TB_AccNo As String:      F_TB_AccNo = "會計項目"
    Dim F_TB_AccName As String:    F_TB_AccName = "項目名稱"
    Dim F_TB_Change As String:     F_TB_Change = "借-貸(本幣)"
    Dim F_GL_Sum As String:        F_GL_Sum = "傳票金額_JE_SUM"
    Dim F_DIFF As String:          F_DIFF = "DIFF"
    Dim F_ACC_ALL As String:       F_ACC_ALL = "ACCOUNT_NUM_ALL"
    
    ' 清理舊表
    dal.DropIfExists T_GL_IN
    dal.DropIfExists T_GL_SUM
    dal.DropIfExists T_LEFT
    dal.DropIfExists T_RIGHT
    dal.DropIfExists T_CALC
    dal.DropIfExists T_CHECK
    dal.DropIfExists T_DIFF
    
    ' 1) 期間抽取 GL
    sql = "SELECT " & T_GL & ".* INTO " & T_GL_IN & _
          " FROM " & T_GL & _
          " WHERE CDate([" & F_PostDate & "]) >= " & sStart & " AND CDate([" & F_PostDate & "]) <= " & sEnd & ";"
    affected = dal.ExecuteSQL(sql)
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - GL In Period: " & affected
    
    ' 2) 彙總 GL (依科目代碼)
    sql = "SELECT [" & F_GL_AccNo & "], " & _
          "SUM(Nz([" & F_GL_Debit & "],0) - Nz([" & F_GL_Credit & "],0)) AS [" & F_GL_Sum & "] " & _
          "INTO " & T_GL_SUM & _
          " FROM " & T_GL_IN & _
          " GROUP BY [" & F_GL_AccNo & "];"
    affected = dal.ExecuteSQL(sql)
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - GL Sum by Account: " & affected
    
    ' 3) LEFT JOIN
    sql = "SELECT " & T_GL_SUM & ".*, " & T_TB & ".* INTO " & T_LEFT & _
          " FROM " & T_GL_SUM & " LEFT JOIN " & T_TB & _
          " ON " & T_GL_SUM & ".[" & F_GL_AccNo & "] = " & T_TB & ".[" & F_TB_AccNo & "];"
    affected = dal.ExecuteSQL(sql)
    
    ' 4) RIGHT JOIN（Access 用 RIGHT JOIN + IS NULL 模擬 FULL OUTER）
    sql = "SELECT " & T_GL_SUM & ".*, " & T_TB & ".* INTO " & T_RIGHT & _
          " FROM " & T_GL_SUM & " RIGHT JOIN " & T_TB & _
          " ON " & T_GL_SUM & ".[" & F_GL_AccNo & "] = " & T_TB & ".[" & F_TB_AccNo & "] " & _
          " WHERE " & T_GL_SUM & ".[" & F_GL_AccNo & "] IS NULL;"
    affected = dal.ExecuteSQL(sql)
    
    ' 5) UNION 成計算表
    sql = "SELECT * INTO " & T_CALC & " FROM (" & _
          " SELECT * FROM " & T_LEFT & " UNION " & _
          " SELECT * FROM " & T_RIGHT & ");"
    affected = dal.ExecuteSQL(sql)
    
    ' 6) 新增 DIFF 欄位
    sql = "ALTER TABLE " & T_CALC & " ADD COLUMN [" & F_DIFF & "] DOUBLE;"
    dal.ExecuteSQL sql
    sql = "UPDATE " & T_CALC & _
          " SET [" & F_DIFF & "] = Nz([" & F_TB_Change & "],0) - Nz([" & F_GL_Sum & "],0);"
    dal.ExecuteSQL sql
    
    ' 7) 新增 ACCOUNT_NUM_ALL 欄位並寫入
    sql = "ALTER TABLE " & T_CALC & " ADD COLUMN [" & F_ACC_ALL & "] TEXT(64);"
    dal.ExecuteSQL sql
    sql = "UPDATE " & T_CALC & _
          " SET [" & F_ACC_ALL & "] = Left(IIf(Nz([" & F_GL_AccNo & "],'')<> '', [" & F_GL_AccNo & "], [" & F_TB_AccNo & "]), 64);"
    dal.ExecuteSQL sql
    
    ' 8) 產出 Completeness_Check 精簡表
    sql = "SELECT [" & F_ACC_ALL & "] AS ACCOUNT_NUM_ALL, " & _
                "[" & F_TB_AccName & "] AS 會計科目名稱_TB, " & _
                "Nz([" & F_TB_Change & "],0) AS 試算表變動金額_TB, " & _
                "Nz([" & F_GL_Sum & "],0) AS 傳票金額_JE_SUM, " & _
                "[" & F_DIFF & "] " & _
          "INTO " & T_CHECK & _
          " FROM " & T_CALC & ";"
    dal.ExecuteSQL sql
    
    ' 9) 產出差異清單（Abs(DIFF) > 0.01）
    sql = "SELECT * INTO " & T_DIFF & " FROM " & T_CHECK & " WHERE Abs([" & F_DIFF & "]) > 0.01;"
    dal.ExecuteSQL sql
    diffCount = dal.GetRecordCount(T_DIFF)
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 差異筆數: " & diffCount
    
    ' 回傳是否通過（無差異）
    TestCompleteness = (diffCount = 0)
    
    ' 清理中間表
    dal.DropIfExists T_LEFT
    dal.DropIfExists T_RIGHT
    dal.DropIfExists T_GL_IN
    Exit Function
    
ErrorHandler:
    TestCompleteness = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

Public Function TestBalance() As Boolean
    ' 借貸不平測試：以傳票號碼彙總 (本幣借方金額 - 本幣貸方金額)，取淨額絕對值 > 0.01
    Const METHOD_NAME As String = "TestBalance"
    On Error GoTo ErrorHandler
    Dim sql As String, affected As Long
    Dim resultTable As String: resultTable = "GL_Doc_not_Balance"
    Dim sumTable As String: sumTable = "GL_Doc_Sum"
    Dim T_GL As String: T_GL = "GL"
    Dim F_DocNo As String: F_DocNo = "傳票號碼"
    Dim F_Debit As String: F_Debit = "本幣借方金額"
    Dim F_Credit As String: F_Credit = "本幣貸方金額"
    
    TestBalance = False
    If Not dal.IsConnected Then dal.Connect
    
    dal.DropIfExists sumTable
    dal.DropIfExists resultTable
    
    ' Summarize by DocumentNumber
    sql = "SELECT [" & F_DocNo & "] AS 傳票號碼, " & _
          "SUM(Nz([" & F_Debit & "],0) - Nz([" & F_Credit & "],0)) AS 淨額 " & _
          "INTO " & sumTable & _
          " FROM " & T_GL & _
          " GROUP BY [" & F_DocNo & "];"
    dal.ExecuteSQL sql
    
    ' Extract unbalanced documents
    sql = "SELECT * INTO " & resultTable & _
          " FROM " & sumTable & " WHERE Abs([淨額]) > 0.01;"
    dal.ExecuteSQL sql
    
    TestBalance = (dal.GetRecordCount(resultTable) = 0)
    Exit Function
    
ErrorHandler:
    TestBalance = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

Public Function TestRDE() As Boolean
    ' 延伸：此處保留，避免過度開發
    TestRDE = True
End Function
