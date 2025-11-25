VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SqlBuilder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: SqlBuilder
' Purpose: Fluent Interface for building SQL queries
'
' Features:
'   - SELECT (fields, aggregates, *)
'   - FROM (table, with database path)
'   - JOIN (INNER, LEFT, RIGHT, FULL OUTER)
'   - WHERE (conditions with AND/OR)
'   - GROUP BY / HAVING
'   - ORDER BY
'   - INTO (SELECT INTO for ETL)
'
' Usage:
'   Dim sql As String
'   sql = New SqlBuilder _
'       .SelectFields("Field1", "Field2") _
'       .FromTable("Table1") _
'       .WhereCondition("[Amount] > 1000") _
'       .Build()
'===============================================================================

'-- SELECT clause
Private m_SelectFields As String
Private m_SelectDistinct As Boolean

'-- FROM clause
Private m_FromTable As String
Private m_FromAlias As String
Private m_FromDbPath As String

'-- JOIN clauses
Private m_Joins As Object  ' Collection of join clauses

'-- WHERE clause
Private m_WhereConditions As String

'-- GROUP BY clause
Private m_GroupByFields As String

'-- HAVING clause
Private m_HavingCondition As String

'-- ORDER BY clause
Private m_OrderByFields As String

'-- INTO clause
Private m_IntoTable As String
Private m_IntoDbPath As String

'===============================================================================
' Initialization
'===============================================================================

Private Sub Class_Initialize()
    Call Reset
End Sub

Public Function Reset() As SqlBuilder
    m_SelectFields = ""
    m_SelectDistinct = False
    m_FromTable = ""
    m_FromAlias = ""
    m_FromDbPath = ""
    Set m_Joins = CreateObject("Scripting.Dictionary")
    m_WhereConditions = ""
    m_GroupByFields = ""
    m_HavingCondition = ""
    m_OrderByFields = ""
    m_IntoTable = ""
    m_IntoDbPath = ""
    Set Reset = Me
End Function

'===============================================================================
' SELECT Clause
'===============================================================================

Public Function SelectFields(ParamArray fields() As Variant) As SqlBuilder
    '選擇特定欄位
    Dim i As Long
    Dim fieldList As String
    
    For i = LBound(fields) To UBound(fields)
        If fieldList <> "" Then fieldList = fieldList & ", "
        fieldList = fieldList & CStr(fields(i))
    Next i
    
    m_SelectFields = fieldList
    Set SelectFields = Me
End Function

Public Function SelectAll(Optional ByVal tableAlias As String = "") As SqlBuilder
    '選擇所有欄位
    If tableAlias <> "" Then
        m_SelectFields = tableAlias & ".*"
    Else
        m_SelectFields = "*"
    End If
    Set SelectAll = Me
End Function

Public Function SelectDistinct() As SqlBuilder
    '設定 DISTINCT
    m_SelectDistinct = True
    Set SelectDistinct = Me
End Function

Public Function SelectAggregate(ByVal aggFunc As String, _
                               ByVal field As String, _
                               Optional ByVal alias As String = "") As SqlBuilder
    '新增聚合函數欄位
    '範例: SelectAggregate("SUM", "[Amount]", "TotalAmount")
    Dim aggField As String
    aggField = UCase(aggFunc) & "(" & field & ")"
    
    If alias <> "" Then
        aggField = aggField & " AS [" & alias & "]"
    End If
    
    If m_SelectFields <> "" Then
        m_SelectFields = m_SelectFields & ", " & aggField
    Else
        m_SelectFields = aggField
    End If
    
    Set SelectAggregate = Me
End Function

'===============================================================================
' FROM Clause
'===============================================================================

Public Function FromTable(ByVal tableName As String, _
                         Optional ByVal alias As String = "", _
                         Optional ByVal dbPath As String = "") As SqlBuilder
    '設定來源資料表
    m_FromTable = tableName
    m_FromAlias = alias
    m_FromDbPath = dbPath
    Set FromTable = Me
