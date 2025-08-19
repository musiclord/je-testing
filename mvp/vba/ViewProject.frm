VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewProject 
   Caption         =   "Project"
   ClientHeight    =   3015
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   4560
   OleObjectBlob   =   "ViewProject.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "ViewProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit
Private Const MODULE_NAME As String = "ViewProject"

Public Event NewProject(ByVal name As String, ByVal path As String)
Public Event SelectProject(ByVal name As String, ByVal path As String)

Public Sub Initialize()
    UpdateProjectList
End Sub

'-- button_click
Private Sub btnNew_Click()
    Dim name As String, path As String
    name = Me.txtbProjectName.value
    path = ThisWorkbook.path & "\" & name
    RaiseEvent NewProject(name, path)
End Sub

Private Sub btnSelect_Click()
    Dim name As String, path As String
    name = Me.listProjects.value
    path = ThisWorkbook.path & "\" & name
    Me.Hide
    RaiseEvent SelectProject(name, path)
End Sub

Private Sub btnExit_Click()
    Me.Hide
End Sub

'-- custom
Public Sub UpdateProjectList()
    Const METHOD_NAME As String = ".UpdateProjectList"
    Dim projects As New Collection
    Dim item As Variant
    Dim root As String, folder As String, path As String
    root = ThisWorkbook.path
    folder = Dir(root & "\*", vbDirectory)
    Do While folder <> ""
        If folder <> "." And folder <> ".." Then
            path = root & "\" & folder
            If (GetAttr(path) And vbDirectory) = vbDirectory Then
                projects.Add folder
            End If
        End If
        folder = Dir
    Loop
    Me.listProjects.Clear
    For Each item In projects
        Me.listProjects.AddItem item
    Next item
End Sub


