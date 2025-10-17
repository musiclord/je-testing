VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "StateManager"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: StateManager
' Purpose: 管理專案執行流程的狀態（驗證測試、報表生成等）
'===============================================================================

'@TODO:用於儲存/讀取專案狀態的元件

Private m_Context As ContextManager
'--測試狀態
Private m_IsHolidayImported As Boolean
Private m_IsMakeupDayImported As Boolean
Private m_IsWorkdayImported As Boolean

Private m_IsCompletenessCheckCompleted As Boolean
Private m_IsDocumentBalanceCheckCompleted As Boolean
Private m_IsINFTestCompleted As Boolean