End Function

'===============================================================================
' JOIN Clauses
'===============================================================================

Public Function InnerJoin(ByVal tableName As String, _
                         Optional ByVal alias As String = "", _
                         Optional ByVal dbPath As String = "") As SqlBuilder
    '新增 INNER JOIN
    Call AddJoin("INNER JOIN", tableName, alias, dbPath)
    Set InnerJoin = Me
End Function

Public Function LeftJoin(ByVal tableName As String, _
                        Optional ByVal alias As String = "", _
                        Optional ByVal dbPath As String = "") As SqlBuilder
    '新增 LEFT JOIN
    Call AddJoin("LEFT JOIN", tableName, alias, dbPath)
    Set LeftJoin = Me
End Function

Public Function RightJoin(ByVal tableName As String, _
                         Optional ByVal alias As String = "", _
                         Optional ByVal dbPath As String = "") As SqlBuilder
    '新增 RIGHT JOIN
    Call AddJoin("RIGHT JOIN", tableName, alias, dbPath)
    Set RightJoin = Me
End Function

Public Function OnCondition(ByVal leftField As String, _
                           ByVal operator As String, _
                           ByVal rightField As String) As SqlBuilder
    '設定最後一個 JOIN 的 ON 條件
    If m_Joins.Count > 0 Then
        Dim lastKey As String
        Dim keys As Variant
        keys = m_Joins.Keys
        lastKey = keys(UBound(keys))
        
        Dim joinInfo As Variant
        joinInfo = m_Joins(lastKey)
        
        'Update ON condition (index 4)
        joinInfo(4) = leftField & " " & operator & " " & rightField
        m_Joins(lastKey) = joinInfo
    End If
    
    Set OnCondition = Me
End Function

Private Sub AddJoin(ByVal joinType As String, _
                    ByVal tableName As String, _
                    ByVal alias As String, _
                    ByVal dbPath As String)
    '內部方法：新增 JOIN
    Dim joinKey As String
    joinKey = "JOIN_" & (m_Joins.Count + 1)
    
    'Store: (joinType, tableName, alias, dbPath, onCondition)
    m_Joins(joinKey) = Array(joinType, tableName, alias, dbPath, "")
End Sub

'===============================================================================
' WHERE Clause
'===============================================================================

Public Function WhereCondition(ByVal condition As String) As SqlBuilder
    '設定 WHERE 條件
    m_WhereConditions = condition
    Set WhereCondition = Me
End Function

Public Function AndWhere(ByVal condition As String) As SqlBuilder
    '新增 AND 條件
    If m_WhereConditions <> "" Then
        m_WhereConditions = m_WhereConditions & " AND " & condition
    Else
        m_WhereConditions = condition
    End If
    Set AndWhere = Me
End Function

Public Function OrWhere(ByVal condition As String) As SqlBuilder
    '新增 OR 條件
    If m_WhereConditions <> "" Then
        m_WhereConditions = "(" & m_WhereConditions & ") OR (" & condition & ")"
    Else
        m_WhereConditions = condition
    End If
    Set OrWhere = Me
End Function

'===============================================================================
' GROUP BY Clause
'===============================================================================

Public Function GroupByFields(ParamArray fields() As Variant) As SqlBuilder
    '設定 GROUP BY 欄位
    Dim i As Long
    Dim fieldList As String
    
    For i = LBound(fields) To UBound(fields)
        If fieldList <> "" Then fieldList = fieldList & ", "
        fieldList = fieldList & CStr(fields(i))
    Next i
    
    m_GroupByFields = fieldList
    Set GroupByFields = Me
End Function

'===============================================================================
' HAVING Clause
'===============================================================================

Public Function HavingCondition(ByVal condition As String) As SqlBuilder
    '設定 HAVING 條件
    m_HavingCondition = condition
    Set HavingCondition = Me
End Function

'===============================================================================
' ORDER BY Clause
'===============================================================================

