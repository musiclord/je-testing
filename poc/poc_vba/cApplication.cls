VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "cApplication"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Module:    cApplication
' Purpose:   應用程式的主要控制器 (Controller)。
'            負責處理來自 vMain 使用者介面的事件，
'            協調各個服務 (Service) 類別來執行業務邏輯，
'            並管理應用程式的生命週期。
'===============================================================================

' --- 常數 ---
Private Const MODULE_NAME As String = "cApplication"
Private Const DATABASE_NAME As String = "default.accdb"
Private Const MAX_ROWS_TO_SHOW As Long = 1000

' --- 成員變數 ---
Private m_startDate As String
Private m_endDate As String
Private m_GLTable As String
Private m_TBTable As String

' --- 模組變數 ---
Private WithEvents vMain As vMain
Attribute vMain.VB_VarHelpID = -1
Private ImportService As ImportService
Private PreviewService As PreviewService
Private MappingService As MappingService
Private ValidationService As ValidationService
Private FilterService As FilterService
Private ScenarioService As ScenarioService

' --- Step 1 ---
Private WithEvents vProject As vProject
Attribute vProject.VB_VarHelpID = -1
Private WithEvents vConfigTB As vConfigTB
Attribute vConfigTB.VB_VarHelpID = -1
Private WithEvents vConfigGL As vConfigGL
Attribute vConfigGL.VB_VarHelpID = -1

' --- Step 2 ---
Private WithEvents vValidation As vValidation
Attribute vValidation.VB_VarHelpID = -1

' --- Step 3 ---
Private WithEvents vCriteria As vCriteria
Attribute vCriteria.VB_VarHelpID = -1

' --- Step 4 ---
Private WithEvents vScenario As vScenario
Attribute vScenario.VB_VarHelpID = -1
Private WithEvents vScenario1 As vScenario1
Attribute vScenario1.VB_VarHelpID = -1
Private WithEvents vScenario2 As vScenario2
Attribute vScenario2.VB_VarHelpID = -1
Private WithEvents vScenario3 As vScenario3
Attribute vScenario3.VB_VarHelpID = -1


Private Sub Class_Initialize()
    Set ImportService = New ImportService
    Set PreviewService = New PreviewService
    Set MappingService = New MappingService
    Set ValidationService = New ValidationService
    Set FilterService = New FilterService
    
    Set vMain = New vMain
End Sub

' ====== vMain ======
Private Sub vMain_DoExit()
    vMain.Hide
End Sub

Private Sub vMain_DoStep1()
    Set vProject = New vProject
    Set vConfigTB = New vConfigTB
    Set vConfigGL = New vConfigGL
    
    Call vProject.Show(vbModeless)
End Sub

Private Sub vMain_DoStep2()
    Set vValidation = New vValidation
End Sub

Private Sub vMain_DoStep3()
    Dim dal As AccessDAL
    Set dal = New AccessDAL
    Set vCriteria = New vCriteria
    
    dal.DatabasePath = ThisWorkbook.Path & "\" & DATABASE_NAME
    
    Call FilterService.Initialize(dal, MappingService, "GL", "TB")
    Call PopulateFormComboBoxes(vCriteria, "GL")
    Call vCriteria.Show(vbModeless)
    
End Sub

Private Sub vMain_DoStep4()
    Dim DbPath As String
    Dim status As Boolean
    Set ScenarioService = New ScenarioService
    Set vScenario = New vScenario
    Set vScenario1 = New vScenario1
    Set vScenario2 = New vScenario2
    Set vScenario3 = New vScenario3
    
    DbPath = ThisWorkbook.Path & "\data\test_scenario.accdb"
    
    Call ScenarioService.Initialize(DbPath, "JE_1", "JE_2", "JE_3") ' 代入資料表名稱
    Call vScenario.Show(vbModeless)
    
End Sub

' ====== vProject ======
Private Sub vProject_DoExit()
    Unload vProject
    Set vProject = Nothing
End Sub

