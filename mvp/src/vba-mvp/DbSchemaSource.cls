VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DbSchemaSource"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Schema
' Name:     Source
' Purpose:  處理原始資料，定義核心業務表，主要為 GL 及 TB 資料表
'
'===============================================================================
'--
Private m_GL As MapperFieldGl
Private m_TB As MapperFieldTb
Private m_DateDim As TypeSourceDateDimension
Private m_AccountMapping As TypeSourceAccountMapping

'-------------------------------------------------------------------------------
'-- 初始化
'-------------------------------------------------------------------------------
Public Sub Initialize( _
    ByVal p_GL As MapperFieldGl, _
    ByVal p_TB As MapperFieldTb _
)
    ' 初始化 [GL] 綱要
    Set m_GL = p_GL
    
    ' 初始化 [TB] 綱要
    Set m_TB = p_TB
    
    ' 初始化 [AccountMapping] 綱要
    With m_AccountMapping
        .Name = "ACCOUNT_MAPPING"
        .AccountName = "AccountName"
        .AccountCode = "AccountCode"
        .AccountStandardized = "AccountStandardized"
    End With
    
    ' 初始化 [DateDimension] 綱要
    With m_DateDim
        .Name = "DATE_DIMENSION"
        .DateKey = "DateKey"
        .FullDate = "FullDate"
        .Year = "Year"
        .Month = "Month"
        .Day = "Day"
        .DayOfWeek = "DayOfWeek"
        .IsWeekend = "IsWeekend"
        .IsHolidays = "IsHolidays"
        .IsMakeupDays = "IsMakeupdays"
        .HolidaysDesc = "Holiday_Description"
        .MakeupDaysDesc = "Makeupdays_Description"
    End With
End Sub

'-------------------------------------------------------------------------------
'-- Source Layer
'-------------------------------------------------------------------------------
' [GL]
Public Property Get GL() As MapperFieldGl
    Set GL = m_GL
End Property

' [TB]
Public Property Get TB() As MapperFieldTb
    Set TB = m_TB
End Property

' [科目配對表]
Public Property Get AccountMapping() As TypeSourceAccountMapping
    AccountMapping = m_AccountMapping
End Property

' [日期維度表]
Public Property Get DateDim() As TypeSourceDateDimension
    DateDim = m_DateDim
End Property
