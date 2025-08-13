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

'--Svc_Validation
Public Sub Initialize(ByRef Context As Mgr_Context)
    Set m_ctx = Context
    Set dal = Context.DalData
    Set gl = Context.gl
    Set tb = Context.tb
End Sub

Public Function TestCompleteness(ByVal startDate As Date, ByVal endDate As Date) As Boolean
    Const METHOD_NAME As String = "TestCompleteness"
    On Error GoTo ErrorHandler
    
    dal.Connect
    
    Dim sStart As String, sEnd As String
    sStart = Format(startDate, "\#yyyy\-mm\-dd\#")
    sEnd = Format(endDate, "\#yyyy\-mm\-dd\#")

    Dim T_GL As String: T_GL = "GL"
    Dim T_TB As String: T_TB = "TB"
    Dim T_GL_IN As String: T_GL_IN = "GL_In_Period"
    Dim T_GL_SUM As String: T_GL_SUM = "GL_Account_Sum"
    Dim T_LEFT As String: T_LEFT = "temp_Left"
    Dim T_RIGHT As String: T_RIGHT = "temp_Right"
    Dim T_CALC As String: T_CALC = "Completeness_calculate"
    Dim T_CHECK As String: T_CHECK = "Completeness_Check"
    Dim T_DIFF As String: T_DIFF = "List_of_accounts_with_variance"

    Dim F_PostDate$, F_GL_AccNo$, F_GL_Debit$, F_GL_Credit$
    Dim F_TB_AccNo$, F_TB_AccName$, F_TB_Change$
    Dim F_GL_Sum$, F_DIFF$, F_ACC_ALL$
    F_PostDate = "日期": F_GL_AccNo = "科目代碼"
    F_GL_Debit = "本幣借方金額": F_GL_Credit = "本幣貸方金額"
    F_TB_AccNo = "會計項目": F_TB_AccName = "項目名稱": F_TB_Change = "借-貸(本幣)"
    F_GL_Sum = "傳票金額_JE_SUM": F_DIFF = "DIFF": F_ACC_ALL = "ACCOUNT_NUM_ALL"

    dal.DropIfExists T_GL_IN
    dal.DropIfExists T_GL_SUM
    dal.DropIfExists T_LEFT
    dal.DropIfExists T_RIGHT
    dal.DropIfExists T_CALC
    dal.DropIfExists T_CHECK
    dal.DropIfExists T_DIFF

    Dim sql As String
    sql = "SELECT " & T_GL & ".* INTO " & T_GL_IN & _
          " FROM " & T_GL & _
          " WHERE CDate([" & F_PostDate & "]) >= " & sStart & " AND CDate([" & F_PostDate & "]) <= " & sEnd & ";"
    dal.ExecuteSQL sql

    sql = "SELECT [" & F_GL_AccNo & "], " & _
          "SUM(Nz([" & F_GL_Debit & "],0) - Nz([" & F_GL_Credit & "],0)) AS [" & F_GL_Sum & "] " & _
          "INTO " & T_GL_SUM & _
          " FROM " & T_GL_IN & _
          " GROUP BY [" & F_GL_AccNo & "];"
    dal.ExecuteSQL sql

    sql = "SELECT " & T_GL_SUM & ".*, " & T_TB & ".* INTO " & T_LEFT & _
          " FROM " & T_GL_SUM & " LEFT JOIN " & T_TB & _
          " ON " & T_GL_SUM & ".[" & F_GL_AccNo & "] = " & T_TB & ".[" & F_TB_AccNo & "];"
    dal.ExecuteSQL sql

    sql = "SELECT " & T_GL_SUM & ".*, " & T_TB & ".* INTO " & T_RIGHT & _
          " FROM " & T_GL_SUM & " RIGHT JOIN " & T_TB & _
          " ON " & T_GL_SUM & ".[" & F_GL_AccNo & "] = " & T_TB & ".[" & F_TB_AccNo & "] " & _
          " WHERE " & T_GL_SUM & ".[" & F_GL_AccNo & "] IS NULL;"
    dal.ExecuteSQL sql

    sql = "SELECT * INTO " & T_CALC & " FROM (" & _
          " SELECT * FROM " & T_LEFT & " UNION " & _
          " SELECT * FROM " & T_RIGHT & ");"
    dal.ExecuteSQL sql

    sql = "ALTER TABLE " & T_CALC & " ADD COLUMN [" & F_DIFF & "] DOUBLE;"
    dal.ExecuteSQL sql
    sql = "UPDATE " & T_CALC & " SET [" & F_DIFF & "] = Nz([" & F_TB_Change & "],0) - Nz([" & F_GL_Sum & "],0);"
    dal.ExecuteSQL sql

    sql = "ALTER TABLE " & T_CALC & " ADD COLUMN [" & F_ACC_ALL & "] TEXT(64);"
    dal.ExecuteSQL sql
    sql = "UPDATE " & T_CALC & " SET [" & F_ACC_ALL & "] = Left(IIf(Nz([" & F_GL_AccNo & "],'')<>'', [" & F_GL_AccNo & "], [" & F_TB_AccNo & "]), 64);"
    dal.ExecuteSQL sql

    sql = "SELECT [" & F_ACC_ALL & "] AS ACCOUNT_NUM_ALL, " & _
                "[" & F_TB_AccName & "] AS 會計科目名稱_TB, " & _
                "Nz([" & F_TB_Change & "],0) AS 試算表變動金額_TB, " & _
                "Nz([" & F_GL_Sum & "],0) AS 傳票金額_JE_SUM, " & _
                "[" & F_DIFF & "] " & _
          "INTO " & T_CHECK & _
          " FROM " & T_CALC & ";"
    dal.ExecuteSQL sql

    sql = "SELECT * INTO " & T_DIFF & " FROM " & T_CHECK & " WHERE Abs([" & F_DIFF & "]) > 0.01;"
    dal.ExecuteSQL sql

    TestCompleteness = (dal.GetRecordCount(T_DIFF) = 0)

    dal.DropIfExists T_LEFT
    dal.DropIfExists T_RIGHT
    dal.DropIfExists T_GL_IN
    Exit Function
ErrorHandler:
    TestCompleteness = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

Public Function TestBalance() As Boolean
    Const METHOD_NAME As String = "TestBalance"
    On Error GoTo ErrorHandler
    dal.Connect

    Dim sumTable As String: sumTable = "GL_Doc_Sum"
    Dim resultTable As String: resultTable = "GL_Doc_not_Balance"
    dal.DropIfExists sumTable
    dal.DropIfExists resultTable

    Dim sql As String
    sql = "SELECT [傳票號碼], SUM(Nz([本幣借方金額],0)-Nz([本幣貸方金額],0)) AS 淨額 " & _
          "INTO " & sumTable & " FROM GL GROUP BY [傳票號碼];"
    dal.ExecuteSQL sql

    sql = "SELECT * INTO " & resultTable & " FROM " & sumTable & " WHERE Abs([淨額]) > 0.01;"
    dal.ExecuteSQL sql

    TestBalance = (dal.GetRecordCount(resultTable) = 0)
    Exit Function
ErrorHandler:
    TestBalance = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Number & ":" & Err.Description
End Function

Public Function TestRDE() As Boolean
    TestRDE = True
End Function

