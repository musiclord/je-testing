VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "SchemaSystemFields"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'系統產生的標準化欄位
Public JeAmount As String
Public JeAmountSum As String
Public TbAmount As String
Public JeDrCr As String
Public AccountMerged As String
Public TbJeDiff As String

Public Sub Initialize()
    JeAmount = "K_AMOUNT_JE"
    JeAmountSum = "K_AMOUNT_SUM_JE"
    TbAmount = "K_AMOUNT_TB"
    JeDrCr = "K_DRCR_JE"
    AccountMerged = "K_ACCOUNT_MERGED"
    TbJeDiff = "K_TB_JE_DIFF"
End Sub
