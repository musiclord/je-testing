Attribute VB_Name = "Util"
Option Explicit
Private m_App As New ApplicationMain



'===============================================================================
' 全域常數-資料表名稱
'===============================================================================
'-- JE 相關資料表
Public Const TBL_JE As String = "JE"
Public Const TBL_JE_IN_PERIOD As String = "JE_IN_PERIOD"
Public Const TBL_JE_NOT_IN_PERIOD As String = "JE_NOT_IN_PERIOD"
Public Const TBL_JE_ACCOUNT_SUM As String = "JE_ACCOUNT_SUM"
'-- TB 相關資料表
Public Const TBL_TB As String = "TB"
'-- 完整性檢查相關資料表
Public Const TBL_COMPLETENESS_CALCULATED As String = "COMPLETENESS_CALCULATED"
Public Const TBL_COMPLETENESS_RESULT As String = "COMPLETENESS_RESULT"
'-- 傳票平衡檢查相關資料表
Public Const TBL_DOCUMENT_IN_PERIOD As String = "DOCUMENT_IN_PERIOD"
Public Const TBL_DOCUMENT_SUM As String = "DOCUMENT_SUM"
Public Const TBL_DOCUMENT_DIFF As String = "DOCUMENT_DIFF"
Public Const TBL_DOCUMENT_NOT_BALANCE As String = "DOCUMENT_NOT_BALANCE"
'-- INF 測試相關資料表
Public Const TBL_INF_RANDOM As String = "INF_RANDOM"
Public Const TBL_INF_SORTED As String = "INF_SORTED"
'-- 空值檢查相關資料表
Public Const TBL_NULL_ACCOUNT As String = "NULL_ACCOUNT_RECORDS"
Public Const TBL_NULL_DOCUMENT As String = "NULL_DOCUMENT_RECORDS"
Public Const TBL_NULL_DESCRIPTION As String = "NULL_DESCRIPTION_RECORDS"



'===============================================================================
'專案全域入口介面
'===============================================================================
Public Sub Launch()
    m_App.Initialize
    m_App.Run
End Sub



'===============================================================================
'查詢輔助語法
'===============================================================================
Public Function Nz(ByVal fieldName As String, Optional ByVal defaultValue As String = "0") As String
    ' 將欄位名稱轉換成 IIF(ISNULL(...),defaultValue,...) SQL 語法
    fieldName = Trim$(fieldName)
    ' 如果 fieldName 包含空格或特殊字元，用方括號包圍
    fieldName = "[" & fieldName & "]"
    Nz = "IIF(ISNULL(" & fieldName & ")," & defaultValue & "," & fieldName & ")"
End Function

