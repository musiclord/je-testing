VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} v_Project 
   Caption         =   "Project Configuration"
   ClientHeight    =   3420
   ClientLeft      =   120
   ClientTop       =   468
   ClientWidth     =   4752
   OleObjectBlob   =   "v_Project.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "v_Project"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "v_Project"
' ----- 事件 -----
Public Event DoNew()
Public Event DoSelect()



' ----- [ v_Project ] -----
Private Sub btnNew_Click()
    RaiseEvent DoNew
End Sub

Private Sub btnSelect_Click()
    RaiseEvent DoSelect
End Sub



' ----- [ Custom ] -----
Public Sub UpdateListProjects(projects As Collection)
    ' Update listProject
    Dim item As Variant
    Me.listProjects.Clear
    For Each item In projects
        Me.listProjects.AddItem item
    Next item
End Sub

