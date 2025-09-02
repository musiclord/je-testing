VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewFilter 
   Caption         =   "篩選條件"
   ClientHeight    =   5520
   ClientLeft      =   108
   ClientTop       =   408
   ClientWidth     =   7032
   OleObjectBlob   =   "ViewFilter.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewFilter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewFilter
Public Event OverviewCriteria()

Public Sub Initialize()
    '...
End Sub

Private Sub btnOverview_Click()
    '...
    RaiseEvent OverviewCriteria
End Sub

Private Sub btnExit_Click()
    Me.Hide
    Unload Me
End Sub
