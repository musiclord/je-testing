VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vScenario3 
   Caption         =   "情境-3"
   ClientHeight    =   3015
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   3768
   OleObjectBlob   =   "vScenario3.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "vScenario3"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Public Event Execute()
Public Event DoExit()

Private Sub btnExecute_Click()
    RaiseEvent Execute
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub
