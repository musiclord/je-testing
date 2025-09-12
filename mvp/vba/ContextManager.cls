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
'Class:ContextManager
Private m_DbInput As DbAccess
Private m_DbValid As DbAccess
Private m_Info As EntityInfo
Private m_Je As EntityJe
Private m_Tb As EntityTb

'***** ÄÝ©Ê
Public Property Get DbInput() As DbAccess
    Set DbInput = m_DbInput
End Property
Public Property Set DbInput(ByVal db As DbAccess)
    Set m_DbInput = db
End Property

Public Property Get DbValid() As DbAccess
    Set DbValid = m_DbValid
End Property
Public Property Set DbValid(ByVal db As DbAccess)
    Set m_DbValid = db
End Property

Public Property Get je() As EntityJe
    Set je = m_Je
End Property

Public Property Get tb() As EntityTb
    Set tb = m_Tb
End Property

Public Property Get info() As EntityInfo
    Set info = m_Info
End Property

'***** ¤èªk
Public Sub Initialize()
    Set m_DbInput = New DbAccess
    Set m_DbValid = New DbAccess
    Set m_Je = New EntityJe
    Set m_Tb = New EntityTb
    Set m_Info = New EntityInfo
End Sub
