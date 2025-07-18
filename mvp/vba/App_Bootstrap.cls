VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "App_Bootstrap"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "App_Bootstrap"
'===============================================================================
' Module:   App_Bootstrap
' Purpose:  應用程式啟動器，負責初始化系統組件和建立依賴關係
' Layer:    Application
' Domain:   Bootstrap/Startup
'===============================================================================

'--類別成員
Private m_ProjectManager As Mgr_Project
Private m_ProjectController As Ctrl_Project
Private m_MainController As Ctrl_Main



'--App_Bootstrap
Public Sub Launch()
    Const METHOD_NAME As String = "Launch"
    '初始化
    Set m_ProjectManager = New Mgr_Project
    m_ProjectManager.Initialize
    
    Set m_ProjectController = New Ctrl_Project
    m_ProjectController.Initialize m_ProjectManager
    
    '專案建置
    If m_ProjectController.Build() Then
        '執行主程式
        Set m_MainController = New Ctrl_Main
        m_MainController.Initialize m_ProjectManager
        m_MainController.Run
    Else
        MsgBox "專案建置失敗。", vbExclamation, "專案建置"
    End If
End Sub

Public Sub Shutdown()
    Const METHOD_NAME As String = "Shutdown"
End Sub
