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
Private gl As Ent_GL
Private tb As Ent_TB



'--Svc_Import
Public Sub Initialize(ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ctx = Context
    Set gl = Context.gl
    Set tb = Context.tb
End Sub

Public Function ApplyGLMapping(ByVal mapping As Dictionary) As Boolean
    Const METHOD_NAME As String = "ApplyGLMapping"
    On Error GoTo ErrorHandler
    ApplyGLMapping = False
    Dim key As Variant
    '擷取表單控制項為欄位映射表
    For Each key In mapping.Keys
        gl.SetMapping key, mapping(key)
    Next key
    gl.debug_test
    ApplyGLMapping = True
    Exit Function
    
ErrorHandler:
    ApplyGLMapping = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ImportGL(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportGL"
    On Error GoTo ErrorHandler
    'Create table by gl.name
    'sql = sql & "[" & field & "] " & gl.GetType(field) & " "
    'Do BulkInsert
    
    ImportGL = False
    Dim tableName As String
    Let tableName = gl.name
    
    Dim DalPbc As Dal_Access
    Dim DalData As Dal_Access
    
    Set DalPbc = m_ctx.DalPbc
    Set DalData = m_ctx.DalData
    
    Dim sourceRs As ADODB.Recordset
    
    Set sourceRs = PrepareRecordset(filePath)
    If Not DalPbc.BulkInsert(sourceRs, tableName) Then Exit Function
    
    Set sourceRs = PrepareRecordset(filePath)
    If Not DalData.BulkInsert(sourceRs, tableName) Then Exit Function
    ImportGL = True
    Exit Function
    
ErrorHandler:
    ImportGL = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ApplyTBMapping(ByVal mapping As Dictionary) As Boolean
    Const METHOD_NAME As String = "ApplyTBMapping"
    On Error GoTo ErrorHandler
    ApplyTBMapping = False
    Dim key As Variant
    '擷取表單控制項為欄位映射表
    For Each key In mapping.Keys
        tb.SetMapping key, mapping(key)
    Next key
    tb.debug_test
    ApplyTBMapping = True
    Exit Function
    
ErrorHandler:
    ApplyTBMapping = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ImportTB(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportTB"
    On Error GoTo ErrorHandler
    
    ImportTB = False
    Dim tableName As String
    Let tableName = tb.name
    
    Dim DalPbc As Dal_Access
    Dim DalData As Dal_Access
    
    Set DalPbc = m_ctx.DalPbc
    Set DalData = m_ctx.DalData
    
    Dim sourceRs As ADODB.Recordset
    
    Set sourceRs = PrepareRecordset(filePath)
    If Not DalPbc.BulkInsert(sourceRs, tableName) Then Exit Function
    
    Set sourceRs = PrepareRecordset(filePath)
    If Not DalData.BulkInsert(sourceRs, tableName) Then Exit Function
    
    ImportTB = True
    Exit Function
    
ErrorHandler:
    ImportTB = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--Custom

Public Function PrepareRecordset(ByVal filePath As String) As ADODB.Recordset
    Const METHOD_NAME As String = "PrepareRecordset"
    On Error GoTo ErrorHandler
    Dim conn As ADODB.Connection
    Dim rs As ADODB.Recordset
    Dim connString As String
    Dim folderPath As String
    Dim fileName As String
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
    
ErrorHandler:
    Set PrepareRecordset = Nothing
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function AddLineItem() As Boolean
    '新增項次欄位，區別傳票明細項
    Const METHOD_NAME As String = "AddLineItem"
    AddLineItem = False
    On Error GoTo ErrorHandler
    
    Dim sql As String
    Dim affected As Long
    Dim dal As Dal_Access
    Set dal = m_ctx.DalData
    
    dal.Connect
    '開始事務
    dal.BeginTransaction
    '新增欄位: ID
    sql = "ALTER TABLE GL ADD COLUMN [ID] AUTOINCREMENT PRIMARY KEY;"
    affected = dal.ExecuteNonQuery(sql)
    '新增欄位: LineItem
    sql = "ALTER TABLE GL ADD COLUMN [" & gl.LineItem & "] INTEGER;"
    affected = dal.ExecuteNonQuery(sql)
    '計算項次（按傳票號碼分組，依序編號）
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

'金額處理方式:
'GL: 傳票金額 (單一欄位，借方為正值，貸方為負值)
'TB: 變動金額 (單一欄位，期間內淨變動金額)
Private Function ProcessGLAmounts(ByVal method As Integer) As Boolean
    '總帳金額處理方法
    Const METHOD_NAME As String = "ProcessGLAmounts"
    On Error GoTo ErrorHandler
    
    ProcessGLAmounts = False
    Dim sql As String
    Dim dal As Dal_Access
    Set dal = m_ctx.DalData
    If Not dal.IsConnected Then dal.Connect
    
    Select Case method
        Case 1 '直接使用原始金額欄位
            '邏輯: EntryAmount = EntryAmount
            '場景: 當金額欄位已經包含正負號區分借貸時
            
        Case 2 '借方金額減去貸方金額
            '邏輯: EntryAmount = IIF(ISNULL(DebitAmount), 0, DebitAmount) - IIF(ISNULL(CreditAmount), 0, CreditAmount)
            '場景: 當借方金額和貸方金額分別存在不同欄位時
            sql = "UPDATE" & gl.name & "SET" & gl.EntryAmount & "=" & _
                  "IIF(ISNULL(" & gl.DebitAmount & "), 0, " & gl.DebitAmount & ")" & _
                  " - " & _
                  "IIF(ISNULL(" & gl.CreditAmount & "), 0, " & gl.CreditAmount & ")"
            dal.ExecuteNonQuery sql
            
        Case 3 '依據借貸別標示決定金額正負號
            '邏輯: EntryAmount = IIF(DrCr = IsDebit, Amount, Amount * -1)
            '場景: 當金額存在單一欄位，另有借貸別標示欄位時
            sql = "UPDATE " & gl.name & "SET" & gl.EntryAmount & "= " & _
                  "IIF(" & _
                  "" & gl.DrCr & "=" & gl.IsDebit & ", " & _
                  "" & gl.DebitAmount & ", " & _
                  "" & gl.DebitAmount & "* -1)"
            dal.ExecuteNonQuery sql
        Case Else
            Err.Raise 5, METHOD_NAME, "不支援的金額處理模式: " & method
    End Select
    ProcessGLAmounts = True
    Exit Function
    
ErrorHandler:
    ProcessGLAmounts = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Private Function ProcessTBAmounts(ByVal method As Integer) As Boolean
    '試算表金額處理方法
    Const METHOD_NAME As String = "ProcessTBAmounts"
    On Error GoTo ErrorHandler
    
    ProcessTBAmounts = False
    Dim tableName As String
    tableName = "TB"
    Dim dal As Dal_Access
    Set dal = m_ctx.DalData
    Select Case method
        Case 1 '直接使用變動金額
            '邏輯: ChangeAmount = ChangeAmount
            '場景: 當變動金額已經
            
        Case 2 '期末 - 期初 = 變動金額
            '邏輯: ChangeAmount = ClosingAmount - OpeningAmount
            '場景:
            
        Case 3 '借方 - 貸方 = 變動金額
            '邏輯: DebitAmount - CreditAmount = ChangeAmount
            '場景:
            
        Case 4 '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
            '邏輯: (ClosingDebitAmount - OpeningDebitAmount) - (ClosingCreditAmount - OpeningCreditAmount) = ChangeAmount
            '場景:
            
        Case Else
            Err.Raise 5, METHOD_NAME, "不支援的金額處理模式: " & method
    End Select
    ProcessTBAmounts = True
    Exit Function
    
ErrorHandler:
    ProcessTBAmounts = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

