VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_Main
' Purpose:  莱ノ祘Α北竟
'===============================================================================

' === 盽计 ===
Private Const MODULE_NAME As String = "c_Main"

' === ざㄆン ===
Private WithEvents viewMain As v_Main
Attribute viewMain.VB_VarHelpID = -1

' === 北竟跑计 ===
Private ctrlImport As c_Import                  ' as Step1
Private ctrlValidation As c_Validation          ' as Step2
Private ctrlFilter As c_Filter                  ' as Step3
Private ctrlExport As c_Export                  ' as Step4

' --- c_Main ---
Private Sub Class_Initialize()
    Set viewMain = New v_Main
End Sub

Private Sub Class_Terminate()

End Sub

Public Sub Run()
    viewMain.Show (vbModeless)
End Sub

' --- v_Main ---
Private Sub viewMain_DoExit()
    Unload viewMain
    Set viewMain = Nothing
End Sub
