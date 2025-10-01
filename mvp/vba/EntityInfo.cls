VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "EntityInfo"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: EntityInfo
' Purpose: 用來處理專案所需各類資訊的資料實體
'===============================================================================
'--使用者資訊
Private m_WSHnet As WshNetwork
Private m_UserName As String
Private m_UserDomain As String
Private m_UserFullName As String
Private m_UserObject As Object
'-- 專案資訊
Private m_CompanyName As String
Private m_PeriodStart As Date
Private m_PeriodEnd As Date
'--工作日設定
Private m_Monday As Boolean
Private m_Tuesday As Boolean
Private m_Wednesday As Boolean
Private m_Thursday As Boolean
Private m_Friday As Boolean
Private m_Saturday As Boolean
Private m_Sunday As Boolean


Public Sub Initialize()
    Set m_WSHnet = New WshNetwork
    Set m_UserObject = GetObject("WinNT://" & m_UserDomain & "/" & m_UserName & ",user")
    '取得使用者名稱與網域
    Let m_UserName = m_WSHnet.UserName
    Let m_UserDomain = m_WSHnet.UserDomain
    Let m_UserFullName = m_UserObject.FullName
    If m_UserFullName = "" Then m_UserFullName = m_UserName
End Sub


'***** 屬性訪問
Public Property Get UserName() As String
    Let UserName = m_UserName
End Property

Public Property Get UserFullName() As String
    Let UserFullName = m_UserFullName
End Property

Public Property Get PeriodStart() As Date
    Let PeriodStart = m_PeriodStart
End Property
Public Property Let PeriodStart(ByVal Value As Date)
    Let m_PeriodStart = Value
End Property

Public Property Get PeriodEnd() As Date
    Let PeriodEnd = m_PeriodEnd
End Property
Public Property Let PeriodEnd(ByVal Value As Date)
    Let m_PeriodEnd = Value
End Property

Public Property Get CompanyName() As String
    Let CompanyName = m_CompanyName
End Property
Public Property Let CompanyName(ByVal Value As String)
    Let m_CompanyName = Value
End Property
