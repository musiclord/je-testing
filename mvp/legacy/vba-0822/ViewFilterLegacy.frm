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
Public criteriaStates As New Dictionary
Private m_LastSelection As String

'-------------------------------------------------------------------------------
' 初始化
'-------------------------------------------------------------------------------
Public Sub Initialize(ByRef db As DbAccess)
    Dim Fields As Collection
    Set Fields = db.GetTableFields("JE")
    Call UpdateFields(Fields)
    Me.cboCriteriaSelector.Clear
    Dim i As Long
    Dim criteriaName As String
    Dim state As Dictionary
    ' 預設新增十組條件
    For i = 1 To 8
        Set state = New Dictionary
        criteriaName = "條件_" & CStr(i)
        Me.cboCriteriaSelector.AddItem criteriaName
        criteriaStates.Add criteriaName, state
    Next i
    ' 設定初始狀態
    m_LastSelection = "條件_1"
    Me.cboCriteriaSelector.Value = "條件_1"
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
    
    Set criteriaStates(key) = state
End Sub

'-------------------------------------------------------------------------------
' 載入狀態，遍歷控制項 -> (有紀錄? 載入/清空)
'-------------------------------------------------------------------------------
Private Sub LoadState(ByVal key As String)
    Dim state As Dictionary
    Set state = criteriaStates(key)
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
