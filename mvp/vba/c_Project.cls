VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_Project"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_Project
' Purpose:  開啟主程式前置作業，選取專案目標並設定組態
'===============================================================================
Private Const MODULE_NAME As String = "c_Project"
' ----- 表單事件 -----
Private WithEvents viewProject As v_Project
Attribute viewProject.VB_VarHelpID = -1
' ----- 成員 -----
Private m_Config As m_ManagerConfig
Private m_Context As m_ManagerContext
Private m_Project As m_ManagerProject
Private m_root As String
' ----- 屬性 -----
Public Property Get Config() As m_ManagerConfig
    Set Config = m_Config
End Property
Public Property Get Context() As m_ManagerContext
    Set Context = m_Context
End Property



' ----- [ c_Project ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME As String = "Class_Initialize"
    Set viewProject = New v_Project
    Set m_Config = New m_ManagerConfig
    Set m_Context = New m_ManagerContext
    Set m_Project = New m_ManagerProject
    m_root = ThisWorkbook.path
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME As String = "Class_Terminate"
End Sub

Public Function Build() As Boolean
    Const METHOD_NAME As String = "Build"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    Build = False
    '取得專案目錄清單
    Dim projects As Collection
    Set projects = GetProjectsList()
    '更新表單控制項
    viewProject.UpdateListProjects projects
    '傳 vbModal 來鎖住程序
    viewProject.Show (vbModal)  '<--[ v_Project ]
    '更新 m_Config 和 m_Context
    Set m_Context.Project = m_Project
    '返回狀態
    Build = True
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Function



' ----- [ v_Project ] -----
Private Sub viewProject_DoNew()
    Const METHOD_NAME As String = "viewProject_DoNew"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    '取得輸入
    Dim projectName As String
    Dim projectPath As String
    projectName = viewProject.txtbProjectName.Value
    projectPath = m_root & "\" & projectName
    m_Project.name = projectName
    m_Project.path = projectPath
    '建立專案
    If Not m_Project.Create Then
        MsgBox "創建專案失敗。", vbExclamation, "創建專案"
        Exit Sub
    End If
    viewProject.Hide
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub viewProject_DoSelect()
    Const METHOD_NAME As String = "viewProject_DoSelect"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    '取得輸入
    Dim projectName As String
    Dim projectPath As String
    projectName = viewProject.listProjects.Value
    projectPath = m_root & "\" & projectName
    m_Project.name = projectName
    m_Project.path = projectPath
    '載入專案
    If Not m_Project.Load Then
        MsgBox "載入專案失敗", vbExclamation, "載入專案"
        Exit Sub
    End If
    viewProject.Hide
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Function GetProjectsList() As Collection
    Const METHOD_NAME As String = "GetProjectsList"
    Dim projects As New Collection
    Dim folder As String
    Dim path As String
    '掃描專案目錄
    folder = Dir(m_root & "\*", vbDirectory)
    Do While folder <> ""
        '排除系統及隱藏目錄
        If folder <> "." And folder <> ".." Then
            path = m_root & "\" & folder
            '若路徑屬於目錄
            If (GetAttr(path) And vbDirectory) = vbDirectory Then
                projects.Add (folder)
            End If
        End If
        folder = Dir
    Loop
    Set GetProjectsList = projects
End Function
