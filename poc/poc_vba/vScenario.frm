VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vScenario 
   Caption         =   "Scenarios"
   ClientHeight    =   3795
   ClientLeft      =   108
   ClientTop       =   456
   ClientWidth     =   3000
   OleObjectBlob   =   "vScenario.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "vScenario"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Event RunCase1()
Public Event RunCase2()
Public Event RunCase3()
Public Event DoExit()

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub

Private Sub btnScenario1_Click()
    RaiseEvent RunCase1
End Sub

Private Sub btnScenario2_Click()
    RaiseEvent RunCase2
End Sub

Private Sub btnScenario3_Click()
    RaiseEvent RunCase3
End Sub
