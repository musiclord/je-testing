VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ValidationService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private context As ContextManager
Private db As DbAccess
Private gl As EntityGl
Private tb As EntityTb


Public Sub Initialize()
    'init
End Sub

Public Function Completeness()
    '
End Function
Public Function DocumentBalance()
    '
End Function
Public Function RDE()
    'Relevant Data Element
    'INF Sampling
End Function
