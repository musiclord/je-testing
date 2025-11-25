VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaSystemTables"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'系統產生的測試結果資料表
Public InfRandom As String
Public InfSorted As String
Public NullAccount As String
Public NullDocument As String
Public NullDescription As String

Public Sub Initialize()
    InfRandom = "INF_RANDOM"
    InfSorted = "INF_SORTED"
    NullAccount = "NULL_ACCOUNT_RECORDS"
    NullDocument = "NULL_DOCUMENT_RECORDS"
    NullDescription = "NULL_DESCRIPTION_RECORDS"
End Sub
