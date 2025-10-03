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
' Purpose: 上下文管理器，用於在各模組間傳遞專案運作所需的物件
'===============================================================================
Private m_DbInput As DbAccess
Private m_DbValid As DbAccess
Private m_Info As EntityInfo
Private m_Je As EntityJe
Private m_Tb As EntityTb

'***** 屬性
'存放原始資料的資料庫
Public Property Get DbInput() As DbAccess
    Set DbInput = m_DbInput
End Property
Public Property Set DbInput(ByVal db As DbAccess)
    Set m_DbInput = db
End Property

'存放驗證資料的資料庫
Public Property Get DbValid() As DbAccess
    Set DbValid = m_DbValid
End Property
Public Property Set DbValid(ByVal db As DbAccess)
    Set m_DbValid = db
End Property

'存放篩選資料的資料庫
Public Property Get DbCriteria() As DbAccess
End Property
Public Property Set DbCriteria(ByVal db As DbAccess)
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

'***** 方法
Public Sub Initialize()
    Set m_DbInput = New DbAccess
    Set m_DbValid = New DbAccess
    Set m_Je = New EntityJe
    Set m_Tb = New EntityTb
    Set m_Info = New EntityInfo
End Sub
