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
Private WithEvents vMapJe As ViewImportMapJe
Attribute vMapJe.VB_VarHelpID = -1
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
Private exporter As ServiceExport
Private validator As ServiceValidation
Private filter As ServiceFilter

'***** Application
Public Sub Initialize()
    Set vProject = New ViewProject
    Set vMain = New ViewMain
    Set vImport = New ViewImport
    Set vMapJe = New ViewImportMapJe
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
    Set exporter = New ServiceExport
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

'***** vProject
Private Sub vProject_NewProject(ByVal path As String)
    projector.NewProject path
End Sub

Private Sub vProject_SelectProject(ByVal path As String)
    projector.SelectProject path
    vProject.Hide
    vMain.Initialize fso.GetFolder(path).name
    vMain.Show vbModeless
End Sub

'***** vMain
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
    exporter.Initialize context
    '--
    'vExport.Initialize
    'vExport.Show vbModeless
End Sub

Private Sub vMain_ExitApplication()
    '釋放資源
    If Not context Is Nothing Then
        If Not context.DbInput Is Nothing Then
            context.DbInput.Disconnect
            Set context.DbInput = Nothing
        End If
        If Not context.DbValid Is Nothing Then
            context.DbValid.Disconnect
            Set context.DbValid = Nothing
        End If
        Set context = Nothing
    End If
    Application.Quit
End Sub

'***** vImport
Private Sub vImport_ImportJe(ByVal format As String)
    importer.dType = format
    importer.OpenWizard "je"
    vImport.lblJeStatus.Caption = "匯入資料表: " & context.je.name
End Sub
Private Sub vImport_ImportTb(ByVal format As String)
    importer.dType = format
    importer.OpenWizard "tb"
    vImport.lblTbStatus.Caption = "匯入資料表: " & context.tb.name
End Sub
Private Sub vImport_MapJe()
    '@TODO:檢查是否有匯入 JE 資料表
    vMapJe.Initialize context.DbInput
    vMapJe.Show vbModeless
End Sub
Private Sub vImport_MapTb()
    '@TODO:檢查是否有匯入 TB 資料表
    vMapTb.Initialize context.DbInput
    vMapTb.Show vbModeless
End Sub
Private Sub vImport_Complete(ByVal dtStart As Date, dtEnd As Date)
    '結算所有處理步驟的結果
    context.info.PeriodStart = dtStart
    context.info.PeriodEnd = dtEnd
End Sub

'***** vMapJe
Private Sub vMapJe_ApplyField(ByVal dict As Dictionary, ByVal amountMethod As Long)
    context.je.Method = amountMethod
    If Not importer.ApplyJe(dict) Then
        MsgBox "JE 套用欄位失敗", vbExclamation, "JE 套用欄位"
    Else
        'pass
    End If
End Sub

'***** vMapTb
Private Sub vMapTb_ApplyField(ByVal dict As Dictionary, ByVal amountMethod As Long)
    context.tb.Method = amountMethod
    If Not importer.ApplyTb(dict) Then
        MsgBox "TB套用欄位失敗", vbExclamation, "TB套用欄位"
    Else
        'pass
    End If
End Sub

'***** vValidation
Private Sub vValidation_Completeness()
    '完整性測試
    validator.CheckCompleteness
End Sub

Private Sub vValidation_DocumentBalance()
    '借貸不平測試
    validator.CheckDocumentBalance
End Sub

Private Sub vValidation_NullRecords()
    '檢查空值分錄
    validator.CheckNullRecords
End Sub

Private Sub vValidation_INF()
    '可靠性測試
    validator.CheckINF
End Sub

'***** vExport
Private Sub vExport_PreviewWp()
    exporter.PreviewWp
End Sub

Private Sub vExport_ExportWp()
    exporter.ExportWp
End Sub
