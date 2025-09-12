VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "EntityJe"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:EntityJe
Private m_Name As String
Private m_Method As Long
Private m_Fields As New Dictionary

'***** 方法
Private Sub Class_Initialize()
    m_Name = "JE"
    Dim Fields As Variant
    Dim i As Long
    Fields = Array( _
        "Amount", _
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
        "K_Amount", _
        "K_Amount_Sum", _
        "K_Diff" _
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
    Debug.Print "--------- [ JE ] ---------"
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

'***** 屬性自訂欄位
Public Property Get K_Amount() As String
    '計算用的金額欄位
    K_Amount = m_Fields("K_Amount")
End Property
Public Property Get K_Amount_Sum() As String
    '依科目彙總後的總金額
    K_Amount_Sum = m_Fields("K_Amount_Sum")
End Property


'***** 屬性快速補全
Public Property Get Amount() As String
    '傳票金額
    Amount = m_Fields("Amount")
End Property
Public Property Get DebitAmount() As String
    '借方金額
    DebitAmount = m_Fields("DebitAmount")
End Property
Public Property Get CreditAmount() As String
    '貸方金額
    CreditAmount = m_Fields("CreditAmount")
End Property
Public Property Get EntryDescription() As String
    '傳票摘要
    EntryDescription = m_Fields("EntryDescription")
End Property
Public Property Get AccountNumber() As String
    '科目號碼
    AccountNumber = m_Fields("AccountNumber")
End Property
Public Property Get AccountName() As String
    '科目名稱
    AccountName = m_Fields("AccountName")
End Property
Public Property Get DocumentNumber() As String
    '傳票號碼
    DocumentNumber = m_Fields("DocumentNumber")
End Property
Public Property Get ApprovedBy() As String
    '傳票核准人員
    ApprovedBy = m_Fields("ApprovedBy")
End Property
Public Property Get CreatedBy() As String
    '傳票建立人員
    CreatedBy = m_Fields("CreatedBy")
End Property
Public Property Get SourceModule() As String
    '分錄來源模組
    SourceModule = m_Fields("SourceModule")
End Property
Public Property Get DrCr() As String
    '借貸別
    DrCr = m_Fields("DrCr")
End Property
Public Property Get IsDebit() As String
    '借方標誌
    IsDebit = m_Fields("IsDebit")
End Property
Public Property Get IsManual() As String
    '人工/自動分錄
    IsManual = m_Fields("IsManual")
End Property
Public Property Get IsApprovedDateAsLedgerDate() As String
    '核准日同總帳日
    IsApprovedDateAsLedgerDate = m_Fields("IsApprovedDateAsLedgerDate")
End Property
Public Property Get PostDate() As String
    '總帳日期
    PostDate = m_Fields("PostDate")
End Property
Public Property Get ApprovalDate() As String
    '核准日期
    ApprovalDate = m_Fields("ApprovalDate")
End Property
Public Property Get LineItem() As String
    '項次
    LineItem = m_Fields("LineItem")
End Property