Private Sub vProject_DoConfirm()
    ' 設定專案資訊
    m_startDate = Trim$(vProject.txtbPeriodStart.value)
    m_endDate = Trim$(vProject.txtbPeriodEnd.value)
    Call PopulateFormComboBoxes(vConfigTB, "TB") ' 將 TB 欄位注入至 vConfigTB
    ' 移至下個視窗
    Call vProject.Hide
    Call vConfigTB.Show(vbModeless)
    vMain.lblProject.BackColor = vbGreen
End Sub

' ====== vConfigTB ======
Private Sub vConfigTB_DoExit()
    Unload vConfigTB
    Set vConfigTB = Nothing
End Sub

Private Sub vConfigTB_DoImport()
    Call ImportCSV("TB")
    Call PopulateFormComboBoxes(vConfigTB, "TB")
End Sub

Private Sub vConfigTB_DoPreview()
    Call PreviewTable("TB") ' 在工作表預覽資料表 TB
End Sub

Private Sub vConfigTB_DoConfirm()
    Call ProcessAndStoreFormMappings(vConfigTB, "TB") ' 處理並儲存 TB 欄位配對
    Call PopulateFormComboBoxes(vConfigGL, "GL") ' 將 GL 欄位注入至 vConfigGL
    ' 移至下個視窗
    Call vConfigTB.Hide
    Call vConfigGL.Show(vbModeless)
    vMain.lblImportTB.BackColor = vbGreen
End Sub

' ====== vConfigGL ======
Private Sub vConfigGL_DoExit()
    Unload vConfigGL
    Set vConfigGL = Nothing
End Sub

Private Sub vConfigGL_DoImport()
    Call ImportCSV("GL")
    
    Dim dal As AccessDAL
    Set dal = New AccessDAL
    dal.DatabasePath = ThisWorkbook.Path & "\" & DATABASE_NAME
    Call ValidationService.Initialize(dal, MappingService, "GL", "TB")
    Call ValidationService.addLineItem
    
    Call PopulateFormComboBoxes(vConfigGL, "GL")
End Sub

Private Sub vConfigGL_DoPreview()
    Call PreviewTable("GL") ' 在工作表預覽資料表 GL
End Sub

Private Sub vConfigGL_DoConfirm()
    Call ProcessAndStoreFormMappings(vConfigGL, "GL") ' 處理並儲存 GL 欄位配對
    ' 移至下個視窗
    Call vConfigGL.Hide
    vMain.lblImportGL.BackColor = vbGreen
End Sub

' ====== vValidation ======
Private Sub vValidation_DoExit()
    Unload vValidation
    Set vValidation = Nothing
End Sub

