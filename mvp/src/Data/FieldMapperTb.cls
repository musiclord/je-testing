VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FieldMapperTb"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: FieldMapperTb
' Purpose: 管理 TB (Trial Balance) 資料表的欄位映射
'===============================================================================

Private m_Name As String
Private m_Method As Long
Private m_Fields As Object  ' Scripting.Dictionary

Private Sub Class_Initialize()
    '初始化 TB 欄位映射
    m_Name = "TB"
    m_Method = 1  ' 預設金額處理方式
    
    Set m_Fields = CreateObject("Scripting.Dictionary")
    
    '初始化預設欄位映射
    m_Fields("ChangeAmount") = "ChangeAmount"
    m_Fields("OpeningBalance") = "OpeningBalance"
    m_Fields("OpeningDebitBalance") = "OpeningDebitBalance"
    m_Fields("OpeningCreditBalance") = "OpeningCreditBalance"
    m_Fields("ClosingBalance") = "ClosingBalance"
    m_Fields("ClosingDebitBalance") = "ClosingDebitBalance"
    m_Fields("ClosingCreditBalance") = "ClosingCreditBalance"
    m_Fields("DebitAmount") = "DebitAmount"
    m_Fields("CreditAmount") = "CreditAmount"
    m_Fields("AccountNumber") = "AccountNumber"
    m_Fields("AccountName") = "AccountName"
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
    Debug.Print "********** [ TB 欄位映射 ] **********"
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

Private Sub Class_Terminate()
    Set m_Fields = Nothing
End Sub
