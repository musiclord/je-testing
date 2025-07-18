VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Main"
'===============================================================================
' Module:   Ctrl_Main
' Purpose:  主要功能控制器，協調各步驟流程的執行與視圖切換
' Layer:    Controller
' Domain:   Core Application
'===============================================================================


'--類別成員
Private m_ProjectManager As Mgr_Project
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ImportController As Ctrl_Import
Private m_ValidationController As Ctrl_Validation
Private m_FilterController As Ctrl_Filter
Private m_ExportController As Ctrl_Export
'--事件表單
Private WithEvents viewMain As View_Main
Attribute viewMain.VB_VarHelpID = -1


Public Sub Initialize(ByVal project As Mgr_Project)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ProjectManager = project
    Set m_cfg = m_ProjectManager.Config
    Set m_ctx = m_ProjectManager.Context
    '實例化
    Set viewMain = New View_Main
End Sub

Public Sub Run()
    Const METHOD_NAME As String = "Run"
    '設定表單
    viewMain.Caption = m_ProjectManager.name
    '開啟表單
    viewMain.Show vbModeless
    
End Sub

Private Sub viewMain_DoExit()
    Const METHOD_NAME As String = "viewMain_DoExit"
    viewMain.Hide
End Sub

Private Sub viewMain_DoStep1()
    Const METHOD_NAME As String = "viewMain_DoStep1"
    
    Dim result As Dictionary
    Set m_ImportController = New Ctrl_Import
    m_ImportController.Initialize m_cfg, m_ctx
    '更新處理狀態
    Set result = m_ImportController.Execute()
    
End Sub

Private Sub viewMain_DoStep2()
    Const METHOD_NAME As String = "viewMain_DoStep2"
    
    Dim result As Dictionary
    Set m_ValidationController = New Ctrl_Validation
    m_ValidationController.Initialize m_cfg, m_ctx
    '更新處理狀態
    Set result = m_ValidationController.Execute()
    
End Sub

Private Sub viewMain_DoStep3()
    Const METHOD_NAME As String = "viewMain_DoStep3"
    
    Dim result As Dictionary
    Set m_FilterController = New Ctrl_Filter
    m_FilterController.Initialize m_cfg, m_ctx
    '更新處理狀態
    Set result = m_FilterController.Execute()
    
End Sub

Private Sub viewMain_DoStep4()
    Const METHOD_NAME As String = "viewMain_DoStep4"
    
    Dim result As Dictionary
    Set m_ExportController = New Ctrl_Export
    m_ExportController.Initialize m_cfg, m_ctx
    '更新處理狀態
    Set result = m_ExportController.Execute()
    
End Sub
