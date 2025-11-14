VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceFilterCriteria"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class:    ServiceFilterCriteria
' Purpose:  定義篩選條件規則的服務
' Methods:
'
' Criteria 結構設計:
'   每個 Criterion 為一個 Dict:
'       - "Type"        : String, 條件類型 (Field/Date/Keyword/Special)
'       - "Field"       : String, 欄位名稱 (PostDate, AccountNumber)
'       - "Operator"    : String, 運算子 (=, <>, >=, =< LIKE, IN, BETWEEN)
'       - "Value"       : Variant, 條件值 (String/Date/Number/Array)
'       - "Logic"       : String, 邏輯運算子 (AND/OR, AND)
'       - "Description" : String, 條件描述 (供UI顯示)
'   範例:
'       Dim criterion As New Dictionary
'       criterion("Type") = "Date"
'       criterion("Field") = "PostDate"
'       criterion("Operator") = "IN"
'       criterion("Value") = Array(#1/1/2025#, #1/7/2025#)
'       criterion("Logic") = "AND"
'       criterion("Description") = "總帳日期為週末"
'===============================================================================
Private Const KEY_TYPE As String = "Type"
Private Const KEY_FLD As String = "Field"
Private Const KEY_OP As String = "Operator"
Private Const KEY_VALUE As String = "Value"
Private Const KEY_LOGIC As String = "Logic"
Private Const KEY_DESC As String = "Description"

Private m_Db As DbAccess
Private m_Context As ContextManager
Private m_Criteria As Collection    '<-- Criteria is a collection of Criterion objects
Private m_Criterion As Dictionary   '<-- Criterion is a dictionary of parameters for one rule

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbValid
    Set m_Context = context
End Sub

'-------------------------------------------------------------------------------
' 取得指定索引的條件
' Usage:
'   Dim criteria As Collection
'   Set criteria = criteria.GetCriteria
'-------------------------------------------------------------------------------
Public Function GetCriteria() As Collection
    Set GetCriteria = m_Criteria
End Function

'-------------------------------------------------------------------------------
' 取得指定索引的條件
' Usage:
'   Dim criterion As Dictionary
'   Set criterion = criteria.GetCriterion(1)
'-------------------------------------------------------------------------------
Public Function GetCriterion(index As Long) As Dictionary
    Set GetCriterion = m_Criteria.item(index)
End Function

'-------------------------------------------------------------------------------
' 將條件轉換成 SQL WHERE 子句
' 回傳:
'   String - 完整的 WHERE 子句（不含 WHERE 關鍵字）
' 範例:
'   [IsManual] = True AND [PostDate[ IN (#1/1/2025#, #1/7/2025#)
'-------------------------------------------------------------------------------
Public Function BuildWhereClause() As String
    Dim whereClause As String
    whereClause = ""
    BuildWhereClause = whereClause
End Function

'-------------------------------------------------------------------------------
' 將條件轉換為 SQL 片段，根據條件的 Operator 和 Value 型別生成對應語法
'
'-------------------------------------------------------------------------------
Public Function BuildConditionSql(criterion As Dictionary) As String
    Dim conditionSql As String
    conditionSql = ""
    BuildConditionSql = conditionSql
End Function

'-------------------------------------------------------------------------------
' 新增單一條件至集合
' 範例:
'   Dim criteria As New Dictionary
'   criteria("Type") = "Field"
'   criteria("Field") = "IsManual"
'   criteria("Operator") = "="
'   criteria("Value") = True
'   criteria("Description") = "僅篩選人工分錄"
'   Call filter.AddCriterion(criteria)
'-------------------------------------------------------------------------------
Public Sub AddCriterion(criterion As Dictionary)
    Dim i As Long
    Dim errors As New Collection
    '驗證資料
    If Not criterion.Exists(KEY_TYPE) Then errors.Add "Criterion 缺少 " & KEY_TYPE
    If Not criterion.Exists(KEY_FLD) Then errors.Add "Criterion 缺少 " & KEY_FLD
    If Not criterion.Exists(KEY_OP) Then errors.Add "Criterion 缺少 " & KEY_OP
    If Not criterion.Exists(KEY_VALUE) Then errors.Add "Criterion 缺少 " & KEY_VALUE
    If Not criterion.Exists(KEY_LOGIC) Then errors.Add "Criterion 缺少 " & KEY_LOGIC
    If Not criterion.Exists(KEY_DESC) Then errors.Add "Criterion 缺少 " & KEY_DESC
    '顯示錯誤訊息(若有)
    If errors.Count > 0 Then
        Dim errMsg As String
        errMsg = "請修正以下問題: " & vbCrLf & vbCrLf
        For i = 1 To errors.Count
            errMsg = errMsg & i & ". " & errors(i) & vbCrLf
        Next i
        MsgBox errMsg, vbExclamation, "條件設定失敗"
        Exit Sub
    End If
    '增加條件
    m_Criteria.Add criterion
End Sub

'-------------------------------------------------------------------------------
' 移除指定索引的條件
' Usage:
'   Call filter.RemoveCriterion(2)
'-------------------------------------------------------------------------------
Public Sub RemoveCriterion(index As Long)
    m_Criteria.Remove (index)
End Sub

'-------------------------------------------------------------------------------
' 清空所有條件
' Usage:
'   Call filter.ClearCriteria()             '清空所有條件
'   Call filter.AddCriterion(newCriteria)   '重新開始新增條件
'-------------------------------------------------------------------------------
Public Sub ClearCriteria()
    Set m_Criteria = Nothing
    Dim criteria As New Collection
    Set m_Criteria = criteria
End Sub
