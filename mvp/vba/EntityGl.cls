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

Private Const MODULE_NAME As String = "EntityGl"
Private m_fields As New Dictionary
Private m_Types As New Dictionary

Private Sub Class_Initialize()
    Dim fields As Variant
    Dim i As Long
    fields = Array( _
        Array("EntryAmount", "CURRENCY"), _
        Array("DebitAmount", "CURRENCY"), _
        Array("CreditAmount", "CURRENCY"), _
        Array("EntryDescription", "LONGTEXT"), _
        Array("AccountNumber", "TEXT"), _
        Array("AccountName", "TEXT"), _
        Array("DocumentNumber", "TEXT"), _
        Array("ApprovedBy", "TEXT"), _
        Array("CreatedBy", "TEXT"), _
        Array("SourceModule", "TEXT"), _
        Array("DrCr", "TEXT"), _
        Array("IsDebit", "TEXT"), _
        Array("IsManual", "TEXT"), _
        Array("IsApprovedDateAsLedgerDate", "TEXT"), _
        Array("PostDate", "DATE"), _
        Array("ApprovalDate", "DATE"), _
        Array("LineItem", "INTEGER") _
    )
    For i = LBound(fields) To UBound(fields)
        ' 0:Name, 1:Type
        m_fields(fields(i)(0)) = fields(i)(0) 'name:name
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
    If m_fields.Exists(key) And Len(value) > 0 Then
        m_fields(key) = value
    End If
End Sub

Public Sub PrintFields()
    Dim key As Variant
    Debug.Print "--------- [ GL ] ---------"
    For Each key In m_fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_fields(key))
    Next key
    Debug.Print "--------------------------"
End Sub

'--ÄÝ©Ê
Public Property Get name() As String
    name = "GL"
End Property
Public Property Get EntryAmount() As String
    EntryAmount = " [" & m_fields("EntryAmount") & "] "
End Property
Public Property Get DebitAmount() As String
    DebitAmount = " [" & m_fields("DebitAmount") & "] "
End Property
Public Property Get CreditAmount() As String
    CreditAmount = " [" & m_fields("CreditAmount") & "] "
End Property
Public Property Get DrCr() As String
    DrCr = " [" & m_fields("DrCr") & "] "
End Property
Public Property Get IsDebit() As String
    IsDebit = " [" & m_fields("IsDebit") & "] "
End Property
Public Property Get AccountNumber() As String
    AccountNumber = " [" & m_fields("AccountNumber") & "] "
End Property
Public Property Get AccountName() As String
    AccountName = " [" & m_fields("AccountName") & "] "
End Property
Public Property Get DocumentNumber() As String
    DocumentNumber = " [" & m_fields("DocumentNumber") & "] "
End Property
Public Property Get LineItem() As String
    LineItem = " [" & m_fields("LineItem") & "] "
End Property
Public Property Get PostDate() As String
    PostDate = " [" & m_fields("PostDate") & "] "
End Property
Public Property Get EntryDescription() As String
    EntryDescription = " [" & m_fields("EntryDescription") & "] "
End Property
Public Property Get ApprovalDate() As String
    ApprovalDate = " [" & m_fields("ApprovalDate") & "] "
End Property
Public Property Get ApprovedBy() As String
    ApprovedBy = " [" & m_fields("ApprovedBy") & "] "
End Property
Public Property Get CreatedBy() As String
    CreatedBy = " [" & m_fields("CreatedBy") & "] "
End Property
Public Property Get SourceModule() As String
    SourceModule = " [" & m_fields("SourceModule") & "] "
End Property
Public Property Get IsManual() As String
    IsManual = " [" & m_fields("IsManual") & "] "
End Property
Public Property Get IsApprovedDateAsLedgerDate() As String
    IsApprovedDateAsLedgerDate = " [" & m_fields("IsApprovedDateAsLedgerDate") & "] "
End Property


