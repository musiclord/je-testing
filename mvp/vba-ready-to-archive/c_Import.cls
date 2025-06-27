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

' === 常數 ===
Private Const MODULE_NAME As String = "c_Import"

' === 變數 ===
Private csvPath As String
Private acePath As String
Private tableName As String

' === 介面事件 ===
Private WithEvents viewImport As v_Import
Attribute viewImport.VB_VarHelpID = -1

' === 邏輯服務 ===
Private serviceImport As m_ServiceImport


csvPath = application.GetOpenFilename("CSV 檔案 (*.csv),*.csv", , "選擇要匯入的CSV 檔案") ' 使用者輸入
acePath = "" ' m_ManagerContext.Get("accessPath")
tableName = "" ' GL or TB


Private Function ExecuteImport(csvPath As String, acePath As String, tableName As String) As Boolean
    Dim METHOD_NAME As String: METHOD_NAME = "ExecuteImport"
    
    On Error GoTo ErrorHandler
    
    Debug.Print "步驟 1: 建立 Power Query 查詢..."
    Dim queryTable As queryTable
    queryTable = serviceImport.CreatePowerQueryFrom(csvPath)
    
    Debug.Print "步驟 2: 從 Power Query 連線取得 ADO Recordset..."
    Dim source As ADODB.Recordset
    source = serviceImport.GetRecordsetFrom(queryTable)
    
    Debug.Print "步驟 3: 使用 DAO 批次寫入 Access..."
    result = serviceImport.Ado2Dao(source)
    
Cleanup:
    On Error Resume Next
    
    Exit Function

ErrorHandler:
    Debug.Print "錯誤發生在 " & MODULE_NAME & "." & METHOD_NAME & ": " & Err.Description
    GoTo Cleanup

End Function

Private Sub viewImport_DoExit()

End Sub
