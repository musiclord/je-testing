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
' Purpose:  應用程式主控制器
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "c_Main"

' === 介面事件 ===
Private WithEvents viewMain As v_Main
Attribute viewMain.VB_VarHelpID = -1

' === 控制器變數 ===
Private ctrlImport As c_Import                  ' as Step1
Private ctrlValidation As c_Validation          ' as Step2
Private ctrlFilter As c_Filter                  ' as Step3
Private ctrlExport As c_Export                  ' as Step4

' === 管理員 ===
Private config As m_ManagerConfig
Private context As m_ManagerContext

' === 資料存取 ===
Private dal As i_dal
Private dalAccess As dal_Access
Private dalSql As dal_Sql

' --- c_Main ---
Private Sub Class_Initialize()
    ' --- --- ---
    Set dalAccess = New dal_Access
    Set dalSql = New dal_Sql
    ' --- --- ---
    Set ctrlImport = New c_Import
    Set ctrlValidation = New c_Validation
    Set ctrlFilter = New c_Filter
    Set ctrlExport = New c_Export
    ' --- --- ---
    Set viewMain = New v_Main
    
End Sub

Private Sub Class_Terminate()

End Sub

Public Sub Run(ByVal p_context As m_ManagerContext, ByVal p_config As m_ManagerConfig)
    Set dal = dalAccess ' 實作多型
    Set context = p_context
    Set config = p_config
    
    viewMain.Show (vbModeless)
End Sub

' --- v_Main ---
Private Sub viewMain_DoExit()
    Unload viewMain
    Set viewMain = Nothing
End Sub

