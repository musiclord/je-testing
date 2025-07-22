VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ent_FieldsGL"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ent_FieldsGL"
'===============================================================================
' Module:   Ent_FieldsGL
' Purpose:
' Layer:    Entity
' Domain:   GL Mapping
'===============================================================================

'--類別成員
Private m_mapping As Ent_Fields

'--屬性
Public Property Get AccountNumber() As String
    AccountNumber = m_mapping.GetSourceField("AccountNumber")
End Property

Public Property Get AccountName() As String
    AccountName = m_mapping.GetSourceField("AccountName")
End Property



'--Ent_FieldsGL
Public Sub Initialize()
    Set m_mapping = New Ent_Fields
    m_mapping.Initialize
    Call SetDefaultMapping
End Sub

Private Sub SetDefaultMapping()
    m_mapping.SetMapping "", ""
    m_mapping.SetMapping "", ""
    m_mapping.SetMapping "", ""
    m_mapping.SetMapping "", ""
End Sub

Public Sub SetCustomMapping(ByVal standardField As String, ByVal customerField As String)
    m_mapping.SetMapping standardField, customerField
End Sub
