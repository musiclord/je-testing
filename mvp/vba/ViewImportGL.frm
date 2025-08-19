VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportGL 
   Caption         =   "匯入總帳"
   ClientHeight    =   9588.001
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   7752
   OleObjectBlob   =   "ViewImportGL.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportGL"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' GL
Option Explicit

Public Event ProcessMethod(ByVal method As Long)
Public Event ApplyFields(ByVal method As Long, ByVal fields As Dictionary)
Public Event Import(ByVal filepath As String)
Public Event NextStep()

Private m_fields As Dictionary
Private m_method As Long
Private m_file As String

Public Sub Initialize()
    Const METHOD_NAME As String = ".Initialize"
    DisableControls
End Sub

Private Sub btnNextStep_Click()
    RaiseEvent NextStep
End Sub

Private Sub btnSelectFile_Click()
    m_file = Application.GetOpenFilename()
    Me.lblFilePath.Caption = m_file
    Call UpdateFields(m_file)
    Debug.Print "GL: " & m_file
End Sub

Private Sub btnApply_Click()
    Set m_fields = GetFields()
    RaiseEvent ApplyFields(m_method, m_fields)
End Sub

Private Sub btnImport_Click()
    If m_file = "" Then
        MsgBox "尚未選取檔案路徑", vbCritical, "選取檔案"
        Exit Sub
    End If
    If m_fields Is Nothing Then
        MsgBox "尚未套用欄位設定", vbCritical, "套用欄位"
    End If
    
    RaiseEvent Import(m_file)
End Sub

Private Sub btnMethod1_Click()
    '1:僅傳票金額
    Call DisableControls
    Me.lblEntryAmount.ForeColor = RGB(0, 0, 0)
    Me.EntryAmount.Enabled = True
    m_method = 1
End Sub

Private Sub btnMethod2_Click()
    '2:分別借貸金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("DebitAmount", "CreditAmount")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_method = 2
End Sub

Private Sub btnMethod3_Click()
    '3:分借貸別
    Call DisableControls
    Dim n As Variant
    For Each n In Array("EntryAmount", "DrCr", "IsDebit")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_method = 3
End Sub




'--自訂方法
Private Sub btnTestTemplate_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Call btnMethod2_Click
    Me.AccountName.value = "會計科目"
    Me.AccountNumber.value = "傳票號碼"
    Me.DocumentNumber.value = "傳票號碼"
    Me.DebitAmount.value = "本幣借方金額"
    Me.CreditAmount.value = "本幣貸方金額"
    Me.EntryDescription.value = "摘要"
    Me.IsDebit.value = "借貸"
    Me.PostDate.value = "日期"
End Sub

Private Sub DisableControls()
    '關閉金額欄位處理之控制項
    Dim ctrls As Variant, n As Variant
    ctrls = Array( _
            "EntryAmount", "DrCr", "IsDebit", _
            "DebitAmount", "CreditAmount")
    For Each n In ctrls
        Me.Controls("lbl" & n).ForeColor = RGB(128, 128, 128)
        Me.Controls(n).Enabled = False
    Next n
End Sub

Private Function GetFields() As Dictionary
    Dim fields As New Dictionary
    '金額欄位
    fields("EntryAmount") = GetControlValue(Me.EntryAmount)
    fields("DebitAmount") = GetControlValue(Me.DebitAmount)
    fields("CreditAmount") = GetControlValue(Me.CreditAmount)
    fields("DrCr") = GetControlValue(Me.DrCr)
    fields("IsDebit") = GetControlValue(Me.IsDebit)
    '必選欄位
    fields("AccountNumber") = GetControlValue(Me.AccountNumber)
    fields("AccountName") = GetControlValue(Me.AccountName)
    fields("DocumentNumber") = GetControlValue(Me.DocumentNumber)
    fields("LineItem") = GetControlValue(Me.LineItem)
    fields("PostDate") = GetControlValue(Me.PostDate)
    fields("EntryDescription") = GetControlValue(Me.EntryDescription)
    '可選欄位
    fields("ApprovalDate") = GetControlValue(Me.ApprovalDate)
    fields("ApprovedBy") = GetControlValue(Me.ApprovedBy)
    fields("CreatedBy") = GetControlValue(Me.CreatedBy)
    fields("SourceModule") = GetControlValue(Me.SourceModule)
    fields("IsManual") = GetControlValue(Me.IsManual)
    fields("IsApprovedDateAsLedgerDate") = GetControlValue(Me.IsApprovedDateAsLedgerDate)
    Set GetFields = fields
End Function

Private Sub UpdateFields(ByVal filepath As String)
    '讀取CSV欄位
    Dim db As New DbAccess
    Dim rs As ADODB.Recordset
    Dim fields As New Collection
    Dim i As Long
    Set rs = db.PrepareRecordset(filepath)
    If Not rs Is Nothing Then
        If Not (rs.BOF And rs.EOF) Then
            For i = 0 To rs.fields.Count - 1
                fields.Add rs.fields(i).name
            Next i
        End If
    End If
    '更新欄位至表單控制項
    Dim ctrl As Control
    Dim cbo As MSForms.ComboBox
    Dim temp As String
    For Each ctrl In Me.Controls
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            temp = cbo.Text
            cbo.Clear
            For i = 1 To fields.Count
                cbo.AddItem fields.item(i)
            Next i
        End If
    Next ctrl
    '清理資源
    Set rs = Nothing
    Set db = Nothing
End Sub

Private Function GetControlValue(ctrl As Control) As Variant
    '依控制項類型決定取值方式
    If TypeOf ctrl Is MSForms.ComboBox Then
        Dim cb As MSForms.ComboBox
        Set cb = ctrl
        If cb.ListIndex >= 0 Then
            GetControlValue = cb.value
        Else
            GetControlValue = cb.Text
        End If
    ElseIf TypeOf ctrl Is MSForms.CheckBox Then
        GetControlValue = ctrl.value
    Else
        GetControlValue = ctrl.Text
        If Err.Number <> 0 Then
            Err.Clear
            GetControlValue = ctrl.value
        End If
    End If
End Function



