VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vScenario1 
   Caption         =   "情境-1"
   ClientHeight    =   5010
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   4752
   OleObjectBlob   =   "vScenario1.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "vScenario1"
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
