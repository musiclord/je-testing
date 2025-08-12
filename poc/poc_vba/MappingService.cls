VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "MappingService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False

Option Explicit
'Model: Mapping Service
'Description: Handles mapping procedures of columns between source and target table.

Private Const MODULE_NAME As String = "MappingService"

' --- 私有變數 ---
Private m_GLFieldMappings As Object
Private m_TBFieldMappings As Object

Private Sub Class_Initialize()
    ' 初始化時建立空的字典
    Set m_GLFieldMappings = CreateObject("Scripting.Dictionary")
    m_GLFieldMappings.CompareMode = vbTextCompare
    Set m_TBFieldMappings = CreateObject("Scripting.Dictionary")
    m_TBFieldMappings.CompareMode = vbTextCompare
    Debug.Print MODULE_NAME & " Initialized."
End Sub

Private Sub Class_Terminate()
    Set m_GLFieldMappings = Nothing
    Set m_TBFieldMappings = Nothing
    Debug.Print MODULE_NAME & " Terminated."
End Sub

' --- GL 相關方法 ---
Public Sub SetGLFieldMappings(ByVal mappings As Object)
    Const METHOD_NAME As String = "SetGLFieldMappings"
    Dim key As Variant
    If mappings Is Nothing Or TypeName(mappings) <> "Dictionary" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Error: Invalid mappings received."
        Set m_GLFieldMappings = CreateObject("Scripting.Dictionary")
        m_GLFieldMappings.CompareMode = vbTextCompare
        Exit Sub
    End If
    Set m_GLFieldMappings = mappings
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - GL field mappings stored. Count: " & m_GLFieldMappings.Count
    For Each key In m_GLFieldMappings.Keys: Debug.Print "    GL Map: " & key & " -> " & m_GLFieldMappings(key): Next key
End Sub

Public Function GetGLFieldMappings() As Object ' Returns Scripting.Dictionary
    Set GetGLFieldMappings = m_GLFieldMappings
End Function

' --- TB 相關方法 (新增) ---
Public Sub SetTBFieldMappings(ByVal mappings As Object)
    Const METHOD_NAME As String = "SetTBFieldMappings"
    Dim key As Variant
    If mappings Is Nothing Or TypeName(mappings) <> "Dictionary" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Error: Invalid mappings received."
        Set m_TBFieldMappings = CreateObject("Scripting.Dictionary")
        m_TBFieldMappings.CompareMode = vbTextCompare
        Exit Sub
    End If
    Set m_TBFieldMappings = mappings
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - TB field mappings stored. Count: " & m_TBFieldMappings.Count
    For Each key In m_TBFieldMappings.Keys: Debug.Print "    TB Map: " & key & " -> " & m_TBFieldMappings(key): Next key
End Sub

Public Function GetTBFieldMappings() As Object ' Returns Scripting.Dictionary
    Set GetTBFieldMappings = m_TBFieldMappings
End Function

