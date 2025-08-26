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
Private Const MODULE_Name As String = "Context"

Private m_dbPbc As DbAccess
Private m_dbData As DbAccess
Private m_dbResult As DbAccess

Private m_gl As EntityGl
Private m_tb As EntityTb

Private m_Name

'---
Public Property Get Name() As String
    Name = m_Name
End Property
Public Property Let Name(ByVal value As String)
    m_Name = value
End Property

'---
Public Property Get dbPbc() As DbAccess
    Set dbPbc = m_dbPbc
End Property
Public Property Set dbPbc(ByVal db As DbAccess)
    Set m_dbPbc = db
End Property

Public Property Get dbData() As DbAccess
    Set dbData = m_dbData
End Property
Public Property Set dbData(ByVal db As DbAccess)
    Set m_dbData = db
End Property

Public Property Get dbResult() As DbAccess
    Set dbResult = m_dbResult
End Property
Public Property Set dbResult(ByVal db As DbAccess)
    Set m_dbResult = db
End Property

'---
Public Property Get gl() As EntityGl
    Set gl = m_gl
End Property

Public Property Get tb() As EntityTb
    Set tb = m_tb
End Property

'---
Private Sub Class_Initialize()
    Set m_dbPbc = New DbAccess
    Set m_dbData = New DbAccess
    Set m_dbResult = New DbAccess
    Set m_gl = New EntityGl
    Set m_tb = New EntityTb
    
End Sub

