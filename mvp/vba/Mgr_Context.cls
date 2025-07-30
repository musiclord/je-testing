VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Mgr_Context"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Mgr_Context"
'===============================================================================
' Module:   Mgr_Context
' Purpose:  上下文管理器，維護應用程式執行期間的狀態和資源
' Layer:    Infrastructure
' Domain:   Context Management
'===============================================================================

'--類別成員
Private m_DalConfig As I_Dal
Private m_DalPbc As I_Dal
Private m_DalData As I_Dal
Private m_DalResult As I_Dal
Private m_gl As Ent_GL
Private m_tb As Ent_TB

'--屬性
'------------------|DalConfig
Public Property Get DalConfig() As I_Dal
    Set DalConfig = m_DalConfig
End Property
Public Property Set DalConfig(ByVal dal As I_Dal)
    Set m_DalConfig = dal
End Property
'------------------|DalPbc
Public Property Get DalPbc() As I_Dal
    Set DalPbc = m_DalPbc
End Property
Public Property Set DalPbc(ByVal dal As I_Dal)
    Set m_DalPbc = dal
End Property
'------------------|DalData
Public Property Get DalData() As I_Dal
    Set DalData = m_DalData
End Property
Public Property Set DalData(ByVal dal As I_Dal)
    Set m_DalData = dal
End Property
'------------------|DalResult
Public Property Get DalResult() As I_Dal
    Set DalResult = m_DalResult
End Property
Public Property Set DalResult(ByVal dal As I_Dal)
    Set m_DalResult = dal
End Property
'------------------|GL
Public Property Get gl() As Ent_GL
    Set gl = m_gl
End Property
'------------------|TB
Public Property Get tb() As Ent_TB
    Set tb = m_tb
End Property



'--Mgr_Context
Public Sub Initialize()
    Const METHOD_NAME As String = "Initialize"
    
    Set m_DalConfig = New I_Dal
    Set m_DalPbc = New I_Dal
    Set m_DalData = New I_Dal
    Set m_DalResult = New I_Dal
    Set m_gl = New Ent_GL
    Set m_tb = New Ent_TB
    
    Debug.Print "Mgr_Context Initialized."
End Sub

