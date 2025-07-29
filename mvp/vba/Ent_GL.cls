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
Public Enum FieldsId
    '總帳金額對應方式
    HandlingMethod = 0
    EntryAmount = 1
    DebitAmount = 2
    CreditAmount = 3
    DrCr = 4
    IsDebit = 5
    '必要欄位
    AccountNumber = 6
    AccountName = 7
    DocumentNumber = 8
    LineItem = 9
    PostDate = 10
    EntryDescription = 11
    '可選欄位
    ApprovalDate = 12
    ApprovedBy = 13
    CreatedBy = 14
    SourceModule = 15
    IsManual = 16
    IsApprovedDateAsLedgerDate = 17
    '基於列舉自動+1為總數
    Count
End Enum

'--私有變數
Private m_Fields() As String    '儲存映射後欄位名稱
Private m_Map As Dictionary     '儲存字典
'--屬性
Public Property Get Field(ByVal index As FieldsId) As String
    Dim result As String
    Field = m_Fields(index)
End Property



'--Ent_GL
Private Sub Class_Initialize()
    '動態設定陣列大小
    ReDim m_Fields(0 To FieldsId.Count - 1)
    '總分金額對應方式
    m_Fields(FieldsId.HandlingMethod) = "HandlingMethod"
    m_Fields(FieldsId.EntryAmount) = "EntryAmount"
    m_Fields(FieldsId.DebitAmount) = "DebitAmount"
    m_Fields(FieldsId.CreditAmount) = "CreditAmount"
    m_Fields(FieldsId.DrCr) = "DrCr"
    m_Fields(FieldsId.IsDebit) = "IsDebit"
    '必要欄位
    m_Fields(FieldsId.AccountNumber) = "AccountNumber"
    m_Fields(FieldsId.AccountName) = "AccountName"
    m_Fields(FieldsId.DocumentNumber) = "DocumentNumber"
    m_Fields(FieldsId.LineItem) = "LineItem"
    m_Fields(FieldsId.PostDate) = "PostDate"
    m_Fields(FieldsId.EntryDescription) = "EntryDescription"
    '可選欄位
    m_Fields(FieldsId.ApprovalDate) = "ApprovalDate"
    m_Fields(FieldsId.ApprovedBy) = "ApprovedBy"
    m_Fields(FieldsId.CreatedBy) = "CreatedBy"
    m_Fields(FieldsId.SourceModule) = "SourceModule"
    m_Fields(FieldsId.IsManual) = "IsManual"
    m_Fields(FieldsId.IsApprovedDateAsLedgerDate) = "IsApprovalDateAsLedgerDate"
    '建立欄位名稱到索引的映射
    Set m_Map = New Dictionary
    Dim i As Long
    For i = 0 To UBound(m_Fields)
        m_Map(m_Fields(i)) = i
    Next i
End Sub

Private Sub InitializeField()
    
End Sub

Public Sub SetMapping(index As FieldsId, name As String)
    If Len(name) > 0 Then
        m_Fields(index) = name '覆蓋標準名稱
    End If
End Sub

Public Function SQL(ByVal index As FieldsId) As String
    SQL = "[" & m_Fields(index) & "]"
End Function
