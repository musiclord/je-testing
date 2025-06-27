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
' Purpose:  處理共享元件的服務，藉由依賴注入給其他類別使用，
'           例如:
'===============================================================================

' ----- 常數 -----
Private Const MODULE_NAME As String = "m_ManagerContext"

' ----- 類別成員 -----
Private project As m_ManagerProject
Private dal As i_dal
Private dalAce As dal_Access
Private dalSql As dal_Sql

Private Sub Class_Initialize()
    Set project = New m_ManagerProject
    Set dal = New i_dal
    Set dal = dalAce
End Sub

Private Sub Class_Terminate()

End Sub

' ----- 屬性 -----
Private m_base As String    ' 專案目錄
Public Property Let base(ByVal path As String)
    m_base = path
End Property
Public Property Get base() As String
    base = m_base
End Property

