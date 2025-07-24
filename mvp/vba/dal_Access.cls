VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Dal_Access"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
Private Const MODULE_NAME = "Dal_Access"
'===============================================================================
' Module:   Dal_Access
' Purpose:  Access 資料庫的資料存取實作，提供 CRUD 操作和批次處理功能
' Layer:    Data Access Layer
' Domain:   Database Access
'===============================================================================
'額外註記:
'- 這裡使用 Microsoft Office 16.0 Access Database Engine Object Library 庫
'- Excel VBA 環境的限制（無法直接使用 DoCmd）

Implements I_Dal
'--類別成員
Private Const CHUNK_SIZE As Long = 100000
Private Const DO_EVENTS_INTERVAL As Double = 2#
Private m_path As String
Private m_ws As DAO.Workspace
Private m_db As DAO.Database
Private m_conn As DAO.Connection
Private m_isConnected As Boolean
Private m_inTransaction As Boolean

'-- 類別事件
Private Sub Class_Initialize()
    m_isConnected = False
    m_inTransaction = False
End Sub

Private Sub Class_Terminate()
    On Error Resume Next
    If m_inTransaction Then I_Dal_RollbackTransaction
    If m_isConnected Then I_Dal_Disconnect
End Sub



'===============================================================================
' 連線管理
'===============================================================================
Public Property Get I_Dal_path() As String
    I_Dal_path = m_path
End Property
Public Property Let I_Dal_path(ByVal value As String)
    m_path = value
End Property

Public Property Get I_Dal_IsConnected() As Boolean
    I_Dal_IsConnected = m_isConnected
End Property

Public Sub I_Dal_Connect()
    Const METHOD_NAME As String = "I_Dal_Connect"
    On Error GoTo ErrorHandler
    ' 檢查是否已連線
    If m_isConnected Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已經連線"
        Exit Sub
    ' 驗證資料庫路徑
    ElseIf Len(m_path) = 0 Then
        Err.Raise vbObjectError + 1001, MODULE_NAME & "." & METHOD_NAME, "資料庫路徑未設定"
    ' 檢查資料庫檔案
    ElseIf Len(Dir(m_path)) = 0 Then
        Err.Raise vbObjectError + 1002, MODULE_NAME & "." & METHOD_NAME, "資料庫檔案不存在: " & m_path
    End If
    ' 建立容器
    Set m_ws = DBEngine.Workspaces(0)
    Set m_db = m_ws.OpenDatabase(m_path, False, False)
    m_isConnected = True
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 連線至 " & m_path
    Exit Sub

ErrorHandler:
    m_isConnected = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Number & ": " & Err.Description
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description
End Sub

Public Sub I_Dal_Disconnect()
    Const METHOD_NAME As String = "I_Dal_Disconnect"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & m_db.name
    On Error GoTo ErrorHandler
    
    ' 檢查未完成的事務
    If m_inTransaction Then
        I_Dal_RollbackTransaction
    End If
    ' 關閉資料庫連線
    If Not m_db Is Nothing Then
        m_db.Close
        Set m_db = Nothing
    End If
    
    Set m_ws = Nothing
    m_isConnected = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已斷開連線"
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub



'===============================================================================
' 資料定義 DDL (Data Definition Language)
'===============================================================================

