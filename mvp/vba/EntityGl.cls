VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "EntityGl"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:EntityGl
Private m_Name As String
Private m_Method As Long
Private m_Fields As New Dictionary

'***** 方法
Private Sub Class_Initialize()
    m_Name = "GL"
    Dim Fields As Variant
    Dim i As Long
    Fields = Array( _
        "EntryAmount", _
        "DebitAmount", _
        "CreditAmount", _
        "EntryDescription", _
        "AccountNumber", _
        "AccountName", _
        "DocumentNumber", _
        "ApprovedBy", _
        "CreatedBy", _
        "SourceModule", _
        "DrCr", _
        "IsDebit", _
        "IsManual", _
        "IsApprovedDateAsLedgerDate", _
        "PostDate", _
        "ApprovalDate", _
        "LineItem", _
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
    Debug.Print "--------- [ GL ] ---------"
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print "--------------------------"
End Sub

'***** 屬性，存取狀態
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

'***** 屬性，快速補全
Public Property Get EntryAmount() As String
    EntryAmount = m_Fields("EntryAmount")
End Property
Public Property Get DebitAmount() As String
    DebitAmount = m_Fields("DebitAmount")
End Property
Public Property Get CreditAmount() As String
    CreditAmount = m_Fields("CreditAmount")
End Property
Public Property Get EntryDescription() As String
    EntryDescription = m_Fields("EntryDescription")
End Property
Public Property Get AccountNumber() As String
    AccountNumber = m_Fields("AccountNumber")
End Property
Public Property Get AccountName() As String
    AccountName = m_Fields("AccountName")
End Property
Public Property Get DocumentNumber() As String
    DocumentNumber = m_Fields("DocumentNumber")
End Property
Public Property Get ApprovedBy() As String
    ApprovedBy = m_Fields("ApprovedBy")
End Property
Public Property Get CreatedBy() As String
    CreatedBy = m_Fields("CreatedBy")
End Property
Public Property Get SourceModule() As String
    SourceModule = m_Fields("SourceModule")
End Property
Public Property Get DrCr() As String
    DrCr = m_Fields("DrCr")
End Property
Public Property Get IsDebit() As String
    IsDebit = m_Fields("IsDebit")
End Property
Public Property Get IsManual() As String
    IsManual = m_Fields("IsManual")
End Property
Public Property Get IsApprovedDateAsLedgerDate() As String
    IsApprovedDateAsLedgerDate = m_Fields("IsApprovedDateAsLedgerDate")
End Property
Public Property Get PostDate() As String
    PostDate = m_Fields("PostDate")
End Property
Public Property Get ApprovalDate() As String
    ApprovalDate = m_Fields("ApprovalDate")
End Property
Public Property Get LineItem() As String
    LineItem = m_Fields("LineItem")
End Property
'***** 自訂欄位
Public Property Get K_Amount() As String
    K_Amount = m_Fields("K_Amount")
End Property
