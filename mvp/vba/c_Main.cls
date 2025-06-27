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
    Set m_config = New m_ManagerConfig
    Set m_context = New m_ManagerContext
    Set viewMain = New v_Main
End Sub

Private Sub Class_Terminate()
End Sub

Public Sub Run(ByVal config As m_ManagerConfig, ByVal context As m_ManagerContext)
    
    Set m_config = config
    Set m_context = context
    ' ...
    viewMain.Show (vbModeless)
End Sub


Private Sub viewMain_DoExit()
    viewMain.Hide
End Sub
