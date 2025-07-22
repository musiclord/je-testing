VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Ent_Fields"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Ent_Fields"
'===============================================================================
' Module:   Ent_Fields
' Purpose:
' Layer:    Entity
' Domain:   Fields Mapping
'===============================================================================

'--類別成員
Private m_mappings As Dictionary

'--屬性
Public Property Get Mappings() As Dictionary
    Set Mappings = m_mappings
End Property



'--Ent_Fields
Public Sub Initialize()
    Set m_mappings = New Dictionary
End Sub


Public Sub SetMapping(ByVal standardField As String, ByVal sourceField As String)
    m_mappings(standardField) = sourceField
End Sub

Public Function GetSourceField(ByVal standardField As String) As String
    If m_mappings.Exists(standardField) Then
        GetSourceField = m_mappings(standardField)
    Else
        GetSourceField = standardField
    End If
End Function

