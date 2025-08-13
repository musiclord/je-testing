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


'--類別成員
Private m_Fields As New Dictionary
Private m_FieldsType As New Dictionary

'--Ent_TB
Public Function GetType(ByVal field As String) As String
    On Error Resume Next
    GetType = m_FieldsType(field)
    If Err.Number <> 0 Then
        GetType = "TEXT(255)"
        Err.Clear
    End If
    On Error GoTo 0
End Function

Public Sub SetMapping(ByVal key As String, ByVal value As String)
    If m_Fields.Exists(key) And Len(value) > 0 Then
        m_Fields(key) = value
    End If
End Sub

Public Sub debug_test()
    Dim key As Variant
    Debug.Print "---------- [ TB ] ----------"
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print "----------------------------"
End Sub

Private Sub Class_Initialize()
    '設定預設欄位名稱
    m_Fields.Add "ChangeAmount", "ChangeAmount"
    m_Fields.Add "OpeningAmount", "OpeningAmount"
    m_Fields.Add "OpeningDebitAmount", "OpeningDebitAmount"
    m_Fields.Add "OpeningCreditAmount", "OpeningCreditAmount"
    m_Fields.Add "ClosingAmount", "ClosingAmount"
    m_Fields.Add "ClosingDebitAmount", "ClosingDebitAmount"
    m_Fields.Add "ClosingCreditAmount", "ClosingCreditAmount"
    m_Fields.Add "DebitAmount", "DebitAmount"
    m_Fields.Add "CreditAmount", "CreditAmount"
    m_Fields.Add "AccountNumber", "AccountNumber"
    m_Fields.Add "AccountName", "AccountName"
    '設定預設欄位型別
    m_FieldsType.Add "ChangeAmount", "CURRENCY"
    m_FieldsType.Add "OpeningAmount", "CURRENCY"
    m_FieldsType.Add "OpeningDebitAmount", "CURRENCY"
    m_FieldsType.Add "OpeningCreditAmount", "CURRENCY"
    m_FieldsType.Add "ClosingAmount", "CURRENCY"
    m_FieldsType.Add "ClosingDebitAmount", "CURRENCY"
    m_FieldsType.Add "ClosingCreditAmount", "CURRENCY"
    m_FieldsType.Add "DebitAmount", "CURRENCY"
    m_FieldsType.Add "CreditAmount", "CURRENCY"
    m_FieldsType.Add "AccountNumber", "TEXT"
    m_FieldsType.Add "AccountName", "TEXT"
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