Public Function I_Dal_CreateTable(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "I_Dal_CreateTable"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sourceRs.Source & ", " & tableName
    On Error GoTo ErrorHandler
    
    I_Dal_CreateTable = False
    ' 確保連線
    If Not m_isConnected Then I_Dal_Connect
    ' 刪除現有資料表
    If I_Dal_TableExists(tableName) Then
        I_Dal_DropTable tableName
    End If
    ' 建構 CREATE TABLE
    Dim sql As String, i As Long
    ' HEAD
    sql = "CREATE TABLE [" & tableName & "] ("
    ' BODY
    For i = 0 To sourceRs.Fields.Count - 1
        If i > 0 Then sql = sql & ", "
        sql = sql & "[" & sourceRs.Fields(i).name & "] TEXT"
    Next i
    ' TAIL
    sql = sql & ")"
    ' 使用 DAO 執行 DDL
    m_db.Execute sql, dbFailOnError
    
    Debug.Print "資料表已建立: " & tableName & " (" & sourceRs.Fields.Count & " 欄位)"
    I_Dal_CreateTable = True
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_DropTable(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "I_Dal_DropTable"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & tableName & ")"
    On Error GoTo ErrorHandler
    
    I_Dal_DropTable = False
    '確保連線
    If Not m_isConnected Then I_Dal_Connect
    '檢查資料表
    If Not I_Dal_TableExists(tableName) Then
        Debug.Print "資料表 [" & tableName & "] 不存在"
        I_Dal_DropTable = True
    Else
        '刪除資料表
        m_db.Execute "DROP TABLE [" & tableName & "]", dbFailOnError
        Debug.Print "已刪除資料表 [" & tableName & "]"
        I_Dal_DropTable = True
    End If
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_TableExists(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "I_Dal_TableExists"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & tableName & ")"
    On Error GoTo ErrorHandler
    
    I_Dal_TableExists = False
    Dim tbl As DAO.TableDef
    '確保連線
    If Not m_isConnected Then I_Dal_Connect
    '檢查資料表
    For Each tbl In m_db.TableDefs
        If UCase(tbl.name) = UCase(tableName) Then
            I_Dal_TableExists = True
            Debug.Print "資料表 [" & tableName & "] 存在"
            Exit For
        End If
    Next tbl
    
    If Not I_Dal_TableExists Then
        Debug.Print "資料表 [" & tableName & "] 不存在"
    End If
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--資料操作 DML (Data Manipulation Language)
Public Function I_Dal_ExecuteQuery(ByVal sql As String) As ADODB.Recordset
    Const METHOD_NAME As String = "I_Dal_ExecuteQuery"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sql
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_ExecuteNonQuery(ByVal sql As String) As Long
    Const METHOD_NAME As String = "I_Dal_ExecuteNonQuery"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sql
    On Error GoTo ErrorHandler
    
    ' 確保連線
    If Not m_isConnected Then I_Dal_Connect
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_GetScalar(ByVal sql As String) As Variant
    Const METHOD_NAME As String = "I_Dal_GetScalar"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sql
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--批次操作 (Bulk Operations)
Public Function I_Dal_BulkInsert(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
    '將標準化 Recordset 進行大量插入
    Const METHOD_NAME As String = "I_Dal_BulkInsert"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & sourceRs.Source & "), (" & tableName & ")"
    On Error GoTo ErrorHandler
    
    I_Dal_BulkInsert = False
    Dim targetRs As DAO.Recordset
    Dim dataChunk As Variant
    Dim fetched As Long, total As Long, batchCount As Long
    Dim i As Long, j As Long
    Dim startTime As Double, lastTime As Double
    
    '初始化
    Call PreventFreeze
    startTime = Timer
    lastTime = Timer
    total = 0
    batchCount = 0
    '檢查資料表
    If Not I_Dal_CreateTable(sourceRs, tableName) Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 建立 [" & tableName & "] 失敗"
        Exit Function
    End If
    '開啟資料表
    Set targetRs = m_db.OpenRecordset(tableName, dbOpenTable)
    '分批處理資料
    Do While Not sourceRs.EOF
        batchCount = batchCount + 1
        '使用 GetRows 快速讀取一批資料
        dataChunk = sourceRs.GetRows(CHUNK_SIZE)
        '方法 GetRows 回傳: (欄位索引, 記錄索引)
        If IsArray(dataChunk) Then
            '處理單筆記錄
            If UBound(dataChunk, 1) >= 0 Then
                If UBound(dataChunk, 2) >= 0 Then
                    fetched = UBound(dataChunk, 2) + 1
                Else
                    fetched = 1
                End If
            Else
                fetched = 0
            End If
            '擷取大於零
            If fetched > 0 Then
                '開始事務
                I_Dal_BeginTransaction
                '寫入批次資料
                If fetched = 1 And UBound(dataChunk, 2) < 0 Then
                    '單筆記錄 (一維陣列)
                    targetRs.AddNew
                    For j = 0 To UBound(dataChunk, 1)
                        targetRs.Fields(j).value = dataChunk(j)
                    Next j
                    targetRs.Update
                Else
                    '多筆記錄 (二維陣列)
                    For i = 0 To (fetched - 1)
                        targetRs.AddNew
                        For j = 0 To UBound(dataChunk, 1)
                            '檢查空值
                            If IsNull(dataChunk(j, i)) Then
                                targetRs.Fields(j).value = ""
                            Else
                                targetRs.Fields(j).value = dataChunk(j, i)
                            End If
                        Next j
                        targetRs.Update
                    Next i
                End If
                '提交事務
                I_Dal_CommitTransaction
                '定期更新事件防止凍結
                If (Timer - lastTime) >= DO_EVENTS_INTERVAL Then
                    DoEvents
                    lastTime = Timer
                End If
                '加總已處理筆數
                total = total + fetched
                Debug.Print "批次 " & batchCount & " 完成，累計: " & total & " 筆"
            End If
        End If
        '釋放記憶體
        Erase dataChunk
    Loop
    '釋放資源
    targetRs.Close
    Set targetRs = Nothing
    
    Debug.Print "批次寫入完成，總計: " & total & " 筆"
    Call RestoreExcel
    Debug.Print "寫入時間: " & Format(Timer - startTime, "0.00") & " 秒"
    I_Dal_BulkInsert = True
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
    On Error Resume Next
    '回滾事務
    I_Dal_RollbackTransaction
    If Not targetRs Is Nothing Then targetRs.Close
    Set targetRs = Nothing
    On Error GoTo 0
End Function



'--查詢輔助 (Query Helpers)
Public Function I_Dal_GetTableSchema(ByVal tableName As String) As ADODB.Recordset
    Const METHOD_NAME As String = "I_Dal_GetTableSchema"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function I_Dal_GetTableList() As ADODB.Recordset
    Const METHOD_NAME As String = "I_Dal_GetTableList"
    On Error GoTo ErrorHandler
    
    Exit Function

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--事務管理
Public Sub I_Dal_BeginTransaction()
    Const METHOD_NAME As String = "I_Dal_BeginTransaction"
    On Error GoTo ErrorHandler
    
    '確保連線
    If Not m_isConnected Then I_Dal_Connect
    '檢察事務
    If m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已在事務中"
        Exit Sub
    End If
    '開始事務
    m_ws.BeginTrans
    m_inTransaction = True
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已開始"
    Exit Sub
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub I_Dal_CommitTransaction()
    Const METHOD_NAME As String = "I_Dal_CommitTransaction"
    On Error GoTo ErrorHandler
    
    If Not m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 沒有進行中的事務"
        Exit Sub
    End If
    '提交事務
    m_ws.CommitTrans
    m_inTransaction = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已提交"
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub I_Dal_RollbackTransaction()
    Const METHOD_NAME As String = "I_Dal_RollbackTransaction"
    On Error GoTo ErrorHandler
    
    If Not m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 沒有進行中的事務"
        Exit Sub
    End If
    '回滾事務
    m_ws.Rollback
    m_inTransaction = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已回滾"
    Exit Sub

ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub
