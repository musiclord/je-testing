VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ServiceValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ServiceValidation
' Purpose:  驗證程序服務，應優先使用 DAL 操作資料庫，再考慮 M 語言操作 PowerQuery
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "m_ServiceValidation"

