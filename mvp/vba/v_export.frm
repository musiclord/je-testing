VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} v_Export 
   Caption         =   "Export WP"
   ClientHeight    =   3015
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   4560
   OleObjectBlob   =   "v_export.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "v_export"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "v_Export"
' ----- 事件 -----
Public Event DoExit()



' ----- [ v_Export ] -----
Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub



' ----- [ Custom ] -----
