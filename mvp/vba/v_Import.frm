VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} v_Import 
   Caption         =   "Step1 - Import Data"
   ClientHeight    =   7020
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   12360
   OleObjectBlob   =   "v_Import.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "v_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "v_Import"
' ----- 事件 -----
Public Event ImportGL()
Public Event ImportTB()
Public Event ApplyGL()
Public Event ApplyTB()
Public Event DoExit()



' ----- [ v_Import ] -----
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



' ----- [ Custom ] -----
Public Function GetGLControls() As Dictionary
    Const METHOD_NAME = "GetGLControls"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '初始化
    Dim ctrl As Control
    Dim cmb As ComboBox
    Dim fields As Dictionary
    Set fields = New Dictionary
    '取得欄位
    For Each ctrl In Me.Controls("pageGL").Controls
        If TypeName(ctrl) = "ComboBox" Then
            '加入欄位名稱至映射字典表
            If Not fields.Exists(ctrl.name) Then
                fields.Add ctrl.name, ctrl.Value
            End If
        End If
    Next ctrl
    '回傳欄位字典表
    Set GetGLControls = fields
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Function

Public Function GetTBControls() As Dictionary
    Const METHOD_NAME = "GetTBControls"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '初始化
    Dim ctrl As Control
    Dim cmb As ComboBox
    Dim fields As Dictionary
    Set fields = New Dictionary
    '取得欄位
    For Each ctrl In Me.Controls("pageTB").Controls
        If TypeName(ctrl) = "ComboBox" Then
            '加入欄位名稱至映射字典表
            If Not fields.Exists(ctrl.name) Then
                fields.Add ctrl.name, ctrl.Value
            End If
        End If
    Next ctrl
    '回傳欄位字典表
    Set GetTBControls = fields
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Function
