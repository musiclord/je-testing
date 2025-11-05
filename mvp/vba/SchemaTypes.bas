Attribute VB_Name = "SchemaTypes"
Option Explicit
'===============================================================================
' Module: SchemaTypes
' Purpose: 定義 DatabaseSchema 使用的使用者自訂類型
'
' Note: VBA 不允許在類別模組中定義 Public Type，
'       因此將類型定義移至標準模組
'===============================================================================

'-------------------------------------------------------------------------------
' 巢狀類別：Tables (資料表名稱)
'-------------------------------------------------------------------------------
Public Type TypeTables
    '-- 通用暫存表
    Temp As String                      ' 通用暫存表
    '-- 核心主資料表
    JE As String                        ' JE - 分錄明細資料
    TB As String                        ' TB - 試算表資料
    DateDimension As String             ' 日期維度表
    '-- JE 衍生資料表
    JeInPeriod As String                ' 期間內的 JE
    JeNotInPeriod As String             ' 期間外的 JE
    JeAccountSum As String              ' JE 按科目彙總
    '-- 完整性測試
    CompletenessCalculated As String    ' 計算結果
    CompletenessDiff As String          ' 差異明細
    CompletenessDetail As String        ' 完整性測試明細表
    '-- 借貸平衡測試
    DocumentBalanceSum As String        ' 按傳票號碼彙總金額
    DocumentBalanceDiff As String       ' 不平衡明細
    DocumentBalanceDetail As String     ' 借貸不平測試明細表
    '-- INF 測試
    InfRandom As String                 ' 隨機抽樣
    InfSorted As String                 ' 排序後資料
    '-- 空值檢查
    NullAccount As String               ' 空白科目記錄
    NullDocument As String              ' 空白傳票記錄
    NullDescription As String           ' 空白摘要記錄
    '-- 科目配對
    AccountMapping As String            ' 科目對應主表
End Type
'-------------------------------------------------------------------------------
' 巢狀類別：Fields (共用欄位名稱)
'-------------------------------------------------------------------------------
Public Type TypeFields
    '-- 通用欄位
    AccountMerged As String             ' 統一的科目編號
    DateKey As String                   ' 日期鍵值 (YYYYMMDD)
    Amount As String                    ' 金額
    '-- 完整性檢查專用
    TbJeDiff As String                  ' TB 與 JE 差異金額
    '-- 科目對應專用
    AccountCode As String               ' 科目編號
    AccountName As String               ' 科目名稱
    CategoryName As String              ' 標準分類名稱
End Type
'-------------------------------------------------------------------------------
' 巢狀類別：Reports (報表名稱)
'-------------------------------------------------------------------------------
Public Type TypeReports
    EngagementOverview As String        ' 專案總覽
    DataOverview As String              ' 資料總覽
    ValidationOverview As String        ' 驗證總覽
    CompletenessDetail As String        ' 完整性明細
    DocumentBalanceDetail As String     ' 借貸平衡明細
    InfSampleDetail As String           ' INF 抽樣明細
    AccountMappingInfo As String        ' 科目對應資訊
    FieldMappingInfo As String          ' 欄位對應資訊
End Type
