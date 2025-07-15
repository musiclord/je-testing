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
' ----- 依賴項 -----
Private m_Config As m_ManagerConfig
Private m_Context As m_ManagerContext
' ----- 控制器 -----
Private m_ProjectSelector As c_Project
Private m_MainController As c_Main



Public Sub Launch()
    Const METHOD_NAME As String = "Launch"
    ' 專案建置
    Set m_ProjectSelector = New c_Project
    If Not m_ProjectSelector.Build() Then
        MsgBox "專案建置失敗。", vbExclamation, "專案建置"
        Exit Sub
    Else
        Set m_Config = m_ProjectSelector.Config
        Set m_Context = m_ProjectSelector.Context
    End If
    ' 執行程式
    Set m_MainController = New c_Main
    m_MainController.Run m_Config, m_Context
End Sub

