VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "c_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     c_Import
' Purpose:  匯入檔案程序的控制器
'===============================================================================

' ----- 常數 -----
Private Const MODULE_NAME As String = "c_Import"
' ----- 表單事件 -----
Private WithEvents viewImport As v_Import
Attribute viewImport.VB_VarHelpID = -1
' ----- 類別成員 -----
Private csvPath As String
Private acePath As String
Private tableName As String


