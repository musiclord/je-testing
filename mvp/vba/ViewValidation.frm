VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewValidation 
   Caption         =   "驗證資料"
   ClientHeight    =   5085
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   2115
   OleObjectBlob   =   "ViewValidation.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Form:     ViewValidation
' Purpose:
' Methods:
'===============================================================================
Public Event Completeness()
Public Event DocumentBalance()
Public Event INF()
Public Event NullRecords()
Public Event Submitted(ByVal dto As DataTransferObject)

Public Sub Initialize()
    '...
End Sub

Private Sub btnCompleteness_Click()
    RaiseEvent Completeness
End Sub

Private Sub btnDocumentBalance_Click()
    RaiseEvent DocumentBalance
End Sub

Private Sub btnINF_Click()
    RaiseEvent INF
End Sub

Private Sub btnNullRecords_Click()
    RaiseEvent NullRecords
End Sub

Private Sub btnConfigureAccountMapping_Click()
    '科目配對
    Dim ws As Worksheet
    Set ws = AccountMappingSheet
    ws.Activate
    '清空並初始化
    ws.Cells.Clear
    ws.Columns("A").NumberFormat = "@"
    ws.Columns("B").NumberFormat = "@"
    ws.Columns("C").NumberFormat = "@"
    ws.Range("A1").Value = "Account Number"
    ws.Range("B1").Value = "Account Name"
    ws.Range("C1").Value = "Standardized Class"
    ws.Range("A1:C1").Font.Bold = True
End Sub

Private Sub btnExit_Click()
    Dim dto As DataTransferObject
    Me.Hide
    RaiseEvent Submitted(dto)
End Sub
