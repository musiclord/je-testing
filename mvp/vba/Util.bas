Attribute VB_Name = "Util"
Private app As New Application

Sub launch()
    app.Run
End Sub

Sub LogError( _
    ByVal CLASSName As String, _
    ByVal procName As String, _
    ByVal errObj As ErrObject)
    Debug.Print CLASSName & "." & procName & ": " & _
                errObj.Number & " --> " & errObj.Description
End Sub

Sub PreventFreeze()
    '停用不必要的功能
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Application.Calculation = xlCalculationManual
    Application.DisplayAlerts = False
End Sub

Sub RestoreExcel()
    '恢復功能
    Application.ScreenUpdating = True
    Application.EnableEvents = True
    Application.Calculation = xlCalculationAutomatic
    Application.DisplayAlerts = True
    Application.StatusBar = False
End Sub
