VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewProject 
   Caption         =   "Project Management"
   ClientHeight    =   4000
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   6000
   OleObjectBlob   =   "ViewProject.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ViewProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' ViewProject.frm

Private Sub btnCreate_Click()
    Dim name As String
    Dim client As String
    Dim pEnd As Date
    
    name = txtProjectName.Text
    client = txtClientName.Text
    pEnd = CDate(txtPeriodEnd.Text)
    
    ' Call ServiceProject
    ' ServiceProject.CreateProject ...
    MsgBox "Project Creation Logic", vbInformation
End Sub
