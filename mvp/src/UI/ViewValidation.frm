VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewValidation 
   Caption         =   "Data Validation"
   ClientHeight    =   6000
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   9000
   OleObjectBlob   =   "ViewValidation.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ViewValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' ViewValidation.frm
' Shows validation results

Private m_Service As ServiceValidation

Private Sub UserForm_Initialize()
    Set m_Service = New ServiceValidation
    m_Service.Initialize App.g_Context
End Sub

Private Sub btnRunBalanceCheck_Click()
    Dim rs As Object
    Set rs = m_Service.CheckBalance("JE_Data") ' Assuming table name
    
    If rs Is Nothing Then
        MsgBox "Error running check", vbCritical
        Exit Sub
    End If
    
    If rs.EOF Then
        MsgBox "No unbalanced entries found.", vbInformation
    Else
        MsgBox "Found unbalanced entries!", vbExclamation
        ' Populate ListBox or Grid
    End If
End Sub

Private Sub btnRunIntegrityCheck_Click()
    Dim rs As Object
    Set rs = m_Service.CheckIntegrity("JE_Data", "TB_Data")
    
    If rs.EOF Then
        MsgBox "Integrity Check Passed.", vbInformation
    Else
        MsgBox "Found missing accounts in TB!", vbExclamation
    End If
End Sub
