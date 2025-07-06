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
' Purpose:  主要控制器，使用如 context.dal, context.project.name
'===============================================================================

' ----- 常數 -----
Private Const MODULE_NAME As String = "c_Main"
' ----- 表單事件 -----
Private WithEvents viewMain As v_Main
Attribute viewMain.VB_VarHelpID = -1
' ----- 類別成員 -----
Private m_config As m_ManagerConfig
Private m_context As m_ManagerContext


' ----- [ c_Main ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME As String = "Class_Initialize"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    Set viewMain = New v_Main
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME As String = "Class_Terminate"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Public Sub Run(ByVal Config As m_ManagerConfig, ByVal Context As m_ManagerContext)
    Const METHOD_NAME As String = "Run"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    Set m_config = Config
    Set m_context = Context
    ' ...
    viewMain.Show (vbModeless)
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub


Private Sub viewMain_DoExit()
    Const METHOD_NAME As String = "viewMain_DoExit"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    viewMain.Hide
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub
