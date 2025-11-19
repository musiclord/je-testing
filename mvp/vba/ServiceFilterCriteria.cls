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
    Dim conditionSql As String
    Dim criterion As Dictionary
    Dim logicOperator As String
    Dim i As Long
    
    whereClause = ""
    '逐一處理 m_Criteria 裡的每一個篩選條件
    For i = 1 To m_Criteria.Count
        Set criterion = m_Criteria(i)
        
        '將條件轉成 SQL（例如 [Amount] > 100）
        conditionSql = BuildConditionSql(criterion)
        
        '若條件無效（例如欄位空、值空），跳過
        If Len(conditionSql) = 0 Then GoTo ContinueLoop
        
        '第一次加入條件：直接放進 whereClause
        If Len(whereClause) = 0 Then
            whereClause = conditionSql
        Else
            '第二條以上的條件，需要先加邏輯運算子（AND / OR）
            logicOperator = NormalizeLogic(criterion(KEY_LOGIC))
            whereClause = whereClause & " " & logicOperator & " " & conditionSql
        End If
ContinueLoop:
    Next i
    '若至少有一條條件，最前面加上 WHERE
    If Len(whereClause) > 0 Then
        whereClause = "WHERE " & whereClause
    End If
    BuildWhereClause = whereClause
End Function

'-------------------------------------------------------------------------------
' 將條件轉換為 SQL 片段，根據條件的 Operator 和 Value 型別生成對應語法
'
'-------------------------------------------------------------------------------
Public Function BuildConditionSql(criterion As Dictionary) As String
    Dim conditionSql As String
    Dim Value As Variant
    '抓欄位名稱並格式化（加上方括號、防止保留字衝突）
    Dim fieldName As String
    fieldName = FormatFieldName(criterion(KEY_FLD))
    If Len(fieldName) = 0 Then
        BuildConditionSql = ""
        Exit Function
    End If
    ' 取得運算子，轉成標準 SQL（例如 <> → !=）
    Dim operatorText As String
    operatorText = NormalizeOperator(criterion(KEY_OP))
    Value = criterion(KEY_VALUE)
    '根據不同運算子產生不同 SQL 語法
    Select Case operatorText
        Case "IN"
            ' IN (...) 語法，用於多筆比對
            conditionSql = fieldName & " IN " & BuildInValues(Value)
        Case "BETWEEN"
            ' BETWEEN a AND b，適用區間查詢（數字或日期）
            conditionSql = BuildBetweenSql(fieldName, Value)
        Case "LIKE"
            ' LIKE 'xxx%' 做模糊查詢
            conditionSql = fieldName & " LIKE " & FormatLikeValue(Value)
        Case "IS NULL", "IS NOT NULL"
            ' IS NULL / IS NOT NULL 不需要值
            conditionSql = fieldName & " " & operatorText
        Case Else
            ' 預設情況：一般運算子，例如 =, >, <, <>
            conditionSql = fieldName & " " & operatorText & " " & FormatSqlValue(Value)
    End Select
    '最後如果有內容，就包上一層括號，避免與其他條件邏輯衝突
    If Len(conditionSql) > 0 Then
        conditionSql = "(" & conditionSql & ")"
    End If
    '回傳最終 SQL 片段
    BuildConditionSql = conditionSql
End Function

'-------------------------------------------------------------------------------
' 新增單一條件至集合
' 範例:
'   Dim criterion As New Dictionary
'   criterion("Type") = "Field"
'   ...
'   Call criterion.AddCriterion(criteria)
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

'===============================================================================
' Helper
'===============================================================================

'-------------------------------------------------------------------------------
' 確保物件實體
'-------------------------------------------------------------------------------
Private Sub EnsureCriteria()
    If m_Criteria Is Nothing Then
        Set m_Criteria = New Collection
    End If
End Sub

'-------------------------------------------------------------------------------
' 正規化欄位名稱，加上 [] 以避免保留字衝突
'-------------------------------------------------------------------------------
Private Function FormatFieldName(ByVal fieldName As String) As String
    fieldName = Trim$(fieldName)
    If Len(fieldName) = 0 Then
        FormatFieldName = ""
    ElseIf Left$(fieldName, 1) = "[" And Right$(fieldName, 1) = "]" Then
        FormatFieldName = fieldName
    Else
        FormatFieldName = "[" & fieldName & "]"
    End If
