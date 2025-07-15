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
Private Const MODULE_NAME As String = "c_Import"
' ----- 表單事件 -----
Private WithEvents viewImport As v_Import
Attribute viewImport.VB_VarHelpID = -1
' ----- 依賴項 -----
Private m_Config As m_ManagerConfig
Private m_Context As m_ManagerContext
Private m_Import As m_ServiceImport



' ----- [ c_Import ] -----
Private Sub Class_Initialize()
    Const METHOD_NAME = "Class_Initialize"
    Set viewImport = New v_Import
End Sub

Private Sub Class_Terminate()
    Const METHOD_NAME = "Class_Terminate"
End Sub

Public Function Execute(ByRef Config As m_ManagerConfig, ByRef Context As m_ManagerContext) As Dictionary
    Const METHOD_NAME = "Execute"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '依賴注入
    Dim result As Dictionary
    Set result = New Dictionary
    Set m_Config = Config
    Set m_Context = Context
    '設定表單
    '傳 vbModal 來鎖住程序
    viewImport.Show vbModal   '<--[ viewImport ]
    '待表單關閉後，收集程序狀態並回傳
    result.Add "import_gl", True
    result.Add "import_tb", True
    result.Add "import_holiday", True
    Set Execute = result
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Function



' ----- [ v_Import ] -----
Private Sub viewImport_ImportGL()
    Const METHOD_NAME = "viewImport_ImportGL"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '初始化
    Dim tableName As String
    Dim filePath As String
    '選取 CSV 檔案路徑
    tableName = "GL_Raw"
    filePath = Application.GetOpenFilename()
    '使用者取消
    If Not filePath Then Exit Sub
    '匯入為 GL 資料表
    If Not m_Import.ImportCsv(filePath, tableName) Then
        Debug.Print "ERROR"
    End If
    '...
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub viewImport_ImportTB()
    Const METHOD_NAME = "viewImport_ImportTB"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '初始化
    Dim filePath As String
    '選取 CSV 檔案並匯入為 TB
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then Exit Sub  '使用者取消
    
    '...
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub viewImport_ApplyGL()
    Const METHOD_NAME = "viewImport_ApplyGL"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '初始化
    Dim fields As Dictionary
    Set fields = New Dictionary
    '將選定欄位關聯至標準GL映射表
    Set fields = viewImport.GetGLControls()
    '...
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub viewImport_ApplyTB()
    Const METHOD_NAME = "viewImport_ApplyTB"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    '初始化
    Dim fields As Dictionary
    Set fields = New Dictionary
    '將選定欄位關聯至標準GL映射表
    Set fields = viewImport.GetTBControls()
    '...
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
End Sub

Private Sub viewImport_DoExit()
    Const METHOD_NAME = "viewImport_DoExit"
    viewImport.Hide
End Sub

