Attribute VB_Name = "App"
Option Explicit

' App.bas
' Application Entry Point and Global State

Public g_Context As ContextManager

Public Sub Main()
    ' Entry point for the application
    Bootstrap
    
    ' Show Main View
    ' ViewMain.Show
    MsgBox "JET VBA MVP Framework Initialized.", vbInformation
End Sub

Public Sub Bootstrap()
    If g_Context Is Nothing Then
        Set g_Context = New ContextManager
        g_Context.Initialize
    End If
End Sub

Public Sub ResetApp()
    Set g_Context = Nothing
End Sub
