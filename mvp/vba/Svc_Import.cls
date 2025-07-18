VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Svc_Import"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Svc_Import"
'===============================================================================
' Module:   Svc_Import
' Purpose:  匯入業務服務，處理檔案解析、資料轉換和匯入邏輯
' Layer:    Service
' Domain:   Import Processing
'===============================================================================

'--類別成員
Private m_ContextManager As Mgr_Context
Private m_fieldsGL As Dictionary
Private m_fieldsTB As Dictionary


'--Svc_Import
Public Sub Initialize(ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ContextManager = Context
    '實例化
    Set m_fieldsGL = New Dictionary
    Set m_fieldsTB = New Dictionary
End Sub

Public Function ImportGL(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportGL"
    On Error GoTo ErrorHandler
    
    ImportGL = False
    Dim tableName As String
    tableName = "GL"
    
    ImportGL = True
    Exit Function
    
ErrorHandler:
    ImportGL = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ImportTB(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportTB"
    On Error GoTo ErrorHandler
    
    ImportTB = False
    '...
    ImportTB = False
    Exit Function
    
ErrorHandler:
    ImportTB = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function


'--Custom
Private Function ImportCsv() As Boolean
    Const METHOD_NAME As String = "ImportCsv"
    On Error GoTo ErrorHandler
    ImportCsv = False
    
    '...
    
    ImportCsv = True
    Exit Function
    
ErrorHandler:
    ImportCsv = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Private Function AddLineItem() As Boolean
    '新增項次欄位，區別傳票明細項
    Const METHOD_NAME As String = "AddLineItem"
    AddLineItem = False
    On Error GoTo ErrorHandler
    
    Dim sql As String
    Dim affected As Long
    Dim dal As I_Dal
    Set dal = m_ContextManager.DalData
    
    dal.Connect
    '開始事務
    dal.BeginTransaction
    '新增欄位: ID
    sql = ""
    affected = dal.ExecuteNonQuery(sql)
    '新增欄位: LineItem
    sql = ""
    affected = dal.ExecuteNonQuery(sql)
    '計算項次（按傳票號碼分組，依序編號）
    sql = ""
    affected = dal.ExecuteNonQuery(sql)
    '新增欄位: 傳票金額
    sql = ""
    affected = dal.ExecuteNonQuery(sql)
    '計算傳票金額（借方-貸方）
    sql = ""
    affected = dal.ExecuteNonQuery(sql)
    '提交事務
    dal.CommitTransaction
    dal.Disconnect
    
    AddLineItem = True
    Exit Function
    
ErrorHandler:
    On Error Resume Next
    '回滾事務
    dal.RollbackTransaction
    AddLineItem = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function
