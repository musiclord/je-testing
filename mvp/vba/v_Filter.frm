VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} v_Filter 
   Caption         =   "Filter Criteria"
   ClientHeight    =   3015
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   4560
   OleObjectBlob   =   "v_Filter.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "v_Filter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "v_Filter"
' ----- 事件 -----
Public Event DoExit()



' ----- [ v_Filter ] -----
Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub



' ----- [ Custom ] -----
