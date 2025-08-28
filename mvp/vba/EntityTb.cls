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
'Class:EntityTb
Private m_Method As Long
Private m_Fields As New Dictionary

'--方法
Private Sub Class_Initialize()
    Dim fields As Variant
    Dim i As Long
    fields = Array( _
        "ChangeAmount", _
        "OpeningBalance", _
        "OpeningDebitBalance", _
        "OpeningCreditBalance", _
        "ClosingBalance", _
        "ClosingDebitBalance", _
        "ClosingCreditBalance", _
        "DebitAmount", _
        "CreditAmount", _
        "AccountNumber", _
        "AccountName" _
    )
    For i = LBound(fields) To UBound(fields)
        m_Fields(fields(i)) = ""
    Next i
End Sub

Public Sub SetField(ByVal key As String, ByVal Value As String)
    If m_Fields.Exists(key) And Len(Value) > 0 Then
        m_Fields(key) = Value
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

'--屬性，存取狀態
Public Property Get Name() As String
    Name = "GL"
End Property
Public Property Get method() As Long
    method = m_Method
End Property
Public Property Let method(ByVal Value As Long)
    m_Method = Value
End Property
Public Property Get fields() As Dictionary
    Set fields = m_Fields
End Property

'--屬性，快速補全
Public Property Get ChangeAmount() As String
    ChangeAmount = " [" & m_Fields("ChangeAmount") & "] "
End Property

Public Property Get OpeningBalance() As String
    OpeningBalance = " [" & m_Fields("OpeningBalance") & "] "
End Property

Public Property Get OpeningDebitBalance() As String
    OpeningDebitBalance = " [" & m_Fields("OpeningDebitBalance") & "] "
End Property

Public Property Get OpeningCreditBalance() As String
    OpeningCreditBalance = " [" & m_Fields("OpeningCreditBalance") & "] "
End Property

Public Property Get ClosingBalance() As String
    ClosingBalance = " [" & m_Fields("ClosingBalance") & "] "
End Property

Public Property Get ClosingDebitBalance() As String
    ClosingDebitBalance = " [" & m_Fields("ClosingDebitBalance") & "] "
End Property

Public Property Get ClosingCreditBalance() As String
    ClosingCreditBalance = " [" & m_Fields("ClosingCreditBalance") & "] "
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
