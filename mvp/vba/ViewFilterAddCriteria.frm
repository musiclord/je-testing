VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewFilterAddCriteria 
   Caption         =   "新增條件"
   ClientHeight    =   3768
   ClientLeft      =   108
   ClientTop       =   408
   ClientWidth     =   5268
   OleObjectBlob   =   "ViewFilterAddCriteria.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewFilterAddCriteria"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Form:     ViewFilterAddCriteria
' Purpose:
' Methods:
'===============================================================================
Public Event AddCriteria()
Private m_S As String

Public Sub Initialize()
    '...
End Sub

Private Sub btnAdd_Click()
    RaiseEvent AddCriteria
End Sub
