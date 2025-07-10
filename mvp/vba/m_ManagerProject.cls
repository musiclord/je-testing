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
Private Const MODULE_NAME As String = "m_ManagerProject"
' ----- 成員 -----
Private m_name As String  ' 專案名稱
Private m_path As String  ' 專案目錄
' ----- 屬性 -----
Public Property Get name() As String
    name = m_name
End Property
Public Property Let name(ByVal p_name As String)
    m_name = p_name
    Debug.Print MODULE_NAME & "." & "name: " & m_name
End Property

Public Property Get path() As String
    path = m_path
End Property
Public Property Let path(ByVal p_path As String)
    m_path = p_path
    Debug.Print MODULE_NAME & "." & "path: " & m_path
End Property



Public Function Create() As Boolean
    Const METHOD_NAME = "Create"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    On Error GoTo ErrorHandler
    Create = False
    '1. 創建專案目錄
    If Dir(m_path, vbDirectory) <> "" Then
        MsgBox "專案[" & m_name & "] 已存在。", vbExclamation, "創建專案"
        Exit Function
    Else
        MkDir m_path
    End If
    '2. 創建資料庫
    If Not CreateDatabase(m_path & "\config.accdb") Then Exit Function    ' 專案配置組態
    If Not CreateDatabase(m_path & "\pbc.accdb") Then Exit Function       ' PBC 資料
    If Not CreateDatabase(m_path & "\data.accdb") Then Exit Function      ' 專案資料
    If Not CreateDatabase(m_path & "\result.accdb") Then Exit Function    ' 驗計結果
    '3. 返回狀態
    Create = True
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & Err.Description
    Create = False
End Function

Public Function Load() As Boolean
    Const METHOD_NAME = "Load"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    On Error GoTo ErrorHandler
    Load = False
    '1. 載入專案目錄
    If Dir(m_path, vbDirectory) = "" Then
        MsgBox "專案[" & m_name & "] 不存在。", vbExclamation, "載入專案"
        Exit Function
    End If
    '2. 載入資料庫
    ' dal.dbPath = path
    ' dal.Connect
    '3. 返回狀態
    Load = True
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & Err.Description
    Load = False
End Function

Private Function CreateDatabase(ByVal dbPath As String) As Boolean
    Const METHOD_NAME = "CreateDatabase"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ":( " & dbPath & " )"
    On Error GoTo ErrorHandler
    CreateDatabase = False
    Dim dbe As DAO.dbEngine
    Dim db As DAO.Database
    Set dbe = New DAO.dbEngine
    Set db = dbe.CreateDatabase(dbPath, dbLangGeneral)
    '返回狀態
    CreateDatabase = True
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & Err.Description
    CreateDatabase = False
End Function
