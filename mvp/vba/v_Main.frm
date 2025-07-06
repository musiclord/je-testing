VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} v_Main 
   Caption         =   "Main"
   ClientHeight    =   5415
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   9660.001
   OleObjectBlob   =   "v_Main.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "v_Main"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Public Event DoExit()

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub

