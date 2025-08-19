VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportTB 
   Caption         =   "匯入試算表"
   ClientHeight    =   7920
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   7668
   OleObjectBlob   =   "ViewImportTB.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportTB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
' TB
Option Explicit

Public Event ProcessMethod(ByVal method As Long)
Public Event ApplyFields(ByVal method As Long, ByVal fields As Dictionary)
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

Private Sub btnLastStep_Click()
    RaiseEvent LastStep
End Sub

Private Sub btnNextStep_Click()
    RaiseEvent NextStep
End Sub

Private Sub btnSelectFile_Click()
    m_file = Application.GetOpenFilename()
    Me.lblFilePath.Caption = m_file
    Call UpdateFields(m_file)
    Debug.Print "TB: " & m_file
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
    '防止誤觸
    Me.btnImport.Enabled = False
    RaiseEvent Import(m_file)
    Me.btnImport.Enabled = True
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



'--自訂方法
Private Sub btnTestTemplate_Click()
    'THIS METHOD IS FOR DEBUG TESTING
    Call btnMethod3_Click
    Me.AccountName.value = "項目名稱"
    Me.AccountNumber.value = "會計項目"
    Me.ChangeAmount.value = "借-貸(本幣)"
    Me.DebitAmount.value = "原幣借方金額"
    Me.CreditAmount.value = "原幣貸方金額"
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

Private Function GetFields() As Dictionary
    Dim fields As New Dictionary
    fields("ChangeAmount") = GetControlValue(Me.ChangeAmount)
    fields("OpeningBalance") = GetControlValue(Me.OpeningBalance)
    fields("OpeningDebitBalance") = GetControlValue(Me.OpeningDebitBalance)
    fields("OpeningCreditBalance") = GetControlValue(Me.OpeningCreditBalance)
    fields("ClosingBalance") = GetControlValue(Me.ClosingBalance)
    fields("ClosingDebitBalance") = GetControlValue(Me.ClosingDebitBalance)
    fields("ClosingCreditBalance") = GetControlValue(Me.ClosingCreditBalance)
    fields("DebitAmount") = GetControlValue(Me.DebitAmount)
    fields("CreditAmount") = GetControlValue(Me.CreditAmount)
    fields("AccountNumber") = GetControlValue(Me.AccountNumber)
    fields("AccountName") = GetControlValue(Me.AccountName)
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

