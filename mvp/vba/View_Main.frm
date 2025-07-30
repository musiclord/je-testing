VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} View_Main 
   Caption         =   "Main"
   ClientHeight    =   5412
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   9765.001
   OleObjectBlob   =   "View_Main.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "View_Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME As String = "View_Main"
'===============================================================================
' Module:   View_Main
' Purpose:  主程式介面
' Layer:    View
' Domain:   Main
'===============================================================================

Public Event DoExit()
Public Event DoStep1()
Public Event DoStep2()
Public Event DoStep3()
Public Event DoStep4()

Private Sub btnDoStep1_Click()
    RaiseEvent DoStep1
End Sub

Private Sub btnDoStep2_Click()
    RaiseEvent DoStep2
End Sub

Private Sub btnDoStep3_Click()
    RaiseEvent DoStep3
End Sub

Private Sub btnDoStep4_Click()
    RaiseEvent DoStep4
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub
