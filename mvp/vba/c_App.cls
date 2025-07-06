VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_App"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_App
' Purpose:  應用程式控制器，處理專案建置並執行。
'===============================================================================
Private Const MODULE_NAME As String = "c_App"
' ----- 管理員 -----
Private m_config As m_ManagerConfig
Private m_context As m_ManagerContext
' ----- 控制器 -----
Private project As c_Project
Private main As c_Main


Public Sub Launch()
    Const METHOD_NAME As String = "Launch"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    ' 專案建置
    Set project = New c_Project
    If Not project.Build() Then
        MsgBox "專案建置失敗。", vbExclamation, "專案建置"
        Exit Sub
    Else
    Debug.Print "!!!"
        Set m_config = project.Config
        Set m_context = project.Context
    End If
    
    ' 執行程式
    Set main = New c_Main
    Debug.Print "tag 1"
    Call main.Run(m_config, m_context)
    Debug.Print "tag 2"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

