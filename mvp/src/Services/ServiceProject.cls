VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

' ServiceProject.cls
' Manages Project Creation and Opening

Private m_Context As ContextManager
Private m_DbSchema As DbSchema

Public Sub Initialize(ByVal context As ContextManager)
    Set m_Context = context
    Set m_DbSchema = New DbSchema
End Sub

Public Function CreateProject(ByVal folderPath As String, ByVal projectName As String, ByVal clientName As String, ByVal periodEnd As Date) As Boolean
    On Error GoTo ErrorHandler
    
    Dim dbPath As String
    dbPath = folderPath & "\" & projectName & ".accdb"
    
    ' 1. Create Access Database File
    If Not CreateAccessDatabase(dbPath) Then
        m_Context.Logger.LogError "Failed to create Access database file."
        CreateProject = False
        Exit Function
    End If
    
    ' 2. Initialize DbAccess
    Dim db As DbAccess
    Set db = New DbAccess
    db.Initialize dbPath, m_Context.Logger
    
    ' 3. Create Tables
    If db.OpenConnection() Then
        db.BeginTrans
        db.ExecuteNonQuery m_DbSchema.GetCreateProjectTableSql()
        ' Insert Project Info
        Dim sql As String
        sql = "INSERT INTO ProjectInfo (ProjectName, ClientName, PeriodEnd) VALUES (" & _
              "'" & db.EscapeString(projectName) & "', " & _
              "'" & db.EscapeString(clientName) & "', " & _
              "#" & Format(periodEnd, "yyyy-mm-dd") & "#)"
        db.ExecuteNonQuery sql
        
        db.CommitTrans
        db.CloseConnection
    End If
    
    ' 4. Set as current DB in Context
    Set m_Context.DbAccess = db
    
    m_Context.Logger.LogInfo "Project created successfully: " & dbPath
    CreateProject = True
    Exit Function

ErrorHandler:
    m_Context.Logger.LogError "CreateProject Failed", Err.Number
    CreateProject = False
End Function

Public Function OpenProject(ByVal dbPath As String) As Boolean
    On Error GoTo ErrorHandler
    
    If Dir(dbPath) = "" Then
        m_Context.Logger.LogError "Database file not found: " & dbPath
        OpenProject = False
        Exit Function
    End If
    
    Dim db As DbAccess
    Set db = New DbAccess
    db.Initialize dbPath, m_Context.Logger
    
    If db.OpenConnection() Then
        m_Context.Logger.LogInfo "Project opened: " & dbPath
        Set m_Context.DbAccess = db
        OpenProject = True
    Else
        OpenProject = False
    End If
    Exit Function

ErrorHandler:
    m_Context.Logger.LogError "OpenProject Failed", Err.Number
    OpenProject = False
End Function

Private Function CreateAccessDatabase(ByVal dbPath As String) As Boolean
    On Error Resume Next
    Dim cat As Object
    Set cat = CreateObject("ADOX.Catalog")
    cat.Create "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=" & dbPath
    
    If Err.Number = 0 Then
        CreateAccessDatabase = True
    Else
        m_Context.Logger.LogError "ADOX Create Failed", Err.Number
        CreateAccessDatabase = False
    End If
    Set cat = Nothing
    On Error GoTo 0
End Function
