VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewMain 
   Caption         =   "UserForm1"
   ClientHeight    =   5385
   ClientLeft      =   108
   ClientTop       =   408
   ClientWidth     =   9588.001
   OleObjectBlob   =   "ViewMain.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "ViewMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewMain
Public Event DoStep1()
Public Event DoStep2()
Public Event DoStep3()
Public Event DoStep4()
Public Event ExitApplication()

Public Sub Initialize(ByVal title As String)
    Me.Caption = title
End Sub

Private Sub btnDoStep1_Click()
    '...
    RaiseEvent DoStep1
End Sub

Private Sub btnDoStep2_Click()
    '...
    RaiseEvent DoStep2
End Sub

Private Sub btnDoStep3_Click()
    '...
    RaiseEvent DoStep3
End Sub

Private Sub btnDoStep4_Click()
    '...
    RaiseEvent DoStep4
End Sub

Private Sub btnExit_Click()
    Me.Hide
    Unload Me
    RaiseEvent ExitApplication
End Sub
