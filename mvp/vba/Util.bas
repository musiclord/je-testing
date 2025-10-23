Attribute VB_Name = "Util"
Option Explicit
'===============================================================================
' Module:   Util
' Purpose:
' Methods:
'===============================================================================
Private m_App As New ApplicationMain
'-- 日期維度表
Public Const TBL_DATE_DIMENSION As String = "DATE_DIMENSION"
'-- JE 相關資料表
Public Const TBL_JE As String = "JE"
Public Const TBL_JE_IN_PERIOD As String = "JE_IN_PERIOD"
Public Const TBL_JE_NOT_IN_PERIOD As String = "JE_NOT_IN_PERIOD"
Public Const TBL_JE_ACCOUNT_SUM As String = "JE_ACCOUNT_SUM"
'-- TB 相關資料表
Public Const TBL_TB As String = "TB"
'-- 完整性檢查相關資料表
Public Const TBL_COMPLETENESS_CALCULATED As String = "COMPLETENESS_CALCULATED"
Public Const TBL_COMPLETENESS_DIFF As String = "COMPLETENESS_DIFF"
Public Const TBL_COMPLETENESS_DETAIL As String = "COMPLETENESS_DETAIL"
'-- 借貸平衡檢查相關資料表
Public Const TBL_DOCUMENT_BALANCE_SUM As String = "DOCUMENT_BALANCE_SUM"
Public Const TBL_DOCUMENT_BALANCE_DIFF As String = "DOCUMENT_BALANCE_DIFF"
Public Const TBL_DOCUMENT_BALANCE_DETAIL As String = "DOCUMENT_BALANCE_DETAIL"
'-- INF 測試相關資料表
Public Const TBL_INF_RANDOM As String = "INF_RANDOM"
Public Const TBL_INF_SORTED As String = "INF_SORTED"
'-- 空值檢查相關資料表
Public Const TBL_NULL_ACCOUNT As String = "NULL_ACCOUNT_RECORDS"
Public Const TBL_NULL_DOCUMENT As String = "NULL_DOCUMENT_RECORDS"
Public Const TBL_NULL_DESCRIPTION As String = "NULL_DESCRIPTION_RECORDS"
'-- 報表資料表
Public Const RPT_ENGAGEMENT_OVERVIEW As String = "ENGAGEMENT_OVERVIEW"
Public Const RPT_DATA_OVERVIEW As String = "DATA_OVERVIEW"
Public Const RPT_VALIDATION_OVERVIEW As String = "VALIDATION_OVERVIEW"
Public Const RPT_COMPLETENESS_DETAIL As String = "COMPLETENESS_DETAIL"
Public Const RPT_DOCUMENT_BALANCE_DETAIL As String = "DOCUMENT_BALANCE_DETAIL"
Public Const RPT_INF_SAMPLE_DETAIL As String = "INF_SAMPLE_DETAIL"
Public Const RPT_ACCOUNT_MAPPING_INFO As String = "ACCOUNT_MAPPING_INFO"
Public Const RPT_FIELD_MAPPING_INFO As String = "FIELD_MAPPING_INFO"

'-- 專案全域入口介面
'-------------------------------------------------------------------------------
Public Sub Launch()
    Call m_App.Initialize
    Call m_App.Run
End Sub

'-- 查詢輔助語法
'-------------------------------------------------------------------------------
Public Function Nz( _
    ByVal fieldName As String, _
    Optional ByVal defaultValue As String = "0" _
) As String
    ' 將欄位名稱轉換成 IIF(ISNULL(...),defaultValue,...) SQL 語法
    fieldName = Trim$(fieldName)
    ' 如果 fieldName 包含空格或特殊字元，用方括號包圍
    fieldName = "[" & fieldName & "]"
    Nz = "IIF(ISNULL(" & fieldName & ")," & defaultValue & "," & fieldName & ")"
End Function

Public Function SanitizeNumericField(ByVal fieldName As String) As String
    ' 轉換空值或任何非值為零
    SanitizeNumericField = _
        "CDbl(IIf(" & vbCrLf & _
        "    [" & fieldName & "] IS NULL " & vbCrLf & _
        "        OR Trim([" & fieldName & "]) = '' " & vbCrLf & _
        "        OR Trim([" & fieldName & "]) = '-', " & vbCrLf & _
        "    0, [" & fieldName & "]))"
End Function

'-- 檢查資料方法
'-------------------------------------------------------------------------------
Public Function CheckDate(ByVal Value As Variant) As Boolean
    ' Use: If Not CheckDate(date) Then Exit Sub
    ' CDate (value)
End Function

Public Function CheckDouble(ByVal Value As Variant) As Boolean
    ' Use: If Not CheckDouble(double) Then Exit Sub
    ' CDouble (value)
End Function

Public Function CheckText(ByVal Value As Variant) As Boolean
    ' Use If Not CheckText(text) Then Exit Sub
    ' CStr(value)
End Function

