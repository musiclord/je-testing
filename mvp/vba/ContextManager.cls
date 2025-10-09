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
Private m_DbCriteria As DbAccess
Private m_DbReport As DbAccess
Private m_Info As EntityInfo
Private m_Je As EntityJe
Private m_Tb As EntityTb

'***** 屬性
'輸入資料
Public Property Get DbInput() As DbAccess
    Set DbInput = m_DbInput
End Property
Public Property Set DbInput(ByVal db As DbAccess)
    Set m_DbInput = db
End Property

'驗證資料
Public Property Get DbValid() As DbAccess
    Set DbValid = m_DbValid
End Property
Public Property Set DbValid(ByVal db As DbAccess)
    Set m_DbValid = db
End Property

'篩選資料
Public Property Get DbCriteria() As DbAccess
    Set DbCriteria = m_DbCriteria
End Property
Public Property Set DbCriteria(ByVal db As DbAccess)
    Set m_DbCriteria = db
End Property

'報告資料
Public Property Get DbReport() As DbAccess
    Set DbReport = m_DbReport
End Property
Public Property Set DbReport(ByVal db As DbAccess)
    Set m_DbReport = db
End Property

'JE資料實體
Public Property Get je() As EntityJe
    Set je = m_Je
End Property

'TB資料實體
Public Property Get tb() As EntityTb
    Set tb = m_Tb
End Property

'專案資訊資料實體
Public Property Get info() As EntityInfo
    Set info = m_Info
End Property

'***** 方法
Public Sub Initialize()
    Set m_DbInput = New DbAccess
    Set m_DbValid = New DbAccess
    Set m_DbCriteria = New DbAccess
    Set m_DbReport = New DbAccess
    Set m_Je = New EntityJe
    Set m_Tb = New EntityTb
    Set m_Info = New EntityInfo
End Sub
