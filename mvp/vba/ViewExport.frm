VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewExport 
   Caption         =   "輸出結果"
   ClientHeight    =   5295
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   6420
   OleObjectBlob   =   "ViewExport.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewExport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewExport
Public Event ExportWp()
Public Event ValidationReport()


Public Sub Initialize()
    '...
End Sub

Private Sub btnExportWp_Click()
    '輸出底稿於本機目錄
    RaiseEvent ExportWp
End Sub

Private Sub btnExit_Click()
    Me.Hide
End Sub

Private Sub btnValidationReport_Click()
    '預覽驗證報告
    RaiseEvent ValidationReport
End Sub
