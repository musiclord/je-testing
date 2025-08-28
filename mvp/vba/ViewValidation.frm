VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewValidation 
   Caption         =   "驗證資料"
   ClientHeight    =   3420
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   2205
   OleObjectBlob   =   "ViewValidation.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewValidation
Public Event Completeness()
Public Event DocumentBalance()
Public Event RDE()

Public Sub Initialize()
    '...
End Sub

Private Sub btnCompleteness_Click()
    RaiseEvent Completeness
End Sub

Private Sub btnDocumentBalance_Click()
    RaiseEvent DocumentBalance
End Sub

Private Sub btnRDE_Click()
    RaiseEvent RDE
End Sub

Private Sub btnExit_Click()
    Me.Hide
End Sub
