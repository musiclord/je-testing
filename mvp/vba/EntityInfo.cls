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
'Class:EntityInfo
Private m_WSHnet As WshNetwork
Private m_UserName As String
Private m_UserDomain As String
Private m_UserFullName As String
Private m_UserObject As Object


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
