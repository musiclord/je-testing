VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Logger"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' Logger.cls
' Simple logging utility to print to Immediate Window and optionally a log file

Private m_LogToFile As Boolean
Private m_LogFilePath As String

Public Sub Initialize(Optional ByVal logToFile As Boolean = False, Optional ByVal logFilePath As String = "")
    m_LogToFile = logToFile
    m_LogFilePath = logFilePath
    If m_LogToFile And m_LogFilePath = "" Then
        m_LogFilePath = ThisWorkbook.Path & "\jet_vba.log"
    End If
End Sub

Public Sub LogInfo(ByVal message As String)
    WriteLog "INFO", message
End Sub

Public Sub LogError(ByVal message As String, Optional ByVal errNumber As Long = 0)
    Dim msg As String
    msg = message
    If errNumber <> 0 Then
        msg = msg & " (Err: " & errNumber & ")"
    End If
    WriteLog "ERROR", msg
End Sub

Public Sub LogDebug(ByVal message As String)
    ' Only log debug in development? For now, always log.
    WriteLog "DEBUG", message
End Sub

Private Sub WriteLog(ByVal level As String, ByVal message As String)
    Dim timestamp As String
    timestamp = Format(Now, "yyyy-mm-dd hh:mm:ss")
    
    Dim logLine As String
    logLine = "[" & timestamp & "] [" & level & "] " & message
    
    ' Print to Immediate Window
    Debug.Print logLine
    
    ' Write to file if enabled
    If m_LogToFile Then
        On Error Resume Next ' Prevent logging from crashing the app
        Dim fso As Object
        Set fso = CreateObject("Scripting.FileSystemObject")
        Dim ts As Object
        Set ts = fso.OpenTextFile(m_LogFilePath, 8, True) ' 8 = ForAppending
        ts.WriteLine logLine
        ts.Close
        Set ts = Nothing
        Set fso = Nothing
        On Error GoTo 0
    End If
End Sub
