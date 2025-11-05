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
'===============================================================================
' Class:    ApplicationMain
' Purpose:  主要程式，作為表單和類別的溝通主體
' Methods:
'===============================================================================
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
Private WithEvents vFilterRouter As ViewFilterRouter
Attribute vFilterRouter.VB_VarHelpID = -1
Private WithEvents vFilterCurrent As ViewFilterCurrent
Attribute vFilterCurrent.VB_VarHelpID = -1
Private WithEvents vFilterLegacy As ViewFilterLegacy
Attribute vFilterLegacy.VB_VarHelpID = -1
Private WithEvents vAddCriteria As ViewFilterAddCriteria
Attribute vAddCriteria.VB_VarHelpID = -1
Private WithEvents vExport As ViewExport
Attribute vExport.VB_VarHelpID = -1
'--
Private fso As FileSystemObject
Private calendar As ServiceDateDimension
Private context As ContextManager
Private projector As ServiceProject
Private importer As ServiceImport
Private exporter As ServiceExport
Private reporter As ServiceReport
Private validator As ServiceValidation
Private filter As ServiceFilter

'===============================================================================
'-- Application
'===============================================================================
Public Sub Initialize()
    Set vProject = New ViewProject
    Set vMain = New ViewMain
    Set vImport = New ViewImport
    Set vMapJe = New ViewImportMapJe
    Set vMapTb = New ViewImportMapTb
    Set vValidation = New ViewValidation
    Set vFilterRouter = New ViewFilterRouter
    Set vFilterCurrent = New ViewFilterCurrent
    Set vFilterLegacy = New ViewFilterLegacy
    Set vAddCriteria = New ViewFilterAddCriteria
    Set vExport = New ViewExport
    '--
    Set fso = New FileSystemObject
    Set calendar = New ServiceDateDimension
    Set context = New ContextManager
    Set projector = New ServiceProject
    Set importer = New ServiceImport
    Set exporter = New ServiceExport
    Set reporter = New ServiceReport
    Set validator = New ServiceValidation
    Set filter = New ServiceFilter
    '--
    Call context.Initialize
End Sub
Public Sub Run()
    Call projector.Initialize(context)
    Call vProject.Initialize
    vProject.Show vbModeless
End Sub

'===============================================================================
'-- vProject
'===============================================================================
Private Sub vProject_NewProject(ByVal path As String)
    '---------------------------------------------------------------------------
    ' 依據輸入路徑創建專案目錄
    '---------------------------------------------------------------------------
    projector.NewProject path
End Sub
Private Sub vProject_SelectProject(ByVal path As String)
    '---------------------------------------------------------------------------
    ' 依據輸入路徑載入專案目錄並開啟主要表單介面 ViewMain
    '---------------------------------------------------------------------------
    projector.SelectProject path
    vProject.Hide
    Call vMain.Initialize(fso.GetFolder(path).name)
    vMain.Show vbModeless
End Sub

'===============================================================================
'-- vMain
'===============================================================================
Private Sub vMain_DoStep1()
    '---------------------------------------------------------------------------
    ' 初始化步驟一所需的物件並開啟表單介面 ViewImport
    '---------------------------------------------------------------------------
    Call importer.Initialize(context)
    Call calendar.Initialize(context)
    '--
    Call vImport.Initialize
    vImport.Show vbModeless
End Sub
Private Sub vMain_DoStep2()
    '---------------------------------------------------------------------------
    ' 初始化步驟二所需的物件並開啟表單介面 ViewValidation
    '---------------------------------------------------------------------------
    Call validator.Initialize(context)
    '--
    Call vValidation.Initialize
    vValidation.Show vbModeless
End Sub
Private Sub vMain_DoStep3()
    '---------------------------------------------------------------------------
    ' 初始化步驟三所需的物件並開啟臨時表單介面 ViewFilterRouter 來路由篩選模式
    '---------------------------------------------------------------------------
    Call filter.Initialize(context)
    '--
    vFilterRouter.Show vbModeless
End Sub
Private Sub vMain_DoStep4()
    '---------------------------------------------------------------------------
    ' 初始化步驟四所需的物件並開啟表單介面 ViewExport
    '---------------------------------------------------------------------------
    Call reporter.Initialize(context)
    Call exporter.Initialize(context)
    '--
    Call vExport.Initialize
    vExport.Show vbModeless
End Sub
Private Sub vMain_ExitApplication()
    '---------------------------------------------------------------------------
    ' 關閉程序並釋放資源
    '---------------------------------------------------------------------------
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

'===============================================================================
'-- vImport
'===============================================================================
Private Sub vImport_BeepBoop()
    '//WARNING: BEEP BOOP
    '//WARNING: BEEP BOOP
    '//WARNING: BEEP BOOP
    Dim testString As String
    testString = context.DbSchema.Tables.JE
    Debug.Print "BEEP BOOP:" & context.DbSchema.Tables.JE
    MsgBox testString, vbInformation, testString
