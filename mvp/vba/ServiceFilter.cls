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
' Purpose:  管理篩選條件作業的服務
'
' Note:     這裡主要負責執行篩選條件，管理篩選條件由 ServiceFilterCriteria 負責
'           因此該服務主要職責應該是負責運行篩選條件的程序，
'===============================================================================
Private m_Db As DbAccess
Private m_Context As ContextManager
Private m_Schema As DbSchema
Private m_CriteriaSet As Dictionary 'key:String, item:ServiceFilterCriteria


Public Sub Initialize(context As ContextManager)
    Set m_Db = context.DbValid
    Set m_Schema = context.DbSchema
    Set m_Context = context
    Set m_CriteriaSet = New Dictionary
End Sub

'-------------------------------------------------------------------------------
' 執行批次篩選條件組合
'-------------------------------------------------------------------------------
Public Sub ExecuteBatch(ByVal tableName As String)
    On Error GoTo ErrorHandler
    Dim criteria As ServiceFilterCriteria
    Dim sql As String
    Dim key As Variant
    '遍歷篩選條件集合
    For Each key In m_CriteriaSet.Keys
        '檢查資料表
        tableName = "FILTER_RESULT_" & key
        If m_Db.TableExists(tableName) Then m_Db.DropTable (tableName)
        '設定篩選條件
        Set criteria = m_CriteriaSet(key)
        '建立 SQL 字串
        'sql = criteria.BuildConditionSql
        '執行篩選條件
        m_Db.ExecuteNonQuery sql
    Next key
ErrorHandler:
    Debug.Print "ExecuteBatch:" & Err.Number & " - " & Err.Description
End Sub


'-------------------------------------------------------------------------------
' 處理篩選條件集合
'-------------------------------------------------------------------------------
Public Sub ProcessCriteriaSet(ByVal criteriaSet As Dictionary, ByVal source As String)
    On Error GoTo ErrorHandler
    '檢查條件集合
    
    '判別條件來源表單（格式不一樣）
    If source = "current" Then
        Debug.Print "Processing [Current]:"
    ElseIf source = "legacy" Then
        Debug.Print "Processing [Legacy]:"
        Dim state As Dictionary
        Dim key As Variant
        For Each key In criteriaSet.Keys
            '新增條件組合
            Call AddCriteria(key)
            '轉換為條件
            Set state = criteriaSet(key)
            
            Dim criteria As Dictionary
            'Set criteria = MapLegacyState(key, state)
            Dim item As Variant
            For Each item In criteria
                Call AddCriterion(key, item)
            Next item
        Next key
        
    Else
        Exit Sub
    End If
ErrorHandler:
    Debug.Print "  - ProcessCriteriaSet:" & Err.Number & " - " & Err.Description
End Sub

'===============================================================================
' Helper
'===============================================================================

'-------------------------------------------------------------------------------
' 新增一個條件組合至集合內（key = 使用情境名稱）
'-------------------------------------------------------------------------------
Public Sub AddCriteria(ByVal key As String)
    On Error GoTo ErrorHandler
    Dim criteria As New ServiceFilterCriteria
    Call criteria.Initialize(m_Context)
    Call m_CriteriaSet.Add(criteria, key)
    Exit Sub
ErrorHandler:
    Debug.Print "  - AddCriteria:" & Err.Number & " - " & Err.Description
End Sub

'-------------------------------------------------------------------------------
' 移除指定鍵值的條件組合
'-------------------------------------------------------------------------------
Public Sub RemoveCriteria(ByVal key As String)
    On Error GoTo ErrorHandler
    ' key 已經由使用者輸入過，因此前端的 ListBox 可以選擇目前儲存的條件組合
    ' 使用者選取後，傳入參數為 key 來指定使用者選擇的條件組合做移除
    Call m_CriteriaSet.Remove(key)
    Exit Sub
ErrorHandler:
    Debug.Print "  - RemoveCriteria:" & Err.Number & " - " & Err.Description
End Sub

'-------------------------------------------------------------------------------
' 增加一個篩選條件至「指定鍵值」的條件組合內
'-------------------------------------------------------------------------------
Public Sub AddCriterion(ByVal key As String, ByVal criterion As Dictionary)
    On Error GoTo ErrorHandler
    Dim criteria As ServiceFilterCriteria
    Set criteria = GetCriteria(key)
    Call criteria.AddCriterion(criterion)
    Exit Sub
