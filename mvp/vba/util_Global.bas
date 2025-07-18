Attribute VB_Name = "Util_Global"
Option Explicit

Public Function GetProjectDirectories() As Collection
    Const METHOD_NAME As String = "GetProjectDirectories"
    Dim projects As New Collection
    Dim root As String, folder As String, path As String
    '掃描目錄
    root = ThisWorkbook.path
    folder = Dir(root & "\*", vbDirectory)
    Do While folder <> ""
        '排除系統及隱藏目錄
        If folder <> "." And folder <> ".." Then
            path = root & "\" & folder
            If (GetAttr(path) And vbDirectory) = vbDirectory Then
                projects.Add (folder)
            End If
        End If
        folder = Dir
    Loop
    Set GetProjectDirectories = projects
End Function