End Sub
Private Sub vImport_ImportJournalEntries(ByVal Format As String)
    '---------------------------------------------------------------------------
    ' 使用資料庫匯入精靈處理 JE 匯入
    '---------------------------------------------------------------------------
    importer.dType = Format
    importer.OpenWizard "je"
    vImport.lblImportStatus.Caption = "匯入資料表: " & context.JE.name
End Sub
Private Sub vImport_ImportTrialBalance(ByVal Format As String)
    '---------------------------------------------------------------------------
    ' 使用資料庫匯入精靈處理 TB 匯入
    '---------------------------------------------------------------------------
    importer.dType = Format
    importer.OpenWizard "tb"
    vImport.lblImportStatus.Caption = "匯入資料表: " & context.TB.name
End Sub
Private Sub vImport_JeFieldMappingRequested()
    '---------------------------------------------------------------------------
    ' 開啟JE欄位映射的介面
    '---------------------------------------------------------------------------
    '檢查是否有匯入 JE 資料表
    If Not context.DbInput.TableExists(context.JE.name) Then
        MsgBox "尚未匯入 JE 資料表", vbExclamation, "JE欄位映射"
        vImport.btnImportJe.SetFocus
        Exit Sub
    End If
    '初始化映射JE的表單物件
    Call vMapJe.Initialize(context.DbInput)
    vMapJe.Show vbModeless
End Sub
Private Sub vImport_TbFieldMappingRequested()
    '---------------------------------------------------------------------------
    ' 開啟TB欄位映射的介面
    '---------------------------------------------------------------------------
    '檢查是否有匯入 TB 資料表
    If Not context.DbInput.TableExists(context.TB.name) Then
        MsgBox "尚未匯入 TB 資料表", vbExclamation, "TB欄位映射"
        vImport.btnImportTb.SetFocus
        Exit Sub
    End If
    '初始化映射TB的表單物件
    Call vMapTb.Initialize(context.DbInput)
    vMapTb.Show vbModeless
End Sub
Private Sub vImport_UpdateDateDimensionRequested(ByVal dto As DataTransferObject)
    '---------------------------------------------------------------------------
    ' 更新/覆寫日期維度表
    '---------------------------------------------------------------------------
    '-- 先建立日期維度表
    context.info.periodStart = dto.periodStart
    context.info.periodEnd = dto.periodEnd
    Call calendar.CreateDateDimensionTable
    '-- 準備物件
    Dim dataRange As String
    Dim Types As Variant
    Dim fieldNames As Variant
    dataRange = "A2:B200"
    Types = Array("DATE", "TEXT(50)")
    fieldNames = Array("DateValue", "Description")
    '-- 匯入補班日資料
    Dim rsMakeupDays As DAO.Recordset
    Set rsMakeupDays = importer.ImportFromSheet( _
                                    MakeupDaysSheet, _
                                    dataRange, _
                                    Types, _
                                    fieldNames _
                                )
    If Not rsMakeupDays Is Nothing And Not rsMakeupDays.EOF Then
        Call calendar.MergeMakeupDays(rsMakeupDays)
    Else
        Debug.Print "  - MakeupDaySheet 無資料或匯入失敗"
    End If
    '-- 匯入假日資料
    Dim rsHolidays As DAO.Recordset
    Set rsHolidays = importer.ImportFromSheet( _
                                    HolidaysSheet, _
                                    dataRange, _
                                    Types, _
                                    fieldNames _
                                )
    If Not rsHolidays Is Nothing And Not rsHolidays.EOF Then
        Call calendar.MergeHolidays(rsHolidays)
    Else
        Debug.Print "  - HolidaySheet 無資料或匯入失敗"
    End If
    '-- 匯入週末資料
    Call calendar.MergeWeekends(dto.weekendIndices)
    '-- 更新結束
    MsgBox "日期維度表更新完成", vbInformation, "日期設置"
End Sub
Private Sub vImport_TestDefaultRequested()
    '---------------------------------------------------------------------------
    '//WARNING: ONLY FOR TESTING
    '//NOTE:只負責觸發前端的操作
    '---------------------------------------------------------------------------
    Call vMapJe.Initialize(context.DbInput)
    Call vMapJe.ApplyTestDefaults
    Call vMapTb.Initialize(context.DbInput)
    Call vMapTb.ApplyTestDefaults
End Sub
Private Sub vImport_Submitted(ByVal dto As DataTransferObject)
    '---------------------------------------------------------------------------
    ' 處理匯入表單提交並更新 Context
    '---------------------------------------------------------------------------
    context.info.CompanyName = dto.CompanyName
    context.info.PrepStartDate = dto.PrepStartDate
End Sub

'===============================================================================
'-- vMapJe
'===============================================================================
Private Sub vMapJe_ApplyField(ByVal dict As Dictionary, ByVal amountMethod As Long)
    '---------------------------------------------------------------------------
    ' 套用表單 MapJe 的欄位映射
    '---------------------------------------------------------------------------
    context.JE.Method = amountMethod
    If Not importer.ApplyJe(dict) Then
        vImport.lblFieldMappingStatus.Caption = " JE FAILED"
        MsgBox "JE 套用欄位失敗", vbExclamation, "JE 套用欄位"
    Else
        vImport.lblFieldMappingStatus.Caption = "JE PASS"
    End If
