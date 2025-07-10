VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ManagerContext"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ManagerContext
' Purpose:  處理共享元件的服務，藉由依賴注入給其他類別使用
'===============================================================================
Private Const MODULE_NAME As String = "m_ManagerContext"
' ----- 成員 -----
Private m_Project As m_ManagerProject
Private m_Config As m_ManagerConfig
Private m_dal As i_dal
Private m_dal_Sql As dal_Sql
Private m_dal_Ace As dal_Access
' ----- 屬性 -----
Public Property Get Project() As m_ManagerProject
    Set Project = m_Project
End Property
Public Property Set Project(ByVal p_Project As m_ManagerProject)
    Set m_Project = p_Project
End Property

Public Property Get Config() As m_ManagerConfig
    Set Config = m_Config
End Property
Public Property Set Config(ByVal p_Config As m_ManagerConfig)
    Set m_Config = p_Config
End Property
Public Property Get Dal() As i_dal

End Property



Private Sub Class_Initialize()
    Const METHOD_NAME = "Class_Initialize"
    Set m_Project = New m_ManagerProject
    Set m_Config = New m_ManagerConfig
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME = "Class_Terminate"
End Sub
