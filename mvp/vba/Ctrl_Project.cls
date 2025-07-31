VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ctrl_Project"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ctrl_Project"
'===============================================================================
' Module:   Ctrl_Project
' Purpose:  專案管理控制器，處理專案的建立、選擇與管理操作
' Layer:    Controller
' Domain:   Project Management
'===============================================================================


'--類別成員
Private m_ProjectManager As Mgr_Project
'--事件表單
Private WithEvents viewProject As View_Project
Attribute viewProject.VB_VarHelpID = -1


'--Ctrl_Project
Public Sub Initialize(ByRef ProjectManager As Mgr_Project)
    Const METHOD_NAME As String = "Initialize"
    Set m_ProjectManager = ProjectManager
    Set viewProject = New View_Project
End Sub

Public Function Build() As Boolean
    Const METHOD_NAME As String = "Build"
    On Error GoTo Errorhandler
    
    Build = False
    '取得專案目錄
    Dim projects As Collection
    Set projects = GetProjectDirectories()
    '更新表單控制項
    If Not viewProject.UpdateProjects(projects) Then
        MsgBox "更新控制項失敗。", vbExclamation, "更新控制項"
        Exit Function
    End If
    '開啟表單
    viewProject.Show vbModal
    '待表單關閉後返回狀態
    Build = True
    Exit Function
    
Errorhandler:
    Build = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function


'--View_Project
Private Sub viewProject_DoExit()
    viewProject.Hide
End Sub

Private Sub viewProject_NewProject()
    Const METHOD_NAME As String = "viewProject_SelectProject"
    
    Dim name As String, path As String
    '取得專案路徑
    name = viewProject.txtbProjectName.value
    path = ThisWorkbook.path & "\" & name
    '創建專案
    If Not m_ProjectManager.Create(name, path) Then
        MsgBox "創建專案失敗。", vbExclamation, "專案設置"
    End If
    viewProject.Hide
End Sub

Private Sub viewProject_SelectProject()
    Const METHOD_NAME As String = "viewProject_SelectProject"
    Dim name As String, path As String
    '取得專案路徑
    name = viewProject.listProjects.value
    path = ThisWorkbook.path & "\" & name
    '載入專案
    If Not m_ProjectManager.Load(name, path) Then
        MsgBox "載入專案失敗。", vbExclamation, "專案設置"
    End If
    viewProject.Hide
End Sub
