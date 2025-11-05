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
' Purpose: 統一管理系統中所有資料表與欄位的名稱定義
'
' Design Pattern: Configuration Object (配置物件模式)
'
' Usage:
'   Dim tableName As String
'   tableName = DbSchema.Tables.JournalEntry  '不需要 New
'
' Architecture:
'   採用巢狀類別結構，提供語意化的存取路徑：
'     DatabaseSchema.Tables.XXX      - 資料表名稱
'     DatabaseSchema.Fields.XXX      - 共用欄位名稱
'     DatabaseSchema.Reports.XXX     - 報表名稱
'
' Dependencies:
'   - SchemaTypes.bas: 定義使用者自訂類型（UDT）
'
' Benefits:
'   1. 集中管理 - 所有名稱使用 User-Defined Type 定義在一處
'   2. 命名空間分離 - 透過巢狀結構避免命名衝突
'   3. IntelliSense 友善 - IDE 可提供完整的自動完成
'   4. 類型安全 - 編譯期檢查，避免拼寫錯誤
'   5. 易於重構 - 修改名稱只需改一處
'===============================================================================
'-- 使用 SchemaTypes 模組定義的類型
Private m_Tables As TypeTables
Private m_Fields As TypeFields
Private m_Reports As TypeReports

Private Sub Class_Initialize()
    With Tables
        .JE = "JE"
        .TB = "TB"
    End With
End Sub

'-- 透過 Property Get 回傳 UDT
Public Property Get Tables() As TypeTables
    Tables = m_Tables
End Property
Public Property Get Fields() As TypeFields
    Fields = m_Fields
End Property
Public Property Get Reports() As TypeReports
    Reports = m_Reports
End Property
