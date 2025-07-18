VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} View_Import 
   Caption         =   "Import"
   ClientHeight    =   7020
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   12360
   OleObjectBlob   =   "View_Import.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "View_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Event DoExit()
Public Event ApplyGL()
Public Event ApplyTB()
Public Event ImportGL()
Public Event ImportTB()

Private Sub btnApplyGL_Click()
    RaiseEvent ApplyGL
End Sub

Private Sub btnApplyTB_Click()
    RaiseEvent ApplyTB
End Sub

Private Sub btnImportGL_Click()
    RaiseEvent ImportGL
End Sub

Private Sub btnImportTB_Click()
    RaiseEvent ImportTB
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub


