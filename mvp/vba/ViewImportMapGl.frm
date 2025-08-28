VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportMapGl 
   Caption         =   "UserForm1"
   ClientHeight    =   8820.001
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   7650
   OleObjectBlob   =   "ViewImportMapGl.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportMapGl"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewImportMapGl
Public Event ApplyField(ByVal dict As Dictionary)
Private m_Method As Long

Public Sub Initialize(ByRef db As DbAccess)
    Dim fields As Collection
    Set fields = db.GetTableFields("GL")
    UpdateFields fields
End Sub

Private Sub btnApplyField_Click()
    Dim dict As New Dictionary
    '金額欄位
    dict("EntryAmount") = Me.EntryAmount.Value
    dict("DebitAmount") = Me.DebitAmount.Value
    dict("CreditAmount") = Me.CreditAmount.Value
    dict("DrCr") = Me.DrCr.Value
    dict("IsDebit") = Me.IsDebit.Value
    '必選欄位
    dict("AccountNumber") = Me.AccountNumber.Value
    dict("AccountName") = Me.AccountName.Value
    dict("DocumentNumber") = Me.DocumentNumber.Value
    dict("LineItem") = Me.LineItem.Value
    dict("PostDate") = Me.PostDate.Value
    dict("EntryDescription") = Me.EntryDescription.Value
    '可選欄位
    dict("ApprovalDate") = Me.ApprovalDate.Value
    dict("ApprovedBy") = Me.ApprovedBy.Value
    dict("CreatedBy") = Me.CreatedBy.Value
    dict("SourceModule") = Me.SourceModule.Value
    dict("IsManual") = Me.IsManual.Value
    dict("IsApprovedDateAsLedgerDate") = Me.IsApprovedDateAsLedgerDate.Value
    '傳回
    RaiseEvent ApplyField(dict)
End Sub

Private Sub btnMethod1_Click()
    '僅傳票金額
    Call DisableControls
    Me.lblEntryAmount.ForeColor = RGB(0, 0, 0)
    Me.EntryAmount.Enabled = True
    m_Method = 1
End Sub

Private Sub btnMethod2_Click()
    '分別借貸金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("DebitAmount", "CreditAmount")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 2
End Sub

Private Sub btnMethod3_Click()
    '分借貸別
    Call DisableControls
    Dim n As Variant
    For Each n In Array("EntryAmount", "DrCr", "IsDebit")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 3
End Sub

Private Sub btnTestDefault_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Call btnMethod2_Click
    Me.AccountName.Value = "會計科目"
    Me.AccountNumber.Value = "科目代碼"
    Me.DocumentNumber.Value = "傳票號碼"
    Me.DebitAmount.Value = "本幣借方金額"
    Me.CreditAmount.Value = "本幣貸方金額"
    Me.EntryDescription.Value = "摘要"
    Me.IsDebit.Value = "借貸"
    Me.PostDate.Value = "日期"
End Sub

Private Sub btnExit_Click()
    Me.Hide
End Sub

'--自訂方法
Private Sub UpdateFields(ByVal fields As Collection)
    '更新欄位
    Dim ctrl As MSForms.Control
    Dim cbo As MSForms.ComboBox
    Dim i As Long
    If fields Is Nothing Then Exit Sub
    '遍歷控制項
    For Each ctrl In Me.Controls
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            cbo.Clear
            For i = 1 To fields.Count
                cbo.AddItem fields.item(i)
            Next i
        End If
    Next ctrl
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


