VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SqlEtlBuilder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: SqlEtlBuilder
' Purpose: High-level ETL operations builder (模擬 IDEA script 模式)
'
' Operations:
'   - JoinTables - 資料表聯結 (模擬 db.JoinDatabase)
'   - AppendTables - 資料表附加 (模擬 db.AppendDatabase)
'   - SummarizeBy - 資料彙總 (模擬 db.Summarization)
'   - ExtractWhere - 資料擷取 (模擬 db.Extraction)
'===============================================================================

'===============================================================================
' JoinTables - 資料表聯結
'===============================================================================

Public Function JoinTables(ByVal primaryTable As String, _
                          ByVal secondaryTable As String, _
                          ByVal matchFields As Variant, _
                          Optional ByVal outputTable As String = "", _
                          Optional ByVal joinType As String = "LEFT", _
                          Optional ByVal includePrimaryFields As Boolean = True, _
                          Optional ByVal secondaryFields As Variant = Empty, _
                          Optional ByVal primaryDb As String = "", _
                          Optional ByVal secondaryDb As String = "", _
                          Optional ByVal outputDb As String = "") As String
    '---------------------------------------------------------------------------
    ' 模擬 IDEA JoinDatabase 操作
    ' 
    ' 參數:
    '   primaryTable: 主要資料表
    '   secondaryTable: 次要資料表
    '   matchFields: 配對欄位 Array(Array("PrimaryField", "SecondaryField"))
    '   outputTable: 輸出表名稱
    '   joinType: "INNER", "LEFT", "RIGHT", "FULL"
    '   includePrimaryFields: 是否包含主表所有欄位
    '   secondaryFields: 次表要包含的欄位 Array("Field1", "Field2")
    '   primaryDb: 主表資料庫路徑
    '   secondaryDb: 次表資料庫路徑
    '   outputDb: 輸出資料庫路徑
    '---------------------------------------------------------------------------
    
    Dim builder As New SqlBuilder
    Dim i As Long
    
    '建立 SELECT 欄位
    If includePrimaryFields Then
        builder.SelectFields "P.*"
    End If
    
    '新增次表欄位
    If Not IsEmpty(secondaryFields) And IsArray(secondaryFields) Then
        For i = LBound(secondaryFields) To UBound(secondaryFields)
            builder.SelectFields "S.[" & secondaryFields(i) & "]"
        Next i
    End If
    
    '如果沒有指定欄位，預設全選
    If builder.Build() Like "*SELECT*" And Not builder.Build() Like "*.*" Then
        builder.SelectAll
    End If
    
    '設定 FROM
    builder.FromTable primaryTable, "P", primaryDb
    
    '設定 JOIN
    Select Case UCase(joinType)
        Case "INNER"
            builder.InnerJoin secondaryTable, "S", secondaryDb
        Case "LEFT"
            builder.LeftJoin secondaryTable, "S", secondaryDb
        Case "RIGHT"
            builder.RightJoin secondaryTable, "S", secondaryDb
        Case Else
            builder.LeftJoin secondaryTable, "S", secondaryDb
    End Select
    
    '設定 ON 條件
    If IsArray(matchFields) Then
        Dim matchPair As Variant
        matchPair = matchFields(0)  ' 取第一組配對
        builder.OnCondition "P.[" & matchPair(0) & "]", "=", "S.[" & matchPair(1) & "]"
    End If
    
    '設定 INTO
    If outputTable <> "" Then
        builder.IntoTable outputTable, outputDb
    End If
    
    JoinTables = builder.Build()
End Function

'===============================================================================
' AppendTables - 資料表附加 (UNION)
'===============================================================================

