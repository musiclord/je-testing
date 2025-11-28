VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "CoreProject"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Layer:    Core
' Name:     Project
' Purpose:  專案生命週期管理器。
'           負責建立新專案 (含資料庫初始化)、載入既有專案，
'           以及專案資料夾結構的維護。
'===============================================================================

Private m_Context As CoreContext
Private m_DbSchema As DbSchema

Public Sub Initialize(ByVal p_Context As CoreContext)
    Set m_Context = p_Context
    Set m_DbSchema = New DbSchema
End Sub

Public Function CreateProject( _
    ByVal p_FolderPath As String, _
    ByVal p_ProjectName As String, _
    ByVal p_ClientName As String _
) As Boolean
    ' 依路徑創建專案目錄
End Function

Public Function LoadProject() As Boolean
    ' 依路徑載入專案目錄
End Function

'===============================================================================
' Helper
'===============================================================================
Private Function CreateDatabase(ByVal p_DbName As String) As DbAccess
    ' 根據專案目錄創建資料庫檔案
End Function

Private Function LoadDatabase(ByVal p_DbName As String) As DbAccess
    ' 根據專案目錄載入資料庫檔案
End Function
