VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Application"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private WithEvents vProject As ViewProject
Attribute vProject.VB_VarHelpID = -1
Private WithEvents vMain As ViewMain
Attribute vMain.VB_VarHelpID = -1
Private WithEvents vImportGl As ViewImportGL
Attribute vImportGl.VB_VarHelpID = -1
Private WithEvents vImportTb As ViewImportTB
Attribute vImportTb.VB_VarHelpID = -1
Private WithEvents vImportPeriod As ViewImportPeriod
Attribute vImportPeriod.VB_VarHelpID = -1
Private WithEvents vValidation As ViewValidation
Attribute vValidation.VB_VarHelpID = -1

Private context As ContextManager
Private validator As ValidationService
Private importer As ImportService

Private m_Name As String
Private m_path As String


Private Sub Class_Initialize()
    Set vProject = New ViewProject
    Set vMain = New ViewMain
    Set vImportGl = New ViewImportGL
    Set vImportTb = New ViewImportTB
    Set vImportPeriod = New ViewImportPeriod
    Set vValidation = New ViewValidation
    '...
    Set context = New ContextManager
    Set validator = New ValidationService
    Set importer = New ImportService
    '...
End Sub

Public Sub Run()
    vProject.Initialize
    vProject.Show vbModeless
End Sub



'=================================================================
'========================= [ vProject ] ==========================
'=================================================================

Private Sub vProject_NewProject(ByVal Name As String, ByVal path As String)
    m_Name = Name
    m_path = path
    If Dir(m_path, vbDirectory) <> "" Then
        MsgBox "專案已存在", vbExclamation, "創建專案"
        Exit Sub
    Else
        MkDir m_path
        Set context.dbPbc = CreateDb("pbc")
        Set context.dbData = CreateDb("data")
        Set context.dbResult = CreateDb("result")
    End If
    vProject.UpdateProjectList
End Sub
Private Sub vProject_SelectProject(ByVal Name As String, ByVal path As String)
    m_Name = Name
    m_path = path
    If Dir(m_path, vbDirectory) = "" Then
        MsgBox "專案不存在", vbExclamation, "載入專案"
        Exit Sub
    Else
        Set context.dbPbc = LoadDb("pbc")
        Set context.dbData = LoadDb("data")
        Set context.dbResult = LoadDb("result")
    End If
    vMain.Initialize
    vMain.Show vbModeless
End Sub
Private Function CreateDb(ByVal dbName As String) As DbAccess
    Dim dbe As New DAO.DBEngine, dbs As DAO.Database
    Dim dbPath As String, db As New DbAccess
    dbPath = m_path & "\" & dbName & ".accdb"
    Set dbs = dbe.CreateDatabase(dbPath, dbLangGeneral)
    dbs.Close
    db.path = dbPath
    Set CreateDb = db
End Function
Private Function LoadDb(ByVal dbName As String) As DbAccess
    Dim dbPath As String
    dbPath = m_path & "\" & dbName & ".accdb"
    If Dir(dbPath) = "" Then
        Debug.Print "File Not Found."
    End If
    Dim db As New DbAccess
    db.path = dbPath
    Set LoadDb = db
End Function



'=================================================================
'======= [ Step1: vMain -> vImportGl -> vImportTb ] ==============
'=================================================================

' all procedures should be processed, and parameters shoud stores
' at this class. For example, values should set to context object.

Private Sub vMain_DoStep1()
    vImportGl.Initialize
    vImportTb.Initialize
    vImportGl.Show vbModeless
End Sub
Private Sub vImportGl_ApplyFields(ByVal Method As Long, ByVal Fields As Dictionary)
    context.gl.Method = Method
    Dim key As Variant
    For Each key In Fields.Keys
        context.gl.SetMapping key, Fields(key)
    Next key
    context.gl.PrintFields
End Sub
Private Sub vImportGl_Import(ByVal filepath As String)
    importer.Initialize context
    Application.StatusBar = "正在匯入總帳資料..."
    If Not importer.ImportCsvGl(filepath) Then
        MsgBox "總帳資料匯入失敗！", vbExclamation, "匯入GL"
        Application.StatusBar = "匯入失敗"
    Else
        MsgBox "總帳資料匯入完成！", vbInformation, "匯入GL"
        Application.StatusBar = "匯入成功"
    End If
End Sub
Private Sub vImportGl_NextStep()
    Dim status As Boolean
    status = False
    '若狀態都已處理
    status = True
    If Not status Then
        '有尚未處理的程序
    Else
        '都處理完才進入下一個頁面
        vImportGl.Hide
        vImportTb.Show vbModeless
    End If
End Sub
Private Sub vImportTb_ApplyFields(ByVal Method As Long, ByVal Fields As Dictionary)
    context.tb.Method = Method
    Dim key As Variant
    For Each key In Fields.Keys
        context.tb.SetMapping key, Fields(key)
    Next key
    context.tb.PrintFields
End Sub
Private Sub vImportTb_Import(ByVal filepath As String)
    'db.BulkInsert()
    importer.Initialize context
    Application.StatusBar = "正在匯入試算表資料..."
    If Not importer.ImportCsvTb(filepath) Then
        MsgBox "試算表資料匯入失敗！", vbExclamation, "匯入TB"
        Application.StatusBar = "匯入失敗"
    Else
        MsgBox "試算表資料匯入完成！", vbInformation, "匯入TB"
        Application.StatusBar = "匯入成功"
    End If
End Sub
Private Sub vImportTb_LastStep()
    vImportTb.Hide
    vImportGl.Show vbModeless
End Sub
Private Sub vImportTb_NextStep()
    vImportTb.Hide
    vImportPeriod.Show vbModeless
End Sub
Private Sub vImportPeriod_Finish()
    ' 結算 Step1 的必要參數
    '...
    vImportPeriod.Hide
End Sub


'=================================================================
'============== [ Step2: vValidation ] ===========================
'=================================================================
Private Sub vMain_DoStep2()
    vValidation.Initialize
    vValidation.Show vbModeless
End Sub
Private Sub vValidation_TestCompletess()
    '
End Sub
Private Sub vValidation_ExitForm()
    vValidation.Hide
End Sub



'=================================================================
'=========== [ Step3: vFilter --> vCriteria ] ====================
'=================================================================

Private Sub vMain_DoStep3()
    ' Not defined.
End Sub



'=================================================================
'=============== [ Step4: vExport ] ==============================
'=================================================================

Private Sub vMain_DoStep4()
    ' Not defined.
End Sub


