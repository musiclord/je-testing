VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Validation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Validation"
'===============================================================================
' Module:   Ctrl_Validation
' Purpose:  驗證功能控制器，管理資料驗證流程
' Layer:    Controller
' Domain:   Data Validation
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ValidationService As Svc_Validation
'--事件表單
Private WithEvents viewValidation As View_Validation
Attribute viewValidation.VB_VarHelpID = -1



'--Ctrl_Validation
Public Sub Initialize(ByRef Config As Mgr_Config, ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    Set m_cfg = Config
    Set m_ctx = Context
    Set m_ValidationService = New Svc_Validation
    m_ValidationService.Initialize m_ctx
    Set viewValidation = New View_Validation
End Sub

Public Function Execute() As Dictionary
    Const METHOD_NAME As String = ""
    On Error GoTo ErrorHandler
    
    Dim result As Dictionary
    Set result = New Dictionary
    viewValidation.Show vbModeless
    '檢查處理狀態
    result.Add "test_completeness", True
    result.Add "test_balance", True
    result.Add "test_rde", True
    
    Set Execute = result
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function


'--View_Validation
Private Sub viewValidation_DoExit()
    viewValidation.Hide
End Sub

Private Sub viewValidation_DoTestCompleteness()
    Dim minD As Date, maxD As Date, ok As Boolean, passed As Boolean
    ok = m_ctx.DalData.GetDateRange("GL", "日期", minD, maxD)
    If Not ok Then
        MsgBox "無法取得 GL 期間。", vbExclamation
        Exit Sub
    End If
    passed = m_ValidationService.TestCompleteness(minD, maxD)
    If passed Then
        MsgBox "完整性測試通過（無差異）。", vbInformation
    Else
        Dim n As Long
        n = m_ctx.DalData.GetRecordCount("List_of_accounts_with_variance")
        MsgBox "完整性測試未通過，差異筆數：" & n, vbExclamation
    End If
End Sub

Private Sub viewValidation_DoTestBalance()
    If m_ValidationService.TestBalance Then
        MsgBox "借貸不平測試通過（全部平衡）。", vbInformation
    Else
        Dim n As Long
        n = m_ctx.DalData.GetRecordCount("GL_Doc_not_Balance")
        MsgBox "借貸不平測試未通過，異常傳票：" & n, vbExclamation
    End If
End Sub
