VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CoreSqlBuilder"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Core
' Name:     SqlBuilder
' Purpose:  SQL 語句建構器 (Fluent API)。
'           提供鏈式呼叫介面來組建 SELECT/JOIN/WHERE/GROUP BY 等
'           SQL 子句，避免手動字串拼接的錯誤風險。
'===============================================================================

'-- SELECT clause
Private m_SelectFields As String
Private m_SelectDistinct As Boolean

'-- FROM clause
Private m_FromTable As String
Private m_FromAlias As String
Private m_FromDbPath As String

'-- JOIN clauses
Private m_Joins As Collection

'-- WHERE clause
Private m_WhereConditions As String

'-- GROUP BY clause
Private m_GroupByFields As String

'-- HAVING clause
Private m_HavingCondition As String

'-- ORDER BY clause
Private m_OrderByFields As String

'-- INTO clause
Private m_IntoTable As String
Private m_IntoDbPath As String
