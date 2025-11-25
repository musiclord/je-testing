VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FieldMapperJe"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: FieldMapperJe
' Purpose: 管理 JE (Journal Entry) 資料表的欄位映射
'
' Responsibility:
'   - 儲存「邏輯欄位名稱 → 實際欄位名稱」的對應關係
'   - 處理使用者自訂欄位映射
'   - 提供統一的欄位名稱存取介面
'===============================================================================

Private m_Name As String
Private m_Method As Long
Private m_Fields As Object  ' Scripting.Dictionary

Private Sub Class_Initialize()
    '初始化 JE 欄位映射
    m_Name = "JE"
    m_Method = 1  ' 預設金額處理方式
    
    Set m_Fields = CreateObject("Scripting.Dictionary")
    
    '初始化預設欄位映射（邏輯名稱 = 實際名稱）
    m_Fields("Amount") = "Amount"
    m_Fields("DebitAmount") = "DebitAmount"
    m_Fields("CreditAmount") = "CreditAmount"
    m_Fields("EntryDescription") = "EntryDescription"
    m_Fields("AccountNumber") = "AccountNumber"
    m_Fields("AccountName") = "AccountName"
    m_Fields("DocumentNumber") = "DocumentNumber"
    m_Fields("ApprovedBy") = "ApprovedBy"
    m_Fields("CreatedBy") = "CreatedBy"
    m_Fields("SourceModule") = "SourceModule"
    m_Fields("DrCr") = "DrCr"
    m_Fields("IsDebit") = "IsDebit"
    m_Fields("IsManual") = "IsManual"
    m_Fields("IsApprovedDateAsLedgerDate") = "IsApprovedDateAsLedgerDate"
    m_Fields("PostDate") = "PostDate"
    m_Fields("ApprovalDate") = "ApprovalDate"
    m_Fields("LineItem") = "LineItem"
End Sub

Public Sub SetField(ByVal key As String, ByVal value As String)
    '設定欄位映射
    If m_Fields.Exists(key) And Len(value) > 0 Then
        m_Fields(key) = value
    End If
End Sub

Public Sub PrintFields()
    '輸出欄位映射到立即視窗
    Dim key As Variant
    Debug.Print "********** [ JE 欄位映射 ] **********"
    Debug.Print String(60, "-")
    For Each key In m_Fields.Keys
        Debug.Print CStr(key) & ": " & CStr(m_Fields(key))
    Next key
    Debug.Print String(60, "-")
End Sub

'-- Properties
Public Property Get Name() As String
    Name = m_Name
End Property

Public Property Let Name(ByVal value As String)
    m_Name = value
End Property

Public Property Get Method() As Long
    Method = m_Method
End Property

Public Property Let Method(ByVal value As Long)
    m_Method = value
End Property

Public Property Get Fields() As Object
    Set Fields = m_Fields
End Property

'-- Field Accessors
Public Property Get Amount() As String
    Amount = m_Fields("Amount")
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

Private Sub Class_Terminate()
    Set m_Fields = Nothing
End Sub
