VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewMain 
   Caption         =   "Main"
   ClientHeight    =   5415
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   9768.001
   OleObjectBlob   =   "ViewMain.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "ViewMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit
Private Const MODULE_Name As String = "View_Main"
Public Event DoStep1()
Public Event DoStep2()
Public Event DoStep3()
Public Event DoStep4()

Public Sub Initialize()
    Const METHOD_Name As String = ".Initialize"
    
End Sub

Private Sub btnDoStep1_Click()
    Const METHOD_Name As String = ".btnDoStep1_Click"
    RaiseEvent DoStep1
End Sub

Private Sub btnDoStep2_Click()
    Const METHOD_Name As String = ".btnDoStep2_Click"
    RaiseEvent DoStep2
End Sub

Private Sub btnDoStep3_Click()
    Const METHOD_Name As String = ".btnDoStep3_Click"
    RaiseEvent DoStep3
End Sub

Private Sub btnDoStep4_Click()
    Const METHOD_Name As String = ".btnDoStep4_Click"
    RaiseEvent DoStep4
End Sub

Private Sub btnExit_Click()
    Const METHOD_Name As String = ".btnExit_Click"
    Me.Hide
End Sub

