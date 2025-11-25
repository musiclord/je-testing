VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ContextManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ContextManager
' Purpose: 應用程式上下文管理器 - 管理全局依賴注入與應用程式狀態
'
' Responsibilities:
'   - 管理 Logger, DbAccess, DbSchema 等核心物件
'   - 提供 ProjectInfo 配置存取
'   - 確保依賴物件的初始化順序
'   - 單例式管理（透過模組層級變數實現）
'
' Usage:
'   Dim ctx As New ContextManager
'   ctx.Initialize
'   ctx.OpenProject "C:\path\to\project.accdb"
'===============================================================================

'-- Core Dependencies
Private m_Logger As Logger
Private m_DbAccess As DbAccess
Private m_DbSchema As DbSchema

'-- Project Configuration
Private m_ProjectName As String
Private m_ClientName As String
Private m_PeriodStart As Date
Private m_PeriodEnd As Date
Private m_PrepStartDate As Date
Private m_PrepEndDate As Date
Private m_CompanyName As String

'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize()
    '初始化核心物件
    Set m_Logger = New Logger
    m_Logger.Initialize True, ThisWorkbook.Path & "\jet_vba.log"
    m_Logger.LogInfo "ContextManager initialized"
    
    '初始化 DbSchema（不需要 DbAccess 連線即可使用）
    Set m_DbSchema = New DbSchema
    m_DbSchema.Initialize Nothing, Nothing  ' 稍後透過 Mapper 設定 JE/TB
    
    '專案資訊初始化為空
    m_ProjectName = ""
    m_ClientName = ""
    m_CompanyName = ""
End Sub

Public Sub OpenProject(ByVal dbPath As String)
    '開啟專案資料庫
    If m_Logger Is Nothing Then Initialize
    
    Set m_DbAccess = New DbAccess
    m_DbAccess.Initialize dbPath, m_Logger
    m_DbAccess.Connect
    
    m_Logger.LogInfo "Project opened: " & dbPath
End Sub

Public Sub CloseProject()
    '關閉專案
    If Not m_DbAccess Is Nothing Then
        m_DbAccess.Disconnect
        Set m_DbAccess = Nothing
    End If
    
    If Not m_Logger Is Nothing Then
        m_Logger.LogInfo "Project closed"
    End If
End Sub

'===============================================================================
' Properties - Core Dependencies
'===============================================================================

Public Property Get Logger() As Logger
    If m_Logger Is Nothing Then
        Set m_Logger = New Logger
        m_Logger.Initialize
    End If
    Set Logger = m_Logger
End Property

Public Property Set DbAccess(ByVal value As DbAccess)
    Set m_DbAccess = value
End Property

Public Property Get DbAccess() As DbAccess
    Set DbAccess = m_DbAccess
End Property

Public Property Get DbSchema() As DbSchema
    If m_DbSchema Is Nothing Then
        Set m_DbSchema = New DbSchema
        m_DbSchema.Initialize Nothing, Nothing
    End If
    Set DbSchema = m_DbSchema
End Property

'===============================================================================
' Properties - Project Information
'===============================================================================

Public Property Get ProjectName() As String
    ProjectName = m_ProjectName
End Property

Public Property Let ProjectName(ByVal value As String)
    m_ProjectName = value
End Property

Public Property Get ClientName() As String
    ClientName = m_ClientName
End Property

Public Property Let ClientName(ByVal value As String)
    m_ClientName = value
End Property

Public Property Get CompanyName() As String
    CompanyName = m_CompanyName
End Property

Public Property Let CompanyName(ByVal value As String)
    m_CompanyName = value
End Property

Public Property Get PeriodStart() As Date
    PeriodStart = m_PeriodStart
End Property

Public Property Let PeriodStart(ByVal value As Date)
    m_PeriodStart = value
End Property

Public Property Get PeriodEnd() As Date
    PeriodEnd = m_PeriodEnd
End Property

Public Property Let PeriodEnd(ByVal value As Date)
    m_PeriodEnd = value
End Property

Public Property Get PrepStartDate() As Date
    PrepStartDate = m_PrepStartDate
End Property

Public Property Let PrepStartDate(ByVal value As Date)
    m_PrepStartDate = value
End Property

Public Property Get PrepEndDate() As Date
    PrepEndDate = m_PrepEndDate
End Property

Public Property Let PrepEndDate(ByVal value As Date)
    m_PrepEndDate = value
End Property

'===============================================================================
' Helper Methods
'===============================================================================

Public Function HasActiveProject() As Boolean
    '檢查是否有活動專案
    HasActiveProject = (Not m_DbAccess Is Nothing And m_DbAccess.IsConnected)
End Function

Public Function GetProjectSummary() As String
    '取得專案摘要資訊
    Dim summary As String
    summary = "Project: " & m_ProjectName & vbCrLf
    summary = summary & "Client: " & m_ClientName & vbCrLf
    summary = summary & "Period: " & Format(m_PeriodStart, "yyyy-mm-dd") & " to " & Format(m_PeriodEnd, "yyyy-mm-dd")
    GetProjectSummary = summary
End Function

'===============================================================================
' Cleanup
'===============================================================================

Private Sub Class_Terminate()
    Call CloseProject
    Set m_Logger = Nothing
    Set m_DbSchema = Nothing
End Sub
