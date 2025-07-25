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
Public Enum FieldIndex
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
    Description = 11
    '可選欄位
    ApprovalDate = 12
    ApprovedBy = 13
    CreatedBy = 14
    SourceModule = 15
    IsManual = 16
    IsApprovedOn = 17
End Enum

'--私有變數
Private m_Field(0 To 17) As String '儲存映射後欄位名稱

'--屬性
Public Property Get HandlingMethod() As String
    HandlingMethod = m_FieldNames(FieldIndex.HandlingMethod)
End Property

Public Property Get EntryAmount() As String
    EntryAmount = m_FieldNames(FieldIndex.EntryAmount)
End Property

Public Property Get DebitAmount() As String
    DebitAmount = m_FieldNames(FieldIndex.DebitAmount)
End Property

Public Property Get CreditAmount() As String
    CreditAmount = m_FieldNames(FieldIndex.CreditAmount)
End Property

Public Property Get DrCr() As String
    DrCr = m_FieldNames(FieldIndex.DrCr)
End Property

Public Property Get IsDebit() As String
    IsDebit = m_FieldNames(FieldIndex.IsDebit)
End Property

Public Property Get AccountNumber() As String
    AccountNumber = m_FieldNames(FieldIndex.AccountNumber)
End Property

Public Property Get AccountName() As String
    AccountName = m_FieldNames(FieldIndex.AccountName)
End Property

Public Property Get DocumentNumber() As String
    DocumentNumber = m_FieldNames(FieldIndex.DocumentNumber)
End Property

Public Property Get LineItem() As String
    LineItem = m_FieldNames(FieldIndex.LineItem)
End Property

Public Property Get PostDate() As String
    PostDate = m_FieldNames(FieldIndex.PostDate)
End Property

Public Property Get Description() As String
    Description = m_FieldNames(FieldIndex.Description)
End Property

Public Property Get ApprovalDate() As String
    ApprovalDate = m_FieldNames(FieldIndex.ApprovalDate)
End Property

Public Property Get ApprovedBy() As String
    ApprovedBy = m_FieldNames(FieldIndex.ApprovedBy)
End Property

Public Property Get CreatedBy() As String
    CreatedBy = m_FieldNames(FieldIndex.CreatedBy)
End Property

Public Property Get SourceModule() As String
    SourceModule = m_FieldNames(FieldIndex.SourceModule)
End Property

Public Property Get IsManual() As String
    IsManual = m_FieldNames(FieldIndex.IsManual)
End Property

Public Property Get IsApprovedOn() As String
    IsApprovedOn = m_FieldNames(FieldIndex.IsApprovedOn)
End Property

'--Ent_GL
Public Sub Initialize()
    Dim standardFields As Dictionary
    Set standardFields = GetStandardFields()
    
    Dim key As Variant
    For Each key In standardFields.Keys
        m_Field(standardFields(key)) = CStr(key)
    Next key
End Sub

Public Function GetStandardFields() As Dictionary
    Const METHOD_NAME As String = "GetStandardField"
    
    Dim dict As New Dictionary
    '遍歷 Enum
    dict.Add "HandlingMethod", FieldIndex.HandlingMethod
    dict.Add "EntryAmount", FieldIndex.EntryAmount
    dict.Add "DebitAmount", FieldIndex.DebitAmount
    dict.Add "CreditAmount", FieldIndex.CreditAmount
    dict.Add "DrCr", FieldIndex.DrCr
    dict.Add "IsDebit", FieldIndex.IsDebit
    dict.Add "AccountNumber", FieldIndex.AccountNumber
    dict.Add "AccountName", FieldIndex.AccountName
    dict.Add "DocumentNumber", FieldIndex.DocumentNumber
    dict.Add "LineItem", FieldIndex.LineItem
    dict.Add "PostDate", FieldIndex.PostDate
    dict.Add "Description", FieldIndex.Description
    dict.Add "ApprovalDate", FieldIndex.ApprovalDate
    dict.Add "ApprovedBy", FieldIndex.ApprovedBy
    dict.Add "CreatedBy", FieldIndex.CreatedBy
    dict.Add "SourceModule", FieldIndex.SourceModule
    dict.Add "IsManual", FieldIndex.IsManual
    dict.Add "IsApprovedOn", FieldIndex.IsApprovedOn
    Set GetStandardField = dict
End Function
