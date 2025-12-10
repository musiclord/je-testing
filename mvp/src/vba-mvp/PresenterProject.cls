VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "PresenterProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Presenter
' Name:     Project
' Purpose:  專案管理展示器。
'           處理專案建立、開啟、儲存等操作的 UI 事件，
'           協調 View 與 CoreProject 之間的互動。
'===============================================================================
Private WithEvents v_Project As ViewProject
Attribute v_Project.VB_VarHelpID = -1
Private m_Context As CoreContext
Private m_Project As CoreProject
Private m_Logger As CoreLogger

Public Sub Initialize()
    m_Project.Initialize m_Context
End Sub

Private Sub v_Project_CreateProjectRequested(ByVal p_ProjectName As String)
    m_Project.CreateProject p_ProjectName
End Sub

Private Sub v_Project_LoadProjectRequested(ByVal p_ProjectName As String)
    m_Project.LoadProject p_ProjectName
End Sub
