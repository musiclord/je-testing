VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "m_ServiceImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     m_ServiceImport
' Purpose:  資料匯入服務，將 PBC 檔案匯入至資料庫
'===============================================================================
Private Const MODULE_NAME = "m_ServiceImport"
' ----- 依賴項 -----
Private m_Context As m_ManagerContext
' ----- 成員 -----
Private m_fieldsGL As Dictionary
Private m_fieldsTB As Dictionary
Private m_batchSize As Integer
' ----- 屬性 -----
Public Property Let batchSize(ByVal k As Integer)
    m_batchSize = k
End Property



Public Sub Initialize(ByRef Context As m_ManagerContext, ByVal k As Integer)
    Set m_Context = Context
    m_batchSize = k
End Sub

Public Function ImportCsv(ByVal filePath As String, ByVal tableName As String) As Boolean
    ' 匯入資料至 PBC.accdb
    Const METHOD_NAME = "ImportCsv"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    On Error GoTo ErrorHandler
    ImportCsv = False
    '初始化
    Dim DalPbc As i_dal
    Set DalPbc = m_Context.DalPbc
    '連線資料庫
    If Not DalPbc.IsConnected Then DalPbc.Connect
    '匯入資料表
    If Not DalPbc.BulkInsert(filePath, tableName) Then
        GoTo ErrorHandler
    End If
    
    '...
    ImportCsv = True
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
    Exit Function
    
ErrorHandler:
    Debug.Print ""
    ImportCsv = False
End Function
