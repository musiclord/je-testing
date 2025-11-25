VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceDateDimension"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ServiceDateDimension
' Purpose: 管理日期維度表的建立與維護
'
' Responsibilities:
'   - 建立日期維度表
'   - 合併假日資料
'   - 合併補班日資料
'   - 合併週末資料
'===============================================================================

Private m_Context As Object  ' ContextManager
Private m_Db As Object       ' DbAccess
Private m_Schema As Object   ' DbSchema

'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize(ByVal context As Object)
    Set m_Context = context
    Set m_Db = context.DbAccess
    Set m_Schema = context.DbSchema
End Sub

'===============================================================================
' Date Dimension Creation
'===============================================================================

Public Function CreateDateDimensionTable() As Boolean
    '---------------------------------------------------------------------------
    ' 建立日期維度表
    ' 涵蓋 PeriodStart 到 PeriodEnd 之間的所有日期
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    CreateDateDimensionTable = False
    
    m_Context.Logger.LogInfo "Creating Date Dimension Table"
    
    '刪除舊表
    If m_Db.TableExists(m_Schema.DateDimension.Name) Then
        m_Db.DropTable m_Schema.DateDimension.Name
    End If
    
    '建立日期維度表結構
    Dim sql As String
    sql = "CREATE TABLE [" & m_Schema.DateDimension.Name & "] (" & vbCrLf & _
          "    [" & m_Schema.DateDimension.DateKey & "] TEXT(8) PRIMARY KEY, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.Year & "] INTEGER, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.Month & "] INTEGER, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.Day & "] INTEGER, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.DayOfWeek & "] INTEGER, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.IsWeekend & "] YESNO DEFAULT False, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.IsHoliday & "] YESNO DEFAULT False, " & vbCrLf & _
          "    [" & m_Schema.DateDimension.IsCompensatoryWorkday & "] YESNO DEFAULT False" & vbCrLf & _
          ");"
    m_Db.ExecuteNonQuery sql
    
    '填充日期資料
    Dim startDate As Date
    Dim endDate As Date
    Dim currentDate As Date
    
    startDate = m_Context.PeriodStart
    endDate = m_Context.PeriodEnd
    
    m_Db.BeginTrans
    
    currentDate = startDate
    Do While currentDate <= endDate
        Call InsertDateRecord(currentDate)
        currentDate = DateAdd("d", 1, currentDate)
    Loop
    
    m_Db.CommitTrans
    
    m_Context.Logger.LogInfo "Date Dimension Table created successfully"
    CreateDateDimensionTable = True
    Exit Function
    
ErrorHandler:
    m_Db.RollbackTrans
    m_Context.Logger.LogError "CreateDateDimensionTable failed", Err.Number
    CreateDateDimensionTable = False
End Function

'===============================================================================
' Data Merging
'===============================================================================

Public Function MergeHolidays(ByVal holidayRecordset As DAO.Recordset) As Boolean
    '---------------------------------------------------------------------------
    ' 合併假日資料到日期維度表
    ' 參數: holidayRecordset - 包含假日日期的 Recordset
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    MergeHolidays = False
    
    If holidayRecordset Is Nothing Then Exit Function
    If holidayRecordset.EOF And holidayRecordset.BOF Then Exit Function
    
    m_Context.Logger.LogInfo "Merging holidays"
    
    Dim sql As String
    Dim dateKey As String
    Dim count As Long
    
    m_Db.BeginTrans
    
    holidayRecordset.MoveFirst
    Do While Not holidayRecordset.EOF
        dateKey = Format(holidayRecordset.Fields("DateValue").Value, "yyyymmdd")
        
        '更新假日標記
        sql = "UPDATE [" & m_Schema.DateDimension.Name & "] " & vbCrLf & _
              "SET [" & m_Schema.DateDimension.IsHoliday & "] = True " & vbCrLf & _
              "WHERE [" & m_Schema.DateDimension.DateKey & "] = '" & dateKey & "';"
        m_Db.ExecuteNonQuery sql, False
        
        count = count + 1
        holidayRecordset.MoveNext
    Loop
    
    m_Db.CommitTrans
    
    m_Context.Logger.LogInfo "Merged " & count & " holidays"
    MergeHolidays = True
    Exit Function
    
ErrorHandler:
    m_Db.RollbackTrans
    m_Context.Logger.LogError "MergeHolidays failed", Err.Number
    MergeHolidays = False
End Function

