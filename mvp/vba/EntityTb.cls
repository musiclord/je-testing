VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "EntityTb"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const MODULE_NAME As String = "EntityTB"
Private m_Fields As New Dictionary
Private m_Types As New Dictionary

Private Sub Class_Initialize()
    Dim fields As Variant
    Dim i As Long
    fields = Array( _
        Array("ChangeAmount", "CURRENCY"), _
        Array("OpeningAmount", "CURRENCY"), _
        Array("OpeningDebitAmount", "CURRENCY"), _
        Array("OpeningCreditAmount", "CURRENCY"), _
        Array("ClosingAmount", "CURRENCY"), _
        Array("ClosingDebitAmount", "CURRENCY"), _
        Array("ClosingCreditAmount", "CURRENCY"), _
        Array("DebitAmount", "CURRENCY"), _
        Array("CreditAmount", "CURRENCY"), _
        Array("AccountNumber", "TEXT"), _
        Array("AccountName", "TEXT") _
    )
    For i = LBound(fields) To UBound(fields)
        ' 0:Name, 1:Type
        m_Fields(fields(i)(0)) = fields(i)(0) 'name:name
        m_Types(fields(i)(0)) = fields(i)(1)  'name:type
    Next i
End Sub

Public Function GetType(ByVal field As String) As String
    On Error Resume Next
    GetType = m_Types(field)
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

Public Sub log_fields()
    Dim key As Variant
    Debug.Print "--------- [ TB ] ---------"
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print "--------------------------"
End Sub

'--ÄÝ©Ê
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


