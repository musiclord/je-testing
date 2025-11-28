VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CoreContext"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Core
' Name:     Context
' Purpose:  應用程式上下文容器 (IoC Container)。
'           集中管理核心依賴項 (Logger、DbAccess、DbSchema)，
'           並持有專案組態資訊 (專案名稱、客戶、會計期間等)。
'===============================================================================

'-- Core Dependencies
Private m_Logger As CoreLogger
Private m_Db As DbAccess
Private m_DbSchema As DbSchema

'-- Project Configuration
Private m_ProjectName As String
Private m_ClientName As String
Private m_CompanyName As String
Private m_PeriodStart As Date
Private m_PeriodEnd As Date
Private m_PrepStart As Date
Private m_PrepEnd As Date

'===============================================================================
' Initialization
'===============================================================================
Public Sub Initialize()
    ' 初始化核心物件
    Set m_Logger = New CoreLogger
    
    Set m_Db = New DbAccess
    
    Set m_DbSchema = New DbSchema
    
End Sub


'===============================================================================
' Properties - Core Dependencies
'===============================================================================
Public Property Get logger() As CoreLogger
    If m_Logger Is Nothing Then
        Set m_Logger = New CoreLogger
        m_Logger.Initialize
    End If
End Property

Public Property Set DbAccess(ByVal p_Value As DbAccess)
    Set m_Db = p_Value
End Property

Public Property Get DbAccess() As DbAccess
    Set DbAccess = m_Db
End Property

Public Property Get DbSchema() As DbSchema
    If m_DbSchema Is Nothing Then
        Set m_DbSchema = New DbSchema
        'm_DbSchema.Initialize
    End If
    Set DbSchema = m_DbSchema
End Property
