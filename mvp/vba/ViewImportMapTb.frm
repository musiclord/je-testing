VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportMapTb 
   Caption         =   "UserForm1"
   ClientHeight    =   7020
   ClientLeft      =   105
   ClientTop       =   405
   ClientWidth     =   7635
   OleObjectBlob   =   "ViewImportMapTb.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportMapTb"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'Userform:ViewImportMapTb
Public Event ApplyField(ByVal dict As Dictionary)
Private m_Method As Long

Public Sub Initialize(ByRef db As DbAccess)
    Dim fields As Collection
    Set fields = db.GetTableFields("TB")
    UpdateFields fields
End Sub

Private Sub btnApplyField_Click()
    Dim dict As New Dictionary
    '金額欄位
    dict("ChangeAmount") = Me.ChangeAmount.Value
    dict("OpeningBalance") = Me.OpeningBalance.Value
    dict("OpeningDebitBalance") = Me.OpeningDebitBalance.Value
    dict("OpeningCreditBalance") = Me.OpeningCreditBalance.Value
    dict("ClosingBalance") = Me.ClosingBalance.Value
    dict("ClosingDebitBalance") = Me.ClosingDebitBalance.Value
    dict("ClosingCreditBalance") = Me.ClosingCreditBalance.Value
    dict("DebitAmount") = Me.DebitAmount.Value
    dict("CreditAmount") = Me.CreditAmount.Value
    '必選欄位
    dict("AccountNumber") = Me.AccountNumber.Value
    dict("AccountName") = Me.AccountName.Value
    '傳回
    RaiseEvent ApplyField(dict)
End Sub

Private Sub btnMethod1_Click()
    '設年度變動金額
    Call DisableControls
    Me.lblChangeAmount.ForeColor = RGB(0, 0, 0)
    Me.ChangeAmount.Enabled = True
    m_Method = 1
End Sub

Private Sub btnMethod2_Click()
    '期初期末金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("OpeningBalance", "ClosingBalance")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 2
End Sub

Private Sub btnMethod3_Click()
    '借方貸方金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("DebitAmount", "CreditAmount")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 3
End Sub

Private Sub btnMethod4_Click()
    '借貸之期初期末金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("OpeningDebitBalance", "ClosingDebitBalance", "OpeningCreditBalance", "ClosingCreditBalance")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 4
End Sub

Private Sub btnTestDefault_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Call btnMethod3_Click
    Me.AccountName.Value = "項目名稱"
    Me.AccountNumber.Value = "會計項目"
    Me.ChangeAmount.Value = "借-貸(本幣)"
    Me.DebitAmount.Value = "原幣借方金額"
    Me.CreditAmount.Value = "原幣貸方金額"
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
                cbo.AddItem fields.Item(i)
            Next i
        End If
    Next ctrl
End Sub

Private Sub DisableControls()
    '關閉金額欄位處理之控制項
    Dim ctrls As Variant, n As Variant
    ctrls = Array( _
            "ChangeAmount", "OpeningBalance", "ClosingBalance", _
            "DebitAmount", "OpeningDebitBalance", "ClosingDebitBalance", _
            "CreditAmount", "OpeningCreditBalance", "ClosingCreditBalance")
    For Each n In ctrls
        Me.Controls("lbl" & n).ForeColor = RGB(128, 128, 128)
        Me.Controls(n).Enabled = False
    Next n
End Sub

