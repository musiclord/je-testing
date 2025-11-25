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

' SqlBuilder.cls
' Fluent Interface for building SQL queries

Private mSelectFields As String
Private mFromTable As String
Private mWhereCondition As String
Private mGroupByFields As String
Private mOrderByFields As String

' 初始化
Private Sub Class_Initialize()
    mSelectFields = ""
    mFromTable = ""
    mWhereCondition = ""
    mGroupByFields = ""
    mOrderByFields = ""
End Sub

' SELECT 子句 (注意:ParamArray 本身已經是選用的,不需要 Optional 關鍵字)
Public Function SelectFields(ParamArray fields() As Variant) As SqlBuilder
    Dim i As Long
    Dim fieldList As String
    
    For i = LBound(fields) To UBound(fields)
        If fieldList <> "" Then fieldList = fieldList & ", "
        fieldList = fieldList & CStr(fields(i))
    Next i
    
    mSelectFields = fieldList
    Set SelectFields = Me
End Function

' FROM 子句
Public Function FromTable(tableName As String) As SqlBuilder
    mFromTable = tableName
    Set FromTable = Me
End Function

' WHERE 子句
Public Function WhereCondition(condition As String) As SqlBuilder
    mWhereCondition = condition
    Set WhereCondition = Me
End Function

' GROUP BY 子句 (注意:ParamArray 本身已經是選用的,不需要 Optional 關鍵字)
Public Function GroupByFields(ParamArray fields() As Variant) As SqlBuilder
    Dim i As Long
    Dim fieldList As String
    
    For i = LBound(fields) To UBound(fields)
        If fieldList <> "" Then fieldList = fieldList & ", "
        fieldList = fieldList & CStr(fields(i))
    Next i
    
    mGroupByFields = fieldList
    Set GroupByFields = Me
End Function

' ORDER BY 子句 (注意:ParamArray 本身已經是選用的,不需要 Optional 關鍵字)
Public Function OrderByFields(ParamArray fields() As Variant) As SqlBuilder
    Dim i As Long
    Dim fieldList As String
    
    For i = LBound(fields) To UBound(fields)
        If fieldList <> "" Then fieldList = fieldList & ", "
        fieldList = fieldList & CStr(fields(i))
    Next i
    
    mOrderByFields = fieldList
    Set OrderByFields = Me
End Function

' 建立最終 SQL 字串
Public Function Build() As String
    Dim sql As String
    
    ' SELECT 子句
    If mSelectFields <> "" Then
        sql = "SELECT " & mSelectFields
    Else
        sql = "SELECT *"
    End If
    
    ' FROM 子句
    If mFromTable <> "" Then
        sql = sql & " FROM " & mFromTable
    End If
    
    ' WHERE 子句
    If mWhereCondition <> "" Then
        sql = sql & " WHERE " & mWhereCondition
    End If
    
    ' GROUP BY 子句
    If mGroupByFields <> "" Then
        sql = sql & " GROUP BY " & mGroupByFields
    End If
    
    ' ORDER BY 子句
    If mOrderByFields <> "" Then
        sql = sql & " ORDER BY " & mOrderByFields
    End If
    
    Build = sql
End Function

' 重置建構器
Public Function Reset() As SqlBuilder
    Call Class_Initialize
    Set Reset = Me
End Function

