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
    If m_inTransaction Then RollbackTransaction
    If m_isConnected Then Disconnect
End Sub



'===============================================================================
' 連線管理
'===============================================================================
Public Property Get path() As String
     path = m_path
End Property
Public Property Let path(ByVal value As String)
    m_path = value
End Property

Public Property Get IsConnected() As Boolean
     IsConnected = m_isConnected
End Property

Public Sub Connect()
    Const METHOD_NAME As String = "Connect"
    On Error GoTo Errorhandler
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

Errorhandler:
    m_isConnected = False
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 錯誤: " & Err.Number & ": " & Err.Description
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description
End Sub

Public Sub Disconnect()
    Const METHOD_NAME As String = "Disconnect"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & m_db.name
    On Error GoTo Errorhandler
    
    ' 檢查未完成的事務
    If m_inTransaction Then
         RollbackTransaction
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

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub



'===============================================================================
' 資料定義 DDL (Data Definition Language)
'===============================================================================

Public Function CreateTable(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "CreateTable"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sourceRs.Source & ", " & tableName
    On Error GoTo Errorhandler
    
     CreateTable = False
    ' 確保連線
    If Not m_isConnected Then Connect
    ' 刪除現有資料表
    If TableExists(tableName) Then
         DropTable tableName
    End If
    ' 建構 CREATE TABLE
    Dim sql As String, i As Long
    ' HEAD
    sql = "CREATE TABLE [" & tableName & "] ("
    ' BODY
    For i = 0 To sourceRs.fields.count - 1
        If i > 0 Then sql = sql & ", "
        sql = sql & "[" & sourceRs.fields(i).name & "] TEXT"
    Next i
    ' TAIL
    sql = sql & ")"
    ' 使用 DAO 執行 DDL
    m_db.Execute sql, dbFailOnError
    
    Debug.Print "資料表已建立: " & tableName & " (" & sourceRs.fields.count & " 欄位)"
     CreateTable = True
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function DropTable(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "DropTable"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & tableName & ")"
    On Error GoTo Errorhandler
    
     DropTable = False
    '確保連線
    If Not m_isConnected Then Connect
    '檢查資料表
    If Not TableExists(tableName) Then
        Debug.Print "資料表 [" & tableName & "] 不存在"
         DropTable = True
    Else
        '刪除資料表
        m_db.Execute "DROP TABLE [" & tableName & "]", dbFailOnError
        Debug.Print "已刪除資料表 [" & tableName & "]"
         DropTable = True
    End If
    
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function TableExists(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "TableExists"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & tableName & ")"
    On Error GoTo Errorhandler
    
     TableExists = False
    Dim tbl As DAO.tableDef
    '確保連線
    If Not m_isConnected Then Connect
    '檢查資料表
    For Each tbl In m_db.TableDefs
        If UCase(tbl.name) = UCase(tableName) Then
             TableExists = True
            Debug.Print "資料表 [" & tableName & "] 存在"
            Exit For
        End If
    Next tbl
    
    If Not TableExists Then
        Debug.Print "資料表 [" & tableName & "] 不存在"
    End If
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--資料操作 DML (Data Manipulation Language)
Public Function ExecuteQuery(ByVal sql As String) As DAO.Recordset
    Const METHOD_NAME As String = "ExecuteQuery"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sql
    On Error GoTo Errorhandler
    
    '確保連接
    If Not m_isConnected Then Connect
    '執行查詢並返回 DAO Recordset
    Set ExecuteQuery = m_db.OpenRecordset(sql, dbOpenSnapshot)
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 查詢成功"
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function ExecuteNonQuery(ByVal sql As String) As Long
    Const METHOD_NAME As String = "ExecuteNonQuery"
    On Error GoTo Errorhandler
    
    '確保連接
    If Not m_isConnected Then Connect
    '執行 SQL 命令
    Dim recordsAffected As Long
    m_db.Execute sql, dbFailOnError
    
    '返回受影響的記錄數
     ExecuteNonQuery = m_db.recordsAffected
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 已執行，影響 " & recordsAffected & " 筆記錄"
    Exit Function

Errorhandler:
     ExecuteNonQuery = -1
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function GetScalar(ByVal sql As String) As Variant
    Const METHOD_NAME As String = " GetScalar"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": " & sql
    On Error GoTo Errorhandler
    
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--批次操作 (Bulk Operations)
Public Function BulkInsert(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
    '將標準化 Recordset 進行大量插入
    Const METHOD_NAME As String = "BulkInsert"
    Debug.Print MODULE_NAME & "."; METHOD_NAME & ": (" & sourceRs.Source & "), (" & tableName & ")"
    On Error GoTo Errorhandler
    
     BulkInsert = False
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
    If Not CreateTable(sourceRs, tableName) Then
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
                 BeginTransaction
                '寫入批次資料
                If fetched = 1 And UBound(dataChunk, 2) < 0 Then
                    '單筆記錄 (一維陣列)
                    targetRs.AddNew
                    For j = 0 To UBound(dataChunk, 1)
                        targetRs.fields(j).value = dataChunk(j)
                    Next j
                    targetRs.Update
                Else
                    '多筆記錄 (二維陣列)
                    For i = 0 To (fetched - 1)
                        targetRs.AddNew
                        For j = 0 To UBound(dataChunk, 1)
                            '檢查空值
                            If IsNull(dataChunk(j, i)) Then
                                targetRs.fields(j).value = ""
                            Else
                                targetRs.fields(j).value = dataChunk(j, i)
                            End If
                        Next j
                        targetRs.Update
                    Next i
                End If
                '提交事務
                 CommitTransaction
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
     BulkInsert = True
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
    On Error Resume Next
    '回滾事務
     RollbackTransaction
    If Not targetRs Is Nothing Then targetRs.Close
    Set targetRs = Nothing
    On Error GoTo 0
End Function



'--查詢輔助 (Query Helpers)
Public Function GetTableSchema(ByVal tableName As String) As Variant
    Const METHOD_NAME As String = "GetTableSchema"
    On Error GoTo Errorhandler
    
    Dim tableDef As DAO.tableDef
    Dim field As DAO.field
    Dim fields As New Collection
    Dim fieldsArray() As String
    Dim i As Long
    '確保連接
    If Not m_isConnected Then Connect
    '檢查資料表
    If Not TableExists(tableName) Then
         Set GetTableSchema = Nothing
        Exit Function
    End If
    '檢查欄位
    Set tableDef = m_db.TableDefs(tableName)
    If tableDef.fields.count = 0 Then
        Debug.Print "資料表 [" & tableName & "] 沒有欄位"
        Set GetTableSchema = Nothing
    Else
        For Each field In tableDef.fields
            fields.Add field.name
        Next field
        '轉為陣列
        ReDim fieldsArray(0 To fields.count - 1)
        For i = 1 To fields.count
            fieldsArray(i - 1) = fields(i)
        Next i
        Debug.Print "資料表 [" & tableName & "] 欄位已取得"
        GetTableSchema = fieldsArray
    End If
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function

Public Function GetTableList(ByVal tableName As String) As Variant
    Const METHOD_NAME As String = "GetTableList"
    On Error GoTo Errorhandler
    
    Exit Function

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--事務管理
Public Sub BeginTransaction()
    Const METHOD_NAME As String = "BeginTransaction"
    On Error GoTo Errorhandler
    
    '確保連線
    If Not m_isConnected Then Connect
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
    
Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub CommitTransaction()
    Const METHOD_NAME As String = "CommitTransaction"
    On Error GoTo Errorhandler
    
    If Not m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 沒有進行中的事務"
        Exit Sub
    End If
    '提交事務
    m_ws.CommitTrans
    m_inTransaction = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已提交"
    Exit Sub

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub

Public Sub RollbackTransaction()
    Const METHOD_NAME As String = "RollbackTransaction"
    On Error GoTo Errorhandler
    
    If Not m_inTransaction Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 沒有進行中的事務"
        Exit Sub
    End If
    '回滾事務
    m_ws.Rollback
    m_inTransaction = False
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 事務已回滾"
    Exit Sub

Errorhandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Sub
