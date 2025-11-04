VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceFilter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class:    ServiceFilter
' Purpose:  定義處理篩選條件的服務
' Methods:
'
' Criteria 結構設計:
'   每個 Criterion 為一個 Dict:
'       - "Type"        : String, 條件類型 (Field/Date/Keyword/Special)
'       - "Field"       : String, 欄位名稱 (PostDate, AccountNumber)
'       - "Operator"    : String, 運算子 (=, <>, >, < LIKE, IN, BETWEEN)
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
Private m_Db As DbAccess
Private m_Context As ContextManager
Private m_Criteria As Collection '<- Collection of Dictionary

Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbValid
    Set m_Context = context
    Set m_Criteria = New Collection
End Sub

Public Sub AddCriterion(criterion As Dictionary)
    '---------------------------------------------------------------------------
    ' 新增單一條件至集合
    '
    ' 範例:
    '   Dim criteria As New Dictionary
    '   criteria("Type") = "Field"
    '   criteria("Field") = "IsManual"
    '   criteria("Operator") = "="
    '   criteria("Value") = True
    '   criteria("Description") = "僅篩選人工分錄"
    '   Call filter.AddCriterion(criteria)
    '---------------------------------------------------------------------------
End Sub

Public Sub RemoveCriterion(index As Long)
    '---------------------------------------------------------------------------
    ' 移除指定索引的條件
    '
    ' 範例:
    '   Call filter.RemoveCriterion(2)
    '---------------------------------------------------------------------------
End Sub

Public Sub ClearCriteria()
    '---------------------------------------------------------------------------
    ' 清空所有條件
    '
    ' 範例:
    '   Call filter.ClearCriteria()             '清空所有條件
    '   Call filter.AddCriterion(newCriteria)   '重新開始新增條件
    '---------------------------------------------------------------------------
End Sub

Public Function GetCriterion(index As Long) As Dictionary
    '---------------------------------------------------------------------------
    ' 取得指定索引的條件
    '
    ' 範例:
    '   Dim criteria As Dictionary
    '   Set criteria = filter.GetCriterion(1)
    '   If Not criteria Is Nothing Then
    '       Debug.Print criteria("Description")
    '   End If
    '---------------------------------------------------------------------------
End Function

Public Function BuildWhereClause() As String
    '---------------------------------------------------------------------------
    ' 將條件轉換成 SQL WHERE 子句
    ' 回傳:
    '   String - 完整的 WHERE 子句（不含 WHERE 關鍵字）
    ' 範例:
    '   [IsManual] = True AND [PostDate[ IN (#1/1/2025#, #1/7/2025#)
    '---------------------------------------------------------------------------
End Function

Public Function BuildConditionSql(criterion As Dictionary) As String
    '---------------------------------------------------------------------------
    ' 將條件轉換為 SQL 片段，根據條件的 Operator 和 Value 型別生成對應語法
    '
    '---------------------------------------------------------------------------
End Function
