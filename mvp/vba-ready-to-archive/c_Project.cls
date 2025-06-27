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

' Set project.Name = "AAA"
' ./jet/AAA/
' ./jet/AAA/config.accdb    #stores configuration args
' ./jet/AAA/pbc.accdb       #stores GL and TB
' ./jet/AAA/valid.accdb     #stores validation result
' ./jet/AAA/result.accdb    #stores final results


Private Const ROOT = ThisWorkbook.Path

Private m_project As m_ManagerProject
Private m_context As m_ManagerContext
Private m_config As m_ManagerConfig

Private WithEvents viewProject As v_Project
Attribute viewProject.VB_VarHelpID = -1



Public Function Initialize(ByRef context As m_ManagerContext, ByRef config As m_ManagerConfig) As Boolean
    Initialize = False
    ' ...
    Set viewProject = New v_Project
    viewProject.Show (vbModal) 'LOCK
    ' ...
    context = m_context
    config = m_config
    Initialize = True
End Function

Private Sub viewProject_DoNew()
    
End Sub

Private Sub viewProject_DoSelect()

End Sub
' new / select project
' set path
' init db
' di to app