Public Function OrderByFields(ParamArray fields() As Variant) As SqlBuilder
    '設定 ORDER BY 欄位
    Dim i As Long
    Dim fieldList As String
    
    For i = LBound(fields) To UBound(fields)
        If fieldList <> "" Then fieldList = fieldList & ", "
        fieldList = fieldList & CStr(fields(i))
    Next i
    
    m_OrderByFields = fieldList
    Set OrderByFields = Me
End Function

'===============================================================================
' INTO Clause
'===============================================================================

Public Function IntoTable(ByVal tableName As String, _
                         Optional ByVal dbPath As String = "") As SqlBuilder
    '設定 INTO 目標表（用於 SELECT INTO）
    m_IntoTable = tableName
    m_IntoDbPath = dbPath
    Set IntoTable = Me
End Function

'===============================================================================
' Build SQL
'===============================================================================

Public Function Build() As String
    '建立最終 SQL 字串
    Dim sql As String
    
    '-- SELECT 子句
    If m_SelectFields <> "" Then
        sql = "SELECT "
        If m_SelectDistinct Then sql = sql & "DISTINCT "
        sql = sql & m_SelectFields
    Else
        sql = "SELECT *"
    End If
    
    '-- INTO 子句 (必須在 FROM 之前)
    If m_IntoTable <> "" Then
        sql = sql & vbCrLf & "INTO [" & m_IntoTable & "]"
        If m_IntoDbPath <> "" Then
            sql = sql & " IN '" & m_IntoDbPath & "'"
        End If
    End If
    
    '-- FROM 子句
    If m_FromTable <> "" Then
        sql = sql & vbCrLf & "FROM "
        If m_FromDbPath <> "" Then
            sql = sql & "[" & m_FromTable & "] IN '" & m_FromDbPath & "'"
        Else
            sql = sql & "[" & m_FromTable & "]"
        End If
        
        If m_FromAlias <> "" Then
            sql = sql & " AS " & m_FromAlias
        End If
    End If
    
    '-- JOIN 子句
    If m_Joins.Count > 0 Then
        Dim key As Variant
        For Each key In m_Joins.Keys
            Dim joinInfo As Variant
            joinInfo = m_Joins(key)
            
            Dim joinType As String
            Dim joinTable As String
            Dim joinAlias As String
            Dim joinDbPath As String
            Dim joinOn As String
            
            joinType = joinInfo(0)
            joinTable = joinInfo(1)
            joinAlias = joinInfo(2)
            joinDbPath = joinInfo(3)
            joinOn = joinInfo(4)
            
            sql = sql & vbCrLf & joinType & " "
            
            If joinDbPath <> "" Then
                sql = sql & "[" & joinTable & "] IN '" & joinDbPath & "'"
            Else
                sql = sql & "[" & joinTable & "]"
            End If
            
            If joinAlias <> "" Then
                sql = sql & " AS " & joinAlias
            End If
            
            If joinOn <> "" Then
                sql = sql & vbCrLf & "    ON " & joinOn
            End If
        Next key
    End If
    
    '-- WHERE 子句
    If m_WhereConditions <> "" Then
        sql = sql & vbCrLf & "WHERE " & m_WhereConditions
    End If
    
    '-- GROUP BY 子句
    If m_GroupByFields <> "" Then
        sql = sql & vbCrLf & "GROUP BY " & m_GroupByFields
    End If
    
    '-- HAVING 子句
    If m_HavingCondition <> "" Then
        sql = sql & vbCrLf & "HAVING " & m_HavingCondition
    End If
    
    '-- ORDER BY 子句
    If m_OrderByFields <> "" Then
        sql = sql & vbCrLf & "ORDER BY " & m_OrderByFields
    End If
    
    sql = sql & ";"
    Build = sql
End Function

'===============================================================================
' Cleanup
'===============================================================================

Private Sub Class_Terminate()
    Set m_Joins = Nothing
End Sub
