VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_Main
' Purpose:  主要控制器，使用如 Context.Dal, Context.Project.name
'===============================================================================
Private Const MODULE_NAME As String = "c_Main"
' ----- 表單事件 -----
Private WithEvents viewMain As v_Main
Attribute viewMain.VB_VarHelpID = -1
' ----- 控制器 -----
Private ctrlImport As c_Import
Private ctrlValidation As c_Validation
' ----- 成員 -----
Private m_Config As m_ManagerConfig
Private m_Context As m_ManagerContext



' ----- [ c_Main ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME As String = "Class_Initialize"
    Set viewMain = New v_Main
    Set ctrlImport = New c_Import
    Set ctrlValidation = New c_Validation
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME As String = "Class_Terminate"
    Set ctrlImport = Nothing
    Set ctrlValidation = Nothing
End Sub

Public Sub Run(ByVal Config As m_ManagerConfig, ByVal Context As m_ManagerContext)
    Const METHOD_NAME As String = "Run"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '依賴注入
    Set m_Config = Config
    Set m_Context = Context
    '設定表單
    viewMain.Caption = m_Context.Project.name
    '顯示主介面
    viewMain.Show vbModeless
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub



' ----- [ v_Main ] -----
Private Sub viewMain_DoExit()
    Const METHOD_NAME As String = "viewMain_DoExit"
    ' Save all status through m_Config
    viewMain.Hide
End Sub

Private Sub viewMain_DoStep1()
    Const METHOD_NAME As String = "viewMain_DoStep1"
    Dim result As Dictionary
    Set result = ctrlImport.Execute(m_Config, m_Context)
End Sub

Private Sub viewMain_DoStep2()
    Const METHOD_NAME As String = "viewMain_DoStep2"
    Dim result As Dictionary
    Set result = ctrlValidation.Execute(m_Config, m_Context)
End Sub

Private Sub viewMain_DoStep3()
    Const METHOD_NAME As String = "viewMain_DoStep3"
    Dim result As Dictionary
End Sub

Private Sub viewMain_DoStep4()
    Const METHOD_NAME As String = "viewMain_DoStep4"
    Dim result As Dictionary
End Sub
