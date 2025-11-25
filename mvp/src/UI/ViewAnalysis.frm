VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewAnalysis 
   Caption         =   "Analysis & Mapping"
   ClientHeight    =   6000
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   9000
   OleObjectBlob   =   "ViewAnalysis.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ViewAnalysis"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' ViewAnalysis.frm
' Handles Account Mapping and Filter Definition

Private m_ServiceMapping As ServiceAccountMapping
Private m_ServiceFilter As ServiceFilter

Private Sub UserForm_Initialize()
    Set m_ServiceMapping = New ServiceAccountMapping
    m_ServiceMapping.Initialize App.g_Context
    
    Set m_ServiceFilter = New ServiceFilter
    m_ServiceFilter.Initialize App.g_Context
    
    LoadUnmappedAccounts
End Sub

Private Sub LoadUnmappedAccounts()
    Dim rs As Object
    Set rs = m_ServiceMapping.GetUnmappedAccounts("JE_Data")
    
    ' Populate ListBox
    ' lstUnmapped.Clear
    ' Do While Not rs.EOF
    '     lstUnmapped.AddItem rs.Fields("AccountCode").Value & " - " & rs.Fields("AccountName").Value
    '     rs.MoveNext
    ' Loop
End Sub

Private Sub btnSaveMapping_Click()
    ' Get selected unmapped account and map it
    ' m_ServiceMapping.SaveMapping ...
    MsgBox "Mapping Saved (Placeholder)", vbInformation
End Sub

Private Sub btnApplyFilter_Click()
    ' Build criteria from UI
    ' Dim criteria As String
    ' criteria = m_ServiceFilter.BuildCriteria("Amount", ">", 1000)
    ' MsgBox "Filter Applied: " & criteria
End Sub
