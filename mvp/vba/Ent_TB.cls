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
'ChangeAmount       : CURRENCY
'OpeningAmount      : CURRENCY
'OpeningDebitAmount : CURRENCY
'OpeningCreditAmount: CURRENCY
'ClosingAmount      : CURRENCY
'ClosingDebitAmount : CURRENCY
'ClosingCreditAmount: CURRENCY
'DebitAmount        : CURRENCY
'CreditAmount       : CURRENCY
'AccountNumber      : TEXT
'AccountName        : TEXT

'--類別成員
Private m_Fields As New Dictionary

'--Ent_TB
Public Sub SetMapping(ByVal key As String, ByVal value As String)
    If m_Fields.Exists(key) And Len(value) > 0 Then
        m_Fields(key) = value
    End If
End Sub

Public Sub debug_test()
    Dim key As Variant
    Debug.Print "---------- [ TB ] ----------"
    For Each key In m_Fields(key)
        Debug.Print key & ": " & m_Fields(key)
    Next key
    Debug.Print "----------------------------"
End Sub

Private Sub Class_Initialize()
    Dim fields As Variant
    Dim i As Long
    fields = Array("ChangeAmount", "OpeningAmount", , "OpeningDebitAmount", _
                   "OpeningCreditAmount", "ClosingAmount", "ClosingDebitAmount", _
                   "ClosingCreditAmount", "DebitAmount", "CreditAmount", _
                   "AccountNumber", "AccountName")
    For i = LBound(fields) To UBound(fields)
        m_Fields.Add fields(i), fields(i) '預設欄位名稱
    Next i
End Sub

'--屬性
Public Property Get name() As String
    name = "TB"
End Property
Public Property Get ChangeAmount() As String
    ChangeAmount = " [" & m_Fields("ChangeAmount") & "] "
End Property
Public Property Get OpeningAmount() As String
    OpeningAmount = " [" & m_Fields("OpeningAmount") & "] "
End Property
Public Property Get OpeningDebitAmount() As String
    OpeningDebitAmount = " [" & m_Fields("OpeningDebitAmount") & "] "
End Property
Public Property Get OpeningCreditAmount() As String
    OpeningCreditAmount = " [" & m_Fields("OpeningCreditAmount") & "] "
End Property
Public Property Get ClosingAmount() As String
    ClosingAmount = " [" & m_Fields("ClosingAmount") & "] "
End Property
Public Property Get ClosingDebitAmount() As String
    ClosingDebitAmount = " [" & m_Fields("ClosingDebitAmount") & "] "
End Property
Public Property Get ClosingCreditAmount() As String
    ClosingCreditAmount = " [" & m_Fields("ClosingCreditAmount") & "] "
End Property
Public Property Get DebitAmount() As String
    DebitAmount = " [" & m_Fields("DebitAmount") & "] "
End Property
Public Property Get CreditAmount() As String
    CreditAmount = " [" & m_Fields("CreditAmount") & "] "
End Property
Public Property Get AccountNumber() As String
    AccountNumber = " [" & m_Fields("AccountNumber") & "] "
End Property
Public Property Get AccountName() As String
    AccountName = " [" & m_Fields("AccountName") & "] "
End Property
