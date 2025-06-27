VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ServiceDirectory"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ServiceDirectory
' Purpose:  操作目錄的服務
'===============================================================================

' === 常數 ===
Private Const MODULE_NAME As String = "m_ServicDirectory"

Public Function FolderExists(Path As String) As Boolean
    FolderExists = (Dir(Path, vbDirectory) <> "")
End Function

Public Sub CreateFolder(Path As String)
    If Not FolderExists(Path) Then MkDir Path
End Sub

Public Sub DeleteFolder(Path As String)
    If FolderExists(Path) Then RmDir Path
End If

