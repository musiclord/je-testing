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

Option Explicit

Private m_app As New Application

Public Event ProcessMethod(ByVal METHOD As Long)
Public Event ApplyFields(ByVal METHOD As Long, ByVal fields As Dictionary)
Public Event Import(ByVal file As String)
Public Event NextStep()

Private m_fields As Dictionary
Private m_method As Long
Private m_file As String

Public Sub Initialize()
    Const METHOD_NAME As String = ".Initialize"
End Sub

Private Sub btnApply_Click()
    Set m_fields = GetFields()
    RaiseEvent ApplyFields(m_method, m_fields)
End Sub

Private Sub btnImport_Click()
    If m_file = "" Then
        MsgBox "尚未選取檔案路徑", vbCritical, "選取檔案"
    Else
        RaiseEvent Import(m_file)
    End If
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

Private Sub btnNextStep_Click()
    RaiseEvent NextStep
End Sub

Private Sub btnSelectFile_Click()
    m_file = Application.GetOpenFilename()
    Me.lblFilePath.Caption = m_file
End Sub

Private Sub DisableControls()
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
    fields("EntryAmount") = Me.EntryAmount.value
    fields("DebitAmount") = Me.DebitAmount.value
    fields("CreditAmount") = Me.CreditAmount.value
    fields("DrCr") = Me.DrCr.value
    fields("IsDebit") = Me.IsDebit.value
    '必選欄位
    fields("AccountNumber") = Me.AccountNumber.value
    fields("AccountName") = Me.AccountName.value
    fields("DocumentNumber") = Me.DocumentNumber.value
    fields("LineItem") = Me.LineItem.value
    fields("PostDate") = Me.PostDate.value
    fields("EntryDescription") = Me.EntryDescription.value
    '可選欄位
    fields("ApprovalDate") = Me.ApprovalDate.value
    fields("ApprovedBy") = Me.ApprovedBy.value
    fields("CreatedBy") = Me.CreatedBy.value
    fields("SourceModule") = Me.SourceModule.value
    fields("IsManual") = Me.IsManual.value
    fields("IsApprovedDateAsLedgerDate") = Me.IsApprovedDateAsLedgerDate.value
    Set GetFields = fields
End Function

Private Sub btnTestTemplate_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Me.AccountName.value = "會計科目"
    Me.AccountNumber.value = "傳票號碼"
    Me.DocumentNumber.value = "傳票號碼"
    Me.DebitAmount.value = "本幣借方金額"
    Me.CreditAmount.value = "本幣貸方金額"
    Me.EntryDescription.value = "摘要"
    Me.IsDebit.value = "借貸"
    Me.PostDate.value = "日期"
End Sub
