VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} vConfigGL 
   Caption         =   "GL Configuration"
   ClientHeight    =   8415.001
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   11760
   OleObjectBlob   =   "vConfigGL.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "vConfigGL"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===== 表單資訊 =====
'名稱: vConfigGL
'描述: 設定總帳 (GL) 資料匯入的欄位對應和相關選項。
'

Public Event DoImport()
Public Event DoPreview()
Public Event DoConfirm()
Public Event DoExit()

Private Sub btnConfirm_Click()
    RaiseEvent DoConfirm
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub

Private Sub btnImport_Click()
    RaiseEvent DoImport
End Sub

Private Sub btnPreview_Click()
    RaiseEvent DoPreview
End Sub


Private Sub UserForm_Initialize()
    Debug.Print Me.Name & " Initialized."
End Sub

Public Function GetFieldMappings() As Object ' Scripting.Dictionary
    Const METHOD_NAME As String = "GetFieldMappings"
    Dim mappings As Object ' Scripting.Dictionary
    Dim ctrl As MSForms.Control
    Dim cbo As MSForms.ComboBox
    Dim tag As String
    Dim standardField As String
    Dim selectedField As String

    On Error GoTo ErrorHandler
    
    Set mappings = CreateObject("Scripting.Dictionary")
    mappings.CompareMode = vbTextCompare ' Key 不區分大小寫
    Debug.Print Me.Name & "." & METHOD_NAME & " - Dictionary created."

    For Each ctrl In Me.Controls
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            standardField = Trim(cbo.tag)
            selectedField = Trim(cbo.value)
            If cbo.tag <> "" Then
                If cbo.ListIndex > -1 Then ' 確保有項目被選中
                    mappings.Add standardField, selectedField
                    Debug.Print "  Mapping added: [" & standardField & "] --> [" & selectedField & "], (Name:" & cbo.Name&; ",Tag:" & cbo.tag & ")"
                Else
                    ' ComboBox 被標記但未選擇任何項目
                    Debug.Print "  Info: ComboBox [" & cbo.Name & "] with tag [" & cbo.tag & "] has no selection."
                End If
            End If
            Set cbo = Nothing
        End If
    Next ctrl
    
    Debug.Print Me.Name & "." & METHOD_NAME & " - Mappings collected. Count: " & mappings.Count
    Set GetFieldMappings = mappings ' 回傳建立好的 Dictionary
    Exit Function

ErrorHandler:
    Debug.Print "!!! ERROR in " & Me.Name & "." & METHOD_NAME & " !!!"
    Debug.Print "Error Description: " & Err.Description
    MsgBox "讀取 TB 欄位對應設定時發生錯誤：" & vbCrLf & Err.Description, vbCritical, "錯誤"
    Set GetFieldMappings = Nothing ' 發生錯誤時回傳 Nothing
    Set mappings = Nothing
    Set cbo = Nothing
End Function

Public Sub PopulateComboBoxes(fieldNames As Variant)
    Const METHOD_NAME As String = "PopulateComboBoxes"
    Dim cbo As MSForms.ComboBox
    Dim ctrl As MSForms.Control
    Dim fieldName As Variant

    On Error GoTo ErrorHandler
    
    For Each ctrl In Me.Controls
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            
            Select Case cbo.Name
                Case "cboMethod"
                    cbo.Clear
                    cbo.List = Array("年度變動金額", "期初期末金額", "借方貸方金額", "借貸方之期初末金額")
                    cbo.ListIndex = -1  ' 預設不選中
                
                Case "cboApproveDateAsGLDate"
                    cbo.Clear
                    cbo.List = Array("Yes", "No")
                    cbo.ListIndex = -1
                Case "cboEntryType"
                    cbo.Clear
                    cbo.List = Array("Auto", "Manual")
                    cbo.ListIndex = -1
            End Select
            
            Set cbo = Nothing  ' 釋放物件
        End If
    Next ctrl
    
    ' 檢查傳入的參數是否為有效的陣列
    If IsEmpty(fieldNames) Or Not IsArray(fieldNames) Then
        Debug.Print Me.Name & "." & METHOD_NAME & " - 未收到有效的欄位名稱陣列。"
        
        For Each ctrl In Me.Controls
            If TypeOf ctrl Is MSForms.ComboBox Then
                Set cbo = ctrl
                If cbo.tag <> "" Then
                    cbo.Clear
                End If
                Set cbo = Nothing
            End If
        Next ctrl
        Exit Sub
    End If
    
    For Each ctrl In Me.Controls
        ' 檢查是否為 ComboBox
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            If cbo.tag <> "" Then
                cbo.Clear
                For Each fieldName In fieldNames
                    cbo.AddItem fieldName
                Next fieldName
                If cbo.ListCount > 0 Then
                    cbo.ListIndex = -1
                End If
            End If
            Set cbo = Nothing
        End If
    Next ctrl
    
    For Each ctrl In Me.Controls
        If TypeOf ctrl Is MSForms.ComboBox Then
            Set cbo = ctrl
            If cbo.Name = "cboDocumentNo" Then
                cbo.value = "傳票號碼"
            ElseIf cbo.Name = "cboAmount" Then
                cbo.value = "傳票金額"
            ElseIf cbo.Name = "cboMethod" Then
                cbo.value = "借方與貸方金額"
            ElseIf cbo.Name = "cboDebit" Then
                cbo.value = "本幣借方金額"
            ElseIf cbo.Name = "cboCredit" Then
                cbo.value = "本幣貸方金額"
            ElseIf cbo.Name = "cboDebitFlag" Then
                cbo.value = "借貸"
            ElseIf cbo.Name = "cboPostDate" Then
                cbo.value = "日期"
            ElseIf cbo.Name = "cboAccountNo" Then
                cbo.value = "科目代碼"
            ElseIf cbo.Name = "cboAccountName" Then
                cbo.value = "會計科目"
            ElseIf cbo.Name = "cboDescription" Then
                cbo.value = "摘要"
            End If
            Set cbo = Nothing
        End If
    Next ctrl
    

    Debug.Print Me.Name & "." & METHOD_NAME & " - 已將 " & UBound(fieldNames) + 1 & " 個欄位填入 ComboBox。"
    Exit Sub

ErrorHandler:
    Debug.Print "--- 在 " & Me.Name & "." & METHOD_NAME & " 中發生錯誤 ---"
    Debug.Print "錯誤代碼: " & Err.Number
    Debug.Print "錯誤描述: " & Err.Description
    MsgBox "填入 '" & Me.Caption & "' 的下拉選單時發生錯誤：" & vbCrLf & Err.Description, vbCritical, "錯誤"
    Set cbo = Nothing
End Sub

