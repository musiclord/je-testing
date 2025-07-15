VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "dal_Access"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Name:     dal_Access
' Purpose:  實作 Access 資料庫的具體操作
' Description:  可以參考 https://www.hosp.ncku.edu.tw/~cww/oldguy/oldguy.htm
'===============================================================================
Implements i_dal
Private Const MODULE_NAME As String = "dal_Access"
Private Const PROVIDER As String = "Microsoft.ACE.OLEDB.16.0"
Private Const CHUNK_SIZE As Long = 100000




' ---------- 成員 ----------
Private m_conn As ADODB.Connection
Private m_path As String




' ---------- 類別方法 ----------
Private Sub Class_Initialize()
    Set m_conn = New ADODB.Connection
End Sub




' ---------- 連線管理 ----------
Public Property Get i_dal_path() As String
    i_dal_path = m_path
End Property
Public Property Let i_dal_path(ByVal p_path As String)
    m_path = p_path
End Property
Public Property Get i_dal_IsConnected() As Boolean
    i_dal_IsConnected = (m_conn.State = ADODB.adStateOpen)
End Property

Public Sub i_dal_Connect()
    On Error GoTo ErrorHandler
    
    If m_conn.State = ADODB.adStateOpen Then Exit Sub
    m_conn.ConnectionTimeout = 10
    m_conn.CommandTimeout = 300
    m_conn.Open "Provider=Microsoft.ACE.OLEDB.16.0;" & _
                "Data Source=" & m_path & ";"
    
    Debug.Print MODULE_NAME & ": 已連線至 " & m_path
    Exit Sub
    
ErrorHandler:
    Debug.Print MODULE_NAME & ".Connect 錯誤: " & Err.Description
    Err.Raise Err.Number, MODULE_NAME & ".Connect", Err.Description
End Sub

Public Sub i_dal_Disconnect()
    On Error Resume Next
    If Not m_conn Is Nothing Then
        If m_conn.State = ADODB.adStateOpen Then m_conn.Close
        Set m_conn = Nothing
    End If
    Debug.Print MODULE_NAME & ": 已中斷連線"
End Sub




' ---------- 資料定義 DDL (Data Definition Language) ----------
Private Function i_dal_CreateTable(ByVal tableName As String, ByVal rs As ADODB.Recordset, Optional ByVal dropIfExists As Boolean = True) As Boolean
    Const METHOD_NAME = ""
    i_dal_CreateTable = False
    On Error GoTo ErrorHandler
    
    '確保連線
    i_dal_Connect
    '先 DROP 已存在再 CREATE
    If dropIfExists Then i_dal_DropTable tableName
    
    Dim i As Long
    Dim sqlParts As Collection
    Set sqlParts = New Collection
    '組建字串
    sqlParts.Add "CREATE TABLE ["
    sqlParts.Add tableName
    sqlParts.Add "] ("
    For i = 0 To rs.fields.Count - 1
        If i > 0 Then sqlParts.Add ", "
        sqlParts.Add "["
        sqlParts.Add rs.fields(i).name
        sqlParts.Add "] TEXT"
    Next i
    sqlParts.Add ")"
    '組合字串
    Dim sql As String, part As Variant
    For Each part In sqlParts
        sql = sql & part
    Next part
    '執行字串
    m_conn.Execute sql
    Debug.Print "資料表已建立: " & tableName
    
ErrorHandler:
    Debug.Print "建立資料表失敗: " & Err.Description
End Function

Private Function i_dal_DropTable(ByVal tableName As String) As Boolean
    Const METHOD_NAME = ""
End Function

Private Function i_dal_TableExists(ByVal tableName As String) As Boolean
    Const METHOD_NAME = ""
End Function




' ---------- 資料操作 DML (Data Manipulation Language) ----------
Public Function i_dal_ExecuteQuery(ByVal sql$) As ADODB.Recordset
    Const METHOD_NAME = "i_dal_ExecuteQuery"
    On Error GoTo ErrorHandler
    
    i_dal_Connect
    Set i_dal_ExecuteQuery = m_conn.Execute(sql)
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
    Set i_dal_ExecuteQuery = Nothing
End Function

Public Function i_dal_ExecuteNonQuery(ByVal sql$) As Long
    Const METHOD_NAME = "i_dal_ExecuteNonQuery"
    On Error GoTo ErrorHandler
    
    i_dal_Connect
    m_conn.Execute sql, i_dal_ExecuteNonQuery  '第二參數使用傳址修改
    
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
    i_dal_ExecuteNonQuery = -1
End Function

Public Function i_dal_GetScalar(ByVal sql$) As Variant
    Const METHOD_NAME = "i_dal_GetScalar"
    On Error GoTo ErrorHandler
    
    Dim rs As ADODB.Recordset
    Set rs = i_dal_ExecuteQuery(sql)
    If Not rs.EOF Then
        i_dal_GetScalar = rs.fields(0).Value
    Else
        i_dal_GetScalar = Null
    End If
    
    rs.Close
    Set rs = Nothing
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
    i_dal_GetScalar = Null
End Function




