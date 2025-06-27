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


' ----- [ c_Project ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME As String = ""
    Set m_config = New m_ManagerConfig
    Set m_context = New m_ManagerContext
    Set m_project = New m_ManagerProject
    Set viewProject = New v_Project
    m_root = ThisWorkbook.path
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME As String = ""
End Sub

Public Function Build(ByRef config As m_ManagerConfig, ByRef context As m_ManagerContext) As Boolean
    Const METHOD_NAME As String = "Build"
    Build = False
    
    ' 傳 vbModal 來鎖住程序
    viewProject.Show (vbModal)
    
    ' 藉由傳址將物件指向專案實例，拋回 c_App
    Set config = m_config
    Set context = m_context
    Build = True
End Function

' ----- [ v_Project ] -----
Private Sub viewProject_DoNew()
    Const METHOD_NAME As String = "viewProject_DoNew"
    ' 取得文字欄輸入為新專案名稱
    Dim projectName As String
    projectName = viewProject.txtbProjectName.value
    ' 建立專案
    If Not m_project.Create(projectName, m_root) Then
        MsgBox "創建專案失敗。", vbExclamation, "創建專案"
        Exit Sub
    End If
    
    viewProject.Hide
    
End Sub

Private Sub viewProject_DoSelect()
    Const METHOD_NAME As String = "viewProject_DoSelect"
    ' 取得清單選取值為專案名稱
    Dim projectName As String
    projectName = viewProject.listProjects.value
    ' 載入專案
    If Not m_project.Load(projectName, m_root) Then
        MsgBox "載入專案失敗", vbExclamation, "載入專案"
        Exit Sub
    End If
    
    viewProject.Hide
    
End Sub
