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
' Purpose:  處理共享元件的服務，藉由依賴注入給其他類別使用，例如 DAL 和 CTX
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "m_ManagerContext"

' === 變數 ===
Private dal As i_dal