Public Function AppendTables(ByVal outputTable As String, _
                            Optional ByVal outputDb As String = "", _
                            ParamArray tables() As Variant) As String
    '---------------------------------------------------------------------------
    ' 模擬 IDEA AppendDatabase 操作
    '
    ' 參數:
    '   outputTable: 輸出表名稱
    '   outputDb: 輸出資料庫路徑
    '   tables: 要附加的資料表 Array(Array("Table1", "db1.accdb"), Array("Table2", ""))
    '---------------------------------------------------------------------------
    
    Dim sql As String
    Dim i As Long
    
    sql = "SELECT * " & vbCrLf
    
    If outputTable <> "" Then
        sql = sql & "INTO [" & outputTable & "]"
        If outputDb <> "" Then
            sql = sql & " IN '" & outputDb & "'"
        End If
        sql = sql & vbCrLf
    End If
    
    sql = sql & "FROM (" & vbCrLf
    
    '建立 UNION 查詢
    For i = LBound(tables) To UBound(tables)
        If i > LBound(tables) Then
            sql = sql & "    UNION ALL" & vbCrLf
        End If
        
        Dim tableInfo As Variant
        tableInfo = tables(i)
        
        Dim tableName As String
        Dim dbPath As String
        
        If IsArray(tableInfo) Then
            tableName = tableInfo(0)
            If UBound(tableInfo) > 0 Then
                dbPath = tableInfo(1)
            End If
        Else
            tableName = CStr(tableInfo)
            dbPath = ""
        End If
        
        sql = sql & "    SELECT * FROM [" & tableName & "]"
        If dbPath <> "" Then
            sql = sql & " IN '" & dbPath & "'"
        End If
        sql = sql & vbCrLf
    Next i
    
    sql = sql & ");"
    
    AppendTables = sql
End Function

'===============================================================================
' SummarizeBy - 資料彙總
'===============================================================================

Public Function SummarizeBy(ByVal sourceTable As String, _
                           ByVal groupFields As Variant, _
                           ByVal aggregateFields As Variant, _
                           Optional ByVal outputTable As String = "", _
                           Optional ByVal whereCondition As String = "", _
                           Optional ByVal sourceDb As String = "", _
                           Optional ByVal outputDb As String = "") As String
    '---------------------------------------------------------------------------
    ' 模擬 IDEA Summarization 操作
    '
    ' 參數:
    '   sourceTable: 來源資料表
    '   groupFields: GROUP BY 欄位 Array("Field1", "Field2")
    '   aggregateFields: 聚合欄位 Array(Array("SUM", "Amount", "TotalAmount"))
    '   outputTable: 輸出表名稱
    '   where Condition: WHERE 條件
    '   sourceDb: 來源資料庫路徑
    '   outputDb: 輸出資料庫路徑
    '---------------------------------------------------------------------------
    
    Dim builder As New SqlBuilder
    Dim i As Long
    
    '新增 GROUP BY 欄位到 SELECT
    If IsArray(groupFields) Then
        For i = LBound(groupFields) To UBound(groupFields)
            builder.SelectFields "[" & groupFields(i) & "]"
        Next i
    End If
    
    '新增聚合欄位
    If IsArray(aggregateFields) Then
        For i = LBound(aggregateFields) To UBound(aggregateFields)
            Dim aggInfo As Variant
            aggInfo = aggregateFields(i)
            
            Dim aggFunc As String
            Dim aggField As String
            Dim aggAlias As String
            
            aggFunc = aggInfo(0)
            aggField = aggInfo(1)
            If UBound(aggInfo) > 1 Then
                aggAlias = aggInfo(2)
            Else
                aggAlias = aggFunc & "_" & aggField
            End If
            
            builder.SelectAggregate aggFunc, "[" & aggField & "]", aggAlias
        Next i
    End If
    
    '設定 FROM
    builder.FromTable sourceTable, , sourceDb
    
    '設定 WHERE
    If whereCondition <> "" Then
        builder.WhereCondition whereCondition
    End If
    
    '設定 GROUP BY
    If IsArray(groupFields) Then
        Dim groupFieldList() As Variant
        ReDim groupFieldList(UBound(groupFields) - LBound(groupFields))
        
        For i = LBound(groupFields) To UBound(groupFields)
            groupFieldList(i - LBound(groupFields)) = "[" & groupFields(i) & "]"
        Next i
        
        builder.GroupByFields groupFieldList
    End If
    
    '設定 INTO
    If outputTable <> "" Then
        builder.IntoTable outputTable, outputDb
    End If
    
    SummarizeBy = builder.Build()