End Sub

'===============================================================================
'-- vMapTb
'===============================================================================
Private Sub vMapTb_ApplyField(ByVal dict As Dictionary, ByVal amountMethod As Long)
    '---------------------------------------------------------------------------
    ' 套用表單 MapTb 的欄位映射
    '---------------------------------------------------------------------------
    context.TB.Method = amountMethod
    If Not importer.ApplyTb(dict) Then
        vImport.lblFieldMappingStatus.Caption = "TB FAILED"
        MsgBox "TB套用欄位失敗", vbExclamation, "TB套用欄位"
    Else
        vImport.lblFieldMappingStatus.Caption = "TB PASS"
    End If
End Sub

'===============================================================================
'-- vValidation
'===============================================================================
Private Sub vValidation_Completeness()
    '---------------------------------------------------------------------------
    ' 執行完整性測試
    '---------------------------------------------------------------------------
    If validator.CheckCompleteness() Then
        'exporter.PreviewTable
    End If
End Sub

Private Sub vValidation_DocumentBalance()
    '---------------------------------------------------------------------------
    ' 執行借貸不平測試
    '---------------------------------------------------------------------------
    validator.CheckDocumentBalance
End Sub

Private Sub vValidation_NullRecords()
    '---------------------------------------------------------------------------
    ' 檢查空值分錄
    '---------------------------------------------------------------------------
    validator.CheckNullRecords
End Sub

Private Sub vValidation_INF()
    '---------------------------------------------------------------------------
    ' 執行可靠性測試
    '---------------------------------------------------------------------------
    validator.CheckINF
End Sub

Private Sub vValidation_Submitted(ByVal dto As DataTransferObject)
    '...
End Sub

'===============================================================================
'-- vFilterRouter
'===============================================================================
Private Sub vFilterRouter_RouteToCurrent()
    Call vFilterCurrent.Initialize
    vFilterCurrent.Show vbModeless
End Sub

Private Sub vFilterRouter_RouteToLegacy()
    Call vFilterLegacy.Initialize
    vFilterLegacy.Show vbModeless
End Sub

'===============================================================================
'-- vFilterLegacy
'===============================================================================
Private Sub vFilterLegacy_ExecuteCriterion()
    '---------------------------------------------------------------------------
    '...
    '---------------------------------------------------------------------------
End Sub

Private Sub vFilterLegacy_ShowCriteria()
    '---------------------------------------------------------------------------
    '...
    '---------------------------------------------------------------------------
End Sub

Private Sub vFilterLegacy_Submitted(ByVal dto As DataTransferObject)
    '---------------------------------------------------------------------------
    '...
    '---------------------------------------------------------------------------
End Sub

'===============================================================================
'-- vFilterCurrent
'===============================================================================
Private Sub vAddCriteria_AddCriteria()
    '---------------------------------------------------------------------------
    '...
    '---------------------------------------------------------------------------
End Sub

Private Sub vFilterCurrent_OverviewCriteria()
    '---------------------------------------------------------------------------
    '...
    '---------------------------------------------------------------------------
End Sub

'===============================================================================
'-- vExport
'===============================================================================
Private Sub vExport_ExportWp()
    '---------------------------------------------------------------------------
    ' 匯出全部完整的報表至專案目錄
    '---------------------------------------------------------------------------
    exporter.ExportWp
End Sub

Private Sub vExport_ShowEngagementOverview()
    '---------------------------------------------------------------------------
    ' 產出專案摘要的報表
    '---------------------------------------------------------------------------
    '建立必要報表
    reporter.GenerateEngagementOverview
    '輸出報表
    exporter.ShowEngagementOverview
End Sub

Private Sub vExport_ShowValidationReport()
    '---------------------------------------------------------------------------
    ' 產出驗證結果的報表
    '---------------------------------------------------------------------------
    '建立必要報表
    reporter.GenerateEngagementOverview
    reporter.GenerateDataOverview
    reporter.GenerateValidationOverview
    '輸出報表
    exporter.ShowValidationReport
End Sub
Private Sub vExport_ShowCompletenessReport()
    '---------------------------------------------------------------------------
    ' 產出完整性測試的報表
    '---------------------------------------------------------------------------
    '建立必要報表
    reporter.GenerateEngagementOverview
    reporter.GenerateCompletenessDetail
    '輸出報表
    exporter.ShowCompletenessReport
End Sub
Private Sub vExport_ShowDocumentBalanceReport()
    '---------------------------------------------------------------------------
    ' 產出借貸不平的報表
    '---------------------------------------------------------------------------
    '建立必要報表
    reporter.GenerateEngagementOverview
    reporter.GenerateDocumentBalanceDetail
    '輸出報表
    exporter.ShowDocumentBalanceReport
End Sub