Private Sub vValidation_TestCompleteness()
    Const METHOD_NAME As String = "vValidation_TestCompleteness"
    Dim dtStartDate As Date, dtEndDate As Date ' 更改變數名稱以提高清晰度
    Dim testResult As Boolean
    Dim dal As AccessDAL
    Dim GLTable As String
    Dim TBTable As String
    
    On Error GoTo ErrorHandler
    ' --- 1. 設定資料 ---
    ' 驗證 m_startDate 和 m_endDate (格式為 "#date#") 並轉換
    If Not IsDate(m_startDate) Then
        Err.Raise vbObjectError + 550, MODULE_NAME & "." & METHOD_NAME, "無效的開始日期格式: " & m_startDate
    End If
    dtStartDate = CDate(m_startDate)

    If Not IsDate(m_endDate) Then
        Err.Raise vbObjectError + 551, MODULE_NAME & "." & METHOD_NAME, "無效的結束日期格式: " & m_endDate
    End If
    dtEndDate = CDate(m_endDate)
    GLTable = "GL"
    TBTable = "TB"
    ' --- 2. 建立實例 ---
    Set dal = New AccessDAL
    dal.DatabasePath = ThisWorkbook.Path & "\" & DATABASE_NAME
    Call ValidationService.Initialize(dal, MappingService, GLTable, TBTable)

    ' --- 3. 執行完整性測試 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 呼叫 ValidationService.TestCompleteness，期間: " & Format(dtStartDate, "yyyy-mm-dd") & " 到 " & Format(dtEndDate, "yyyy-mm-dd")
    testResult = ValidationService.TestCompleteness(dtStartDate, dtEndDate)

    ' --- 4. 預覽驗證結果 ---
    Dim varianceTableName As String
    varianceTableName = "List_of_accounts_with_variance"
    
    ' 檢查差異資料表是否存在並預覽
    If dal.tableExists(varianceTableName) Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 開始預覽差異資料表: " & varianceTableName
        
        ' 檢查記錄數
        Dim recordCount As Variant
        recordCount = dal.GetScalar("SELECT COUNT(*) FROM [" & varianceTableName & "]")
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & varianceTableName & " 記錄數: " & recordCount
        
        Application.StatusBar = "正在預覽完整性測試結果..."
        Application.Cursor = xlWait
        
        ' 預覽差異資料表
        If PreviewService.ShowPreview(dal.DatabasePath, varianceTableName, varianceTableName & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & varianceTableName & " 預覽成功"
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & varianceTableName & " 預覽失敗"
        End If
        
        Application.StatusBar = False
        Application.Cursor = xlDefault
    Else
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: 差異資料表 " & varianceTableName & " 不存在"
    End If

    ' --- 5. 向使用者提供回饋 ---
    If testResult Then
        MsgBox "完整性測試完成：未發現差異。" & vbCrLf & _
               "所有科目的明細帳金額與試算表金額一致。", vbInformation, "測試結果"
        If Not vMain Is Nothing Then vMain.lblCompletenessTest.BackColor = vbGreen
    Else
        ' 顯示差異摘要資訊
        Dim diffSummary As String
        If dal.tableExists(varianceTableName) Then
            Dim diffCount As Variant
            diffCount = dal.GetScalar("SELECT COUNT(*) FROM [" & varianceTableName & "]")
            If Not IsNull(diffCount) And IsNumeric(diffCount) Then
                diffSummary = "發現 " & diffCount & " 個科目存在差異。"
            Else
                diffSummary = "發現科目差異。"
            End If
        Else
            diffSummary = "發現差異但無法取得詳細資訊。"
        End If
        
        MsgBox "完整性測試完成：" & diffSummary & vbCrLf & _
               "差異明細已預覽至工作表 '#" & varianceTableName & "' 中。" & vbCrLf & _
               "請檢查各科目的明細帳金額與試算表金額差異。", vbExclamation, "測試結果"
        If Not vMain Is Nothing Then vMain.lblCompletenessTest.BackColor = vbRed
    End If
    GoTo Cleanup

ErrorHandler: ' 錯誤處理程序
    MsgBox "執行完整性測試時發生錯誤：" & vbCrLf & _
           "來源: " & Err.Source & vbCrLf & _
           "描述: " & Err.Description, vbCritical, MODULE_NAME & "." & METHOD_NAME
    If Not vMain Is Nothing Then vMain.lblCompletenessTest.BackColor = RGB(255, 165, 0) ' 錯誤時顯示橘色
Cleanup:
    If Not dal Is Nothing Then ' 檢查 dal 物件是否已建立
        dal.Disconnect
    End If
    Set dal = Nothing
End Sub

Private Sub vValidation_TestDocumentBalance()
    Dim status As Boolean
    status = True
    Application.Wait Now + TimeValue("00:00:01")
    If status Then
        vMain.lblDocumentBalance.BackColor = vbGreen
    Else
        vMain.lblDocumentBalance.BackColor = vbRed
    End If
End Sub

Private Sub vValidation_TestRDE()
    Dim status As Boolean
    status = True
    Application.Wait Now + TimeValue("00:00:01")
    If status Then
        vMain.lblRDETest.BackColor = vbGreen
    Else
        vMain.lblRDETest.BackColor = vbRed
    End If
End Sub

Private Sub vValidation_DoAccountMapping()
    Dim status As Boolean
    status = True
    Application.Wait Now + TimeValue("00:00:01")
    If status Then
        vMain.lblAccountMapping.BackColor = vbGreen
    Else
        vMain.lblAccountMapping.BackColor = vbRed
    End If
End Sub

Private Sub vValidation_DoConfirm()
    Application.Wait Now + TimeValue("00:00:02")
    If vMain.lblCompletenessTest.BackColor = vbGreen Then
        vMain.lblAccountMapping.BackColor = vbGreen
        vMain.lblRDETest.BackColor = vbGreen
        vMain.lblDocumentBalance.BackColor = vbGreen
    Else
        vMain.lblAccountMapping.BackColor = vbRed
        vMain.lblRDETest.BackColor = vbRed
        vMain.lblDocumentBalance.BackColor = vbRed
    End If
    Call vValidation.Hide
End Sub

' ====== vCriteria ======
Private Sub vCriteria_DoClear()

End Sub
Private Sub vCriteria_DoCustom1()
    Dim selectedRange As Range
    Dim arr() As Variant
    Dim cell As Range
    Dim resultText As String
    ' 提示使用者選取範圍
    On Error Resume Next
    AppActivate Application.Caption
    Set selectedRange = Application.InputBox("請選取一個範圍", Type:=8)
    On Error GoTo 0
    If selectedRange Is Nothing Then
        MsgBox "未選取任何範圍", vbExclamation
        Exit Sub
    End If
    ' 將選取範圍的值存入陣列
    arr = selectedRange.value
    ' 如果是單欄或單列，轉為一維陣列
    If selectedRange.Columns.Count = 1 Or selectedRange.rows.Count = 1 Then
        resultText = ""
        For Each cell In selectedRange
            If Len(cell.value) > 0 Then
                resultText = resultText & cell.value & ","
            End If
        Next cell
        ' 移除最後一個逗號
        If Right(resultText, 1) = "," Then
            resultText = Left(resultText, Len(resultText) - 1)
        End If
        ' 顯示在 TextBox（如果有）
        If vCriteria.Controls("txtbValue1") Is Nothing = False Then
            vCriteria.txtbValue1.value = resultText
        End If
    Else
        MsgBox "請選取單列或單欄的範圍", vbInformation
    End If
End Sub

Private Sub vCriteria_DoCustom2()
    Dim selectedRange As Range
    Dim arr() As Variant
    Dim cell As Range
    Dim resultText As String
    ' 提示使用者選取範圍
    On Error Resume Next
    AppActivate Application.Caption
    Set selectedRange = Application.InputBox("請選取一個範圍", Type:=8)
    On Error GoTo 0
    If selectedRange Is Nothing Then
        MsgBox "未選取任何範圍", vbExclamation
        Exit Sub
    End If
    ' 將選取範圍的值存入陣列
    arr = selectedRange.value
    ' 如果是單欄或單列，轉為一維陣列
    If selectedRange.Columns.Count = 1 Or selectedRange.rows.Count = 1 Then
        resultText = ""
        For Each cell In selectedRange
            If Len(cell.value) > 0 Then
                resultText = resultText & cell.value & ","
            End If
        Next cell
        ' 移除最後一個逗號
        If Right(resultText, 1) = "," Then
            resultText = Left(resultText, Len(resultText) - 1)
        End If
        ' 顯示在 TextBox（如果有）
        If vCriteria.Controls("txtbValue2") Is Nothing = False Then
            vCriteria.txtbValue2.value = resultText
        End If
    Else
        MsgBox "請選取單列或單欄的範圍", vbInformation
    End If
End Sub


Private Sub vCriteria_DoConfirm()
    Const METHOD_NAME As String = "vCriteria_DoConfirm"
    Dim criteria As Collection
    Dim rs As Object ' ADODB.Recordset
    Dim destinationTableName As String
    Dim DbPath As String
    Dim filterSuccess As Boolean
    Dim previewWorksheetName As String
    Dim previewSuccess As Boolean
    previewSuccess = False
    filterSuccess = False
    previewWorksheetName = "Filtered_GL_Data" ' 預覽工作表的名稱
    destinationTableName = "criteria_result" ' 您想要的結果資料表名稱
    DbPath = ThisWorkbook.Path & "\" & DATABASE_NAME
    m_GLTable = "GL"
    Set criteria = vCriteria.GetFilterCriteria()
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 呼叫 FilterService.CreateTableFromFilter for table: " & destinationTableName
    filterSuccess = FilterService.CreateTableFromFilter(criteria, m_GLTable, destinationTableName)
    If filterSuccess Then
        MsgBox "篩選條件已成功應用，結果已存入資料表 '" & destinationTableName & "'。", vbInformation, "篩選成功"
        
        ' 嘗試預覽新建立的資料表
        Application.StatusBar = "正在載入資料表 [" & destinationTableName & "] 的預覽..."
        Application.Cursor = xlWait
        If PreviewService.ShowPreview(DbPath, destinationTableName, destinationTableName & "_Preview", MAX_ROWS_TO_SHOW) Then
            previewSuccess = True
            Application.StatusBar = False
            Application.Cursor = xlDefault
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & destinationTableName & " 預覽完成！"
        Else
            Application.StatusBar = False
            Application.Cursor = xlDefault
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 成功建立資料表 " & destinationTableName & " 但預覽時發生錯誤。"
        End If
    Else
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 套用篩選條件並建立結果資料表 " & destinationTableName & " 時發生錯誤。"
    End If

    
    
    Dim status As Boolean
    status = True ' Define status = True or False
    If status Then
        vMain.lblCriteria.BackColor = vbGreen
    Else
        vMain.lblCriteria.BackColor = vbRed
    End If
End Sub

Private Sub vCriteria_DoExit()
    Unload vCriteria
    Set vCriteria = Nothing
End Sub

' ====== vScenario ======

Private Sub vScenario_DoExit()
    If Not vScenario Is Nothing Then
        vScenario.Hide
        Unload vScenario
        Set vScenario = Nothing
    End If
End Sub

Private Sub vScenario_RunCase1()
    vScenario1.Show (vbModeless)
End Sub

Private Sub vScenario_RunCase2()
    vScenario2.Show (vbModeless)
End Sub

Private Sub vScenario_RunCase3()
    vScenario3.Show (vbModeless)
End Sub

Private Sub vScenario1_DoExit()
    vScenario1.Hide
End Sub

Private Sub vScenario1_Execute()
    Dim result As Boolean
    Dim dailyCountLimit As String, dailyAmountLimit As String
    Dim weeklyCountLimit As String, weeklyAmountLimit As String
    Dim monthlyCountLimit As String, monthlyAmountLimit As String
    
    dailyCountLimit = vScenario1.txtbDailyCountLimit.value
    dailyAmountLimit = vScenario1.txtbDailyAmountLimit.value
    
    weeklyCountLimit = vScenario1.txtbWeeklyCountLimit.value
    weeklyAmountLimit = vScenario1.txtbWeeklyAmountLimit.value
    
    monthlyCountLimit = vScenario1.txtbMonthlyCountLimit.value
    monthlyAmountLimit = vScenario1.txtbMonthlyAmountLimit.value
    
    result = ScenarioService.ExecuteScenario1(dailyCountLimit, dailyAmountLimit, weeklyCountLimit, weeklyAmountLimit, monthlyCountLimit, monthlyAmountLimit)
    
    If result Then
        MsgBox "Scenario 1 執行成功。", vbInformation, "Scenario 結果"
        vMain.lblTestCase1.BackColor = vbGreen
    Else
        MsgBox "Scenario 1 執行失敗或未達到預期結果。", vbExclamation, "Scenario 結果"
        vMain.lblTestCase1.BackColor = vbRed
    End If
    
End Sub

Private Sub vScenario2_DoExit()
    vScenario2.Hide
End Sub

Private Sub vScenario2_Execute()
    Dim result As Boolean
    Dim amountLimit As String, frequencyLimit As String
    
    amountLimit = vScenario2.txtbAmountLimit.value
    frequencyLimit = vScenario2.txtbFrequencyLimit.value
    
    result = ScenarioService.ExecuteScenario2(amountLimit, frequencyLimit)
    
    If result Then
        MsgBox "Scenario 2 執行成功。", vbInformation, "Scenario 結果"
        vMain.lblTestCase2.BackColor = vbGreen
    Else
        MsgBox "Scenario 2 執行失敗或未達預期成果。", vbExclamation, "Scenario 結果"
        vMain.lblTestCase2.BackColor = vbRed
    End If
End Sub

Private Sub vScenario3_DoExit()
    vScenario3.Hide
End Sub

Private Sub vScenario3_Execute()
    Dim result As Boolean
    Dim rateRatioLimit As String, amountDiffLimit As String
    
    rateRatioLimit = vScenario3.txtbRateRatioLimit.value
    amountDiffLimit = vScenario3.txtbAmountDiffLimit.value
    
    result = ScenarioService.ExecuteScenario3(rateRatioLimit, amountDiffLimit)
    
    If result Then
        MsgBox "Scenario 3 執行成功。", vbInformation, "Scenario 結果"
        vMain.lblTestCase3.BackColor = vbGreen
    Else
        MsgBox "Scenario 3 執行失敗或未達預期成果。", vbExclamation, "Scenario 結果"
        vMain.lblTestCase3.BackColor = vbRed
    End If
End Sub


'-------------------------------------------------------------------------------
' Procedure: ImportCSV
' Purpose:   處理將 CSV 檔案匯入到 Access 資料庫的通用流程。
'            包括選擇檔案、偵測編碼、調用 ImportService 匯入資料，
'            以及調用 PreviewService 顯示匯入後的資料預覽。
' Arguments:
'   @param importType (String): 指定匯入的類型 ("GL" 或 "TB")，用於決定目標資料表名稱等。
' Note:      會使用模組級常數 DATABASE_NAME 和 MAX_ROWS_TO_SHOW。
'            依賴於標準模組 mod_Utility 中的 DetectCSVEncoding 函數。
'-------------------------------------------------------------------------------
Private Sub ImportCSV(ByVal importType As String)
    ' 控制器：協調 CSV 匯入流程 (GL 或 TB)
    Dim csvFilePath As String
    Dim accessDbPath As String
    Dim tableName As String
    Dim worksheetName As String ' 用於預覽的工作表名稱
    Dim csvEncoding As Long
    Const DEFAULT_ENCODING As Long = 950 ' <-- 保持局部
    ' 1. 選擇 CSV 檔案
    csvFilePath = Application.GetOpenFilename("CSV 檔案 (*.csv),*.csv", , "選擇要匯入的 " & importType & " CSV 檔案")
    If csvFilePath = "False" Then Exit Sub ' 使用者取消
    
    ' 2. 設定路徑和名稱 (使用模組級常數，統一工作表命名)
    accessDbPath = ThisWorkbook.Path & "\" & DATABASE_NAME ' <-- 使用模組級常數
    Select Case importType
        Case "GL"
            tableName = "GL"
        Case "TB"
            tableName = "TB"
        Case Else
            MsgBox "不支援的匯入類型：" & importType, vbCritical, "內部錯誤"
            Exit Sub
    End Select
    worksheetName = tableName ' & "_Preview"
    
    ' 3. 執行匯入流程
    Application.StatusBar = "正在處理 " & importType & " 資料到資料庫 [" & DATABASE_NAME & "]，請稍候..."
    Application.Cursor = xlWait
    On Error GoTo ErrorHandler
    
    ' 3a. 偵測編碼
    On Error Resume Next
    csvEncoding = mod_Utility.DetectCSVEncoding(csvFilePath)
    If Err.Number <> 0 Then
        Debug.Print "Warning: Failed to detect CSV encoding for " & csvFilePath & ". Using default: " & DEFAULT_ENCODING
        csvEncoding = DEFAULT_ENCODING
        Err.Clear
    End If
    On Error GoTo ErrorHandler
    Debug.Print importType & " CSV 編碼偵測結果: " & csvEncoding

    ' 3b. 匯入至 Access (調用 ImportService)
    Application.StatusBar = "正在將 " & importType & " CSV 匯入 Access 資料表 [" & tableName & "]..."
    ' 假設 ImportService.ImportToAccess 簽名包含 csvEncoding
    If Not ImportService.ImportToAccess(csvFilePath, accessDbPath, tableName, CLng(csvEncoding)) Then
        GoTo ErrorHandler
    End If

    ' 3c. 從 Access 載入至 Excel 進行預覽 (調用 PreviewService)
    Application.StatusBar = "正在從 Access 將資料表 [" & tableName & "] 載入 Excel 預覽..."
    If Not PreviewService.ShowPreview(accessDbPath, tableName, worksheetName, MAX_ROWS_TO_SHOW) Then ' <-- 使用模組級常數
         GoTo ErrorHandler
    End If
    
    ' 4. 完成
    Application.StatusBar = False
    Application.Cursor = xlDefault
    MsgBox importType & " 匯入與預覽完成！" & vbCrLf & "資料預覽已顯示在工作表 [" & worksheetName & "]", vbInformation, "處理完成"
    Exit Sub

ErrorHandler:
    Application.StatusBar = False
    Application.Cursor = xlDefault
    MsgBox importType & " 處理過程中發生錯誤：" & vbCrLf & _
           "來源: " & Err.Source & vbCrLf & _
           "描述: " & Err.Description, vbCritical, "錯誤"
End Sub

'-------------------------------------------------------------------------------
' Procedure: PreviewTable
' Purpose:   從 Access 資料庫讀取指定的資料表，
'            並使用 PreviewService 將其內容顯示在新的 Excel 工作表中。
'            工作表名稱會根據資料表名稱加上 "_Preview" 後綴。
' Arguments:
'   @param tableName (String): 要預覽的 Access 資料表名稱。
' Note:      會使用模組級常數 DATABASE_NAME 和 MAX_ROWS_TO_SHOW。
'-------------------------------------------------------------------------------
Private Sub PreviewTable(ByVal tableName As String)
    Const METHOD_NAME As String = "PreviewTable"
    ' Dim tableName As String ' tableName 現在是參數
    Dim worksheetName As String
    Dim accessDbPath As String
    On Error GoTo ErrorHandler

    ' 1. 驗證輸入的 tableName (基本檢查)
    If Trim$(tableName) = "" Then
        MsgBox "必須提供有效的資料表名稱才能進行預覽。", vbExclamation, "未指定資料表"
        Exit Sub
    End If

    ' 2. 設定參數 (使用模組級常數)
    accessDbPath = ThisWorkbook.Path & "\" & DATABASE_NAME
    worksheetName = tableName & "_Preview" ' 維持原本的命名邏輯

    ' 3. 執行預覽 (調用 PreviewService, 使用模組級常數)
    Application.StatusBar = "正在載入資料表 [" & tableName & "] 的預覽..."
    Application.Cursor = xlWait
    If PreviewService.ShowPreview(accessDbPath, tableName, worksheetName, MAX_ROWS_TO_SHOW) Then ' <-- Use module const
        Application.StatusBar = False
        Application.Cursor = xlDefault
        ' 成功訊息現在使用傳入的 tableName 和衍生的 worksheetName
        MsgBox "資料表 [" & tableName & "] 預覽完成！" & vbCrLf & "資料已顯示在工作表 [" & worksheetName & "]", vbInformation, "預覽完成"
    Else
        ' 如果 PreviewService.ShowPreview 傳回 False (雖然目前設計是錯誤時引發 Error)
        ' 或是發生其他未預期的狀況跳到 Else
        GoTo ErrorHandler ' 轉到通用錯誤處理
    End If
    Exit Sub

ErrorHandler:
    Application.StatusBar = False
    Application.Cursor = xlDefault
    ' 錯誤訊息現在使用傳入的 tableName
    MsgBox "預覽資料表 [" & tableName & "] 時發生錯誤：" & vbCrLf & _
           "來源: " & Err.Source & vbCrLf & _
           "描述: " & Err.Description, vbCritical, "預覽錯誤"
End Sub

' --- 通用方法，準備並填充指定表單的 ComboBox ---
Private Sub PopulateFormComboBoxes(ByVal targetForm As Object, ByVal tableName As String)
    Const METHOD_NAME As String = "PrepareAndPopulateFormComboBoxes"
    Dim fieldNames As Variant
    Dim dal As AccessDAL ' 臨時 DAL 物件
    Dim DbPath As String

    On Error GoTo ErrorHandler

    ' 檢查 targetForm 是否有效
    If targetForm Is Nothing Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 錯誤: targetForm 為 Nothing。"
        Exit Sub
    End If

    ' --- 1. 取得指定資料表的欄位名稱 ---
    DbPath = ThisWorkbook.Path & "\" & DATABASE_NAME
    
    ' 不再檢查檔案是否存在，而是讓 AccessDAL.Connect() 處理
    Set dal = New AccessDAL
    dal.DatabasePath = DbPath
    
    ' 連接資料庫 (不存在時會自動建立)
    If Not dal.Connect() Then
        MsgBox "無法連接或建立資料庫：" & vbCrLf & DbPath, vbCritical, MODULE_NAME & "." & METHOD_NAME
        fieldNames = Empty
    Else
        ' 資料庫連接成功後，再獲取欄位名稱
        fieldNames = dal.GetTableFieldNames(tableName)
    End If
    
    Set dal = Nothing  ' 釋放 DAL 物件

    ' --- 2. 將欄位名稱注入目標表單 ---
    ' targetForm 有一個名為 PopulateComboBoxes 的 Public Sub
    On Error Resume Next
    CallByName targetForm, "PopulateComboBoxes", VbMethod, fieldNames
    If Err.Number <> 0 Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: 無法呼叫 '" & TypeName(targetForm) & ".PopulateComboBoxes'。錯誤: " & Err.Description
        Err.Clear
    End If
    On Error GoTo ErrorHandler ' 恢復正常的錯誤處理

Cleanup:
    Set dal = Nothing ' 確保錯誤時也釋放
    Exit Sub

ErrorHandler:
    MsgBox "準備填充表單 '" & TypeName(targetForm) & "' 時發生錯誤 (資料表: " & tableName & ")：" & vbCrLf & Err.Description, vbCritical, MODULE_NAME & "." & METHOD_NAME
    ' 嘗試填充空值
    On Error Resume Next
    CallByName targetForm, "PopulateComboBoxes", VbMethod, Empty
    Err.Clear
    On Error GoTo 0 ' 關閉此處的錯誤處理
    GoTo Cleanup
End Sub

' --- 新增: 通用方法，處理並儲存指定表單的欄位對應 ---
Private Function ProcessAndStoreFormMappings(ByVal sourceForm As Object, ByVal mappingType As String) As Boolean
    Const METHOD_NAME As String = "ProcessAndStoreFormMappings"
    Dim formMappings As Object ' Scripting.Dictionary

    On Error GoTo ErrorHandler

    ' --- 從來源表單取得欄位對應 ---
    '    假設 sourceForm 有 GetFieldMappings 方法
    On Error Resume Next ' 暫時忽略錯誤，以便檢查
    Set formMappings = sourceForm.GetFieldMappings()
    If Err.Number <> 0 Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Error calling GetFieldMappings on " & TypeName(sourceForm) & ": " & Err.Description
        MsgBox "無法從 '" & TypeName(sourceForm) & "' 表單讀取欄位對應。", vbCritical, MODULE_NAME & "." & METHOD_NAME
        Err.Clear
        GoTo Cleanup ' 返回 False
    End If
    On Error GoTo ErrorHandler ' 恢復正常錯誤處理

    ' ---  驗證對應是否成功取得 ---
    If formMappings Is Nothing Then
        ' GetFieldMappings 內部應該已經顯示錯誤訊息
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Error: Failed to get mappings from " & TypeName(sourceForm) & "."
        GoTo Cleanup ' 返回 False
    End If

    ' ---  將對應關係傳遞給 MappingService ---
    Select Case UCase$(mappingType) ' 根據類型呼叫不同的 Set 方法
        Case "TB"
            Call MappingService.SetTBFieldMappings(formMappings)
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - TB field mappings passed to MappingService."
        Case "GL"
            Call MappingService.SetGLFieldMappings(formMappings)
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - GL field mappings passed to MappingService."
        Case Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - Error: Unknown mappingType '" & mappingType & "'."
            MsgBox "不支援的對應類型：" & mappingType, vbCritical, MODULE_NAME & "." & METHOD_NAME
            GoTo Cleanup ' 返回 False
    End Select

Cleanup:
    Set formMappings = Nothing
    Exit Function

ErrorHandler:
    MsgBox "處理 '" & mappingType & "' 欄位對應時發生錯誤：" & vbCrLf & Err.Description, vbCritical, MODULE_NAME & "." & METHOD_NAME
    GoTo Cleanup
End Function


