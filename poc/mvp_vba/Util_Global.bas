Attribute VB_Name = "Util_Global"
Option Explicit

Public Sub ShowProgress( _
        currentValue As Long, _
        maxValue As Long, _
        Optional message As String = "處理中..." _
    )
    '具體命名，避免和VBA資源衝突
    Dim percentage As Double
    If maxValue > 0 Then
        percentage = (currentValue / maxValue) * 100
        '更新狀態列
        Application.StatusBar = message & " " & Format(currentValue, "#,##0") & " / " & Format(maxValue, "#,##0") & " (" & Format(percentage, "0.0") & "%)"
        DoEvents
    End If
End Sub

Public Sub PreventFreeze()
    ' 停用不必要的功能
    Application.ScreenUpdating = False
    Application.EnableEvents = False
    Application.Calculation = xlCalculationManual
    Application.DisplayAlerts = False
End Sub

Public Sub RestoreExcel()
    ' 恢復功能
    Application.ScreenUpdating = True
    Application.EnableEvents = True
    Application.Calculation = xlCalculationAutomatic
    Application.DisplayAlerts = True
    Application.StatusBar = False
End Sub

Public Function GetProjectDirectories() As Collection
    Const METHOD_NAME As String = "GetProjectDirectories"
    Dim projects As New Collection
    Dim root As String, folder As String, path As String
    '掃描目錄
    root = ThisWorkbook.path
    folder = Dir(root & "\*", vbDirectory)
    Do While folder <> ""
        '排除系統及隱藏目錄
        If folder <> "." And folder <> ".." Then
            path = root & "\" & folder
            If (GetAttr(path) And vbDirectory) = vbDirectory Then
                projects.Add (folder)
            End If
        End If
        folder = Dir
    Loop
    Set GetProjectDirectories = projects
End Function