End Function

'===============================================================================
' ExtractWhere - 資料擷取
'===============================================================================

Public Function ExtractWhere(ByVal sourceTable As String, _
                            ByVal whereCondition As String, _
                            Optional ByVal outputTable As String = "", _
                            Optional ByVal fields As Variant = Empty, _
                            Optional ByVal sourceDb As String = "", _
                            Optional ByVal outputDb As String = "") As String
    '---------------------------------------------------------------------------
    ' 模擬 IDEA Extraction 操作
    '
    ' 參數:
    '   sourceTable: 來源資料表
    '   whereCondition: WHERE 條件
    '   outputTable: 輸出表名稱
    '   fields: 要擷取的欄位 Array("Field1", "Field2")，空則全選
    '   sourceDb: 來源資料庫路徑
    '   outputDb: 輸出資料庫路徑
    '---------------------------------------------------------------------------
    
    Dim builder As New SqlBuilder
    Dim i As Long
    
    '設定 SELECT 欄位
    If IsEmpty(fields) Or Not IsArray(fields) Then
        builder.SelectAll
    Else
        For i = LBound(fields) To UBound(fields)
            builder.SelectFields "[" & fields(i) & "]"
        Next i
    End If
    
    '設定 FROM
    builder.FromTable sourceTable, , sourceDb
    
    '設定 WHERE
    builder.WhereCondition whereCondition
    
    '設定 INTO
    If outputTable <> "" Then
        builder.IntoTable outputTable, outputDb
    End If
    
    ExtractWhere = builder.Build()
End Function

'===============================================================================
' FullOuterJoin - 全外部連接 (通過 UNION 模擬)
'===============================================================================

Public Function FullOuterJoin(ByVal primaryTable As String, _
                             ByVal secondaryTable As String, _
                             ByVal matchFields As Variant, _
                             Optional ByVal outputTable As String = "", _
                             Optional ByVal primaryDb As String = "", _
                             Optional ByVal secondaryDb As String = "", _
                             Optional ByVal outputDb As String = "") As String
    '---------------------------------------------------------------------------
    ' Access 不支援 FULL OUTER JOIN，使用 LEFT + RIGHT UNION 模擬
    '---------------------------------------------------------------------------
    
    Dim sql As String
    Dim matchPair As Variant
    matchPair = matchFields(0)
    
    sql = "SELECT * " & vbCrLf
    
    If outputTable <> "" Then
        sql = sql & "INTO [" & outputTable & "]"
        If outputDb <> "" Then
            sql = sql & " IN '" & outputDb & "'"
        End If
        sql = sql & vbCrLf
    End If
    
    sql = sql & "FROM (" & vbCrLf
    
    '左連接
    sql = sql & "    SELECT P.*, S.* " & vbCrLf
    sql = sql & "    FROM [" & primaryTable & "]"
    If primaryDb <> "" Then sql = sql & " IN '" & primaryDb & "'"
    sql = sql & " AS P" & vbCrLf
    sql = sql & "    LEFT JOIN [" & secondaryTable & "]"
    If secondaryDb <> "" Then sql = sql & " IN '" & secondaryDb & "'"
    sql = sql & " AS S" & vbCrLf
    sql = sql & "        ON P.[" & matchPair(0) & "] = S.[" & matchPair(1) & "]" & vbCrLf
    
    sql = sql & "    UNION" & vbCrLf
    
    '右連接
    sql = sql & "    SELECT P.*, S.* " & vbCrLf
    sql = sql & "    FROM [" & primaryTable & "]"
    If primaryDb <> "" Then sql = sql & " IN '" & primaryDb & "'"
    sql = sql & " AS P" & vbCrLf
    sql = sql & "    RIGHT JOIN [" & secondaryTable & "]"
    If secondaryDb <> "" Then sql = sql & " IN '" & secondaryDb & "'"
    sql = sql & " AS S" & vbCrLf
    sql = sql & "        ON P.[" & matchPair(0) & "] = S.[" & matchPair(1) & "]" & vbCrLf
    
    sql = sql & ");"
    
    FullOuterJoin = sql
End Function
