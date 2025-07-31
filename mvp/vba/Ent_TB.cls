VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ent_TB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ent_TB"
'===============================================================================
' Module:   Ent_TB
' Purpose:
' Layer:    Entity
' Domain:   Trial Balance
'===============================================================================

'--列舉
Public Enum TBFieldsIndex
    '--試算表金額
    ChangeAmount
    OpeningAmount
    ClosingAmount
    DebitAmount
    CreditAmount
    '--必選欄位
    AccountNumber
    AccountName
    '--基於列舉 +1 尾數
    count
End Enum

'--私有變數
Private m_Fields() As String    '設陣列儲存字串
Private m_Map As New Dictionary
'--屬性
Public Property Get name() As String
    name = "TB"
End Property
Public Property Get field(ByVal index As TBFieldsIndex) As String
    field = m_Fields(index)
End Property



'--Ent_TB
Public Sub SetMapping(ByVal key As Variant, value As String)
    Dim index As Long
    If Len(value) > 0 Then
        m_Fields(m_Map(key)) = value '覆寫
    End If
End Sub

Public Sub debug_test()
    Dim i As Long
    Debug.Print "----------------------------------------"
    For i = LBound(m_Fields) To UBound(m_Fields)
        Debug.Print "Index " & i & ": " & m_Fields(i)
    Next i
    Debug.Print "----------------------------------------"
End Sub

Private Sub Class_Initialize()
    '動態設定陣列大小
    ReDim m_Fields(0 To TBFieldsIndex.count - 1)
    'm_Fields --> 總分金額對應方式
    m_Fields(TBFieldsIndex.ChangeAmount) = "ChangeAmount"
    m_Fields(TBFieldsIndex.OpeningAmount) = "OpeningAmount"
    m_Fields(TBFieldsIndex.ClosingAmount) = "ClosingAmount"
    m_Fields(TBFieldsIndex.DebitAmount) = "DebitAmount"
    m_Fields(TBFieldsIndex.CreditAmount) = "CreditAmount"
    'm_Fields --> 必要欄位
    m_Fields(TBFieldsIndex.AccountNumber) = "AccountNumber"
    m_Fields(TBFieldsIndex.AccountName) = "AccountName"
    'm_Map --> 總分金額對應方式
    m_Map.Add "ChangeAmount", TBFieldsIndex.ChangeAmount
    m_Map.Add "OpeningAmount", TBFieldsIndex.OpeningAmount
    m_Map.Add "ClosingAmount", TBFieldsIndex.ClosingAmount
    m_Map.Add "DebitAmount", TBFieldsIndex.DebitAmount
    m_Map.Add "CreditAmount", TBFieldsIndex.CreditAmount
    'm_Map --> 必要欄位
    m_Map.Add "AccountNumber", TBFieldsIndex.AccountNumber
    m_Map.Add "AccountName", TBFieldsIndex.AccountName
End Sub
