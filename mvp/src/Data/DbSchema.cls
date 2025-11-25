VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DbSchema"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: DbSchema
' Purpose: 定義資料庫結構 (Schema) 與資料表、欄位名稱常數
'
' Architecture:
'   採用 Class-based hierarchy 模擬 legacy 的 UDT 結構
'   提供統一的 schema 定義存取點，避免硬編碼字串
'
' Dependencies:
'   - FieldMapperJe.cls: JE 欄位映射管理
'   - FieldMapperTb.cls: TB 欄位映射管理
'
' Usage:
'   Dim schema As New DbSchema
'   schema.Initialize jeMapper, tbMapper
'   Debug.Print schema.JE.Name  ' 取得 JE 表名稱
'   Debug.Print schema.Fields.JeAmount  ' 取得系統產生欄位名稱
'===============================================================================

'-- 私有成員變數
Private m_JeMapper As Object    ' FieldMapperJe
Private m_TbMapper As Object    ' FieldMapperTb

'-- Schema 結構類別
Private m_DateDimension As SchemaTableDateDimension
Private m_AccountMapping As SchemaTableAccountMapping
Private m_Fields As SchemaSystemFields
Private m_Reports As SchemaSystemReports
Private m_SystemTables As SchemaSystemTables

'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize(Optional ByVal jeMapper As Object = Nothing, Optional ByVal tbMapper As Object = Nothing)
    '初始化所有 schema 定義
    Set m_JeMapper = jeMapper
    Set m_TbMapper = tbMapper
    
    '建立 schema 物件
    Set m_DateDimension = New SchemaTableDateDimension
    Set m_AccountMapping = New SchemaTableAccountMapping
    Set m_Fields = New SchemaSystemFields
    Set m_Reports = New SchemaSystemReports
    Set m_SystemTables = New SchemaSystemTables
    
    '初始化各 schema 物件
    m_DateDimension.Initialize
    m_AccountMapping.Initialize
    m_Fields.Initialize
    m_Reports.Initialize
    m_SystemTables.Initialize
End Sub

'===============================================================================
' Public Properties - 資料表存取
'===============================================================================

Public Property Get JE() As Object
    Set JE = m_JeMapper
End Property

Public Property Get TB() As Object
    Set TB = m_TbMapper
End Property

Public Property Get DateDimension() As SchemaTableDateDimension
    Set DateDimension = m_DateDimension
End Property

Public Property Get AccountMapping() As SchemaTableAccountMapping
    Set AccountMapping = m_AccountMapping
End Property

Public Property Get Fields() As SchemaSystemFields
    Set Fields = m_Fields
End Property

Public Property Get Reports() As SchemaSystemReports
    Set Reports = m_Reports
End Property

Public Property Get SystemTables() As SchemaSystemTables
    Set SystemTables = m_SystemTables
End Property

'===============================================================================
' SQL Generation Methods (保留原有方法以便相容)
'===============================================================================

Public Function GetCreateProjectTableSql() As String
    GetCreateProjectTableSql = _
        "CREATE TABLE ProjectInfo (" & _
        "ID AUTOINCREMENT PRIMARY KEY, " & _
        "ProjectName TEXT(255), " & _
        "ClientName TEXT(255), " & _
        "PeriodStart DATETIME, " & _
        "PeriodEnd DATETIME, " & _
        "CreatedDate DATETIME DEFAULT NOW()" & _
        ");"
End Function

Public Function GetCreateJeTableSql(ByVal tableName As String) As String
    '基本 JE 表結構 - 欄位將透過 FieldMapper 動態映射
    GetCreateJeTableSql = _
        "CREATE TABLE " & tableName & " (" & _
        "ID AUTOINCOUNTER PRIMARY KEY" & _
        ");"
End Function

Public Function GetCreateTbTableSql(ByVal tableName As String) As String
    '基本 TB 表結構 - 欄位將透過 FieldMapper 動態映射
    GetCreateTbTableSql = _
        "CREATE TABLE " & tableName & " (" & _
        "ID AUTOINCOUNTER PRIMARY KEY" & _
        ");"
End Function

Public Function GetCreateDateDimensionSql() As String
    With m_DateDimension
        GetCreateDateDimensionSql = _
            "CREATE TABLE " & .Name & " (" & _
            .DateKey & " TEXT(8) PRIMARY KEY, " & _
            .Year & " INTEGER, " & _
            .Month & " INTEGER, " & _
            .Day & " INTEGER, " & _
            .DayOfWeek & " INTEGER, " & _
            .IsWeekend & " YESNO, " & _
            .IsHoliday & " YESNO, " & _
            .IsCompensatoryWorkday & " YESNO" & _
            ");"
    End With
End Function

Public Function GetCreateAccountMappingSql() As String
    With m_AccountMapping
        GetCreateAccountMappingSql = _
            "CREATE TABLE " & .Name & " (" & _
            "ID AUTOINCOUNTER PRIMARY KEY, " & _
            .AccountNumber & " TEXT(50), " & _
            .AccountName & " TEXT(255), " & _
            .AccountStandardized & " TEXT(100)" & _
            ");"
    End With
End Function

Private Sub Class_Terminate()
    Set m_JeMapper = Nothing
    Set m_TbMapper = Nothing
    Set m_DateDimension = Nothing
    Set m_AccountMapping = Nothing
    Set m_Fields = Nothing
    Set m_Reports = Nothing
    Set m_SystemTables = Nothing
End Sub
