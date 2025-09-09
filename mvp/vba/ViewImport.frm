VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImport 
   Caption         =   "Import"
   ClientHeight    =   5652
   ClientLeft      =   108
   ClientTop       =   408
   ClientWidth     =   8148
   OleObjectBlob   =   "ViewImport.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "ViewImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewImport
Public Event ImportGl()
Public Event ImportTb()
Public Event MapGl()
Public Event MapTb()
Public Event Complete()
Public Event FormatGl(ByVal format As String)
Public Event FormatTb(ByVal format As String)

Public Sub Initialize()
    Me.optGlXlsx.Value = True
    Call optGlXlsx_Click
    Me.optTbXlsx.Value = True
    Call optTbXlsx_Click
End Sub

Private Sub btnImportGl_Click()
    '...
    RaiseEvent ImportGl
End Sub

Private Sub btnImportTb_Click()
    '...
    RaiseEvent ImportTb
End Sub

Private Sub btnMapGl_Click()
    '...
    RaiseEvent MapGl
End Sub

Private Sub btnMapTb_Click()
    '...
    RaiseEvent MapTb
End Sub

Private Sub btnExit_Click()
    Me.Hide
    RaiseEvent Complete
End Sub

Private Sub btnTestDefault_Click()
    'THIS Method IS FOR DEBUG TESTING
    Me.PeriodStart.text = "2024/01/01"
    Me.PeriodEnd.text = "2024/12/31"
    Me.chkSaturday.Value = True
    Me.chkSunday.Value = True
End Sub


Private Sub optGlXlsx_Click()
    RaiseEvent FormatGl("excel")
End Sub

Private Sub optGlCsv_Click()
    RaiseEvent FormatGl("csv")
End Sub

Private Sub optTbXlsx_Click()
    RaiseEvent FormatTb("excel")
End Sub

Private Sub optTbCsv_Click()
    RaiseEvent FormatTb("csv")
End Sub

