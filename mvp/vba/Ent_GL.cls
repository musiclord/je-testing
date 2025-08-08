VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ent_GL"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ent_GL"
'===============================================================================
' Module:   Ent_GL
' Purpose:
' Layer:    Entity
' Domain:   General Ledger
'===============================================================================

'--類別成員
Private m_Fields As New Dictionary
Private m_FieldsType As New Dictionary


'--Ent_GL
Public Function GetType(ByVal field As String) As String
    GetType = m_FieldsType(field)
End Function

Public Sub SetMapping(ByVal key As String, ByVal value As String)
    If m_Fields.Exists(key) And Len(value) > 0 Then
        m_Fields(key) = value
    End If
End Sub

Public Sub debug_test()
    Dim key As Variant
    Debug.Print "---------- [ GL ] ----------"
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print "----------------------------"
End Sub

Private Sub Class_Initialize()
    '使用二維陣列: [[名稱1,型別],[名稱2,型別],...]
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
        '0: 名稱; 1: 型別
        m_Fields(fields(i)(0)) = fields(i)(0)
        m_FieldsType(fields(i)(0)) = fields(i)(1)
    Next i
End Sub


'--屬性
Public Property Get name() As String
    name = "GL"
End Property
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
