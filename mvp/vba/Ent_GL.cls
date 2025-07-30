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

'--列舉
Public Enum GLFieldsIndex
    '總帳金額對應方式
    EntryAmount
    DebitAmount
    CreditAmount
    DrCr
    IsDebit
    '必要欄位
    AccountNumber
    AccountName
    DocumentNumber
    LineItem
    PostDate
    EntryDescription
    '可選欄位
    ApprovalDate
    ApprovedBy
    CreatedBy
    SourceModule
    IsManual
    IsApprovedDateAsLedgerDate
    '基於列舉 +1 尾數
    count
End Enum

'--私有變數
Private m_Fields() As String    '設陣列儲存字串
Private m_Map As New Dictionary
'--屬性
Public Property Get name() As String
    name = "GL"
End Property
Public Property Get field(ByVal index As GLFieldsIndex) As String
    field = m_Fields(index)
End Property



'--Ent_GL
Public Sub SetMapping(ByVal key As Variant, value As String)
    Dim index As Long
    If Len(value) > 0 Then
        m_Fields(m_Map(key)) = value '覆寫
    End If
End Sub

Public Sub debug_test()
    Dim i As Long
    For i = LBound(m_Fields) To UBound(m_Fields)
        Debug.Print "Index " & i & ": " & m_Fields(i)
    Next i
End Sub


Private Sub Class_Initialize()
    '動態設定陣列大小
    ReDim m_Fields(0 To GLFieldsIndex.count - 1)
    'm_Fields --> 總分金額對應方式
    m_Fields(GLFieldsIndex.EntryAmount) = "EntryAmount"
    m_Fields(GLFieldsIndex.DebitAmount) = "DebitAmount"
    m_Fields(GLFieldsIndex.CreditAmount) = "CreditAmount"
    m_Fields(GLFieldsIndex.DrCr) = "DrCr"
    m_Fields(GLFieldsIndex.IsDebit) = "IsDebit"
    'm_Map --> 總分金額對應方式
    m_Map.Add "EntryAmount", GLFieldsIndex.EntryAmount
    m_Map.Add "DebitAmount", GLFieldsIndex.DebitAmount
    m_Map.Add "CreditAmount", GLFieldsIndex.CreditAmount
    m_Map.Add "DrCr", GLFieldsIndex.DrCr
    m_Map.Add "IsDebit", GLFieldsIndex.IsDebit
    'm_Fields --> 必要欄位
    m_Fields(GLFieldsIndex.AccountNumber) = "AccountNumber"
    m_Fields(GLFieldsIndex.AccountName) = "AccountName"
    m_Fields(GLFieldsIndex.DocumentNumber) = "DocumentNumber"
    m_Fields(GLFieldsIndex.LineItem) = "LineItem"
    m_Fields(GLFieldsIndex.PostDate) = "PostDate"
    m_Fields(GLFieldsIndex.EntryDescription) = "EntryDescription"
    'm_Map --> 必要欄位
    m_Map.Add "AccountNumber", GLFieldsIndex.AccountNumber
    m_Map.Add "AccountName", GLFieldsIndex.AccountName
    m_Map.Add "DocumentNumber", GLFieldsIndex.DocumentNumber
    m_Map.Add "LineItem", GLFieldsIndex.LineItem
    m_Map.Add "PostDate", GLFieldsIndex.PostDate
    m_Map.Add "EntryDescription", GLFieldsIndex.EntryDescription
    'm_Fields --> 可選欄位
    m_Fields(GLFieldsIndex.ApprovalDate) = "ApprovalDate"
    m_Fields(GLFieldsIndex.ApprovedBy) = "ApprovedBy"
    m_Fields(GLFieldsIndex.CreatedBy) = "CreatedBy"
    m_Fields(GLFieldsIndex.SourceModule) = "SourceModule"
    m_Fields(GLFieldsIndex.IsManual) = "IsManual"
    m_Fields(GLFieldsIndex.IsApprovedDateAsLedgerDate) = "IsApprovalDateAsLedgerDate"
    'm_Map --> 可選欄位
    m_Map.Add "ApprovalDate", GLFieldsIndex.ApprovalDate
    m_Map.Add "ApprovedBy", GLFieldsIndex.ApprovedBy
    m_Map.Add "CreatedBy", GLFieldsIndex.CreatedBy
    m_Map.Add "SourceModule", GLFieldsIndex.SourceModule
    m_Map.Add "IsManual", GLFieldsIndex.IsManual
    m_Map.Add "IsApprovalDateAsLedgerDate", GLFieldsIndex.IsApprovedDateAsLedgerDate
End Sub


