VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ManagerConfig"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ManagerConfig
' Purpose:  處理程式所有控制項的組態，並由資料庫R/W，專門處理表單控制項的資料
'           例如:儲存當前專案控制項的狀態，並在下次載入時還原。
'===============================================================================
Private Const MODULE_NAME As String = "m_ManagerConfig"


