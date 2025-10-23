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
Private Const FLD_DATEKEY As String = "DateKey"                 '[DATE]   唯一主鍵，格式: YYYYMMDD
Private Const FLD_YEAR As String = "Year"                       '[NUM]    西元年 (1900-?)
Private Const FLD_MONTH As String = "Month"                     '[NUM]    月份 (1-12)
Private Const FLD_DAY As String = "Day"                         '[NUM]    日 (1-31)
Private Const FLD_DAY_OF_WEEK As String = "DayOfWeek"           '[NUM]    天 (1-7)
Private Const FLD_IS_WEEKEND As String = "IsWeekend"            '[Y/N]    -1/0 (系統自動產生)
Private Const FLD_IS_HOLIDAY As String = "IsHolidays"            '[Y/N]    -1/0 (由使用者上傳的資料覆寫)
Private Const FLD_IS_MAKEUP_DAY As String = "IsMakeupDays"       '[Y/N]    -1/0 (由使用者上傳的資料覆寫)
Private Const FLD_HOLIDAY_DESC As String = "HolidaysDesc"        '[CHAR]   假期說明 (選填)
Private Const FLD_MAKEUP_DAY_DESC As String = "MakeupDaysDesc"   '[CHAR]   補班日說明 (選填)

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
    Call m_Db.ExecuteNonQuery(sql)
End Sub

Public Sub MergeHolidays(rsHolidays As DAO.Recordset)
    '---------------------------------------------------------------------------
    ' 將使用者於工作表匯入的假期資料，合併至 DateDimension 資料表
    '---------------------------------------------------------------------------
    If rsHolidays Is Nothing Then Exit Sub
    If rsHolidays.EOF Then Exit Sub
    rsHolidays.MoveFirst
    Do While Not rsHolidays.EOF
        '預期 rsHolidays 有欄位 Date(DATE), Description(TEXT)
        Dim sql As String
        sql = "UPDATE " & TBL_DATE_DIMENSION & " " & vbCrLf & _
              "SET [" & FLD_IS_HOLIDAY & "] = True, " & vbCrLf & _
              "    [" & FLD_HOLIDAY_DESC & "] = '" & Replace(rsHolidays!Description, "'", "''") & vbCrLf & "' " & _
              "WHERE [" & FLD_DATEKEY & "] = #" & Format(rsHolidays!Date, "mm/dd/yyyy") & "#;"
        Call m_Db.ExecuteNonQuery(sql)
        rsHolidays.MoveNext
    Loop
    rsHolidays.Close
End Sub

Public Sub MergeMakeupDays(rsMakeupDays As DAO.Recordset)
    '---------------------------------------------------------------------------
    ' 將使用者於工作表匯入的補班日資料，合併至 DateDimension 資料表
    '---------------------------------------------------------------------------
    If rsMakeupDays Is Nothing Then Exit Sub
    If rsMakeupDays.EOF Then Exit Sub
    rsMakeupDays.MoveFirst
    Do While Not rsMakeupDays.EOF
        '預期 rsMakeupDays 有欄位 Date(DATE), Description(TEXT)
        Dim sql  As String
        sql = "UPDATE " & TBL_DATE_DIMENSION & " " & vbCrLf & _
              "SET [" & FLD_IS_MAKEUP_DAY & "] = True, " & vbCrLf & _
              "    [" & FLD_MAKEUP_DAY_DESC & "] = '" & Replace(rsMakeupDays!MakeUpDesc, "'", "''") & "' " & _
              "WHERE [" & FLD_DATEKEY & "] = #" & Format(rsMakeupDays!MakeUpDate, "mm/dd/yyyy") & "#"
        Call m_Db.ExecuteNonQuery(sql)
        rsMakeupDays.MoveNext
    Loop
    rsMakeupDays.Close
End Sub

Public Sub CreateDateDimensionTable()
    '---------------------------------------------------------------------------
    ' 設定日期維度表的起始日及結束日
    '---------------------------------------------------------------------------
    Dim dateStart As Date
    Dim dateEnd As Date
    dateStart = m_Context.info.PeriodStart
    dateEnd = m_Context.info.PeriodEnd
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
          "    [" & FLD_IS_HOLIDAY & "] YESNO," & vbCrLf & _
          "    [" & FLD_IS_MAKEUP_DAY & "] YESNO," & vbCrLf & _
          "    [" & FLD_HOLIDAY_DESC & "] TEXT(50)," & vbCrLf & _
          "    [" & FLD_MAKEUP_DAY_DESC & "] TEXT(50)," & vbCrLf & _
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
        rs(FLD_IS_HOLIDAY).Value = False
        rs(FLD_IS_MAKEUP_DAY).Value = False
        rs(FLD_HOLIDAY_DESC).Value = vbNullString
        rs(FLD_MAKEUP_DAY_DESC).Value = vbNullString
        rs.Update
        '遞增下一日
        currentDate = DateAdd("d", 1, currentDate)
    Loop
    rs.Close
    Set rs = Nothing
End Sub
