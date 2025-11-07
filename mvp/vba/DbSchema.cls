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
' Purpose: 統一管理系統中所有資料表與欄位的名稱定義（階層式結構）
'
' Design Pattern: Configuration Object (配置物件模式)
'
' Usage:
'   ' 清晰的階層關係
'   sql = "SELECT [" & Schema.JE.AccountNumber & "] FROM " & Schema.JE.Name
'   sql = "SELECT [" & Schema.TB.AccountNumber & "] FROM " & Schema.TB.Name
'
' Architecture:
'   DbSchema (階層式結構)
'     ├── 資料表
'     │   ├── JE (TypeTableJe)
'     │   │   ├── Name = "JE"
'     │   │   ├── AccountNumber = "AccountNumber"
'     │   │   ├── PostDate = "PostDate"
'     │   │   └── K_Amount = "AMOUNT_JE"
'     │   ├── TB (TypeTableTb)
'     │   │   ├── Name = "TB"
'     │   │   ├── AccountNumber = "AccountNumber"
'     │   │   └── K_Amount = "AMOUNT_TB"
'     │   ├── DateDimension (TypeTableDateDimension)
'     │   ├── CompletenessDetail (TypeTableCompletenessDetail)
'     │   ├── AccountMapping (TypeTableAccountMapping)
'     │   └── Derived (TypeDerivedTables) - 衍生資料表集合
'     └── 報表
'         ├── ReportEngagementOverview (TypeReportEngagementOverview)
'         ├── ReportDataOverview (TypeReportDataOverview)
'         ├── ReportValidationOverview (TypeReportValidationOverview)
'         ├── ReportCompletenessDetail (TypeReportCompletenessDetail)
'         ├── ReportDocumentBalanceDetail (TypeReportDocumentBalanceDetail)
'         ├── ReportInfSampleDetail (TypeReportInfSampleDetail)
'         ├── ReportAccountMappingInfo (TypeReportAccountMappingInfo)
'         └── ReportFieldMappingInfo (TypeReportFieldMappingInfo)
'
' Dependencies:
'   - SchemaTypes.bas: 定義使用者自訂類型（UDT）
'
' Benefits:
'   1. 集中管理 - 所有資料表/欄位名稱定義在一處
'   2. 命名空間分離 - 透過階層結構避免命名衝突
'   3. IntelliSense 友善 - IDE 提供完整的自動完成
'   4. 類型安全 - 編譯期檢查，減少拼寫錯誤
'   5. 易於重構 - 修改名稱只需改一處
'   6. 符合 OOP - 欄位從屬於資料表，符合正規化原則
'===============================================================================
' 使用 SchemaTypes 模組定義的 UDT
'===============================================================================
Private m_JE As FieldMapperJe
Private m_TB As FieldMapperTb
Private m_DateDimension As TypeTableDateDimension
Private m_AccountMapping As TypeTableAccountMapping
Private m_Tables As TypeSystemTables
Private m_Fields As TypeSystemFields
Private m_Reports As TypeSystemReports

'===============================================================================
' 透過屬性回傳 UDT
'===============================================================================
'-- 資料表
Public Property Get JE() As FieldMapperJe
    Set JE = m_JE
End Property
Public Property Get TB() As FieldMapperTb
    Set TB = m_TB
End Property
Public Property Get DateDimension() As TypeTableDateDimension
    DateDimension = m_DateDimension
End Property
Public Property Get AccountMapping() As TypeTableAccountMapping
    AccountMapping = m_AccountMapping
End Property
Public Property Get Tables() As TypeSystemTables
    Tables = m_Tables
End Property
Public Property Get Fields() As TypeSystemFields
    Fields = m_Fields
End Property
Public Property Get Reports() As TypeSystemReports
    Reports = m_Reports
End Property

