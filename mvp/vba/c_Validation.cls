VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_Validation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_Validation
' Purpose:  驗證資料程序的控制器
'===============================================================================
Private Const MODULE_NAME As String = "c_Validation"
' ----- 表單事件 -----
Private WithEvents viewValidation As v_Validation
Attribute viewValidation.VB_VarHelpID = -1
' ----- 依賴項 -----
Private m_Config As m_ManagerConfig
Private m_Context As m_ManagerContext
' ----- 成員 -----
Private m_gl As String
Private m_tb As String


Private Sub Class_Initialize()
    Const METHOD_NAME = "Class_Initialize"
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME = "Class_Terminate"
End Sub

Public Function Execute(ByRef Config As m_ManagerConfig, ByRef Context As m_ManagerContext) As Dictionary
    Const METHOD_NAME = "Execute"
    Set m_Config = Config
    Set m_Context = Context
    ' ...
    Execute("completeness") = True
    Execute("document_balance") = True
    Execute("rde") = True
End Function


