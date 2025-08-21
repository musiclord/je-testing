VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportPeriod 
   Caption         =   "匯入期間日期"
   ClientHeight    =   4455
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   8100
   OleObjectBlob   =   "ViewImportPeriod.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportPeriod"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Event Finish()


Private Sub btnFinish_Click()
    RaiseEvent Finish
End Sub

Private Sub btnTestTemplate_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Me.PeriodStart.Text = "2024/01/01"
    Me.PeriodEnd.Text = "2024/12/31"
    Me.chkSaturday.value = True
    Me.chkSunday.value = True
End Sub
