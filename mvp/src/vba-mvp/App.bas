Attribute VB_Name = "App"
Option Explicit
'===============================================================================
' Layer:    Global
' Name:     App
' Purpose:  應用程式進入點與全域上下文管理。
'           提供 Main() 進入點、Bootstrap 初始化流程，
'           以及全域 CoreContext 實例的生命週期控制。
'===============================================================================
 
Public g_Context As CoreContext
 
Public Sub Main()
    ' Entry point for the application
    Call Bootstrap
    
End Sub

Public Sub Bootstrap()
    If g_Context Is Nothing Then
        Set g_Context = New CoreContext
        g_Context.Initialize
    End If
End Sub

Public Sub ResetApp()
    Set g_Context = Nothing
End Sub
