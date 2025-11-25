Attribute VB_Name = "Main"
Option Explicit

'===============================================================================
' Module: Main
' Purpose: Application Entry Point and Global State Management
'
' Usage:
'   JET_Main - Start the application
'   GetGlobalContext - Access singleton context
'   JET_Cleanup - Release resources
'===============================================================================

' Global application state
Private g_Context As ContextManager
Private g_AppSettings As Object  ' Scripting.Dictionary

'===============================================================================
' Application Entry Point
'===============================================================================

Public Sub JET_Main()
    '---------------------------------------------------------------------------
    ' Main application entry point
    ' Initializes global context and shows main navigation form
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ' Welcome message
    Debug.Print String(80, "=")
    Debug.Print "JET VBA - Journal Entry Testing Tool"
    Debug.Print "Version 1.0.0"
    Debug.Print "Starting application..."
    Debug.Print String(80, "=")
    
    ' Initialize global context (singleton pattern)
    If g_Context Is Nothing Then
        Set g_Context = New ContextManager
        Debug.Print "✓ Context Manager initialized"
    End If
    
    ' Initialize app settings
    If g_AppSettings Is Nothing Then
        Set g_AppSettings = CreateObject("Scripting.Dictionary")
        Call LoadAppSettings
        Debug.Print "✓ Settings loaded"
    End If
    
    ' Show main form
    ViewMain.Show vbModeless
    Debug.Print "✓ Main form displayed"
    
    Exit Sub
    
ErrorHandler:
    MsgBox "Application startup failed:" & vbCrLf & _
           Err.Description, vbCritical, "JET VBA Error"
    Debug.Print "✗ Startup error: " & Err.Description
End Sub

'===============================================================================
' Global Context Access
'===============================================================================

Public Function GetGlobalContext() As ContextManager
    '---------------------------------------------------------------------------
    ' Returns the singleton ContextManager instance
    ' Creates it if it doesn't exist
    '---------------------------------------------------------------------------
    If g_Context Is Nothing Then
        Set g_Context = New ContextManager
    End If
    Set GetGlobalContext = g_Context
End Function

Public Function GetAppSettings() As Object
    '---------------------------------------------------------------------------
    ' Returns the application settings dictionary
    '---------------------------------------------------------------------------
    If g_AppSettings Is Nothing Then
        Set g_AppSettings = CreateObject("Scripting.Dictionary")
        Call LoadAppSettings
    End If
    Set GetAppSettings = g_AppSettings
End Function

'===============================================================================
' Application Cleanup
'===============================================================================

Public Sub JET_Cleanup()
    '---------------------------------------------------------------------------
    ' Release resources and save settings
    '---------------------------------------------------------------------------
    On Error Resume Next
    
    ' Save settings
    Call SaveAppSettings
    
    ' Close active project
    If Not g_Context Is Nothing Then
        If g_Context.HasActiveProject Then
            g_Context.CloseProject
        End If
    End If
    
    ' Release references
    Set g_Context = Nothing
    Set g_AppSettings = Nothing
    
    Debug.Print "✓ Application cleaned up"
End Sub

'===============================================================================
' Settings Management
'===============================================================================

Private Sub LoadAppSettings()
    '---------------------------------------------------------------------------
    ' Load application settings from registry or config file
    '---------------------------------------------------------------------------
    On Error Resume Next
    
    ' Default settings
    g_AppSettings.Add "RecentProjectsMax", 5
    g_AppSettings.Add "AutoSaveInterval", 300  ' seconds
    g_AppSettings.Add "LastProjectPath", ""
    g_AppSettings.Add "DefaultOutputFormat", "Excel"
    
    ' TODO: Load from registry or config file
    ' For now, using defaults
    
End Sub

Private Sub SaveAppSettings()
    '---------------------------------------------------------------------------
    ' Save application settings to registry or config file
    '---------------------------------------------------------------------------
    On Error Resume Next
    
    ' TODO: Implement persistent storage
    ' For now, settings are session-only
    
End Sub

'===============================================================================
' Utility Functions
'===============================================================================

Public Function GetVersion() As String
    '--------------------------------------------------------------------------- 
    ' Returns the application version string
    '---------------------------------------------------------------------------
    GetVersion = "1.0.0"
End Function

Public Function GetRecentProjects() As Collection
    '---------------------------------------------------------------------------
    ' Returns collection of recent project paths
    '---------------------------------------------------------------------------
    Dim projects As New Collection
    
    ' TODO: Load from persistent storage
    ' For now, return empty collection
    
    Set GetRecentProjects = projects
End Function

Public Sub AddRecentProject(ByVal projectPath As String)
    '---------------------------------------------------------------------------
    ' Add a project to the recent projects list
    '---------------------------------------------------------------------------
    ' TODO: Implement recent projects tracking
End Sub
