VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ApplicationMain"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'Class:ApplicationMain
'--
Private WithEvents vProject As ViewProject
Attribute vProject.VB_VarHelpID = -1
Private WithEvents vMain As ViewMain
Attribute vMain.VB_VarHelpID = -1
Private WithEvents vImport As ViewImport
Attribute vImport.VB_VarHelpID = -1
Private WithEvents vMapGl As ViewImportMapGl
Attribute vMapGl.VB_VarHelpID = -1
Private WithEvents vMapTb As ViewImportMapTb
Attribute vMapTb.VB_VarHelpID = -1
Private WithEvents vValidation As ViewValidation
Attribute vValidation.VB_VarHelpID = -1
Private WithEvents vFilter As ViewFilter
Attribute vFilter.VB_VarHelpID = -1
Private WithEvents vAddCriteria As ViewFilterAddCriteria
Attribute vAddCriteria.VB_VarHelpID = -1
Private WithEvents vExport As ViewExport
Attribute vExport.VB_VarHelpID = -1
'--
Private fso As FileSystemObject
Private context As ContextManager
Private projector As ServiceProject
Private importer As ServiceImport
Private validator As ServiceValidation
Private filter As ServiceFilter

'-- Application
Public Sub Initialize()
    Set vProject = New ViewProject
    Set vMain = New ViewMain
    Set vImport = New ViewImport
    Set vMapGl = New ViewImportMapGl
    Set vMapTb = New ViewImportMapTb
    Set vValidation = New ViewValidation
    Set vFilter = New ViewFilter
    Set vAddCriteria = New ViewFilterAddCriteria
    Set vExport = New ViewExport
    '--
    Set fso = New FileSystemObject
    Set context = New ContextManager
    Set projector = New ServiceProject
    Set importer = New ServiceImport
    Set validator = New ServiceValidation
    Set filter = New ServiceFilter
    '--
    context.Initialize
End Sub

Public Sub Run()
    projector.Initialize context
    vProject.Initialize
    vProject.Show vbModeless
End Sub


'-- vProject
Private Sub vProject_NewProject(ByVal path As String)
    projector.NewProject path
End Sub

Private Sub vProject_SelectProject(ByVal path As String)
    projector.SelectProject path
    vProject.Hide
    vMain.Initialize fso.GetFolder(path).Name
    vMain.Show vbModeless
End Sub

'-- vMain
Private Sub vMain_DoStep1()
    importer.Initialize context
    '--
    vImport.Initialize
    vImport.Show vbModeless
End Sub
Private Sub vMain_DoStep2()
    validator.Initialize context
    '--
    vValidation.Initialize
    vValidation.Show vbModeless
End Sub
Private Sub vMain_DoStep3()
    filter.Initialize context
    '--
    vFilter.Initialize
    vFilter.Show vbModeless
End Sub
Private Sub vMain_DoStep4()
    'exporter.Initialize context
    '--
    'vExport.Initialize
    'vExport.Show vbModeless
End Sub

'-- vImport
Private Sub vImport_ImportGl()
    importer.OpenWizard "gl"
    vImport.lblGlStatus.Caption = "匯入資料表: " & context.gl.Name
End Sub
Private Sub vImport_ImportTb()
    importer.OpenWizard "tb"
    vImport.lblTbStatus.Caption = "匯入資料表: " & context.tb.Name
End Sub
Private Sub vImport_MapGl()
    vMapGl.Initialize context.DbInput
    vMapGl.Show vbModeless
End Sub
Private Sub vImport_MapTb()
    vMapTb.Initialize context.DbInput
    vMapTb.Show vbModeless
End Sub
Private Sub vImport_FormatGl(ByVal format As String)
    importer.dType = format
End Sub
Private Sub vImport_FormatTb(ByVal format As String)
    importer.dType = format
End Sub
Private Sub vImport_Complete()
    '結算所有處理步驟的結果
End Sub

'-- vMapGl
Private Sub vMapGl_ApplyField(ByVal dict As Dictionary)
    If Not importer.ApplyGl(dict) Then
        'error
    Else
        'pass
    End If
End Sub

'-- vMapTb
Private Sub vMapTb_ApplyField(ByVal dict As Dictionary)
    If Not importer.ApplyTb(dict) Then
        'error
    Else
        'pass
    End If
End Sub