End Function

'-------------------------------------------------------------------------------
' 正規化運算子
'-------------------------------------------------------------------------------
Private Function NormalizeOperator(ByVal opText As String) As String
    opText = Trim$(UCase$(opText))
    If opText = "" Then opText = "="
    NormalizeOperator = opText
End Function

'-------------------------------------------------------------------------------
' 正規化邏輯運算子 (AND/OR)
'-------------------------------------------------------------------------------
Private Function NormalizeLogic(ByVal logicText As String) As String
    logicText = Trim$(UCase$(logicText))
    If logicText <> "OR" Then logicText = "AND"
    NormalizeLogic = logicText
End Function

'-------------------------------------------------------------------------------
' 格式化 SQL Value
'-------------------------------------------------------------------------------
Private Function FormatSqlValue(ByVal Value As Variant) As String
    If IsNull(Value) Then
        FormatSqlValue = "Null"
        Exit Function
    End If

    Select Case VarType(Value)
        Case vbString
            FormatSqlValue = "'" & EscapeSqlString(CStr(Value)) & "'"
        Case vbBoolean
            FormatSqlValue = IIf(CBool(Value), "True", "False")
        Case vbDate
            FormatSqlValue = "#" & Format$(CDate(Value), "yyyy-mm-dd") & "#"
        Case vbByte, vbInteger, vbLong, vbSingle, vbDouble, vbCurrency, vbDecimal
            FormatSqlValue = CStr(Value)
        Case Else
            FormatSqlValue = "'" & EscapeSqlString(CStr(Value)) & "'"
    End Select
End Function

'-------------------------------------------------------------------------------
' LIKE 條件的值，預設使用 %Value%
'-------------------------------------------------------------------------------
Private Function FormatLikeValue(ByVal Value As Variant) As String
    Dim textValue As String
    If IsNull(Value) Then Value = ""
    textValue = "%" & EscapeSqlString(CStr(Value)) & "%"
    FormatLikeValue = "'" & textValue & "'"
End Function

'-------------------------------------------------------------------------------
' 建立 IN (...) 內容
'-------------------------------------------------------------------------------
Private Function BuildInValues(ByVal Value As Variant) As String
    Dim inClause As String
    Dim i As Long

    If IsArray(Value) Then
        For i = LBound(Value) To UBound(Value)
            inClause = AppendListValue(inClause, FormatSqlValue(Value(i)))
        Next i
    Else
        inClause = AppendListValue(inClause, FormatSqlValue(Value))
    End If

    If Len(inClause) = 0 Then
        inClause = "(Null)"
    Else
        inClause = "(" & inClause & ")"
    End If

    BuildInValues = inClause
End Function

'-------------------------------------------------------------------------------
' 建立 BETWEEN 語句內容
'-------------------------------------------------------------------------------
Private Function BuildBetweenSql(ByVal fieldName As String, ByVal Value As Variant) As String
    Dim startValue As Variant
    Dim endValue As Variant

    If IsArray(Value) And UBound(Value) >= LBound(Value) + 1 Then
        startValue = Value(LBound(Value))
        endValue = Value(LBound(Value) + 1)
    Else
        startValue = Value
        endValue = Value
    End If

    BuildBetweenSql = fieldName & " BETWEEN " & _
                      FormatSqlValue(startValue) & " AND " & _
                      FormatSqlValue(endValue)
End Function

'-------------------------------------------------------------------------------
' 串接清單值
'-------------------------------------------------------------------------------
Private Function AppendListValue(ByVal listText As String, ByVal ValueText As String) As String
    If Len(ValueText) = 0 Then
        AppendListValue = listText
    ElseIf Len(listText) = 0 Then
        AppendListValue = ValueText
    Else
        AppendListValue = listText & ", " & ValueText
    End If
End Function

'-------------------------------------------------------------------------------
' SQL 字串跳脫
'-------------------------------------------------------------------------------
Private Function EscapeSqlString(ByVal ValueText As String) As String
    EscapeSqlString = Replace(ValueText, "'", "''")
End Function
