VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ManagerProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ManagerProject
' Purpose:  處理專案服務，依據指定專案資訊獨立出目錄及組態
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "m_ManagerProject"

' === 變數 ===
Private projectId As String
Private projectName As String
Private projectPath As String


Private CreateProject() '創建專案

Private LoadProject()   '載入專案

Private DeleteProject() '刪除專案


