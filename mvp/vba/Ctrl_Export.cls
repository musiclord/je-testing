VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Export"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Export"
'===============================================================================
' Module:   Ctrl_Export
' Purpose:  匯出功能控制器，處理資料匯出流程和使用者互動
' Layer:    Controller
' Domain:   Export Processing
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ExportService As Svc_Export
'--事件表單
Private WithEvents viewExport As View_Export
Attribute viewExport.VB_VarHelpID = -1



'--Ctrl_Export
Public Sub Initialize(ByRef Config As Mgr_Config, ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_cfg = Config
    Set m_ctx = Context
    '實例化
    Set m_ExportService = New Svc_Export
    Set viewExport = New View_Export
End Sub

Public Function Execute() As Dictionary
    Const METHOD_NAME As String = "Execute"
    On Error GoTo Errorhandler
    
    Dim result As Dictionary
    Set result = New Dictionary
    viewExport.Show vbModeless
    '檢查處理狀態
    result.Add "completeness_report", True
    result.Add "inf_report", True
    result.Add "criteria_report", True
    result.Add "high_risk_entry_report", True
    
    Set Execute = result
    Exit Function
    
Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--View_Export
Private Sub viewExport_DoExit()
    Const METHOD_NAME As String = "viewExport_DoExit"
    viewExport.Hide
End Sub
