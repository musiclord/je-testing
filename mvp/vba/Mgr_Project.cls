VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Mgr_Project"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Mgr_Project"
'===============================================================================
' Module:   Mgr_Project
' Purpose:  專案管理器，負責專案的商業邏輯處理與資料存取協調
' Layer:    Manager
' Domain:   Project Management
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_path As String
Private m_name As String

'--屬性
Public Property Get Config() As Mgr_Config
    Set Config = m_cfg
End Property
Public Property Get Context() As Mgr_Context
    Set Context = m_ctx
End Property
Public Property Get path() As String
    path = m_path
End Property
Public Property Get name() As String
    name = m_name
End Property



'--Mgr_Project
Public Sub Initialize()
    Const METHOD_NAME As String = "Initialize"
    '實例化
    Set m_cfg = New Mgr_Config
    Set m_ctx = New Mgr_Context
    m_ctx.Initialize
End Sub

Public Function Create(ByVal name As String, path As String) As Boolean
    Const METHOD_NAME As String = "Create"
    On Error GoTo ErrorHandler
    
    Create = False
    m_name = name
    m_path = path
    '確認專案目錄
    If Dir(m_path, vbDirectory) <> "" Then
        MsgBox "專案 [" & m_name & "] 已存在。", vbExclamation, "創建專案"
        Exit Function
    Else
        '創建目錄
        MkDir m_path
        '創建資料庫，建立DAL物件，將依賴注入給 m_ctx 管理
        Set m_ctx.DalConfig = CreateDatabase("config")
        Set m_ctx.DalPbc = CreateDatabase("pbc")
        Set m_ctx.DalData = CreateDatabase("data")
        Set m_ctx.DalResult = CreateDatabase("result")
    End If
    
    Create = True
    Exit Function
    
ErrorHandler:
    Create = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function Load(ByVal name As String, ByVal path As String) As Boolean
    Const METHOD_NAME As String = "Load"
    On Error GoTo ErrorHandler
    
    Load = False
    m_name = name
    m_path = path
    '確認專案目錄
    If Dir(m_path, vbDirectory) = "" Then
        MsgBox "專案 [" & m_name & "] 不存在。", vbExclamation, "載入專案"
        Exit Function
    Else
        '載入資料庫
        Set m_ctx.DalConfig = LoadDatabase("config")
        Set m_ctx.DalPbc = LoadDatabase("pbc")
        Set m_ctx.DalData = LoadDatabase("data")
        Set m_ctx.DalResult = LoadDatabase("result")
    End If
    
    Load = True
    Exit Function
    
ErrorHandler:
    Load = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--Custom
Private Function CreateDatabase(ByVal dbName As String) As Dal_Access
    Const METHOD_NAME As String = "CreateDatabase"
    On Error GoTo ErrorHandler
    
    Dim dbe As DAO.DBEngine
    Dim db As DAO.Database
    Dim dbPath As String
    Dim dal As Dal_Access
    '建立 DAO 資料庫
    dbPath = m_path & "\" & dbName & ".accdb"
    Set dbe = New DAO.DBEngine
    Set db = dbe.CreateDatabase(dbPath, dbLangGeneral)
    db.Close
    '建立 DAL 物件
    Set dal = New Dal_Access
    dal.path = dbPath
    
    Set CreateDatabase = dal
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Private Function LoadDatabase(ByVal dbName As String) As Dal_Access
    Const METHOD_NAME As String = "LoadDatabase"
    On Error GoTo ErrorHandler
    
    '檢查資料庫檔案
    Dim dbPath As String
    dbPath = m_path & "\" & dbName & ".accdb"
    If Dir(dbPath) = "" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> File not found: " & dbPath
        Set LoadDatabase = Nothing
        Exit Function
    End If
    
    '建立 DAL 物件
    Dim dal As Dal_Access
    Set dal = New Dal_Access
    dal.path = dbPath
    
    Set LoadDatabase = dal
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function
