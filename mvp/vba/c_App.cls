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

' ----- 管理員 -----
Private m_config As m_ManagerConfig
Private m_context As m_ManagerContext
' ----- 控制器 -----
Private project As c_Project
Private main As c_Main


Public Sub Launch()
    Set m_config = New m_ManagerConfig
    Set m_context = New m_ManagerContext
    
    ' 專案建置
    Set project = New c_Project
    If Not project.Build(m_config, m_context) Then
        MsgBox "專案建置失敗。", vbExclamation, "專案建置"
        Exit Sub
    End If
    
    ' 執行程式
    Set main = New c_Main
    Call main.Run(m_config, m_context) ' 引入傳址的實例，並在 c_Main 使用傳值
    
End Sub