Public Function MergeMakeupDays(ByVal makeupRecordset As DAO.Recordset) As Boolean
    '---------------------------------------------------------------------------
    ' 合併補班日資料到日期維度表
    ' 補班日：IsWeekend = False, IsCompensatoryWorkday = True
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    MergeMakeupDays = False
    
    If makeupRecordset Is Nothing Then Exit Function
    If makeupRecordset.EOF And makeupRecordset.BOF Then Exit Function
    
    m_Context.Logger.LogInfo "Merging makeup workdays"
    
    Dim sql As String
    Dim dateKey As String
    Dim count As Long
    
    m_Db.BeginTrans
    
    makeupRecordset.MoveFirst
    Do While Not makeupRecordset.EOF
        dateKey = Format(makeupRecordset.Fields("DateValue").Value, "yyyymmdd")
        
        '更新補班日標記
        sql = "UPDATE [" & m_Schema.DateDimension.Name & "] " & vbCrLf & _
              "SET [" & m_Schema.DateDimension.IsWeekend & "] = False, " & vbCrLf & _
              "    [" & m_Schema.DateDimension.IsCompensatoryWorkday & "] = True " & vbCrLf & _
              "WHERE [" & m_Schema.DateDimension.DateKey & "] = '" & dateKey & "';"
        m_Db.ExecuteNonQuery sql, False
        
        count = count + 1
        makeupRecordset.MoveNext
    Loop
    
    m_Db.CommitTrans
    
    m_Context.Logger.LogInfo "Merged " & count & " makeup workdays"
    MergeMakeupDays = True
    Exit Function
    
ErrorHandler:
    m_Db.RollbackTrans
    m_Context.Logger.LogError "MergeMakeupDays failed", Err.Number
    MergeMakeupDays = False
End Function

Public Function MergeWeekends(ByVal weekendIndices As Variant) As Boolean
    '---------------------------------------------------------------------------
    ' 合併週末資料到日期維度表
    ' 參數: weekendIndices - Array(1, 7) 表示星期日和星期六
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    MergeWeekends = False
    
    If Not IsArray(weekendIndices) Then Exit Function
    
    m_Context.Logger.LogInfo "Merging weekends"
    
    Dim sql As String
    Dim i As Long
    Dim whereClause As String
    
    '建立 WHERE 條件
    For i = LBound(weekendIndices) To UBound(weekendIndices)
        If i > LBound(weekendIndices) Then whereClause = whereClause & " OR "
        whereClause = whereClause & "[" & m_Schema.DateDimension.DayOfWeek & "] = " & CStr(weekendIndices(i))
    Next i
    
    '更新週末標記
    sql = "UPDATE [" & m_Schema.DateDimension.Name & "] " & vbCrLf & _
          "SET [" & m_Schema.DateDimension.IsWeekend & "] = True " & vbCrLf & _
          "WHERE " & whereClause & ";"
    m_Db.ExecuteNonQuery sql
    
    m_Context.Logger.LogInfo "Weekends merged successfully"
    MergeWeekends = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "MergeWeekends failed", Err.Number
    MergeWeekends = False
End Function

'===============================================================================
' Helper Methods
'===============================================================================

Private Sub InsertDateRecord(ByVal dateValue As Date)
    '插入單日記錄
    On Error Resume Next
    
    Dim sql As String
    Dim dateKey As String
    Dim yearValue As Integer
    Dim monthValue As Integer
    Dim dayValue As Integer
    Dim dayOfWeekValue As Integer
    Dim isWeekend As Boolean
    
    dateKey = Format(dateValue, "yyyymmdd")
    yearValue = Year(dateValue)
    monthValue = Month(dateValue)
    dayValue = Day(dateValue)
    dayOfWeekValue = Weekday(dateValue, vbSunday)  ' 1=Sunday, 7=Saturday
    isWeekend = (dayOfWeekValue = 1 Or dayOfWeekValue = 7)  ' 預設週末
    
    sql = "INSERT INTO [" & m_Schema.DateDimension.Name & "] " & vbCrLf & _
          "([" & m_Schema.DateDimension.DateKey & "], " & _
          "[" & m_Schema.DateDimension.Year & "], " & _
          "[" & m_Schema.DateDimension.Month & "], " & _
          "[" & m_Schema.DateDimension.Day & "], " & _
          "[" & m_Schema.DateDimension.DayOfWeek & "], " & _
          "[" & m_Schema.DateDimension.IsWeekend & "]) " & vbCrLf & _
          "VALUES ('" & dateKey & "', " & _
          yearValue & ", " & _
          monthValue & ", " & _
          dayValue & ", " & _
          dayOfWeekValue & ", " & _
          IIf(isWeekend, "True", "False") & ");"
    
    m_Db.ExecuteNonQuery sql, False
    
    On Error GoTo 0
End Sub

'===============================================================================
' Cleanup
'===============================================================================

Private Sub Class_Terminate()
    Set m_Context = Nothing
    Set m_Db = Nothing
    Set m_Schema = Nothing
End Sub
