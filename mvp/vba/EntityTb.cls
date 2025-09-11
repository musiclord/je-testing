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
Private m_Name As String
Private m_Method As Long
Private m_Fields As New Dictionary

'***** 方法
Private Sub Class_Initialize()
    m_Name = "TB"
    Dim Fields As Variant
    Dim i As Long
    Fields = Array( _
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
        "AccountName", _
        "K_Amount" _
    )
    For i = LBound(Fields) To UBound(Fields)
        m_Fields(Fields(i)) = Fields(i)
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

'***** 屬性訪問
Public Property Get Name() As String
    Name = m_Name
End Property
Public Property Let Name(ByVal Value As String)
    m_Name = Value
End Property
Public Property Get Method() As Long
    Method = m_Method
End Property
Public Property Let Method(ByVal Value As Long)
    m_Method = Value
End Property
Public Property Get Fields() As Dictionary
    Set Fields = m_Fields
End Property

'***** 屬性快速補全
Public Property Get ChangeAmount() As String
    ChangeAmount = m_Fields("ChangeAmount")
End Property
Public Property Get OpeningBalance() As String
    OpeningBalance = m_Fields("OpeningBalance")
End Property
Public Property Get OpeningDebitBalance() As String
    OpeningDebitBalance = m_Fields("OpeningDebitBalance")
End Property
Public Property Get OpeningCreditBalance() As String
    OpeningCreditBalance = m_Fields("OpeningCreditBalance")
End Property
Public Property Get ClosingBalance() As String
    ClosingBalance = m_Fields("ClosingBalance")
End Property
Public Property Get ClosingDebitBalance() As String
    ClosingDebitBalance = m_Fields("ClosingDebitBalance")
End Property
Public Property Get ClosingCreditBalance() As String
    ClosingCreditBalance = m_Fields("ClosingCreditBalance")
End Property
Public Property Get DebitAmount() As String
    DebitAmount = m_Fields("DebitAmount")
End Property
Public Property Get CreditAmount() As String
    CreditAmount = m_Fields("CreditAmount")
End Property
Public Property Get AccountNumber() As String
    AccountNumber = m_Fields("AccountNumber")
End Property
Public Property Get AccountName() As String
    AccountName = m_Fields("AccountName")
End Property

'***** 屬性，快速補全自訂欄位
Public Property Get K_Amount() As String
    K_Amount = m_Fields("K_Amount")
End Property
