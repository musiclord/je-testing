VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImport 
   Caption         =   "Import"
   ClientHeight    =   5655
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   8145
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
Public Event ImportJe()
Public Event ImportTb()
Public Event MapJe()
Public Event MapTb()
Public Event Complete()
Public Event FormatJe(ByVal format As String)
Public Event FormatTb(ByVal format As String)

Public Sub Initialize()
    Me.optJeXlsx.value = True
    Call optJeXlsx_Click
    Me.optTbXlsx.value = True
    Call optTbXlsx_Click
End Sub

Private Sub btnImportJe_Click()
    '...
    RaiseEvent ImportJe
End Sub

Private Sub btnImportTb_Click()
    '...
    RaiseEvent ImportTb
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
    Me.Hide
    RaiseEvent Complete
End Sub

Private Sub btnTestDefault_Click()
    'THIS Method IS FOR DEBUG TESTING
    Me.PeriodStart.text = "2024/01/01"
    Me.PeriodEnd.text = "2024/12/31"
    Me.chkSaturday.value = True
    Me.chkSunday.value = True
End Sub


Private Sub optJeXlsx_Click()
    RaiseEvent FormatJe("excel")
End Sub

Private Sub optJeCsv_Click()
    RaiseEvent FormatJe("csv")
End Sub

Private Sub optTbXlsx_Click()
    RaiseEvent FormatTb("excel")
End Sub

Private Sub optTbCsv_Click()
    RaiseEvent FormatTb("csv")
End Sub

