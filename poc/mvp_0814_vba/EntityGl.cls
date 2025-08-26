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

Private Const MODULE_Name As String = "EntityGl"
Private m_Method As Long
Private m_Fields As New Dictionary
Private m_Types As New Dictionary

Private Sub Class_Initialize()
    Dim Fields As Variant
    Dim i As Long
    Fields = Array( _
        Array("EntryAmount", "CURRENCY"), _
        Array("DebitAmount", "CURRENCY"), _
        Array("CreditAmount", "CURRENCY"), _
        Array("EntryDescription", "LONGTEXT"), _
        Array("AccountNumber", "TEXT(50)"), _
        Array("AccountName", "TEXT(50)"), _
        Array("DocumentNumber", "TEXT(50)"), _
        Array("ApprovedBy", "TEXT(50)"), _
        Array("CreatedBy", "TEXT(50)"), _
        Array("SourceModule", "TEXT(50)"), _
        Array("DrCr", "TEXT(50)"), _
        Array("IsDebit", "TEXT(50)"), _
        Array("IsManual", "TEXT(50)"), _
        Array("IsApprovedDateAsLedgerDate", "TEXT(50)"), _
        Array("PostDate", "DATE"), _
        Array("ApprovalDate", "DATE"), _
        Array("LineItem", "INTEGER") _
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
    Debug.Print "--------- [ GL ] ---------"
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print "--------------------------"
End Sub

'--ÄÝ©Ê
Public Property Get Name() As String
    Name = "GL"
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
Public Property Get EntryAmount() As String
    EntryAmount = " [" & m_Fields("EntryAmount") & "] "
End Property
Public Property Get DebitAmount() As String
    DebitAmount = " [" & m_Fields("DebitAmount") & "] "
End Property
Public Property Get CreditAmount() As String
    CreditAmount = " [" & m_Fields("CreditAmount") & "] "
End Property
Public Property Get DrCr() As String
    DrCr = " [" & m_Fields("DrCr") & "] "
End Property
Public Property Get IsDebit() As String
    IsDebit = " [" & m_Fields("IsDebit") & "] "
End Property
Public Property Get AccountNumber() As String
    AccountNumber = " [" & m_Fields("AccountNumber") & "] "
End Property
Public Property Get AccountName() As String
    AccountName = " [" & m_Fields("AccountName") & "] "
End Property
Public Property Get DocumentNumber() As String
    DocumentNumber = " [" & m_Fields("DocumentNumber") & "] "
End Property
Public Property Get LineItem() As String
    LineItem = " [" & m_Fields("LineItem") & "] "
End Property
Public Property Get PostDate() As String
    PostDate = " [" & m_Fields("PostDate") & "] "
End Property
Public Property Get EntryDescription() As String
    EntryDescription = " [" & m_Fields("EntryDescription") & "] "
End Property
Public Property Get ApprovalDate() As String
    ApprovalDate = " [" & m_Fields("ApprovalDate") & "] "
End Property
Public Property Get ApprovedBy() As String
    ApprovedBy = " [" & m_Fields("ApprovedBy") & "] "
End Property
Public Property Get CreatedBy() As String
    CreatedBy = " [" & m_Fields("CreatedBy") & "] "
End Property
Public Property Get SourceModule() As String
    SourceModule = " [" & m_Fields("SourceModule") & "] "
End Property
Public Property Get IsManual() As String
    IsManual = " [" & m_Fields("IsManual") & "] "
End Property
Public Property Get IsApprovedDateAsLedgerDate() As String
    IsApprovedDateAsLedgerDate = " [" & m_Fields("IsApprovedDateAsLedgerDate") & "] "
End Property


