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
' Purpose:  負責管理日期維度表 (Date Dimension)
'           以每日為單位提供標準化的日期屬性，其用途為:
'               - 提供唯一的日期鍵值 YYYYMMDD 為主鍵
'               - 儲存日期相關屬性如 Year, Month, Day, DayOfWeek
'               - 標示是否為周末(IsWeekend)、假日(IsHolidays)、補班日(IsMakeupDays)
'               - 提供假期與補班日的文字描述 (HolidaysDesc, MakeupDaysDesc)
' NonBusinessDays:
'     - Holidays: 國定假日
'     - MakeUpDays: 補班日/加班日
'     - Weekend: 週末
'===============================================================================
'--
Private m_Context As ContextManager
Private m_Db As DbAccess
'--
Private Const FLD_DATEKEY As String = "DateKey"                   '[DATE]   唯一主鍵，格式: YYYYMMDD
Private Const FLD_YEAR As String = "Year"                         '[NUM]    西元年 (1900-?)
Private Const FLD_MONTH As String = "Month"                       '[NUM]    月份 (1-12)
Private Const FLD_DAY As String = "Day"                           '[NUM]    日 (1-31)
Private Const FLD_DAY_OF_WEEK As String = "DayOfWeek"             '[NUM]    天 (1-7)
Private Const FLD_IS_WEEKEND As String = "IsWeekend"              '[Y/N]    -1/0 (系統自動產生)
Private Const FLD_IS_HOLIDAYS As String = "IsHolidays"            '[Y/N]    -1/0 (由使用者上傳的資料覆寫)
Private Const FLD_IS_MAKEUP_DAYS As String = "IsMakeupDays"       '[Y/N]    -1/0 (由使用者上傳的資料覆寫)
Private Const FLD_HOLIDAYS_DESC As String = "HolidaysDesc"        '[CHAR]   假期說明 (選填)
Private Const FLD_MAKEUP_DAYS_DESC As String = "MakeupDaysDesc"   '[CHAR]   補班日說明 (選填)

Public Sub Initialize(context As ContextManager)
    Set m_Context = context
    Set m_Db = context.DbInput
End Sub

Public Sub MergeWeekends(ByVal selectedDays As Variant)
    '---------------------------------------------------------------------------
    ' 將使用者於表單中設定的周末，合併至 DateDimension 資料表
    '---------------------------------------------------------------------------
    Dim dayList As String
    Dim item As Variant
    Dim affectedCount As Long
    '將使用者勾選的星期數字組合成逗號分隔字串
    For Each item In selectedDays
        If dayList <> "" Then dayList = dayList & ","
        dayList = dayList & item
    Next item
    '清除欄位資料
    Dim sql As String
    sql = "UPDATE " & TBL_DATE_DIMENSION & " SET [" & FLD_IS_WEEKEND & "] = False;"
    Call m_Db.ExecuteNonQuery(sql)
    'Weekday(d) 默認星期日為第一天，回傳編碼
    sql = "UPDATE " & TBL_DATE_DIMENSION & " " & vbCrLf & _
          "SET [" & FLD_IS_WEEKEND & "] = True " & vbCrLf & _
          "WHERE Weekday([" & FLD_DATEKEY & "]) IN (" & dayList & ");"
    affectedCount = m_Db.ExecuteNonQuery(sql)
    Debug.Print "  - 已套用 " & selectedDays.Count & " 個週末設定 (共影響 " & affectedCount & " 筆記錄)"
End Sub

Public Sub MergeHolidays(rsHolidays As DAO.Recordset)
    '---------------------------------------------------------------------------
    ' 將使用者於工作表匯入的假期資料，合併至 DateDimension 資料表
    '---------------------------------------------------------------------------
    If rsHolidays Is Nothing Then Exit Sub
    If rsHolidays.EOF Then Exit Sub
    
    Dim totalCount As Long
    Dim affectedCount As Long
    
    rsHolidays.MoveFirst
    If rsHolidays.RecordCount = -1 Then rsHolidays.MoveLast
    totalCount = rsHolidays.RecordCount
    rsHolidays.MoveFirst
    
    Do While Not rsHolidays.EOF
        '預期 rsHolidays 有欄位 Date(DATE), Description(TEXT)
        Dim holidayDate As Variant
        Dim holidayDesc As String
        holidayDate = rsHolidays.Fields(0).Value
        If rsHolidays.Fields.Count > 1 And Not IsNull(rsHolidays.Fields(1).Value) Then
            holidayDesc = rsHolidays.Fields(1).Value
        Else
            holidayDesc = vbNullString
        End If
        If IsDate(holidayDate) Then
            Dim sql As String
            sql = "UPDATE " & TBL_DATE_DIMENSION & " " & vbCrLf & _
                  "SET [" & FLD_IS_HOLIDAYS & "] = True, " & vbCrLf & _
                  "    [" & FLD_HOLIDAYS_DESC & "] = '" & Replace(holidayDesc, "'", "''") & "' " & vbCrLf & _
                  "WHERE [" & FLD_DATEKEY & "] = #" & Format(CDate(holidayDate), "mm/dd/yyyy") & "#;"
            affectedCount = affectedCount + m_Db.ExecuteNonQuery(sql)
        End If
        rsHolidays.MoveNext
    Loop
    rsHolidays.Close
    Debug.Print "  - 已套用 " & totalCount & " 筆假日資料 (共影響 " & affectedCount & " 筆記錄)"
End Sub

