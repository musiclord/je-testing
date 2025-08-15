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

Private m_name As String
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

Private Sub vProject_NewProject(ByVal name As String, ByVal path As String)
    m_name = name
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
Private Sub vProject_SelectProject(ByVal name As String, ByVal path As String)
    m_name = name
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
Private Sub vImportGl_ApplyFields(ByVal METHOD As Long, ByVal fields As Dictionary)
    Dim key As Variant
    For Each key In fields.Keys
        context.gl.SetMapping key, fields(key)
    Next key
    context.gl.PrintFields
End Sub
Private Sub vImportGl_Import(ByVal filepath As String)
    '--If Not context.dbPbc.BulkInsert()
    Dim db As DbAccess
    Set db = context.dbPbc
    If Not importer.ImportCsv(filepath, db) Then
        MsgBox "匯入GL失敗", vbExclamation, "匯入GL"
    Else
        '匯入GL成功
    End If
End Sub
Private Sub vImportGl_NextStep()
    vImportGl.Hide
    vImportTb.Show vbModeless
End Sub
Private Sub vImportTb_ApplyFields(ByVal METHOD As Long, ByVal fields As Dictionary)
    Dim key As Variant
    For Each key In fields.Keys
        context.tb.SetMapping key, fields(key)
    Next key
    context.tb.PrintFields
End Sub
Private Sub vImportTb_Import(ByVal file As String)
    'db.BulkInsert()
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


