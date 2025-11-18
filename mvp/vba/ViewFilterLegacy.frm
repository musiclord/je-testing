VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewFilterLegacy 
   Caption         =   "Legacy Filter"
   ClientHeight    =   8370.001
   ClientLeft      =   120
   ClientTop       =   468
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
'===============================================================================
' Form:     ViewFilterLegacy
' Purpose:
' Methods:
'===============================================================================
Public Event ExecuteCriterion()
Public Event ShowCriteria()
Public Event Submitted(ByVal dto As DataTransferObject)

Public Sub Initialize()
    '...
End Sub

Private Sub btnExecuteCriterion_Click()
    Dim cbo As MSForms.ComboBox
    
    
    If Me.chkPostedOnWeekend.value Then
        '總帳日期在週末
        '查詢 DateDimension 建立 IN 條件
        
    End If
    
    If Me.chkApprovedOnWeekend.value Then
        '核准日期在週末
        '查詢 DateDimension 建立 IN 條件
    End If
    
    If Me.chkPostedOnHoliday.value Then
        '總帳日期在國定假日
        '查詢 DateDimension 建立 IN 條件
    End If
    
    If Me.chkApprovedOnHoliday.value Then
        '核准日期在國定假日
        '查詢 DateDimension 建立 IN 條件
    End If
    
    If Me.chkExcludePostedOnMakeupDay.value Then
        '需排除總帳日期在補班日/加班日
        '查詢 DateDimension 建立 IN 條件
    End If
    
    If Me.chkExcludeApprovedOnMakeupDay.value Then
        '需排除核准日期在補班日/加班日
        '查詢 DateDimension 建立 IN 條件
    End If
    
    If Me.chkOnlyDebit.value Then
        '僅考量借方傳票
        '根據 JE 的欄位標籤排除
    End If
    
    If Me.chkOnlyCredit.value Then
        '僅考量貸方傳票
        '根據 JE 的欄位標籤排除
    End If
    
    If Me.chkSelectManualEntries.value Then
        '篩選人工編制傳票
        '根據 JE 的欄位標籤排除
    End If
    
    If Me.chkKeywordFilter.value Then
        '特定文字篩選
        Set cbo = Me.cboKeywordFilter
        Dim keyword As String
        keyword = Me.txtbKeywordFilter.value
    End If
    
    If Me.chkDateRangeFilter.value Then
        '特定日期區間
        Set cbo = Me.cboDateRangeFilter
        Dim dateRangeStart As String
        dateRangeStart = Me.txtbDateRangeStart
        Dim dateRangeEnd As String
        dateRangeEnd = Me.txtbDateRangeEnd
    End If
    
    If Me.chkNumericValueFilter.value Then
        '特定數值區間
        Set cbo = Me.cboNumericValueFilter
        Dim numericValueStart As Long
        numericValueStart = CLng(Me.txtbNumericValueStart.value)
        Dim numericValueEnd As Long
        numericValueEnd = CLng(Me.txtbNumericValueEnd.value)
    End If
    
    RaiseEvent ExecuteCriterion
End Sub

Private Sub btnShowCriteria_Click()
    '...
    RaiseEvent ShowCriteria
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