Public Sub MergeMakeupDays(rsMakeupDays As DAO.Recordset)
    '---------------------------------------------------------------------------
    ' 將使用者於工作表匯入的補班日資料，合併至 DateDimension 資料表
    '---------------------------------------------------------------------------
    If rsMakeupDays Is Nothing Then Exit Sub
    If rsMakeupDays.EOF Then Exit Sub
    
    Dim totalCount As Long
    Dim affectedCount As Long
    
    rsMakeupDays.MoveFirst
    If rsMakeupDays.RecordCount = -1 Then rsMakeupDays.MoveLast
    totalCount = rsMakeupDays.RecordCount
    rsMakeupDays.MoveFirst
    
    Do While Not rsMakeupDays.EOF
        ' 預期 rsMakeupDays 有欄位 Date(DATE), Description(TEXT)
        Dim makeupDate As Variant
        Dim makeupDesc As String
        makeupDate = rsMakeupDays.Fields(0).Value
        If rsMakeupDays.Fields.Count > 1 And Not IsNull(rsMakeupDays.Fields(1).Value) Then
            makeupDesc = rsMakeupDays.Fields(1).Value
        Else
            makeupDesc = vbNullString
        End If
        If IsDate(makeupDate) Then
            Dim sql As String
            sql = "UPDATE " & TBL_DATE_DIMENSION & " " & vbCrLf & _
                  "SET [" & FLD_IS_MAKEUP_DAYS & "] = True, " & vbCrLf & _
                  "    [" & FLD_MAKEUP_DAYS_DESC & "] = '" & Replace(makeupDesc, "'", "''") & "' " & vbCrLf & _
                  "WHERE [" & FLD_DATEKEY & "] = #" & Format(CDate(makeupDate), "mm/dd/yyyy") & "#;"
            affectedCount = affectedCount + m_Db.ExecuteNonQuery(sql)
        End If
        rsMakeupDays.MoveNext
    Loop
    rsMakeupDays.Close
    Debug.Print "  - 已套用 " & totalCount & " 筆補班日資料 (共影響 " & affectedCount & " 筆記錄)"
End Sub

Public Sub CreateDateDimensionTable()
    '---------------------------------------------------------------------------
    ' 設定日期維度表的起始日及結束日
    '---------------------------------------------------------------------------
    Dim dateStart As Date
    Dim dateEnd As Date
    dateStart = m_Context.info.periodStart
    dateEnd = m_Context.info.periodEnd
    '檢查日期邏輯
    If dateStart = 0 Or dateEnd = 0 Or dateStart > dateEnd Then Exit Sub
    '檢查資料表是否存在
    If m_Db.TableExists(TBL_DATE_DIMENSION) Then
        Call m_Db.DropTable(TBL_DATE_DIMENSION)
    End If
    '建立日期維度表
    Dim sql As String
    sql = "CREATE TABLE " & TBL_DATE_DIMENSION & " ( " & vbCrLf & _
          "    [" & FLD_DATEKEY & "] DATE, " & vbCrLf & _
          "    [" & FLD_YEAR & "] SHORT, " & vbCrLf & _
          "    [" & FLD_MONTH & "] SHORT, " & vbCrLf & _
          "    [" & FLD_DAY & "] SHORT, " & vbCrLf & _
          "    [" & FLD_DAY_OF_WEEK & "] SHORT, " & vbCrLf & _
          "    [" & FLD_IS_WEEKEND & "] YESNO, " & vbCrLf & _
          "    [" & FLD_IS_HOLIDAYS & "] YESNO," & vbCrLf & _
          "    [" & FLD_IS_MAKEUP_DAYS & "] YESNO," & vbCrLf & _
          "    [" & FLD_HOLIDAYS_DESC & "] TEXT(50)," & vbCrLf & _
          "    [" & FLD_MAKEUP_DAYS_DESC & "] TEXT(50)," & vbCrLf & _
          "    CONSTRAINT PK_" & TBL_DATE_DIMENSION & " PRIMARY KEY ([" & FLD_DATEKEY & "])" & vbCrLf & _
          ");"
    Call m_Db.ExecuteNonQuery(sql)
    '遍歷新增日期表
    Dim rs As DAO.Recordset
    Set rs = m_Db.Database.OpenRecordset(TBL_DATE_DIMENSION, dbOpenDynaset)
    Dim currentDate As Date
    currentDate = dateStart
    '逐日產生日期記錄，直到期間結束日
    Do While currentDate <= dateEnd
        Dim dow As Integer
        dow = Weekday(currentDate, vbSunday)
        '新增記錄並填入欄位值
        rs.AddNew
        rs(FLD_DATEKEY).Value = currentDate
        rs(FLD_YEAR).Value = Year(currentDate)
        rs(FLD_MONTH).Value = Month(currentDate)
        rs(FLD_DAY).Value = Day(currentDate)
        rs(FLD_DAY_OF_WEEK).Value = dow
        rs(FLD_IS_WEEKEND).Value = (dow = vbSunday Or dow = vbSaturday)
        rs(FLD_IS_HOLIDAYS).Value = False
        rs(FLD_IS_MAKEUP_DAYS).Value = False
        rs(FLD_HOLIDAYS_DESC).Value = vbNullString
        rs(FLD_MAKEUP_DAYS_DESC).Value = vbNullString
        rs.Update
        '遞增下一日
        currentDate = DateAdd("d", 1, currentDate)
    Loop
    Debug.Print "已建立日期維度表 (範圍: " & dateStart & " ~ " & dateEnd & ")"
    rs.Close
    Set rs = Nothing
End Sub
