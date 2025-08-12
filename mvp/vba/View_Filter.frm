VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} View_Filter 
   Caption         =   "Filter"
   ClientHeight    =   3624
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   6576
   OleObjectBlob   =   "View_Filter.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "View_Filter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "View_FilterStratification"
'===============================================================================
' Module:   View_FilterStratification
' Purpose:  原本的 Account Mapping 負責將
' Layer:    View
' Domain:   Filter Stratification
'===============================================================================



Public Event DoExit()

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub
