VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImport 
   Caption         =   "Import"
   ClientHeight    =   8640.001
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   8295.001
   OleObjectBlob   =   "ViewImport.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewImport
Public Event ImportJournalEntries(ByVal format As String)
Public Event ImportTrialBalance(ByVal format As String)
Public Event JeFieldMappingRequested()
Public Event TbFieldMappingRequested()
Public Event UpdateDateDimensionRequested()
Public Event TestDefaultRequested() '僅作測試用途
Public Event Submitted(ByVal dto As DataTransferObject)

Private m_format As String

Public Sub Initialize()
    Me.optXlsx.Value = True
    Me.chkSaturday.Value = True
    Me.chkSunday.Value = True
    Call optXlsx_Click
End Sub

Private Sub btnConfigureCalendar_Click()
    ' 在工作表中匯入非工作日
    RaiseEvent UpdateDateDimensionRequested
End Sub

Private Sub btnImportJe_Click()
    '激活事件來開啟資料庫匯入精靈
    RaiseEvent ImportJournalEntries(m_format)
End Sub

Private Sub btnImportTb_Click()
    '激活事件來開啟資料庫匯入精靈
    RaiseEvent ImportTrialBalance(m_format)
End Sub

Private Sub btnMapJe_Click()
    RaiseEvent JeFieldMappingRequested
End Sub

Private Sub btnMapTb_Click()
    RaiseEvent TbFieldMappingRequested
End Sub

Private Sub btnExit_Click()
    '檢查必填欄位
    Dim errors As Collection
    Set errors = New Collection
    
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
    dto.Monday = Me.chkMonday.Value
    dto.Tuesday = Me.chkTuesday.Value
    dto.Wednesday = Me.chkWednesday.Value
    dto.Thursday = Me.chkThursday.Value
    dto.Friday = Me.chkFriday.Value
    dto.Saturday = Me.chkSaturday.Value
    dto.Sunday = Me.chkSunday.Value
    Me.Hide
    RaiseEvent Submitted(dto)
End Sub

Private Sub btnTestDefault_Click()
    '##### FOR DEBUG TESTING #####
    Me.txtbCompanyName.Text = "台塑寧波"
    Me.txtbPeriodStart.Text = "2024/01/01"
    Me.txtbPeriodEnd.Text = "2024/12/31"
    Me.txtbPrepStartDate = "2024/12/31"
    Me.chkSaturday.Value = True
    Me.chkSunday.Value = True
    RaiseEvent TestDefaultRequested
End Sub

Private Sub optCsv_Click()
    m_format = "csv"
End Sub

Private Sub optXlsx_Click()
    m_format = "xlsx"
End Sub
