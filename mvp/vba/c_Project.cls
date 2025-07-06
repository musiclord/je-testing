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

' ----- 常數 -----
Private Const MODULE_NAME As String = "c_Project"
' ----- 表單事件 -----
Private WithEvents viewProject As v_Project
Attribute viewProject.VB_VarHelpID = -1
' ----- 類別成員 -----
Private m_config As m_ManagerConfig
Private m_context As m_ManagerContext
Private m_project As m_ManagerProject
Private m_root As String

Public Property Get Config() As m_ManagerConfig
    Config = m_config
End Property

Public Property Get Context() As m_ManagerContext
    Context = m_context
End Property


' ----- [ c_Project ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME As String = "Class_Initialize"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    Set m_config = New m_ManagerConfig
    Set m_context = New m_ManagerContext
    Set m_project = New m_ManagerProject
    Set viewProject = New v_Project
    m_root = ThisWorkbook.path
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME As String = "Class_Terminate"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Public Function Build() As Boolean
    Const METHOD_NAME As String = "Build"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    Build = False
    
    '取得專案目錄清單
    Dim projects As Collection
    Set projects = GetProjectsList()
    ' 更新表單控制項
    viewProject.UpdateListProjects projects
    ' 傳 vbModal 來鎖住程序
    viewProject.Show (vbModal)
    ' 這裡應該要對新增的 m_config 和 m_context 做修改
    '...
    
    Build = True
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Function

' ----- [ v_Project ] -----
Private Sub viewProject_DoNew()
    Const METHOD_NAME As String = "viewProject_DoNew"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    ' 取得文字欄輸入為新專案名稱
    Dim projectName As String
    projectName = viewProject.txtbProjectName.value
    ' 建立專案
    If Not m_project.Create(projectName, m_root) Then
        MsgBox "創建專案失敗。", vbExclamation, "創建專案"
        Exit Sub
    End If
    
    viewProject.Hide
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub viewProject_DoSelect()
    Const METHOD_NAME As String = "viewProject_DoSelect"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    ' 取得清單選取值為專案名稱
    Dim projectName As String
    projectName = viewProject.listProjects.value
    ' 載入專案
    If Not m_project.Load(projectName, m_root) Then
        MsgBox "載入專案失敗", vbExclamation, "載入專案"
        Exit Sub
    End If
    
    viewProject.Hide
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Function GetProjectsList() As Collection
    Const METHOD_NAME As String = "GetProjectsList"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    Dim projects As New Collection
    Dim folder As String
    Dim path As String
    
    ' 掃描專案目錄
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
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
    
End Function
