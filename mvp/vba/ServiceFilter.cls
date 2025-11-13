VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceFilter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class:    ServiceFilter
' Purpose:  管理篩選條件作業的服務

'===============================================================================
Private m_Db As DbAccess
Private m_Context As ContextManager

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbValid
    Set m_Context = context
End Sub
