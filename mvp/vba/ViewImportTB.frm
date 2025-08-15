VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportTB 
   Caption         =   "匯入試算表"
   ClientHeight    =   7920
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   7665
   OleObjectBlob   =   "ViewImportTB.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportTB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit

Public Event ProcessMethod(ByVal METHOD As Long)
Public Event ApplyFields(ByVal METHOD As Long, ByVal fields As Dictionary)
Public Event Import(ByVal file As String)
Public Event LastStep()
Public Event NextStep()

Private m_fields As Dictionary
Private m_method As Long
Private m_file As String

Public Sub Initialize()
    Const METHOD_NAME As String = ".Initialize"
    DisableControls
End Sub

Private Sub btnApply_Click()
    Set m_fields = GetFields()
    RaiseEvent ApplyFields(m_method, m_fields)
End Sub

Private Sub btnImport_Click()
    RaiseEvent Import(m_file)
End Sub

Private Sub btnLastStep_Click()
    RaiseEvent LastStep
End Sub

Private Sub btnNextStep_Click()
    RaiseEvent NextStep
End Sub

Private Sub btnMethod1_Click()
    '1:設年度變動金額
    Call DisableControls
    Me.lblChangeAmount.ForeColor = RGB(0, 0, 0)
    Me.ChangeAmount.Enabled = True
    m_method = 1
End Sub

Private Sub btnMethod2_Click()
    '2:期初期末金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("OpeningBalance", "ClosingBalance")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_method = 2
End Sub

Private Sub btnMethod3_Click()
    '3:借方貸方金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("DebitAmount", "CreditAmount")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_method = 3
End Sub

Private Sub btnMethod4_Click()
    '4:借貸之期初期末金額
    Call DisableControls
    Dim n As Variant
    For Each n In Array("OpeningDebitBalance", "ClosingDebitBalance", "OpeningCreditBalance", "ClosingCreditBalance")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_method = 4
End Sub

Private Sub DisableControls()
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

Private Sub btnSelectFile_Click()
    m_file = Application.GetOpenFilename()
    Me.lblFilePath.Caption = m_file
End Sub

Private Function GetFields() As Dictionary
    Dim fields As New Dictionary
    fields("ChangeAmount") = Me.ChangeAmount.value
    fields("OpeningBalance") = Me.OpeningBalance.value
    fields("OpeningDebitBalance") = Me.OpeningDebitBalance.value
    fields("OpeningCreditBalance") = Me.OpeningCreditBalance.value
    fields("ClosingBalance") = Me.ClosingBalance.value
    fields("ClosingDebitBalance") = Me.ClosingDebitBalance.value
    fields("ClosingCreditBalance") = Me.ClosingCreditBalance.value
    fields("DebitAmount") = Me.DebitAmount.value
    fields("CreditAmount") = Me.CreditAmount.value
    fields("AccountNumber") = Me.AccountNumber.value
    fields("AccountName") = Me.AccountName.value
    Set GetFields = fields
End Function

Private Sub btnTestTemplate_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    btnMethod3_Click
    Me.AccountName.value = "項目名稱"
    Me.AccountNumber.value = "會計項目"
    Me.ChangeAmount.value = "借-貸(本幣)"
    Me.DebitAmount.value = "原幣借方金額"
    Me.CreditAmount.value = "原幣貸方金額"
End Sub
