Option Explicit
Private app As App_Bootstrap

Private Sub btnLaunch_Click()
    Set app = New App_Bootstrap
    app.Launch
End Sub
