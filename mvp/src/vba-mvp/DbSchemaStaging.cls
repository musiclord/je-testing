VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DbSchemaStaging"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Schema
' Name:     Staging
' Purpose:  ...
'
'===============================================================================

'--


'-------------------------------------------------------------------------------
'-- Staging Layer
'-------------------------------------------------------------------------------
'-- Tables
Public Property Get TBL_JE_IN_PERIOD() As String
    ' 期間內的 JE
    TBL_JE_IN_PERIOD = "JE_IN_PERIOD"
End Property
Public Property Get TBL_JE_NOT_IN_PERIOD() As String
    ' 期間外的 JE
    TBL_JE_NOT_IN_PERIOD = "JE_NOT_IN_PERIOD"
End Property
Public Property Get TBL_ACCOUNT_SUM() As String
    ' JE 按科目彙總
    TBL_ACCOUNT_SUM = "ACCOUNT_SUM"
End Property
Public Property Get TBL_COMPLETENESS_CAL() As String
    ' 完整性計算結果
    TBL_COMPLETENESS_CAL = "COMPLETENESS_CALCULATED"
End Property
Public Property Get TBL_COMPLETENESS_DIFF() As String
    ' 完整性差異結果
    TBL_COMPLETENESS_DIFF = "COMPLETENESS_DIFF"
End Property
Public Property Get TBL_COMPLETENESS_DETAIL() As String
    ' 完整性測試明細
    TBL_COMPLETENESS_DETAIL = "COMPLETENESS_DETAIL"
End Property
Public Property Get TBL_DOC_BALANCE_SUM() As String
    ' 傳票彙總
    TBL_DOC_BALANCE_SUM = "DOCUMENT_BALANCE_SUM"
End Property
Public Property Get TBL_DOC_BALANCE_DIFF() As String
    ' 借貸不平結果
    TBL_DOC_BALANCE_DIFF = "DOCUMENT_BALANCE_DIFF"
End Property
Public Property Get TBL_DOC_BALANCE_DETAIL() As String
    ' 借貸不平明細
    TBL_DOC_BALANCE_DETAIL = "DOCUMENT_BALANCE_DETAIL"
End Property
Public Property Get TBL_INF_RANDOM() As String
    ' INF 隨機抽樣
    TBL_INF_RANDOM = "INF_RANDOM"
End Property
Public Property Get TBL_INF_SORTED() As String
    ' INF 排序資料
    TBL_INF_SORTED = "INF_SORTED"
End Property
Public Property Get TBL_NULL_ACCOUNT() As String
    ' 空白科目記錄
    TBL_NULL_ACCOUNT = "NULL_ACCOUNT"
End Property
Public Property Get TBL_NULL_DOC() As String
    ' 空白傳票記錄
    TBL_NULL_DOC = "NULL_DOC"
End Property
Public Property Get TBL_NULL_DESC() As String
    ' 空白摘要記錄
    TBL_NULL_DESC = "NULL_DESCRIPTION"
End Property
'-- Fields
Public Property Get FLD_COMPLETENESS_ACCOUNT_MERGED() As String
    ' 合併 JE 和 TB 科目編號
    FLD_COMPLETENESS_ACCOUNT_MERGED = "K_ACCOUNT_MERGED"
End Property
Public Property Get FLD_COMPLETENESS_DIFF() As String
    ' JE 和 TB 差異金額
    FLD_COMPLETENESS_DIFF = "K_TB_JE_DIFF"
End Property
