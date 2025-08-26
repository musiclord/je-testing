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

Private Const MODULE_Name As String = "EntityTB"
Private m_Method As Long
Private m_Fields As New Dictionary
Private m_Types As New Dictionary

Private Sub Class_Initialize()
    Dim Fields As Variant
    Dim i As Long
    Fields = Array( _
        Array("ChangeAmount", "CURRENCY"), _
        Array("OpeningBalance", "CURRENCY"), _
        Array("OpeningDebitBalance", "CURRENCY"), _
        Array("OpeningCreditBalance", "CURRENCY"), _
        Array("ClosingBalance", "CURRENCY"), _
        Array("ClosingDebitBalance", "CURRENCY"), _
        Array("ClosingCreditBalance", "CURRENCY"), _
        Array("DebitAmount", "CURRENCY"), _
        Array("CreditAmount", "CURRENCY"), _
        Array("AccountNumber", "TEXT"), _
        Array("AccountName", "TEXT") _
    )
    For i = LBound(Fields) To UBound(Fields)
        ' 0:Name, 1:Type
        m_Fields(Fields(i)(0)) = Fields(i)(0) 'Name:Name
        m_Types(Fields(i)(0)) = Fields(i)(1)  'Name:type
    Next i
End Sub

Public Function GetType(ByVal field As String) As String
    On Error Resume Next
    If Len(Trim(field)) = 0 Then
        GetType = "TEXT(255)"
        Exit Function
    End If
    GetType = m_Types(field)
    If Err.Number <> 0 Or Len(GetType) = 0 Then
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

Public Sub PrintFields()
    Dim key As Variant
    Debug.Print "--------- [ TB ] ---------"
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print "--------------------------"
End Sub

'--ÄÝ©Ê
Public Property Get Name() As String
    Name = "TB"
End Property
Public Property Get Method() As Long
    Method = m_Method
End Property
Public Property Let Method(ByVal value As Long)
    m_Method = value
End Property
Public Property Get Fields() As Dictionary
    Set Fields = m_Fields
End Property
'--Äæ¦ì¸É¥þ
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


