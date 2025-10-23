VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImport 
   Caption         =   "Import"
   ClientHeight    =   8430.001
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   7155
   OleObjectBlob   =   "ViewImport.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Form:     ViewImport
' Purpose:
' Methods:
'===============================================================================
Public Event ImportJournalEntries(ByVal Format As String)
Public Event ImportTrialBalance(ByVal Format As String)
Public Event JeFieldMappingRequested()
Public Event TbFieldMappingRequested()
Public Event UpdateDateDimensionRequested()
Public Event TestDefaultRequested() '僅作測試用途
Public Event Submitted(ByVal dto As DataTransferObject)
'--
Private m_Weekend As Collection
Private m_Format As String

Public Sub Initialize()
    '預設匯入格式為 XLSX
    Me.optXlsx.Value = True
    Call optXlsx_Click
    '預設非工作日清單
    With Me.lstWeekend
        .AddItem "Sunday"       '1
        .AddItem "Monday"       '2
        .AddItem "Tuesday"      '3
        .AddItem "Wednesday"    '4
        .AddItem "Thursday"     '5
        .AddItem "Friday"       '6
        .AddItem "Saturday"     '7
        '預設選取周日和周六
        .Selected(0) = True
        .Selected(6) = True
    End With
End Sub

Private Sub btnConfigureCalendar_Click()
    ' 將所有日期覆寫
    '//TODO:要先檢查所有日期(Holiday, MakeUpDay, Weekend)的狀態
    RaiseEvent UpdateDateDimensionRequested
End Sub

Private Sub btnApplyDateConfig_Click()
    '收集並套用日期設定
    Dim MakeupDayDates As New Collection
    Dim HolidayDates As New Collection
    
    'RaiseEvent UpdateDateDimensionRequested
End Sub

Private Sub btnConfigureHoliday_Click()
    Dim ws As Worksheet
    Set ws = HolidaySheet
    '開啟工作表讓用戶填入假期資料
    ws.Activate
    '清空並初始化
    ws.Cells.Clear
    ws.Columns("A").NumberFormat = "m/d/yyyy"   '簡短日期
    ws.Columns("B").NumberFormat = "@"          '文字
    ws.Range("A1").Value = "Date"
    ws.Range("B1").Value = "Description"
    ws.Range("A1:B1").Font.Bold = True
End Sub

Private Sub btnConfigureMakeUpDay_Click()
    Dim ws As Worksheet
    Set ws = MakeupDaySheet
    '開啟工作表讓用戶填入補班日資料
    ws.Activate
    '清空並初始化
    ws.Cells.Clear
    ws.Columns("A").NumberFormat = "m/d/yyyy"   '簡短日期
    ws.Columns("B").NumberFormat = "@"          '文字
    ws.Range("A1").Value = "Date"
    ws.Range("B1").Value = "Description"
    ws.Range("A1:B1").Font.Bold = True
End Sub

Private Sub btnConfigureWeekend_Click()
    '設定非工作日
    Dim weekendIndices As New Collection
    Dim i As Long
    For i = 0 To Me.lstWeekend.ListCount - 1
        If Me.lstWeekend.Selected(i) Then
            weekendIndices.Add i + 1
        End If
    Next i
    Set m_Weekend = weekendIndices
    Debug.Print "m_Weekend.Count: " & m_Weekend.Count
End Sub

Private Sub btnImportJe_Click()
    '激活事件來開啟資料庫匯入精靈
    RaiseEvent ImportJournalEntries(m_Format)
End Sub

Private Sub btnImportTb_Click()
    '激活事件來開啟資料庫匯入精靈
    RaiseEvent ImportTrialBalance(m_Format)
End Sub

Private Sub btnMapJe_Click()
    RaiseEvent JeFieldMappingRequested
End Sub

Private Sub btnMapTb_Click()
    RaiseEvent TbFieldMappingRequested
End Sub

Private Sub btnExit_Click()
    '檢查必填欄位
    Dim errors As New Collection
    If Trim(Me.txtbCompanyName.Value & "") = "" Then
        errors.Add "請填寫公司名稱"
    End If
    If Trim(Me.txtbPeriodStart.Value & "") = "" Then
        errors.Add "請填寫會計期間開始日"
    ElseIf Not IsDate(Me.txtbPeriodStart.Value) Then
        errors.Add "會計期間開始日格式錯誤，請使用 yyyy/mm/dd 格式"
    End If
    If Trim(Me.txtbPeriodEnd.Value & "") = "" Then
        errors.Add "請填寫會計期間結束日"
    ElseIf Not IsDate(Me.txtbPeriodEnd.Value) Then
        errors.Add "會計期間結束日格式錯誤，請使用 yyyy/mm/dd 格式"
    End If
    If Trim(Me.txtbPrepStartDate.Value & "") = "" Then
        errors.Add "請填寫財報準備期間開始日"
    ElseIf Not IsDate(Me.txtbPrepStartDate.Value) Then
        errors.Add "財報準備期間開始日格式錯誤，請使用 yyyy/mm/dd 格式"
    End If
    '顯示錯誤訊息(若有)
    If errors.Count > 0 Then
        Dim errMsg As String
        Dim i As Long
        errMsg = "請修正以下問題:" & vbCrLf & vbCrLf
        For i = 1 To errors.Count
            errMsg = errMsg & i & ". " & errors(i) & vbCrLf
        Next i
        MsgBox errMsg, vbExclamation, "資料設定失敗"
        Exit Sub
    End If
    '驗證資料邏輯
    If CDate(Me.txtbPeriodStart.Value) > CDate(Me.txtbPeriodEnd.Value) Then
        MsgBox "會計期間開始日不能晚於結束日", vbExclamation, "日期邏輯錯誤"
        Me.txtbPeriodStart.SetFocus
        Exit Sub
    End If
    '組裝 DTO 物件以回傳資料
    Dim dto As New DataTransferObject
    dto.CompanyName = CStr(Me.txtbCompanyName.Value)
    dto.PeriodStart = CDate(Me.txtbPeriodStart.Value)
    dto.PeriodEnd = CDate(Me.txtbPeriodEnd.Value)
    dto.PrepStartDate = CDate(Me.txtbPrepStartDate.Value)
    Me.Hide
    RaiseEvent Submitted(dto)
End Sub

Private Sub btnTestDefault_Click()
    '//WARNING: ONLY FOR TESTING
    '填上假期
    Call btnConfigureHoliday_Click
    Dim ws As Worksheet
    Set ws = HolidaySheet
    ws.Range("A2").Value = DateSerial(2024, 10, 12)
    ws.Range("B2").Value = "國慶日"
    ws.Columns("A:B").AutoFit
    '填上補班日
    Call btnConfigureMakeUpDay_Click
    Set ws = MakeupDaySheet
    ws.Range("A2").Value = DateSerial(2024, 11, 4)
    ws.Range("B2").Value = "補班日"
    ws.Columns("A:B").AutoFit
    '填上控制項
    Me.txtbCompanyName.Text = "台塑寧波"
    Me.txtbPeriodStart.Text = "2024/01/01"
    Me.txtbPeriodEnd.Text = "2024/12/31"
    Me.txtbPrepStartDate = "2024/12/31"
    RaiseEvent TestDefaultRequested
End Sub

Private Sub optCsv_Click()
    m_Format = "csv"
End Sub

Private Sub optXlsx_Click()
    m_Format = "xlsx"
End Sub
