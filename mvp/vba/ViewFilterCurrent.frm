VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewFilterCurrent 
   Caption         =   "篩選條件"
   ClientHeight    =   5520
   ClientLeft      =   108
   ClientTop       =   408
   ClientWidth     =   7032
   OleObjectBlob   =   "ViewFilterCurrent.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewFilterCurrent"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Form:     ViewFilterCurrent
' Purpose:
' Methods:
'===============================================================================
Public Event OverviewCriteria()
Public Event Submitted(dto As DataTransferObject)
'--
Private m_Sql As String

Public Sub Initialize()
    '...
End Sub

Private Sub btnCustomSQL_Click()
    m_Sql = ""
End Sub

Private Sub btnExecute_Click()
    '...
End Sub

Private Sub btnOverview_Click()
    '...
    RaiseEvent OverviewCriteria
End Sub

Private Sub btnAddCriteria_Click()
    '...
End Sub

Private Sub btnAddPreset_Click()
    '...
End Sub

Private Sub btnRemoveCondition_Click()
    '...
End Sub

Private Sub btnRemovePreset_Click()
    '...
End Sub


Private Sub btnExit_Click()
    '...
    '檢查並驗證
    '...
    Dim dto As New DataTransferObject
    '...
    Me.Hide
    Unload Me
    RaiseEvent Submitted(dto)
End Sub

