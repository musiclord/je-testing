Attribute VB_Name = "AppUtils"
Option Explicit
'===============================================================================
' Layer:    Global
' Name:     Utils
' Purpose:  通用工具函式庫。
'           提供檔案系統操作 (FSO)、字串處理、日期格式化等
'           跨模組共用的輔助功能。
'===============================================================================

'--
Public g_Fso As Scripting.FileSystemObject

'--------------------------------------------------------------------------------
' Initialization
'--------------------------------------------------------------------------------
Private Sub Class_Initialize()
    Set g_Fso = New Scripting.FileSystemObject
End Sub


