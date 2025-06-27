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
    On Error GoTo ErrorHandler
    
    Create = False
    
    ' 創建專案目錄
    Dim path As String
    path = root & "\" & name
    If Dir(path, vbDirectory) <> "" Then
        MsgBox "專案[" & name & "] 已存在。", vbExclamation, "創建專案"
        Exit Function
    Else
        MkDir path
    End If
    

    ' 創建資料庫
    Dim dbEngine As DAO.dbEngine
    Dim db As DAO.Database
    Dim configPath As String, pbcPath As String, dataPath As String, resultPath As String
    
    configPath = path & "\" & "config.accdb"
    pbcPath = path & "\" & "pbc.accdb"
    dataPath = path & "\" & "data.accdb"
    resultPath = path & "\" & "result.accdb"
    
    ' Initialize config
    
    ' Initialize context
    Create = True

ErrorHandler:

End Function

Public Function Load() As Boolean
    ' Load exist project by given name.
    
End Function

Public Function Setup() As Boolean

End Function
