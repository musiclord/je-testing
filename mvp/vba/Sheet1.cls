Option Explicit

Private app As c_App

Private Sub btnLaunch_Click()
    Set app = New c_App
    Call app.Launch
End Sub
