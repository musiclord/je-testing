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
    '依賴注入
    Set m_cfg = Config
    Set m_ctx = Context
    '實例化
    Set m_ValidationService = New Svc_Validation
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
    Const METHOD_NAME As String = "viewValidation_DoExit"
    viewValidation.Hide
End Sub
