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

Private context As ContextManager
Private db As DbAccess
Private gl As EntityGl
Private tb As EntityTb

Private m_name As String
Private m_path As String


Private Sub Class_Initialize()
    Set vProject = New ViewProject
    Set vMain = New ViewMain
    Set vImportGl = New ViewImportGL
    Set vImportTb = New ViewImportTB
    '...
    Set context = New ContextManager
    Set db = New DbAccess
    Set gl = New EntityGl
    Set tb = New EntityTb
    '...
End Sub

Public Sub Run()
    vProject.Initialize
    vProject.Show vbModeless
End Sub

'-- vProject
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

'-- vMain
Private Sub vMain_DoStep1()
    ' vImportGl -> vImportTb -> vImportHoliday
    vImportGl.Initialize
    vImportGl.Show vbModeless
    
    vImportTb.Initialize
    vImportTb.Show vbModeless
    
End Sub
Private Sub vMain_DoStep2()
    ' All procedure independent
End Sub
Private Sub vMain_DoStep3()
    ' Not defined.
End Sub
Private Sub vMain_DoStep4()
    ' Not defined.
End Sub

'-- vImportGl
Private Sub vImportGl_ProcessMethod(ByVal method As Long)
    '這裡只接收 method 並生成，但不執行；
End Sub
