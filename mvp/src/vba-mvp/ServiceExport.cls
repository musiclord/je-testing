VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceExport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Service
' Name:     Export
' Purpose:  報表匯出服務。
'           將驗證結果與異常明細輸出為 Excel 底稿，
'           產生符合審計需求的測試報告。
'===============================================================================

'--
Private m_Context As CoreContext
Private m_Db As DbAccess

Public Sub Initialize(ByVal p_Context As CoreContext)
    Set m_Context = p_Context
    Set m_Db = p_Context.DbAccess
End Sub

