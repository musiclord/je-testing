VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} View_Import 
   Caption         =   "Import"
   ClientHeight    =   7020
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   12360
   OleObjectBlob   =   "View_Import.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "View_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit

Public Event DoExit()
Public Event OpenGL()
Public Event OpenTB()
Public Event ApplyGL()
Public Event ApplyTB()
Public Event ImportGL()
Public Event ImportTB()
Public Event AddLineItem()


Private Sub btnOpenGL_Click()

End Sub

Private Sub btnOpenTB_Click()

End Sub

Private Sub btn_AddLineItem_Click()
    RaiseEvent AddLineItem
End Sub

Private Sub btnApplyGL_Click()
    RaiseEvent ApplyGL
End Sub

Private Sub btnApplyTB_Click()
    RaiseEvent ApplyTB
End Sub

Private Sub btnImportGL_Click()
    RaiseEvent ImportGL
End Sub

Private Sub btnImportTB_Click()
    RaiseEvent ImportTB
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub

Public Sub UpdatePageGL(ByVal fields As Collection)
    Const METHOD_NAME As String = "UpdatePageGL"
    '更新 GL 頁面控制項
    Dim ctrl As Control
    Dim cbo As MSForms.ComboBox
    Dim pfx As String
    Dim temp As String
    Dim i As Long
    '遍歷表單控制項
    For Each ctrl In Me.Controls
        pfx = Left(ctrl.name, 2)
        If (TypeOf ctrl Is MSForms.ComboBox) And (pfx = "GL") Then
            Set cbo = ctrl
            temp = cbo.Text
            cbo.Clear
            '總帳金額對應欄位
            If ctrl.Tag = "amount" Then
                If ctrl.name = "GL_HandlingMethod" Then
                    cbo.AddItem "僅傳票金額"
                    cbo.AddItem "分別借貸方金額"
                    cbo.AddItem "依借貸別判斷"
                Else
                    For i = 1 To fields.count
                        cbo.AddItem fields.item(i)
                    Next i
                End If
            ElseIf (ctrl.Tag = "required") Or (ctrl.Tag = "optional") Then
                For i = 1 To fields.count
                    cbo.AddItem fields.item(i)
                Next i
            End If
            cbo.Text = temp
        End If
    Next ctrl
End Sub

Public Sub UpdatePageTB(ByVal fields As Collection)
    Const METHOD_NAME As String = "UpdatePageTB"
    '更新 TB 頁面控制項
    Dim ctrl As Control
    Dim cbo As MSForms.ComboBox
    Dim pfx As String
    Dim temp As String
    Dim i As Long
    '遍歷表單控制項
    For Each ctrl In Me.Controls
        pfx = Left(ctrl.name, 2)
        If (TypeOf ctrl Is MSForms.ComboBox) And (pfx = "TB") Then
            Set cbo = ctrl
            temp = cbo.Text
            cbo.Clear
            '總帳金額對應欄位
            If ctrl.Tag = "amount" Then
                If ctrl.name = "TB_HandlingMethod" Then
                    cbo.AddItem "年度變動金額"
                    cbo.AddItem "期初期末金額"
                    cbo.AddItem "借方貸方金額"
                    cbo.AddItem "借貸之期初期末金額"
                Else
                    For i = 1 To fields.count
                        cbo.AddItem fields.item(i)
                    Next i
                End If
            ElseIf (ctrl.Tag = "required") Or (ctrl.Tag = "optional") Then
                For i = 1 To fields.count
                    cbo.AddItem fields.item(i)
                Next i
            End If
            cbo.Text = temp
        End If
    Next ctrl
End Sub

Public Function GetGLMapping() As Dictionary
    Const METHOD_NAME As String = "GetGLMapping"
    Dim mapping As New Dictionary
    '總帳金額
    mapping("EntryAmount") = Me.GL_EntryAmount.Text
    mapping("DebitAmount") = Me.GL_DebitAmount.Text
    mapping("CreditAmount") = Me.GL_CreditAmount.Text
    mapping("DrCr") = Me.GL_DrCr.Text
    mapping("IsDebit") = Me.GL_IsDebit.Text
    '必要欄位
    mapping("AccountNumber") = Me.GL_AccountNumber.Text
    mapping("AccountName") = Me.GL_AccountName.Text
    mapping("DocumentNumber") = Me.GL_DocumentNumber.Text
    mapping("LineItem") = Me.GL_LineItem.Text
    mapping("PostDate") = Me.GL_PostDate.Text
    mapping("EntryDescription") = Me.GL_EntryDescription.Text
    '可選欄位
    mapping("ApprovalDate") = Me.GL_ApprovalDate.Text
    mapping("ApprovedBy") = Me.GL_ApprovedBy.Text
    mapping("CreatedBy") = Me.GL_CreatedBy.Text
    mapping("SourceModule") = Me.GL_SourceModule.Text
    mapping("IsManual") = Me.GL_IsManual.Text
    mapping("IsApprovedDateAsLedgerDate") = Me.GL_IsApprovedDateAsLedgerDate.Text
    Set GetGLMapping = mapping
End Function

Public Function GetTBMapping() As Dictionary
    Const METHOD_NAME As String = "GetTBMapping"
    '回傳 TB 欄位映射表
    Dim mapping As New Dictionary
    '試算表金額
    mapping("ChangeAmount") = Me.TB_ChangeAmount.Text
    mapping("OpeningAmount") = Me.TB_OpeningAmount
    mapping("ClosingAmount") = Me.TB_ClosingAmount
    mapping("DebitAmount") = Me.TB_DebitAmount
    mapping("CreditAmount") = Me.TB_CreditAmount
    '必要欄位
    mapping("AccountNumber") = Me.TB_AccountNumber
    mapping("AccountName") = Me.TB_AccountName
    Set GetTBMapping = mapping
End Function