'===============================================================================
' 初始化 UDT 成員
'===============================================================================
Private Sub InitializeTables()
    '---------------------------------------------------------------------------
    ' 初始化所有資料表的 Schema 映射定義
    '---------------------------------------------------------------------------
    '-- DateDimension: 系統定義的標準化欄位
    With m_DateDimension
        .Name = "DATE_DIMENSION"
        '-- 欄位
        .DateKey = "DateKey"
        .Year = "Year"
        .Month = "Month"
        .Day = "Day"
        .DayOfWeek = "DayOfWeek"
        .IsWeekend = "IsWeekend"
        .IsHolidays = "IsHolidays"
        .IsMakeupDays = "IsMakeupDays"
        .HolidaysDesc = "HolidaysDesc"
        .MakeupDaysDesc = "MakeupDaysDesc"
    End With
    
    '-- AccountMapping: 系統定義的標準化欄位
    With m_AccountMapping
        .Name = "ACCOUNT_MAPPING"
        '-- 欄位
        .AccountCode = "AccountCode"
        .AccountName = "AccountName"
        .AccountStandardized = "AccountStandardized"
        .IsActive = "IsActive"
        .CreatedDate = "CreatedDate"
    End With
    
    '-- 初始化衍生資料表
    With m_Tables
        .JeInPeriod = "JE_IN_PERIOD"
        .JeNotInPeriod = "JE_NOT_IN_PERIOD"
        .JeAccountSum = "JE_ACCOUNT_SUM"
        .CompletenessCalculated = "COMPLETENESS_CALCULATED"
        .CompletenessDiff = "COMPLETENESS_DIFF"
        .CompletenessDetail = "COMPLETENESS_DETAIL"
        .DocumentBalanceSum = "DOCUMENT_BALANCE_SUM"
        .DocumentBalanceDiff = "DOCUMENT_BALANCE_DIFF"
        .DocumentBalanceDetail = "DOCUMENT_BALANCE_DETAIL"
        .InfRandom = "INF_RANDOM"
        .InfSorted = "INF_SORTED"
        .NullAccount = "NULL_ACCOUNT_RECORDS"
        .NullDocument = "NULL_DOCUMENT_RECORDS"
        .NullDescription = "NULL_DESCRIPTION_RECORDS"
    End With
    
    '-- 初始化衍生欄位表
    With m_Fields
        '//
        '//NOTE: 由於 UDT 僅作為副本傳送，而不可修改狀態
        '//      因此以下欄位名稱暫時可用，若後續有動態連結
        '//      則應該交由 FieldMapper 處理
        '//
        .JeUid = "識別碼_JE"
        .JeAmount = "K_AMOUNT_JE"
        .JeAmountSum = "K_AMOUNT_SUM_JE"
        .TbAmount = "K_AMOUNT_TB"
        .AccountMerged = "ACCOUNT_MERGED"
        .TbJeDiff = "TB_JE_DIFF"
    End With
End Sub
Private Sub InitializeReports()
    '---------------------------------------------------------------------------
    ' 初始化所有報表的 Schema 映射定義
    '---------------------------------------------------------------------------
    '-- ENGAGEMENT_OVERVIEW
    With m_Reports.EngagementOverview
        .Name = "ENGAGEMENT_OVERVIEW"
        '-- 欄位
        .Client = "客戶"
        .PrepStartDate = "財報準備期間開始日"
        .PeriodStart = "資料期間開始日"
        .PeriodEnd = "資料期間結束日"
        .PreparedBy = "報表生產人"
        .PreparedDate = "報表生產時間"
    End With
    '-- DATA_OVERVIEW
    With m_Reports.DataOverview
        .Name = "DATA_OVERVIEW"
        '-- 欄位
        .JeName = "分錄檔案名稱"
        .JeNetAmount = "分錄借貸淨額"
        .JeDebitSum = "分錄借方合計金額"
        .JeCreditSum = "分錄貸方合計金額"
        .JeRecordCount = "分錄筆數"
        .TbName = "試算表檔案名稱"
        .TbAccountCount = "試算表科目數量"
    End With
    '-- VALIDATION_OVERVIEW
    With m_Reports.ValidationOverview
        .Name = "VALIDATION_OVERVIEW"
        '-- 欄位
        .NullAccountRecordCount = "無會計科目編號筆數"
        .NullDocumentRecordCount = "無傳票號碼筆數"
        .NullDescriptionRecordCount = "無傳票摘要筆數"
        .NotInPeriodCount = "傳票核准日不在會計期間內筆數"
        .CompletenessDiffCount = "完整性差異筆數"
        .DocumentBalanceDiffCount = "借貸不平差異筆數"
    End With
    '-- COMPLETENESS_DETAIL
    With m_Reports.CompletenessDetail
        .Name = "COMPLETENESS_DETAIL"
    End With
    '-- DOCUMENT_BALANCE_DETAIL
    With m_Reports.DocumentBalanceDetail
        .Name = "DOCUMENT_BALANCE_DETAIL"
    End With
    '-- ACCOUNT_MAPPING_INFO
    With m_Reports.AccountMappingInfo
        .Name = "ACCOUNT_MAPPING_INFO"
    End With
    '-- FIELD_MAPPING_INFO
    With m_Reports.FieldMappingInfo
        .Name = "FIELD_MAPPING_INFO"
    End With
End Sub

Public Sub Initialize( _
    ByVal jeMapper As FieldMapperJe, _
    ByVal tbMapper As FieldMapperTb _
)
    '---------------------------------------------------------------------------
    ' 模擬建構子初始化
    '---------------------------------------------------------------------------
    Call InitializeTables
    Call InitializeReports
    Set m_JE = jeMapper
    Set m_TB = tbMapper
End Sub
