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
' Purpose:  定義處理篩選條件的服務
' Methods:
'===============================================================================
Private db As DbAccess

Public Sub Initialize(context As ContextManager)
    Set db = context.DbValid
End Sub

