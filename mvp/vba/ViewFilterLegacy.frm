VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewFilterLegacy 
   Caption         =   "Legacy Filter"
   ClientHeight    =   8370.001
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   8880.001
   OleObjectBlob   =   "ViewFilterLegacy.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "ViewFilterLegacy"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Form:     ViewFilterLegacy
' Purpose:
' Methods:
'===============================================================================
Public Event ExecuteCriteriaRequested()
Public Event ShowCriteriaRequested()
Public Event Submitted(ByVal dto As DataTransferObject)
'--
Public CriteriaStates As New Dictionary
Private m_LastSelection As String

'-------------------------------------------------------------------------------
' 初始化
'-------------------------------------------------------------------------------
Public Sub Initialize()
    Me.cboCriteriaSelector.Clear
    Dim i As Long
    Dim state As Dictionary
    ' 預設新增十組條件
    For i = 1 To 10
        Set state = New Dictionary
        Me.cboCriteriaSelector.AddItem CStr(i)
        CriteriaStates.Add CStr(i), state
    Next i
    ' 設定初始狀態
    m_LastSelection = "1"
    Me.cboCriteriaSelector.Value = "1"
End Sub

'-------------------------------------------------------------------------------
' 若改變條件組合選單，則儲存改變前的狀態，並載入改變後所選取的條件組合
'-------------------------------------------------------------------------------
Private Sub cboCriteriaSelector_Change()
    Dim newKey As String
    newKey = Me.cboCriteriaSelector.Value
    ' 儲存上一次選取項目的狀態  - Save Old
    Call SaveState(m_LastSelection)
    ' 載入目前選取項目的狀態    - Load New
    Call LoadState(newKey)
    ' 更新指標                  - Update Pointer
    m_LastSelection = newKey
End Sub

'-------------------------------------------------------------------------------
' 執行篩選條件
'-------------------------------------------------------------------------------
Private Sub btnExecuteCriteria_Click()
    SaveState (m_LastSelection)
    RaiseEvent ExecuteCriteriaRequested
End Sub

Private Sub btnShowCriteria_Click()
    '...
    RaiseEvent ShowCriteriaRequested
End Sub

'-------------------------------------------------------------------------------
' 退出表單
'-------------------------------------------------------------------------------
Private Sub btnExit_Click()
    '檢查並驗證
    Dim dto As New DataTransferObject
    '...
    Me.Hide
    Unload Me
    RaiseEvent Submitted(dto)
End Sub

'===============================================================================
' HELPER
'===============================================================================
' 儲存狀態，遍歷控制項 -> 寫入字典
'-------------------------------------------------------------------------------
Private Sub SaveState(ByVal key As String)
    If key = "" Then Exit Sub
    Dim state As New Dictionary
    Dim ctrl As MSForms.Control
    On Error Resume Next ' 忽略無 Value 屬性的控制項
    For Each ctrl In Me.Controls
        If ctrl.name <> "cboCriteriaSelector" Then
            Select Case TypeName(ctrl)
                Case "CheckBox", "ComboBox", "TextBox"
                    state(ctrl.name) = ctrl.Value
            End Select
        End If
    Next ctrl
    On Error GoTo 0
    
    Set CriteriaStates(key) = state
End Sub

'-------------------------------------------------------------------------------
' 載入狀態，遍歷控制項 -> (有紀錄? 載入/清空)
'-------------------------------------------------------------------------------
Private Sub LoadState(ByVal key As String)
    Dim state As Dictionary
    Set state = CriteriaStates(key)
    Dim ctrl As MSForms.Control
    ' 如果該組設定是空的(全新)，則清空表單
    If state.Count = 0 Then
        On Error Resume Next
        For Each ctrl In Me.Controls
            If ctrl.name <> "cboCriteriaSelector" Then
                Select Case TypeName(ctrl)
                    Case "CheckBox": ctrl.Value = False
                    Case "TextBox": ctrl.Value = ""
                    Case "ComboBox": ctrl.Value = ""
                End Select
            End If
        Next ctrl
        On Error GoTo 0
    Else
        ' 否則載入設定值
        Dim ctrlName As Variant
        On Error Resume Next
        For Each ctrlName In state.Keys
            Me.Controls(ctrlName).Value = state(ctrlName)
        Next ctrlName
        On Error GoTo 0
    End If
End Sub
