VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportGL 
   Caption         =   "匯入總帳"
   ClientHeight    =   9585.001
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   7755
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

Public Event ApplyFields(ByVal Method As Long, ByVal Fields As Dictionary)
Public Event Import(ByVal filepath As String)
Public Event NextStep()

Private m_Fields As Dictionary
Private m_Method As Long
Private m_file As String

Public Sub Initialize()
    Const METHOD_Name As String = ".Initialize"
    DisableControls
End Sub

Private Sub btnNextStep_Click()
    RaiseEvent NextStep
End Sub

Private Sub btnSelectFile_Click()
    m_file = Application.GetOpenFilename()
    'Me.lblFilePath.Caption = m_file
    Me.Caption = Me.Caption & ": " & m_file
    Call UpdateFields(m_file)
    Debug.Print "GL: " & m_file
End Sub

Private Sub btnApply_Click()
    Set m_Fields = GetFields()
    RaiseEvent ApplyFields(m_Method, m_Fields)
End Sub

Private Sub btnImport_Click()
    If m_file = "" Then
        MsgBox "尚未選取檔案路徑", vbCritical, "選取檔案"
        Exit Sub
    End If
    If m_Fields Is Nothing Then
        MsgBox "尚未套用欄位設定", vbCritical, "套用欄位"
        Exit Sub
    End If
    If m_Method = 0 Then
        MsgBox "尚未選擇金額處理方式", vbCritical, "金額欄位"
        Exit Sub
    End If
    
    RaiseEvent Import(m_file)
End Sub

Private Sub btnMethod1_Click()
    '1:僅傳票金額
    Call DisableControls
    Me.lblEntryAmount.ForeColor = RGB(0, 0, 0)
    Me.EntryAmount.Enabled = True
    m_Method = 1
End Sub

Private Sub btnMethod2_Click()
    '2:分別借貸金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("DebitAmount", "CreditAmount")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 2
End Sub

Private Sub btnMethod3_Click()
    '3:分借貸別
    Call DisableControls
    Dim n As Variant
    For Each n In Array("EntryAmount", "DrCr", "IsDebit")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 3
End Sub




'--自訂方法
Private Sub btnTestTemplate_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Call btnMethod2_Click
    Me.AccountName.value = "會計科目"
    Me.AccountNumber.value = "科目代碼"
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
    Dim Fields As New Dictionary
    '金額欄位
    Fields("EntryAmount") = GetControlValue(Me.EntryAmount)
    Fields("DebitAmount") = GetControlValue(Me.DebitAmount)
    Fields("CreditAmount") = GetControlValue(Me.CreditAmount)
    Fields("DrCr") = GetControlValue(Me.DrCr)
    Fields("IsDebit") = GetControlValue(Me.IsDebit)
    '必選欄位
    Fields("AccountNumber") = GetControlValue(Me.AccountNumber)
    Fields("AccountName") = GetControlValue(Me.AccountName)
    Fields("DocumentNumber") = GetControlValue(Me.DocumentNumber)
    Fields("LineItem") = GetControlValue(Me.LineItem)
    Fields("PostDate") = GetControlValue(Me.PostDate)
    Fields("EntryDescription") = GetControlValue(Me.EntryDescription)
    '可選欄位
    Fields("ApprovalDate") = GetControlValue(Me.ApprovalDate)
    Fields("ApprovedBy") = GetControlValue(Me.ApprovedBy)
    Fields("CreatedBy") = GetControlValue(Me.CreatedBy)
    Fields("SourceModule") = GetControlValue(Me.SourceModule)
    Fields("IsManual") = GetControlValue(Me.IsManual)
    Fields("IsApprovedDateAsLedgerDate") = GetControlValue(Me.IsApprovedDateAsLedgerDate)
    Set GetFields = Fields
End Function

Private Sub UpdateFields(ByVal filepath As String)
    '讀取CSV欄位
    Dim db As New DbAccess
    Dim rs As ADODB.Recordset
    Dim Fields As New Collection
    Dim i As Long
    Set rs = db.PrepareRecordset(filepath)
    If Not rs Is Nothing Then
        If Not (rs.BOF And rs.EOF) Then
            For i = 0 To rs.Fields.Count - 1
                Fields.Add rs.Fields(i).Name
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
            For i = 1 To Fields.Count
                cbo.AddItem Fields.item(i)
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