ErrorHandler:
    Debug.Print "  - AddCriterion:" & Err.Number & " - " & Err.Description
End Sub

'-------------------------------------------------------------------------------
' 移除指定條件組合鍵值的篩選條件
'-------------------------------------------------------------------------------
Public Sub RemoveCriterion(ByVal key As String, ByVal index As Long)
    On Error GoTo ErrorHandler
    Dim criteria As ServiceFilterCriteria
    Set criteria = GetCriteria(key)
    Call criteria.RemoveCriterion(index)
    Exit Sub
ErrorHandler:
    Debug.Print "  - RemoveCriterion:" & Err.Number & " - " & Err.Description
End Sub

'-------------------------------------------------------------------------------
' 取出指定鍵值的條件組合（內部使用）
'-------------------------------------------------------------------------------
Private Function GetCriteria(ByVal key As String) As ServiceFilterCriteria
    On Error Resume Next '若已存在 key 則忽略
    Set GetCriteria = m_CriteriaSet(key)
    On Error GoTo 0
End Function


'-------------------------------------------------------------------------------
' 設置條件組合，傳入參數為該條件組合的鍵值及對應的字典
' 由於 Legacy 方法是藉由元件名稱對應 BOOLEAN 值來啟用指定篩選條件
' 在單個條件組合中若啟用多個項目
' 最後仍由 ServiceFilterCriteria 合併為 SQL 字串
'-------------------------------------------------------------------------------
Public Sub MapLegacyState(ByVal key As String, state As Dictionary)
    Dim criterion As Dictionary
    
    If state("chkPostedOnWeekend") Then
        '【總帳日期在週末】
        ' WHERE CDate([PostDate]) IN (
        '     SELECT [DateKey]
        '     FROM DATE_DIMENSION
        '     WHERE [IsWeekend] = True
        ' )
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Date"
            criterion("field") = "CDate([" & .JE.PostDate & "])"
            criterion("operator") = "IN"
            criterion("value") = "SELECT [" & .DateDimension.DateKey & "] " & _
                                 "FROM " & .DateDimension.name & " " & _
                                 "WHERE [" & .DateDimension.IsWeekend & "] = True"
            criterion("logic") = "AND"
            criterion("description") = "【總帳日期在週末】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkApprovedOnWeekend") Then
        '【核准日期在週末】
        ' WHERE CDate([ApprovalDate]) IN (
        '     SELECT [DateKey]
        '     FROM DATE_DIMENSION
        '     WHERE [IsWeekend] = True
        ' )
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Date"
            criterion("field") = "CDate([" & .JE.ApprovalDate & "])"
            criterion("operator") = "IN"
            criterion("value") = "SELECT [" & .DateDimension.DateKey & "] " & _
                                 "FROM " & .DateDimension.name & " " & _
                                 "WHERE [" & .DateDimension.IsWeekend & "] = True"
            criterion("logic") = "AND"
            criterion("description") = "【核准日期在週末】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkPostedOnHoliday") Then
        '【總帳日期在國定假日】
        ' WHERE CDate([PostDate]) IN (
        '     SELECT [DateKey]
        '     FROM DATE_DIMENSION
        '     WHERE [IsHlodays] = True
        ' )
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Date"
            criterion("field") = "CDate([" & .JE.PostDate & "])"
            criterion("operator") = "IN"
            criterion("value") = "SELECT [" & .DateDimension.DateKey & "]" & _
                                 "FROM " & .DateDimension.name & " " & _
                                 "WHERE [" & .DateDimension.IsHolidays & "] = True"
            criterion("logic") = "AND"
            criterion("description") = "【總帳日期在國定假日】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkApprovedOnHoliday") Then
        '【核准日期在國定假日】
        ' WHERE CDate([ApprovalDate]) IN (
        '     SELECT [DateKey]
        '     FROM DATE_DIMENSION
        '     WHERE [IsHolidays] = True
        ' )
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Date"
            criterion("field") = "CDate([" & .JE.ApprovalDate & "])"
            criterion("operator") = "IN"
            criterion("value") = "SELECT [" & .DateDimension.DateKey & "]" & _
                                 "FROM " & .DateDimension.name & " " & _
                                 "WHERE [" & .DateDimension.IsHolidays & "] = True"
            criterion("logic") = "AND"
            criterion("description") = "【核准日期在國定假日】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkExcludePostedOnMakeupDay") Then
        '【需排除總帳日期在補班日/加班日】
        ' WHERE CDate([PostDate]) NOT IN (
        '     SELECT [DateKey]
        '     FROM DATE_DIMENSION
        '     WHERE [IsMakeupDays] = True
        ' )
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Date"
            criterion("field") = "CDate([" & .JE.PostDate & "])"
            criterion("operator") = "NOT IN"
            criterion("value") = "SELECT [" & .DateDimension.DateKey & "] " & _
                                 "FROM " & .DateDimension.name & " " & _
                                 "WHERE [" & .DateDimension.IsMakeupDays & "] = True"
            criterion("logic") = "AND"
            criterion("description") = "【需排除總帳日期在補班日/加班日】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkExcludeApprovedOnMakeupDay") Then
        '【需排除核准日期在補班日/加班日】
        ' WHERE CDate([ApprovalDate]) NOT IN (
        '     SELECT [DateKey]
        '     FROM DATE_DIMENSION
        '     WHERE [IsMakeupDays] = True
        ' )
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Date"
            criterion("field") = "CDate([" & .JE.ApprovalDate & "])"
            criterion("operator") = "NOT IN" ' 修正為 NOT IN
            criterion("value") = "SELECT [" & .DateDimension.DateKey & "] " & _
                                 "FROM " & .DateDimension.name & " " & _
                                 "WHERE [" & .DateDimension.IsMakeupDays & "] = True"
            criterion("logic") = "AND"
            criterion("description") = "【需排除核准日期在補班日/加班日】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkOnlyDebit") Then
        '【僅考量借方傳票】
        ' WHERE [DrCr] = "D"
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "String"
            criterion("field") = "[" & .JE.DrCr & "]"
            criterion("operator") = "="
            criterion("value") = "'D'"
            criterion("logic") = "AND"
            criterion("description") = "【僅考量借方傳票】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkOnlyCredit") Then
        '【僅考量貸方傳票】
        ' WHERE [DrCr] = <> "D"
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "String"
            criterion("field") = "[" & .JE.DrCr & "]"
            criterion("operator") = "<>"
            criterion("value") = "'D'" ' 非借方即視為貸方 (或視需求改為 = 'C')
            criterion("logic") = "AND"
            criterion("description") = "【僅考量貸方傳票】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkSelectManualEntries") Then
        '【篩選人工編制傳票】
        ' WHERE [IsManual] = True
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = "Boolean"
            criterion("field") = "[" & .JE.IsManual & "]"
            criterion("operator") = "="
            criterion("value") = True
            criterion("logic") = "AND"
            criterion("description") = "【篩選人工編制傳票】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkKeywordFilter") Then
        '【特定文字篩選】
        ' WHERE [_TEXT_] LIKE '*_KEYWORD_*'
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = ""
            criterion("field") = ""
            criterion("operator") = ""
            criterion("value") = ""
            criterion("logic") = ""
            criterion("description") = "【核准日期在週末】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkDateRangeFilter") Then
        '【特定日期區間】
        ' WHERE [_DATE_] BETWEEN #dateRangeStart# AND #dateRangeEnd#
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = ""
            criterion("field") = ""
            criterion("operator") = ""
            criterion("value") = ""
            criterion("logic") = ""
            criterion("description") = "【核准日期在週末】"
        End With
        Call AddCriterion(key, criterion)
    End If
    If state("chkNumericValueFilter") Then
        '【特定數值區間】
        ' WHERE [_NUM_] BETWEEN numericValueStart AND numericValueEnd
        Set criterion = New Dictionary
        With m_Schema
            criterion("type") = ""
            criterion("field") = ""
            criterion("operator") = ""
            criterion("value") = ""
            criterion("logic") = ""
            criterion("description") = "【核准日期在週末】"
        End With
        Call AddCriterion(key, criterion)
    End If
    
End Sub
