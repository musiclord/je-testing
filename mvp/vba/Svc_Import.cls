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
Private m_ctx As Mgr_Context


'--Svc_Import
Public Sub Initialize(ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ctx = Context
End Sub

Public Function ImportGL(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportGL"
    On Error GoTo ErrorHandler
    
    ImportGL = False
    Dim sourceRs As ADODB.Recordset
    Dim tableName As String
    Dim dal As I_Dal
    Let tableName = "GL"
    ' Let tableName = m_ctx.m_gl.name
    Set dal = m_ctx.DalPbc
    Set sourceRs = PrepareRecordset(filePath)
    If Not dal.BulkInsert(sourceRs, tableName) Then Exit Function
    
    ImportGL = True
    Exit Function
    
ErrorHandler:
    ImportGL = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.DESCRIPTION
End Function

Public Function ImportTB(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportTB"
    On Error GoTo ErrorHandler
    
    ImportTB = False
    Dim sourceRs As ADODB.Recordset
    Dim tableName As String
    Dim dal As I_Dal
    Let tableName = "TB"
    Set dal = m_ctx.DalPbc
    Set sourceRs = PrepareRecordset(filePath)
    If Not dal.BulkInsert(sourceRs, tableName) Then Exit Function
    
    ImportTB = True
    Exit Function
    
ErrorHandler:
    ImportTB = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.DESCRIPTION
End Function
Public Function ApplyGLMapping(ByVal sourceFields As Dictionary) As Boolean
    Const METHOD_NAME As String = "ApplyGLMapping"
    On Error GoTo ErrorHandler
    
    '擷取表單所有控制項 為 欄位映射表
    '複製 PBC 至 DATA 並將設置好欄位
    
    ApplyGLMapping = False
    Dim gl As New Ent_GL
    Dim key As Variant
    Dim index As FieldsId
    Dim value As String
    For Each key In sourceFields.Keys
        
        value = sourceFields(key)
        If Len(value) > 0 Then
            gl.SetMapping index, value
        End If
        ' gl.SetMapping
    Next
    'Dim sourceTable As String, targetTable As String
    'Dim sourceFields As String, standardFields As String
    'Dim sql As String, affected As Long
    'sql = "INSERT INTO [" & targetTable & "] " & _
    '      "(" & standardFields & ") " & _
    '      "SELECT " & _
    '      "(" & customerFields & ") " & _
    '      "FROM [" & sourceTable & "] IN [" & m_ctx.DalPbc.path & "]"
    'affected = m_ctx.DalData.ExecuteNonQuery(sql)
    ApplyGLMapping = True
    Exit Function
    
ErrorHandler:
    ApplyGLMapping = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.DESCRIPTION
End Function

Public Function ApplyTBMapping(ByVal fieldsMapping As Dictionary) As Boolean
    Const METHOD_NAME As String = "ApplyTBMapping"
    On Error GoTo ErrorHandler
    
    ApplyTBMapping = False
    '..
    ApplyTBMapping = True
    Exit Function
    
ErrorHandler:
    ApplyTBMapping = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.DESCRIPTION
End Function

'--Custom
Private Function PrepareRecordset(ByVal filePath As String) As ADODB.Recordset
    Const METHOD_NAME As String = "PrepareRecordset"
    On Error GoTo ErrorHandler
    
    Dim conn As ADODB.Connection
    Dim rs As ADODB.Recordset
    Dim connString As String
    Dim folderPath As String, fileName As String
    Dim SQL As String, encoding As String
    
    Set conn = New ADODB.Connection
    Set rs = New ADODB.Recordset
    '設編碼為 utf-8
    encoding = "65001"
    '拆解路徑
    folderPath = Left(filePath, InStrRev(filePath, "\") - 1)
    fileName = Mid(filePath, InStrRev(filePath, "\") + 1)
    '連線字串
    connString = "Provider=Microsoft.ACE.OLEDB.12.0;" & _
                       "Data Source=" & folderPath & ";" & _
                       "Extended Properties=""Text;HDR=Yes;FMT=Delimited;IMEX=1;CharacterSet=" & encoding & """"
    '建立連線
    conn.Open connString
    '建立查詢
    SQL = "SELECT * FROM [" & fileName & "]"
    '開啟查詢
    rs.Open SQL, conn, adOpenStatic, adLockReadOnly, adCmdText
    
    Set PrepareRecordset = rs
    Exit Function
    
ErrorHandler:
    Set PrepareRecordset = Nothing
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.DESCRIPTION
End Function

Private Function AddLineItem() As Boolean
    '新增項次欄位，區別傳票明細項
    Const METHOD_NAME As String = "AddLineItem"
    AddLineItem = False
    On Error GoTo ErrorHandler
    
    Dim SQL As String
    Dim affected As Long
    Dim dal As I_Dal
    Set dal = m_ctx.DalData
    
    dal.Connect
    '開始事務
    dal.BeginTransaction
    '新增欄位: ID
    SQL = ""
    affected = dal.ExecuteNonQuery(SQL)
    '新增欄位: LineItem
    SQL = ""
    affected = dal.ExecuteNonQuery(SQL)
    '計算項次（按傳票號碼分組，依序編號）
    SQL = ""
    affected = dal.ExecuteNonQuery(SQL)
    '新增欄位: 傳票金額
    SQL = ""
    affected = dal.ExecuteNonQuery(SQL)
    '計算傳票金額（借方-貸方）
    SQL = ""
    affected = dal.ExecuteNonQuery(SQL)
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
                Err.Number & ":" & Err.DESCRIPTION
End Function
