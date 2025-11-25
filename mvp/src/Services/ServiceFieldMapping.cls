VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceFieldMapping"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' ServiceFieldMapping.cls
' Handles field mapping logic (Auto-map, Validation)

Public Function AutoMapFields(ByVal sourceFields As Variant, ByVal targetFields As Variant) As Object
    ' sourceFields: Array of strings (from CSV header)
    ' targetFields: Array of strings (Database columns)
    ' Returns: Dictionary (Source -> Target)
    
    Dim map As Object
    Set map = CreateObject("Scripting.Dictionary")
    
    Dim i As Long
    Dim j As Long
    
    For i = LBound(targetFields) To UBound(targetFields)
        Dim target As String
        target = targetFields(i)
        
        ' Simple fuzzy match
        For j = LBound(sourceFields) To UBound(sourceFields)
            Dim source As String
            source = sourceFields(j)
            
            If IsMatch(source, target) Then
                If Not map.Exists(source) Then
                    map.Add source, target
                    Exit For ' Found a match for this target
                End If
            End If
        Next j
    Next i
    
    Set AutoMapFields = map
End Function

Private Function IsMatch(ByVal source As String, ByVal target As String) As Boolean
    ' Simple heuristic
    Dim s As String, t As String
    s = LCase(Replace(source, "_", ""))
    t = LCase(Replace(target, "_", ""))
    
    If s = t Then IsMatch = True: Exit Function
    If InStr(s, t) > 0 Or InStr(t, s) > 0 Then IsMatch = True: Exit Function
    
    ' Specific synonyms
    If t = "debit" And (s = "dr" Or s = "debitamount") Then IsMatch = True: Exit Function
    If t = "credit" And (s = "cr" Or s = "creditamount") Then IsMatch = True: Exit Function
    If t = "accountcode" And (s = "acct" Or s = "account" Or s = "gl") Then IsMatch = True: Exit Function
    
    IsMatch = False
End Function
