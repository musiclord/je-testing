VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} View_Project 
   Caption         =   "Project"
   ClientHeight    =   3012
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   4560
   OleObjectBlob   =   "View_Project.frx":0000
   StartUpPosition =   1  '所屬視窗中央
End
Attribute VB_Name = "View_Project"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME As String = "View_Project"
'===============================================================================
' Module:   View_Project
' Purpose:  專案設置介面，可選擇創建專案，或是指定已存在的專案目錄
' Layer:    View
' Domain:   Project
'===============================================================================

Public Event DoExit()
Public Event NewProject()
Public Event SelectProject()

Private Sub btnNew_Click()
    RaiseEvent NewProject
End Sub

Private Sub btnSelect_Click()
    RaiseEvent SelectProject
End Sub

Private Sub btnExit_Click()
    RaiseEvent DoExit
End Sub


'--自訂方法
Public Function UpdateProjects(projects As Collection) As Boolean
    '更新控制項: listProjects
    Const METHOD_NAME As String = "UpdateProjects"
    On Error GoTo Errorhandler
    UpdateProjects = False
    
    Dim item As Variant
    Me.listProjects.Clear
    For Each item In projects
        Me.listProjects.AddItem item
    Next item
    
    UpdateProjects = True
    Exit Function
Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & Err.Description
    UpdateProjects = False
End Function
