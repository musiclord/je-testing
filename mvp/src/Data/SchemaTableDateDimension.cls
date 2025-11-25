VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaTableDateDimension"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'DATE_DIMENSION: 日期維度表 Schema
Public Name As String
Public DateKey As String
Public Year As String
Public Month As String
Public Day As String
Public DayOfWeek As String
Public IsWeekend As String
Public IsHoliday As String
Public IsCompensatoryWorkday As String

Public Sub Initialize()
    Name = "DATE_DIMENSION"
    DateKey = "DateKey"
    Year = "Year"
    Month = "Month"
    Day = "Day"
    DayOfWeek = "DayOfWeek"
    IsWeekend = "IsWeekend"
    IsHoliday = "IsHoliday"
    IsCompensatoryWorkday = "IsCompensatoryWorkday"
End Sub
