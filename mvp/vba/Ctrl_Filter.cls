VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Filter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Filter"
'===============================================================================
' Module:   Ctrl_Filter
' Purpose:  篩選功能控制器，管理資料篩選條件設定和執行
' Layer:    Controller
' Domain:   Data Filtering
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_FilterService As Svc_Filter
'--事件表單
Private WithEvents viewFilter As View_Filter
Attribute viewFilter.VB_VarHelpID = -1



'--Ctrl_Filter
Public Sub Initialize(ByRef Config As Mgr_Config, ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_cfg = Config
    Set m_ctx = Context
    '實例化
    Set m_FilterService = New Svc_Filter
    Set viewFilter = New View_Filter
End Sub

Public Function Execute() As Dictionary
    Const METHOD_NAME As String = ""
    On Error GoTo ErrorHandler
    
    Dim result As Dictionary
    Set result = New Dictionary
    viewFilter.Show vbModeless
    '檢查處理狀態
    result.Add "run_criteria", True '執行篩選條件
    result.Add "validate_criteria", True '核對篩選結果
    
    Set Execute = result
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function


'--View_Filter
Private Sub viewFilter_DoExit()
    Const METHOD_NAME As String = "viewFilter_DoExit"
    viewFilter.Hide
End Sub
