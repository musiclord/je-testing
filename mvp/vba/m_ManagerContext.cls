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
Private m_DalConfig As i_dal
Private m_DalPbc As i_dal
Private m_DalData As i_dal
Private m_DalResult As i_dal

' ----- 屬性 -----
' Project
Public Property Get Project() As m_ManagerProject
    Set Project = m_Project
End Property
Public Property Set Project(ByVal p_Project As m_ManagerProject)
    Set m_Project = p_Project
End Property
' Config
Public Property Get Config() As m_ManagerConfig
    Set Config = m_Config
End Property
Public Property Set Config(ByVal p_Config As m_ManagerConfig)
    Set m_Config = p_Config
End Property
' DalConfig
Public Property Get DalConfig() As i_dal
    Set DalConfig = m_DalConfig
End Property
' DalPbc
Public Property Get DalPbc() As i_dal
    Set DalPbc = m_DalPbc
End Property
' DalData
Public Property Get DalData() As i_dal
    Set DalData = m_DalData
End Property
' DalResult
Public Property Get DalResult() As i_dal
    Set DalResult = m_DalResult
End Property


Private Sub Class_Initialize()
    Const METHOD_NAME = "Class_Initialize"
    ' 初始化類別物件
    Set m_Project = New m_ManagerProject
    Set m_Config = New m_ManagerConfig
    ' 初始化資料庫連線
    Set m_DalConfig = New dal_Access
    Set m_DalPbc = New dal_Access
    Set m_DalData = New dal_Access
    Set m_DalResult = New dal_Access
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME = "Class_Terminate"
End Sub

Public Function InitializeDatabases(ByVal projectPath As String) As Boolean
    m_DalConfig.path = projectPath & "\config.accdb"
    m_DalPbc.path = projectPath & "\pbc.accdb"
    m_DalData.path = projectPath & "\data.accdb"
    m_DalResult.path = projectPath & "\result.accdb"
End Function
