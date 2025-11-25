VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewMain 
   Caption         =   "JET VBA Tool"
   ClientHeight    =   7000
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   10000
   OleObjectBlob   =   "ViewMain.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ViewMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' ViewMain.frm
' Main Dashboard

Private Sub UserForm_Initialize()
    ' Check if project is loaded
    UpdateUI
End Sub

Private Sub UpdateUI()
    ' Update labels/buttons based on state
    If App.g_Context Is Nothing Then
        lblStatus.Caption = "Not Initialized"
    ElseIf App.g_Context.DbAccess Is Nothing Then
        lblStatus.Caption = "No Project Open"
    Else
        lblStatus.Caption = "Project Open"
    End If
End Sub

Private Sub btnNewProject_Click()
    ViewProject.Show
    UpdateUI
End Sub

Private Sub btnImport_Click()
    ViewImport.Show
End Sub

Private Sub btnExit_Click()
    Unload Me
End Sub
