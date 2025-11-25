VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaTableAccountMapping"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'ACCOUNT_MAPPING: 科目配對表 Schema
Public Name As String
Public AccountNumber As String
Public AccountName As String
Public AccountStandardized As String

Public Sub Initialize()
    Name = "ACCOUNT_MAPPING"
    AccountNumber = "科目編號"
    AccountName = "科目名稱"
    AccountStandardized = "科目分類名稱"
End Sub
