VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewValidation 
   Caption         =   "Validation"
   ClientHeight    =   3015
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   4560
   OleObjectBlob   =   "ViewValidation.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "ViewValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Event TestCompletess()
Public Event TestDocumentBalance()
Public Event TestRDE()
Public Event ExitForm()

Public Sub Initialize()
    'init
End Sub

Private Sub btnCompleteness_Click()
    RaiseEvent TestCompletess
End Sub
Private Sub btnDocumentBalance_Click()
    RaiseEvent TestDocumentBalance
End Sub
Private Sub btnRDE_Click()
    RaiseEvent TestRDE
End Sub
Private Sub btnExit_Click()
    RaiseEvent ExitForm
End Sub
