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
' Purpose: 負責管理日期維度表 (Date Dimension)
'===============================================================================

Private m_Context As ContextManager
Private m_Db As DbAccess


Public Sub Initialize(context As ContextManager)
    Set m_Context = context
    Set m_Db = context.DbInput
End Sub

Public Sub MergeHolidays()
    '將使用者於工作表匯入的假期資料，合併至 DateDimension 資料表
End Sub

Public Sub MergeMakeUpDays()
    '將使用者於工作表匯入的補班日資料，合併至 DateDimension 資料表
End Sub

Public Sub MergeWeekends()
    '將使用者於表單中設定的周末，合併至 DateDimension 資料表
End Sub

Private Sub CreateDateDimensionTable()
    '設定欄位常數
    Const FLD_DATEKEY As String = "DateKey"                 '[DATE]   唯一主鍵，格式: YYYYMMDD
    Const FLD_YEAR As String = "Year"                       '[NUM]    西元年 (1900-?)
    Const FLD_MONTH As String = "Month"                     '[NUM]    月份 (1-12)
    Const FLD_DAY As String = "Day"                         '[NUM]    日 (1-31)
    Const FLD_DAY_OF_WEEK As String = "DayOfWeek"           '[NUM]    天 (1-7)
    Const FLD_IS_WEEKEND As String = "IsWeekend"            '[Y/N]    -1/0 (系統自動產生)
    Const FLD_IS_HOLIDAY As String = "IsHoliday"            '[Y/N]    -1/0 (由使用者上傳的資料覆寫)
    Const FLD_IS_MAKEUP_DAY As String = "IsMakeUpDay"       '[Y/N]    -1/0 (由使用者上傳的資料覆寫)
    Const FLD_HOLIDAY_DESC As String = "HolidayDesc"        '[CHAR]   假期說明 (選填)
    Const FLD_MAKEUP_DAY_DESC As String = "MakeUpDayDesc"   '[CHAR]   補班日說明 (選填)
    '設定日期維度表的起始日及結束日
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
          "    [" & FLD_IS_HOLIDAY & "] YESNO" & vbCrLf & _
          "    [" & FLD_IS_MAKEUP_DAY & "] YESNO" & vbCrLf & _
          "    [" & FLD_HOLIDAY_DESC & "] TEXT(50)" & vbCrLf & _
          "    [" & FLD_MAKEUP_DAY_DESC & "] TEXT(50)" & vbCrLf & _
          "    CONSTRAINT PK_" & TBL_DATE_DIMENSION & " PRIMARY KEY (" & FLD_DATEKEY & ")" & vbCrLf & _
          ");"
    m_Db.ExecuteNonQuery sql
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
