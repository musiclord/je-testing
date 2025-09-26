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
Public Event Complete(ByVal dtStart As Date, dtEnd As Date)

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
    Dim dtStart As Date, dtEnd As Date
    dtStart = CDate(Me.PeriodStart.Value)
    dtEnd = CDate(Me.PeriodEnd.Value)
    Me.Hide
    RaiseEvent Complete(dtStart, dtEnd)
End Sub

Private Sub btnTestDefault_Click()
    'THIS Method IS FOR DEBUG TESTING
    Me.txtbCompanyName.Text = "台塑寧波"
    Me.PeriodStart.Text = "2024/01/01"
    Me.PeriodEnd.Text = "2024/12/31"
    Me.chkSaturday.Value = True
    Me.chkSunday.Value = True
End Sub

Private Sub optCsv_Click()
    m_format = "csv"
End Sub

Private Sub optXlsx_Click()
    m_format = "xlsx"
End Sub
