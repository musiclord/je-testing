VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:ServiceValidation
Private db As DbAccess

Public Sub Initialize(ByRef context As ContextManager)
    Set db = context.DbValid
End Sub
Public Function Completeness() As Boolean
    
End Function
    
Public Function DocumentBalance() As Boolean

End Function

Public Function RDE() As Boolean
    
End Function


