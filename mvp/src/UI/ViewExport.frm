VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewExport 
   Caption         =   "Export Reports"
   ClientHeight    =   4000
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   6000
   OleObjectBlob   =   "ViewExport.frx":0000
   StartUpPosition =   1  'CenterOwner
End
Attribute VB_Name = "ViewExport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

' ViewExport.frm
' Handles Report Generation

Private m_ServiceExport As ServiceExport

Private Sub UserForm_Initialize()
    Set m_ServiceExport = New ServiceExport
    m_ServiceExport.Initialize App.g_Context
End Sub

Private Sub btnLeadSchedule_Click()
    m_ServiceExport.GenerateLeadSchedule "JE_Data", "AccountMapping"
    MsgBox "Lead Schedule Generated!", vbInformation
End Sub

Private Sub btnRawData_Click()
    ' Export raw table
    Dim rs As Object
    Set rs = App.g_Context.DbAccess.ExecuteQuery("SELECT * FROM JE_Data")
    m_ServiceExport.ExportToSheet rs, "Raw Data"
    MsgBox "Raw Data Exported!", vbInformation
End Sub
