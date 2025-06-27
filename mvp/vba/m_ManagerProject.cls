VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ManagerProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ManagerProject
' Purpose:  處理專案服務，依據指定專案資訊獨立出目錄及組態
'===============================================================================

' ----- 常數 -----
Private Const MODULE_NAME As String = "m_ManagerProject"

' ----- 屬性 -----
Private m_name As String  ' 專案名稱
Private m_root As String  ' 專案目錄
Public Property Let name(ByVal value As String)
    m_name = value
End Property
Public Property Get name() As String
    name = m_name
End Property
Public Property Let root(ByVal value As String)
    m_root = value
End Property
Public Property Get root() As String
    root = m_root
End Property

Public Function Create(ByVal name As String, ByVal root As String) As Boolean
    Const METHOD_NAME = "Create"
    On Error GoTo ErrorHandler
    Create = False
    
    ' 1. 創建專案目錄
    Dim path As String
    path = root & "\" & name
    If Dir(path, vbDirectory) <> "" Then
        MsgBox "專案[" & name & "] 已存在。", vbExclamation, "創建專案"
        Exit Function
    Else
        MkDir path
    End If
    
    ' 2. 創建資料庫
    If Not CreateDatabase(path & "\config.accdb") Then Exit Function    ' 專案配置組態
    If Not CreateDatabase(path & "\pbc.accdb") Then Exit Function       ' PBC 資料
    If Not CreateDatabase(path & "\data.accdb") Then Exit Function      ' 專案資料
    If Not CreateDatabase(path & "\result.accdb") Then Exit Function    ' 驗計結果

    Create = True
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & Err.Description
    Create = False
    Exit Function
End Function

Public Function Load(ByVal name As String, ByVal root As String) As Boolean
    Const METHOD_NAME = "Load"
    On Error GoTo ErrorHandler
    Load = False
    
    ' 1. 載入專案目錄
    Dim path As String
    path = root & "\" & name
    If Dir(path, vbDirectory) = "" Then
        MsgBox "專案[" & name & "] 不存在。", vbExclamation, "載入專案"
        Exit Function
    End If
    
    ' 2. 載入資料庫
    ' 在 i_dal 中設置 dbPath 並 Connect 即可
    ' dal.dbPath = path
    ' dal.Connect
        
    Load = True
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & Err.Description
    Load = False
    Exit Function
End Function

Private Function CreateDatabase(ByVal dbPath As String) As Boolean
    On Error GoTo ErrorHandler
    CreateDatabase = False
    
    Dim dbEngine As DAO.dbEngine
    Dim db As DAO.Database
    
    Set dbEngine = New DAO.dbEngine
    Set db = dbEngine.CreateDatabase(dbPath, dbLangGeneral)
    
    CreateDatabase = True
End Function
