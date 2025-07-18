VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Import"
'===============================================================================
' Module:   Ctrl_Import
' Purpose:  匯入功能控制器，協調檔案匯入流程和錯誤處理
' Layer:    Controller
' Domain:   Import Processing
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ImportService As Svc_Import
'--事件表單
Private WithEvents viewImport As View_Import
Attribute viewImport.VB_VarHelpID = -1



'--Ctrl_Import
Public Sub Initialize(ByRef Config As Mgr_Config, ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_cfg = Config
    Set m_ctx = Context
    '實例化
    Set m_ImportService = New Svc_Import
    Set viewImport = New View_Import
End Sub

Public Function Execute() As Dictionary
    Const METHOD_NAME As String = "Execute"
    On Error GoTo ErrorHandler
    
    Dim result As Dictionary
    Set result = New Dictionary
    viewImport.Show vbModeless
    '檢查處理狀態
    result.Add "import_gl", True
    result.Add "import tb", True
    result.Add "import_holiday", True
    
    Set Execute = result
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--View_Import
Private Sub viewImport_DoExit()
    Const METHOD_NAME As String = "viewImport_DoExit"
    viewImport.Hide
End Sub

Private Sub viewImport_ImportGL()
    Const METHOD_NAME As String = "viewImport_ImportGL"
    
    Dim filePath As String
    '選取CSV路徑
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 使用者取消操作。"
        Exit Sub
    End If
    '匯入資料表
    If Not m_ImportService.ImportGL(filePath) Then
        MsgBox "資料匯入失敗", vbCritical, "匯入GL"
    End If
End Sub

Private Sub viewImport_ImportTB()
    Const METHOD_NAME As String = "viewImport_ImportTB"
    
    Dim filePath As String
    '選取CSV路徑
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 使用者取消操作。"
        Exit Sub
    End If
    '匯入資料表
    If Not m_ImportService.ImportTB(filePath) Then
        MsgBox "資料匯入失敗", vbCritical, "匯入TB"
    End If
End Sub

Private Sub viewImport_ApplyGL()
    Const METHOD_NAME As String = "viewImport_ApplyGL"
End Sub

Private Sub viewImport_ApplyTB()
    Const METHOD_NAME As String = "viewImport_ApplyTB"
End Sub
