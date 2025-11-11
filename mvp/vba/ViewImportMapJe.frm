VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportMapJe 
   Caption         =   "處理 JE 欄位映射"
   ClientHeight    =   8820.001
   ClientLeft      =   108
   ClientTop       =   408
   ClientWidth     =   9168.001
   OleObjectBlob   =   "ViewImportMapJe.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewImportMapJe"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Form:     ViewImportMapJe
' Purpose:
' Methods:
'===============================================================================
Public Event ApplyField(ByVal dict As Dictionary, ByVal Method As Long)
Private m_Method As Long

Public Sub Initialize(ByRef db As DbAccess)
    Dim Fields As Collection
    Set Fields = db.GetTableFields("JE")
    Call UpdateFields(Fields)
    Call DisableControls
    Call btnMethod1_Click
End Sub

'--公開方法供外部調用(用於測試)
Public Sub ApplyTestDefaults()
    '填入測試參數
    Call btnTestDefaults_Click
    '應用測試參數
    Call btnApplyField_Click
End Sub
Private Sub btnTestDefaults_Click()
    '### FOR DEBUG TESTING ###
    Call btnMethod2_Click
    Me.AccountName.Value = FindField(Me.AccountName, "項目名稱")
    Me.AccountNumber.Value = FindField(Me.AccountNumber, "會計項目")
    Me.DocumentNumber.Value = FindField(Me.DocumentNumber, "傳票號碼")
    Me.EntryDescription.Value = FindField(Me.EntryDescription, "摘要")
    Me.PostDate.Value = FindField(Me.PostDate, "日期")
    Me.DebitAmount.Value = FindField(Me.DebitAmount, "借方金額")
    Me.CreditAmount.Value = FindField(Me.CreditAmount, "貸方金額")
End Sub

Private Sub btnApplyField_Click()
    Dim dict As New Dictionary
    '金額欄位
    dict("Amount") = Me.Amount.Value
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
    RaiseEvent ApplyField(dict, m_Method)
End Sub

Private Sub btnMethod1_Click()
    '僅傳票金額
    Call DisableControls
    Me.lblAmount.ForeColor = RGB(0, 0, 0)
    Me.Amount.Enabled = True
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
    For Each n In Array("Amount", "DrCr", "IsDebit")
        Me.Controls("lbl" & n).ForeColor = RGB(0, 0, 0)
        Me.Controls(n).Enabled = True
    Next n
    m_Method = 3
End Sub

Private Sub btnExit_Click()
    '檢查必填欄位
    Dim errors As Collection
    Set errors = New Collection
    If Trim(Me.AccountNumber.Value & "") = "" Then
        errors.Add "請選擇會計科目編號"
    End If
    If Trim(Me.AccountName.Value & "") = "" Then
        errors.Add "請選擇會計科目名稱"
    End If
    If Trim(Me.DocumentNumber.Value & "") = "" Then
        errors.Add "請選擇傳票編號"
    End If
    If Trim(Me.EntryDescription.Value & "") = "" Then
        errors.Add "請選擇傳票摘要"
    End If
    If Trim(Me.LineItem.Value & "") = "" Then
        errors.Add "請選擇傳票項次"
    End If
    If Trim(Me.PostDate.Value & "") = "" Then
        errors.Add "請選擇總帳日期"
    End If
    '顯示錯誤訊息(若有)
    If errors.Count > 0 Then
        Dim errMsg As String
        Dim i As Long
        errMsg = "請修正以下問題:" & vbCrLf & vbCrLf
        For i = 1 To errors.Count
            errMsg = errMsg & i & ". " & errors(i) & vbCrLf
        Next i
        MsgBox errMsg, vbExclamation, "欄位映射失敗"
    End If
    
    Me.Hide
End Sub

'--自訂方法
Private Sub UpdateFields(ByVal Fields As Collection)
    '更新欄位
    Dim ctrl As MSForms.Control
    Dim cbo As MSForms.ComboBox
    Dim i As Long
    If Fields Is Nothing Then Exit Sub
    '遍歷控制項
    For Each ctrl In Me.Controls
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            cbo.Clear
            For i = 1 To Fields.Count
                cbo.AddItem Fields.item(i)
            Next i
        End If
    Next ctrl
End Sub

Private Sub DisableControls()
    '關閉金額欄位處理之控制項
    Dim ctrls As Variant, n As Variant
    ctrls = Array( _
            "Amount", "DrCr", "IsDebit", _
            "DebitAmount", "CreditAmount")
    For Each n In ctrls
        Me.Controls("lbl" & n).ForeColor = RGB(128, 128, 128)
        Me.Controls(n).Enabled = False
    Next n
End Sub

Private Function FindField(ByVal cbo As MSForms.ComboBox, ByVal keyword As String) As String
    '在 ComboBox 中尋找包含關鍵字的項目
    Dim i As Long
    For i = 0 To cbo.ListCount - 1
        If InStr(1, cbo.List(i), keyword, vbTextCompare) > 0 Then
            FindField = cbo.List(i)
            Exit Function
        End If
    Next i
    '如果找不到，回傳空字串
    FindField = ""
End Function

