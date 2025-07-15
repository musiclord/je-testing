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



' ----- [ c_Validation ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME = "Class_Initialize"
    Set viewValidation = New v_Validation
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME = "Class_Terminate"
End Sub

Public Function Execute(ByRef Config As m_ManagerConfig, ByRef Context As m_ManagerContext) As Dictionary
    Const METHOD_NAME = "Execute"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '依賴注入
    Dim result As Dictionary
    Set result = New Dictionary
    Set m_Config = Config
    Set m_Context = Context
    '設定表單
    '傳 vbModal 來鎖住程序
    viewValidation.Show vbModal
    '待表單關閉後，收集程序狀態並回傳
    result.Add "completeness", True
    result.Add "document_balance", True
    result.Add "rde", True
    Set Execute = result
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Function



' ----- [ v_Validation ] -----
Private Sub viewValidation_DoExit()
    Const METHOD_NAME = "viewValidation_DoExit"
    viewValidation.Hide
End Sub
