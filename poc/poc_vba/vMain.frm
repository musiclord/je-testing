VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vMain 
   Caption         =   "vMain"
   ClientHeight    =   7410
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   10752
   OleObjectBlob   =   "vMain.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "vMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'View: Main
'Description: Where things begins...

Public Event DoStep1()
Public Event DoStep2()
Public Event DoStep3()
Public Event DoStep4()
Public Event DoExit()

Private Sub UserForm_Initialize()
    Me.Show (vbModeless)
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub

Private Sub btnGotoStep1_Click()
    RaiseEvent DoStep1
End Sub

Private Sub btnGotoStep2_Click()
    RaiseEvent DoStep2
End Sub

Private Sub btnGotoStep3_Click()
    RaiseEvent DoStep3
End Sub

Private Sub btnGotoStep4_Click()
    RaiseEvent DoStep4
End Sub


