VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ServicDirectory"
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

Public Function FolderExists(path As String) As Boolean
    FolderExists = (Dir(path, vbDirectory) <> "")
End Function

Public Sub CreateFolder(path As String)
    If Not FolderExists(path) Then MkDir path
End Sub

Public Sub DeleteFolder(path As String)
    If FolderExists(path) Then RmDir path
End If

