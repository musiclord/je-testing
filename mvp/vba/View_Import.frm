VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} View_Import 
   Caption         =   "Import"
   ClientHeight    =   7020
   ClientLeft      =   120
   ClientTop       =   468
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
Public Event ApplyGL()
Public Event ApplyTB()
Public Event ImportGL()
Public Event ImportTB()

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

Public Sub UpdatePageGL(ByVal fieldNames As Dictionary)
    Const METHOD_NAME As String = "UpdatePageGL"
    '更新 GL 頁面控制項
    Dim ctrl As Controls
    Dim cbo As MSForms.ComboBox
    Dim fieldName As Variant
    '遍歷表單控制項
    For Each ctrl In Me.Controls
        '若為 ComboBox
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            cbo.Clear
            '總帳金額對應欄位
            '必要設定欄位
            '可選設定欄位
            For Each fieldName In fieldNames.Keys
                cbo.AddItem fieldName
            Next fieldName
        End If
    Next ctrl
End Sub

Public Sub UpdatePageTB(ByVal fieldNames As Dictionary)
    Const METHOD_NAME As String = "UpdatePageTB"
    '更新 TB 頁面控制項
    Dim ctrl As Controls
    Dim cbo As MSForms.ComboBox
    Dim fieldName As Variant
    '遍歷表單控制項
    For Each ctrl In Me.Controls
        '若為 ComboBox
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            cbo.Clear
            '總帳金額對應欄位
            '必要設定欄位
            '可選設定欄位
            For Each fieldName In fieldNames.Keys
                cbo.AddItem fieldName
            Next fieldName
        End If
    Next ctrl
End Sub

Public Function GetGLMapping() As Dictionary
    Const METHOD_NAME As String = "GetGLMapping"
    '回傳 GL 欄位映射表
    Dim key As String
    Dim cbo As MSForms.ComboBox
    Dim ctrl As Controls
    Dim mapping As Dictionary
    Set mapping = New Dictionary
    For Each ctrl In Me.Controls
        If (TypeOf ctrl Is MSForms.ComboBox) Then
            Set cbo = ctrl
            If ctrl.Tag = "mapping" Then
                '移除控制項名稱前綴
                key = Replace(cbo.name, "cbo", "")
                If cbo.Text <> "" Then
                    mapping(key) = cbo.Text
                End If
            ElseIf ctrl.Tag = "amount" Then
                key = Replace(cbo.name, "cbo", "")
                If cbo.Text <> "" Then
                    mapping(key) = cbo.Text
                End If
            End If
        End If
    Next ctrl
    
    Set GetGLMapping = mapping
End Function

Public Function GetTBMapping() As Dictionary
    Const METHOD_NAME As String = "GetTBMapping"
    '回傳 TB 欄位映射表
    Dim key As String
    Dim cbo As MSForms.ComboBox
    Dim ctrl As Controls
    Dim mapping As Dictionary
    Set mapping = New Dictionary
    For Each ctrl In Me.Controls
        If (TypeOf ctrl Is MSForms.ComboBox) Then
            If ctrl.Tag = "mapping" Then
                Set cbo = ctrl
                '移除控制項名稱前綴
                key = Replace(cbo.name, "cbo", "")
                If cbo.Text <> "" Then
                    mapping(key) = cbo.Text
                End If
            End If
        End If
    Next ctrl
    
    Set GetTBMapping = mapping
End Function