' ---------- 批次操作 (Bulk Operations) ----------
Public Function i_dal_BulkInsert(ByVal dataSource As Variant, ByVal tableName As String)
    Const METHOD_NAME = "i_dal_BulkInsert"
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": Start"
    
    On Error GoTo ErrorHandler
    
    ' 初始化
    Dim timeStart As Double: timeStart = Timer
    ' 確保連線
    i_dal_Connect
    ' ===[ START ]===
    '初始化
    Dim conn As ADODB.Connection
    Dim rs As ADODB.Recordset
    Dim folderPath As String, filePath As String, fileName As String
    '取得參數
    If TypeName(dataSource) = "String" Then
        filePath = dataSource
        folderPath = Left(filePath, InStrRev(filePath, "\"))
        fileName = Mid(filePath, InStrRev(filePath, "\") + 1)
        '設置連線
        Set conn = New ADODB.Connection
        conn.Open "Provider=" & PROVIDER & ";" & _
                  "Data Source=" & folderPath & ";" & _
                  "Extended Properties=""Text;HDR=Yes;FMT=Delimited;CharacterSet=65001;IMEX=1;MaxScanRows=0"""
        
        Set rs = New ADODB.Recordset
        rs.CursorLocation = adUseClient
        rs.Open "SELECT * FROM [" & fileName & "]", conn, adOpenStatic, adLockReadOnly
        
    ElseIf TypeName(dataSource) = "Recordset" Then
        Set rs = dataSource
        
    Else
        Err.Raise vbObjectError + 1, METHOD_NAME, "不支援的資料來源類型: " & TypeName(dataSource)
        
    End If
    
    '建立資料表
    If Not i_dal_CreateTable(tableName, rs, True) Then
        Debug.Print "建立資料表失敗"
        GoTo Cleanup
    End If
    
    '參數化 INSERT 命令
    Dim cmd As ADODB.Command
    Set cmd = New ADODB.Command
    Set cmd.ActiveConnection = m_conn
    
    '命令字串
    Dim sql As String, i As Long, j As Long
    sql = "INSERT INTO [" & tableName & "] VALUES ("
    For i = 0 To rs.fields.Count - 1
        sql = sql & IIf(i > 0, ", ", "") & "?"
    Next i
    sql = sql & ")"
    cmd.CommandText = sql
    cmd.Prepared = True
    
    '建立參數
    For i = 0 To rs.fields.Count - 1
        cmd.Parameters.Append (cmd.CreateParameter("p" & i, adVarChar, adParamInput, 255))
    Next i
    
    '批次處理迴圈
    Dim chunkData As Variant
    Dim batch As Long, total As Long, fetched As Long
    
    Do While Not rs.EOF
        batch = batch + 1
        chunkData = rs.GetRows(CHUNK_SIZE)
        
        If IsArray(chunkData) Then
            fetched = IIf(UBound(chunkData, 2) >= 0, UBound(chunkData, 2) + 1, 1)
            '交易開始
            m_conn.BeginTrans
            '寫入批次資料
            For i = 0 To fetched - 1
                For j = 0 To UBound(chunkData, 1)
                    cmd.Parameters(j).Value = IIf(IsNull(chunkData(j, i)), "", chunkData(j, i))
                Next j
                cmd.Execute
            Next i
            '交易確認
            m_conn.CommitTrans
            '加總資料筆數
            total = total + fetched
            
            If batch Mod 10 = 0 Then
                Debug.Print "已處理: " & total & "筆，進度: " & Format(total / rs.RecordCount * 100, "0.0") & "%"
            End If
        End If
        
        Erase chunkData
    Loop
    
    '===[  END  ]===
    Debug.Print "Time elapsed: " & Format(Timer - timeStart, "0.00") & " seconds."
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": End"
    i_dal_BulkInsert = True
    Exit Function
Cleanup:
    On Error Resume Next
    If Not rs Is Nothing Then
        rs.Close
        Set rs = Nothing
    End If
    
    If Not conn Is Nothing Then
        conn.Close
        Set conn = Nothing
    End If
    
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & ".BulkInsert 錯誤: " & Err.Description
    GoTo Cleanup
End Function




' ---------- 查詢輔助 (Query Helpers) ----------
Private Function i_dal_GetTableSchema(ByVal tableName As String) As ADODB.Recordset
    Const METHOD_NAME = "i_dal_GetTableSchema"
    On Error GoTo ErrorHandler
    
    i_dal_Connect
    Set i_dal_GetTableSchema = m_conn.OpenSchema(adSchemaColumns, Array(Empty, Empty, tableName))
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
    Set i_dal_GetTableSchema = Nothing
End Function

Private Function i_dal_GetTableList() As ADODB.Recordset
    Const METHOD_NAME = "i_dal_GetTableList"
    On Error GoTo ErrorHandler
    
    i_dal_Connect
    Set i_dal_GetTableList = m_conn.OpenSchema(adSchemaTables, Array(Empty, Empty, Empty, "TABLE"))
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
    Set i_dal_GetTableList = Nothing
End Function



' ---- 事務管理 -----
Public Sub i_dal_BeginTransaction()
    Const METHOD_NAME = "i_dal_BeginTransaction"
    On Error GoTo ErrorHandler
    
    i_dal_Connect
    m_conn.BeginTrans
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
End Sub
Public Sub i_dal_CommitTransaction()
    Const METHOD_NAME = "i_dal_CommitTransaction"
    On Error GoTo ErrorHandler
    
    m_conn.CommitTrans
    Exit Sub
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
End Sub
Public Sub i_dal_RollbackTransaction()
    Const METHOD_NAME = "i_dal_RollbackTransaction"
    On Error GoTo ErrorHandler
    
    m_conn.RollbackTrans
    
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Description
End Sub
