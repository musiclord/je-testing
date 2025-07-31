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
'試算表金額處理方法
' status_SA = 1 : 直接使用變動金額
' status_SA = 2 : 期末 - 期初 = 變動金額
' status_SA = 3 : 借方 - 貸方 = 變動金額
' status_SA = 4 : (期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
'總帳金額處理方法
' status_Amount = 1 : 不須分辨借貸
' status_Amount = 2 : 需要分辨借方金額與貸方金額
' status_Amount = 3 : 依據借貸別區分

'--類別成員
Private m_ctx As Mgr_Context
Private m_gl As Ent_GL
Private m_tb As Ent_TB



'--Svc_Import
Public Sub Initialize(ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ctx = Context
    Set m_gl = Context.gl
    Set m_tb = Context.tb
End Sub

Public Function ImportGL(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportGL"
    On Error GoTo Errorhandler
    
    ImportGL = False
    Dim sourceRs As ADODB.Recordset
    Dim tableName As String
    Dim dalPbc As Dal_Access, dalData As Dal_Access
    Let tableName = m_gl.name
    Set dalPbc = m_ctx.dalPbc
    Set dalData = m_ctx.dalData
    Set sourceRs = PrepareRecordset(filePath)
    If Not dalPbc.BulkInsert(sourceRs, tableName) Then Exit Function
    If Not dalData.BulkInsert(sourceRs, tableName) Then Exit Function
    
    ImportGL = True
    Exit Function
    
Errorhandler:
    ImportGL = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ImportTB(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportTB"
    On Error GoTo Errorhandler
    
    ImportTB = False
    Dim sourceRs As ADODB.Recordset
    Dim tableName As String
    Dim dalPbc As Dal_Access, dalData As Dal_Access
    Let tableName = m_tb.name
    Set dalPbc = m_ctx.dalPbc
    Set dalData = m_ctx.dalData
    Set sourceRs = PrepareRecordset(filePath)
    If Not dalPbc.BulkInsert(sourceRs, tableName) Then Exit Function
    If Not dalData.BulkInsert(sourceRs, tableName) Then Exit Function
    
    ImportTB = True
    Exit Function
    
Errorhandler:
    ImportTB = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ApplyGLMapping(ByVal mapping As Dictionary) As Boolean
    Const METHOD_NAME As String = "ApplyGLMapping"
    On Error GoTo Errorhandler
    
    ApplyGLMapping = False
    Dim key As Variant
    '擷取表單控制項為欄位映射表
    For Each key In mapping.Keys
        m_gl.SetMapping key, mapping(key)
    Next key
    m_gl.debug_test
    ApplyGLMapping = True
    Exit Function
    
Errorhandler:
    ApplyGLMapping = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ApplyTBMapping(ByVal mapping As Dictionary) As Boolean
    Const METHOD_NAME As String = "ApplyTBMapping"
    On Error GoTo Errorhandler
    
    ApplyTBMapping = False
    Dim key As Variant
    '擷取表單控制項為欄位映射表
    For Each key In mapping.Keys
        m_tb.SetMapping key, mapping(key)
    Next key
    m_tb.debug_test
    ApplyTBMapping = True
    Exit Function
    
Errorhandler:
    ApplyTBMapping = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

'--Custom
Private Function PrepareRecordset(ByVal filePath As String) As ADODB.Recordset
    Const METHOD_NAME As String = "PrepareRecordset"
    On Error GoTo Errorhandler
    
    Dim conn As ADODB.Connection
    Dim rs As ADODB.Recordset
    Dim connString As String
    Dim folderPath As String, fileName As String
    Dim sql As String, encoding As String
    
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
    sql = "SELECT * FROM [" & fileName & "]"
    '開啟查詢
    rs.Open sql, conn, adOpenStatic, adLockReadOnly, adCmdText
    
    Set PrepareRecordset = rs
    Exit Function
    
Errorhandler:
    Set PrepareRecordset = Nothing
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function AddLineItem() As Boolean
    '新增項次欄位，區別傳票明細項
    Const METHOD_NAME As String = "AddLineItem"
    AddLineItem = False
    On Error GoTo Errorhandler
    
    Dim sql As String
    Dim affected As Long
    Dim dal As Dal_Access
    Set dal = m_ctx.dalData
    
    dal.Connect
    '開始事務
    dal.BeginTransaction
    '新增欄位: ID
    sql = "ALTER TABLE GL ADD COLUMN ID AUTOINCREMENT PRIMARY KEY;"
    affected = dal.ExecuteNonQuery(sql)
    '新增欄位: LineItem
    sql = "ALTER TABLE GL ADD COLUMN [LineItem] INTEGER;"
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
    
Errorhandler:
    On Error Resume Next
    '回滾事務
    dal.RollbackTransaction
    AddLineItem = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function
