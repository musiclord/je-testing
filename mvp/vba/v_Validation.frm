VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} v_Validation 
   Caption         =   "Step2 - Validation"
   ClientHeight    =   4410
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   4560
   OleObjectBlob   =   "v_Validation.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "v_Validation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "v_Validation"
' ----- 事件 -----
Public Event DoExit()


' ----- [ v_Validation ] -----
Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub



' ----- [ Custom ] -----
