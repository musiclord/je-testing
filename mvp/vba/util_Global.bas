Attribute VB_Name = "util_Global"
Option Explicit

Private application As c_Main

Public Sub RunApplication()
    Set application = New c_Main
    application.Run
End Sub
