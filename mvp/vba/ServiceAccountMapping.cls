VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceAccountMapping"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: ServiceAccountMapping
' Purpose: 管理科目配對的服務
'
' Description:
'   負責從驗證結果（COMPLETENESS_DETAIL）提取科目清單,
'   匯出至 AccountMappingSheet 供審計人員標註,
'   並將標註結果匯入至資料庫以供後續分析使用。
'
' Dependencies:
'   - ServiceValidation: 需先執行 CheckCompleteness() 產生 COMPLETENESS_DETAIL
'   - AccountMappingSheet: Excel 工作表物件
'
' Workflow:
'   1. ExportAccountMappingTemplate() - 從 COMPLETENESS_DETAIL 匯出科目清單
'   2. [使用者手動標註分類]
'   3. ImportAccountMapping() - 讀取工作表並儲存至資料庫
'   4. ValidateAccountMapping() - 驗證對應關係的完整性
'
' AccountMapping
'     - STANDARDIZED_ACCOUNT_NAME:
'         (1)Cash
'         (2)Revenue
'         (3)Receipt in advance
'         (4)Receivables
'         (5)Others
'
' Fields
'     1. GL Number,   原始科目代號（文字或數字）
'     2. GL Name,     標準化科目名稱，如果沒有就填 "Not in TB"
'     3. Standardized Account Name
'
' Data
'     - TBL_COMPLETENESS_DETAIL, 經過完整性測試的資料已經由科目代號(TB的)分組過
'
' Example
'-------------------------------------------------------------------------------
'     GL_Number |   GL_Name            |  Standardized Account Name*
'     1101**    |   Not in TB          |  Cash
'     1102A*    |   [銀存]支票存款     |  Cash
'     1102C*    |   [銀存]外匯活期存款 |  Cash
'     1103**    |   定期存款           |  Cash
'-------------------------------------------------------------------------------
'
'===============================================================================
Private Const FLD_ACCOUNT_NUMBER As String = "AccountNumber"
Private Const FLD_ACCOUNT_NAME As String = "AccountName"
Private Const FLD_STANDARDIZED As String = "Standardized"
'--
Private m_Context As ContextManager
Private m_DbValid As DbAccess
Private m_Db As DbAccess
Private m_Schema As DbSchema

Public Sub Initialize(context As ContextManager)
    Set m_Context = context
    Set m_Db = context.DbInput
    Set m_Schema = context.DbSchema
    Set m_DbValid = context.DbValid
End Sub

Public Function ExportTemplate() As Boolean
    '---------------------------------------------------------------------------
    ' 從 COMPLETENESS_DETAIL 匯出科目清單至 AccountMappingSheet
    ' 資料來源欄位:
    '   - ACCOUNT_MERGED: 統一的會計科目編號
    '   - tb.AccountName: 試算表的科目名稱（可能為 NULL 或 "Not in TB"）
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    '檢查前置條件
    If Not m_DbValid.TableExists(m_Schema.Tables.CompletenessDetail) Then
        Debug.Print "ServiceAccountMapping: COMPLETENESS_DETAIL 表不存在，請先執行完整性檢查"
        MsgBox "請先執行完整性檢查", vbExclamation, "科目配對"
    End If
    '查詢科目
    Dim sql As String
    '//TODO: 從這裡分支出問題，因為這裡要跨服務使用資料表欄位
    '//      因此需先設計好 DbSchema 和 Entity 間的邏輯
    sql = "SELECT * " & vbCrLf & _
          "    []," & vbCrLf & _
          "" & vbCrLf & _
          "" & vbCrLf & _
          "" & vbCrLf & _
          "" & vbCrLf & _
          ""
    
    Exit Function
ErrorHandler:
    Debug.Print ""
End Function


