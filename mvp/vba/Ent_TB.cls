VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ent_TB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ent_TB"
'===============================================================================
' Module:   Ent_TB
' Purpose:
' Layer:    Entity
' Domain:   Trial Balance
'===============================================================================

'--列舉
Public Enum FieldIndex
    '--試算表金額
    HandlingMethod
    ChangeAmount
    OpeningAmount
    ClosingAmount
    DebitAmount
    CreditAmount
    '--必選欄位
    AccountNumber
    AccountName
End Enum
