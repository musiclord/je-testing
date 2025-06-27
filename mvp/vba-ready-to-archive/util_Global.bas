Attribute VB_Name = "util_Global"
Option Explicit

' === 管理員 ===
Private m_context As m_ManagerContext
Private m_config As m_ManagerConfig

' === 控制器 ===
Private project As c_Project
Private app As c_Main

' === 主要接口 ===
Public Sub RunApplication()
    ' ...
    Set project = New c_Project
    If project.Initialize(m_context, m_config) Then Return ' 用 ByRef 傳址來直接修改
    Set app = New c_Main
    Call app.Run(m_context, m_config) ' 用 ByVal 傳值來代入副本
End Sub
