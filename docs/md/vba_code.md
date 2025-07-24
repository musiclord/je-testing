- Ctrl_Main.cls
```vba
Option Explicit
Private Const MODULE_NAME = "Ctrl_Main"
'===============================================================================
' Module:   Ctrl_Main
' Purpose:  主要功能控制器，協調各步驟流程的執行與視圖切換
' Layer:    Controller
' Domain:   Core Application
'===============================================================================


'--類別成員
Private m_ProjectManager As Mgr_Project
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ImportController As Ctrl_Import
Private m_ValidationController As Ctrl_Validation
Private m_FilterController As Ctrl_Filter
Private m_ExportController As Ctrl_Export
'--事件表單
Private WithEvents viewMain As View_Main


Public Sub Initialize(ByVal project As Mgr_Project)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ProjectManager = project
    Set m_cfg = m_ProjectManager.Config
    Set m_ctx = m_ProjectManager.Context
    '實例化
    Set viewMain = New View_Main
End Sub

Public Sub Run()
    Const METHOD_NAME As String = "Run"
    '設定表單
    viewMain.Caption = m_ProjectManager.name
    '開啟表單
    viewMain.Show vbModeless
    
End Sub

Private Sub viewMain_DoExit()
    Const METHOD_NAME As String = "viewMain_DoExit"
    viewMain.Hide
End Sub

Private Sub viewMain_DoStep1()
    Const METHOD_NAME As String = "viewMain_DoStep1"
    
    Dim result As Dictionary
    Set m_ImportController = New Ctrl_Import
    m_ImportController.Initialize m_cfg, m_ctx
    Set result = m_ImportController.Execute()
    
End Sub

Private Sub viewMain_DoStep2()
    Const METHOD_NAME As String = "viewMain_DoStep2"
    
    Dim result As Dictionary
    Set m_ValidationController = New Ctrl_Validation
    m_ValidationController.Initialize m_cfg, m_ctx
    Set result = m_ValidationController.Execute()
    '更新處理狀態
    
End Sub

Private Sub viewMain_DoStep3()
    Const METHOD_NAME As String = "viewMain_DoStep3"
    
    Dim result As Dictionary
    Set m_FilterController = New Ctrl_Filter
    m_FilterController.Initialize m_cfg, m_ctx
    Set result = m_FilterController.Execute()
    '更新處理狀態
    
End Sub

Private Sub viewMain_DoStep4()
    Const METHOD_NAME As String = "viewMain_DoStep4"
    
    Dim result As Dictionary
    Set m_ExportController = New Ctrl_Export
    m_ExportController.Initialize m_cfg, m_ctx
    Set result = m_ExportController.Execute()
    '更新處理狀態
    
End Sub

```
- Ctrl_Import.cls
```vba
Option Explicit
Private Const MODULE_NAME = "Ctrl_Import"
'===============================================================================
' Module:   Ctrl_Import
' Purpose:  匯入功能控制器，協調檔案匯入流程和錯誤處理
' Layer:    Controller
' Domain:   Import Processing
'===============================================================================

'--類別成員
Private m_cfg As Mgr_Config
Private m_ctx As Mgr_Context
Private m_ImportService As Svc_Import
'--事件表單
Private WithEvents viewImport As View_Import



'--Ctrl_Import
Public Sub Initialize(ByRef Config As Mgr_Config, ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_cfg = Config
    Set m_ctx = Context
    '實例化
    Set m_ImportService = New Svc_Import
    Set viewImport = New View_Import
    '初始化
    m_ImportService.Initialize m_ctx
    
End Sub

Public Function Execute() As Dictionary
    Const METHOD_NAME As String = "Execute"
    On Error GoTo ErrorHandler
    
    Dim result As Dictionary
    Set result = New Dictionary
    viewImport.Show vbModeless
    '檢查處理狀態
    result.Add "import_gl", True
    result.Add "import tb", True
    result.Add "import_holiday", True
    
    Set Execute = result
    Exit Function
    
ErrorHandler:
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " --> " & _
                Err.Number & ":" & Err.Description
End Function



'--View_Import
Private Sub viewImport_DoExit()
    Const METHOD_NAME As String = "viewImport_DoExit"
    viewImport.Hide
End Sub

Private Sub viewImport_ImportGL()
    Const METHOD_NAME As String = "viewImport_ImportGL"
    
    Dim filePath As String
    '選取CSV路徑
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 使用者取消操作。"
        Exit Sub
    End If
    '匯入資料表
    If Not m_ImportService.ImportGL(filePath) Then
        MsgBox "資料匯入失敗", vbCritical, "匯入GL"
    End If
End Sub

Private Sub viewImport_ImportTB()
    Const METHOD_NAME As String = "viewImport_ImportTB"
    
    Dim filePath As String
    '選取CSV路徑
    filePath = Application.GetOpenFilename()
    If filePath = "False" Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & ": 使用者取消操作。"
        Exit Sub
    End If
    '匯入資料表
    If Not m_ImportService.ImportTB(filePath) Then
        MsgBox "資料匯入失敗", vbCritical, "匯入TB"
    End If
End Sub

Private Sub viewImport_ApplyGL()
    Const METHOD_NAME As String = "viewImport_ApplyGL"
    '標準化欄位名稱至 Ent_FieldsGL
    
End Sub

Private Sub viewImport_ApplyTB()
    Const METHOD_NAME As String = "viewImport_ApplyTB"
    '標準化欄位名稱至 Ent_FieldsTB
    
End Sub

```
- Svc_Import.cls
```vba
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
Private m_fieldsGL As Dictionary
Private m_fieldsTB As Dictionary


'--Svc_Import
Public Sub Initialize(ByRef Context As Mgr_Context)
    Const METHOD_NAME As String = "Initialize"
    '依賴注入
    Set m_ctx = Context
    '實例化
    Set m_fieldsGL = New Dictionary
    Set m_fieldsTB = New Dictionary
End Sub

Public Function ImportGL(ByVal filePath As String) As Boolean
    Const METHOD_NAME As String = "ImportGL"
    On Error GoTo ErrorHandler
    
    ImportGL = False
    Dim sourceRs As ADODB.Recordset
    Dim tableName As String
    Dim dal As I_Dal
    Let tableName = "GL"
    Set dal = m_ctx.DalPbc
    Set sourceRs = PrepareRecordset(filePath)
    If Not dal.BulkInsert(sourceRs, tableName) Then Exit Function
    
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
                Err.Number & ":" & Err.Description
End Function


'--Custom
Private Function PrepareRecordset(ByVal filePath As String) As ADODB.Recordset
    Const METHOD_NAME As String = "PrepareRecordset"
    On Error GoTo ErrorHandler
    
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
    
ErrorHandler:
    Set PrepareRecordset = Nothing
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
    Set dal = m_ctx.DalData
    
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

```
- I_Dal.cls
```vba
Option Explicit
Private Const MODULE_NAME = "I_Dal"
'===============================================================================
' Module:   I_Dal
' Purpose:  資料存取層的介面定義，主要提供 CRUD 操作
' Layer:    Interface
' Domain:   Data Access
'===============================================================================
'額外註記:
'- 保留資料存取層的通用方法，未來可擴展至 SQL Server


'--連線管理
Public Property Get path() As String
End Property
Public Property Let path(ByVal value As String)
End Property
Public Property Get IsConnected() As Boolean
End Property
Public Sub Connect()
End Sub
Public Sub Disconnect()
End Sub



'--資料定義 DDL (Data Definition Language)
Public Function CreateTable(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
End Function
Public Function DropTable(ByVal tableName As String) As Boolean
End Function
Public Function TableExists(ByVal tableName As String) As Boolean
End Function



'--資料操作 DML (Data Manipulation Language)
Public Function ExecuteQuery(ByVal sql$) As ADODB.Recordset
End Function
Public Function ExecuteNonQuery(ByVal sql$) As Long
End Function
Public Function GetScalar(ByVal sql$) As Variant
End Function



'--批次操作 (Bulk Operations)
Public Function BulkInsert(ByVal sourceRs As ADODB.Recordset, ByVal tableName As String) As Boolean
End Function



'--查詢輔助 (Query Helpers)
Public Function GetTableSchema(ByVal tableName As String) As ADODB.Recordset
End Function
Public Function GetTableList() As ADODB.Recordset
End Function



'--事務管理
Public Sub BeginTransaction()
End Sub
Public Sub CommitTransaction()
End Sub
Public Sub RollbackTransaction()
End Sub

```
- Dal_Access.cls
```vba
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

```
- Ent_Fields.cls
```vba
Option Explicit
Private Const MODULE_NAME = "Ent_Fields"
'===============================================================================
' Module:   Ent_Fields
' Purpose:
' Layer:    Entity
' Domain:   Fields Mapping
'===============================================================================

'--類別成員
Private m_mappings As Dictionary

'--屬性
Public Property Get Mappings() As Dictionary
    Set Mappings = m_mappings
End Property



'--Ent_Fields
Public Sub Initialize()
    Set m_mappings = New Dictionary
End Sub


Public Sub SetMapping(ByVal standardField As String, ByVal sourceField As String)
    m_mappings(standardField) = sourceField
End Sub

Public Function GetSourceField(ByVal standardField As String) As String
    If m_mappings.Exists(standardField) Then
        GetSourceField = m_mappings(standardField)
    Else
        GetSourceField = standardField
    End If
End Function


```
- Ent_FieldsGL.cls
```vba
Option Explicit
Private Const MODULE_NAME = "Ent_FieldsGL"
'===============================================================================
' Module:   Ent_FieldsGL
' Purpose:
' Layer:    Entity
' Domain:   GL Mapping
'===============================================================================

'--類別成員
Private m_mapping As Ent_Fields

'--屬性
Public Property Get AccountNumber() As String
    AccountNumber = m_mapping.GetSourceField("AccountNumber")
End Property

Public Property Get AccountName() As String
    AccountName = m_mapping.GetSourceField("AccountName")
End Property



'--Ent_FieldsGL
Public Sub Initialize()
    Set m_mapping = New Ent_Fields
    m_mapping.Initialize
    Call SetDefaultMapping
End Sub

Private Sub SetDefaultMapping()
    m_mapping.SetMapping "", ""
    m_mapping.SetMapping "", ""
    m_mapping.SetMapping "", ""
    m_mapping.SetMapping "", ""
End Sub

Public Sub SetCustomMapping(ByVal standardField As String, ByVal customerField As String)
    m_mapping.SetMapping standardField, customerField
End Sub

```
