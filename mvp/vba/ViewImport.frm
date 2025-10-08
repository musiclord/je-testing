VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImport 
   Caption         =   "Import"
   ClientHeight    =   6735
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   8145
   OleObjectBlob   =   "ViewImport.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewImport
Public Event ImportJe(ByVal format As String)
Public Event ImportTb(ByVal format As String)
Public Event MapJe()
Public Event MapTb()
Public Event TestDefaultRequested() '僅作測試用途
Public Event Confirm(ByVal dto As DataTransferObject)

Private m_format As String

Public Sub Initialize()
    Me.optXlsx.Value = True
    Call optXlsx_Click
End Sub

Private Sub btnImportJe_Click()
    '...
    RaiseEvent ImportJe(m_format)
End Sub

Private Sub btnImportTb_Click()
    '...
    RaiseEvent ImportTb(m_format)
End Sub

Private Sub btnMapJe_Click()
    '...
    RaiseEvent MapJe
End Sub

Private Sub btnMapTb_Click()
    '...
    RaiseEvent MapTb
End Sub

Private Sub btnExit_Click()
    Dim dto As New DataTransferObject
    dto.CompanyName = CStr(Me.txtbCompanyName.Value)
    dto.PeriodStart = CDate(Me.txtbPeriodStart.Value)
    dto.PeriodEnd = CDate(Me.txtbPeriodEnd.Value)
    dto.PrepStartDate = CDate(Me.txtbPrepStartDate.Value)
    dto.Monday = Me.chkMonday.Value
    dto.Tuesday = Me.chkTuesday.Value
    dto.Wednesday = Me.chkWednesday.Value
    dto.Thursday = Me.chkThursday.Value
    dto.Friday = Me.chkFriday.Value
    dto.Saturday = Me.chkSaturday.Value
    dto.Sunday = Me.chkSunday.Value
    Me.Hide
    RaiseEvent Confirm(dto)
End Sub

Private Sub btnTestDefault_Click()
    '##### FOR DEBUG TESTING #####
    Me.txtbCompanyName.Text = "台塑寧波"
    Me.txtbPeriodStart.Text = "2024/01/01"
    Me.txtbPeriodEnd.Text = "2024/12/31"
    Me.txtbPrepStartDate = "2024/12/31"
    Me.chkSaturday.Value = True
    Me.chkSunday.Value = True
    RaiseEvent TestDefaultRequested
End Sub

Private Sub optCsv_Click()
    m_format = "csv"
End Sub

Private Sub optXlsx_Click()
    m_format = "xlsx"
End Sub
