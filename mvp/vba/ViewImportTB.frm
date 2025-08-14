VERSION 5.00
Begin {C62A69F0-16DC-11CE-9E98-00AA00574A4F} ViewImportTB 
   Caption         =   "Import TB"
   ClientHeight    =   8010
   ClientLeft      =   120
   ClientTop       =   465
   ClientWidth     =   7905
   OleObjectBlob   =   "ViewImportTB.frx":0000
   StartUpPosition =   1  '©ÒÄÝµøµ¡¤¤¥¡
End
Attribute VB_Name = "ViewImportTB"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False

Option Explicit

Public Event ProcessMethod(ByVal method As Long)
Public Event ApplyFields(ByVal fields As Dictionary)
Public Event Import()
Public Event LastStep()
Public Event NextStep()

Private m_file As String

Public Sub Initialize()
    Const METHOD_NAME As String = ".Initialize"
End Sub

Private Sub btnApply_Click()
    ' fields = GetFields()
    ' RaiseEvent ApplyFields(fields)
    
End Sub

Private Sub btnImport_Click()
    'RaiseEvent Import(m_file)
End Sub

Private Sub btnLastStep_Click()
    RaiseEvent LastStep
End Sub

Private Sub btnNextStep_Click()
    RaiseEvent NextStep
End Sub

Private Sub btnMethod1_Click()
    
    RaiseEvent ProcessMethod(1)
End Sub

Private Sub btnMethod2_Click()
    RaiseEvent ProcessMethod(2)
End Sub

Private Sub btnMethod3_Click()
    RaiseEvent ProcessMethod(3)
End Sub

Private Sub btnMethod4_Click()
    RaiseEvent ProcessMethod(4)
End Sub


