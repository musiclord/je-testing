VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewFilterLegacy 
   Caption         =   "Legacy Filter"
   ClientHeight    =   8370.001
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   8880.001
   OleObjectBlob   =   "ViewFilterLegacy.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewFilterLegacy"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Event ExecuteCriterion()
Public Event ShowCriteria()
Public Event Submitted(ByVal dto As DataTransferObject)

Public Sub Initialize()
    '...
End Sub

Private Sub btnExecuteCriterion_Click()
    Dim cbo As MSForms.ComboBox
    
    If Me.chkPostedOnWeekend.Value Then
        '總帳日期在週末
    End If
    
    If Me.chkApprovedOnWeekend.Value Then
        '核准日期在週末
    End If
    
    If Me.chkPostedOnHoliday.Value Then
        '總帳日期在國定假日
    End If
    
    If Me.chkApprovedOnHoliday.Value Then
        '核准日期在國定假日
    End If
    
    If Me.chkExcludePostedOnMakeupDay.Value Then
        '需排除總帳日期在補班日/加班日
    End If
    
    If Me.chkExcludeApprovedOnMakeupDay.Value Then
        '需排除核准日期在補班日/加班日
    End If
    
    If Me.chkOnlyDebit.Value Then
        '僅考量借方傳票
    End If
    
    If Me.chkOnlyCredit.Value Then
        '僅考量貸方傳票
    End If
    
    If Me.chkSelectManualEntries.Value Then
        '篩選人工編制傳票
    End If
    
    If Me.chkKeywordFilter.Value Then
        '特定文字篩選
        Set cbo = Me.cboKeywordFilter
        Dim keyword As String
        keyword = Me.txtbKeywordFilter.Value
    End If
    
    If Me.chkDateRangeFilter.Value Then
        '特定日期區間
        Set cbo = Me.cboDateRangeFilter
        Dim dateRangeStart As String
        dateRangeStart = Me.txtbDateRangeStart
        Dim dateRangeEnd As String
        dateRangeEnd = Me.txtbDateRangeEnd
    End If
    
    If Me.chkNumericValueFilter.Value Then
        '特定數值區間
        Set cbo = Me.cboNumericValueFilter
        Dim numericValueStart As Long
        numericValueStart = CLng(Me.txtbNumericValueStart.Value)
        Dim numericValueEnd As Long
        numericValueEnd = CLng(Me.txtbNumericValueEnd.Value)
    End If
End Sub

Private Sub btnExit_Click()
    '...
    '檢查並驗證
    '...
    Dim dto As New DataTransferObject
    RaiseEvent Submitted(dto)
End Sub

Private Sub btnShowCriteria_Click()
    '...
    RaiseEvent ShowCriteria
End Sub

