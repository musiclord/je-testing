VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "DbAccess"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const CLS As String = "DbAccess"
Private Const CHUNK_SIZE As Long = 100000
Private Const DO_EVENTS_INTERVAL As Double = 2#

Private m_path As String
Private m_ws As DAO.Workspace
Private m_db As DAO.Database
Private m_conn As DAO.Connection
Private m_isConnected As Boolean

Public Property Get path() As String
    path = m_path
End Property
Public Property Let path(ByVal value As String)
    m_path = value
End Property

Public Function PrepareRecordset(ByVal filepath As String) As ADODB.Recordset
    Const PROC As String = "PrepareRecordset"
    On Error GoTo ErrorHandler
    Dim conn As New ADODB.Connection
    Dim rs As New ADODB.Recordset
    Dim connStr As String, folderpath As String, fileName As String
    Dim sql As String, encoding As String
    encoding = "65001" 'utf-8
    folderpath = Left(filepath, InStrRev(filepath, "\") - 1)
    fileName = Mid(filepath, InStrRev(filepath, "\") + 1)
    connStr = "Provider=Microsoft.ACE.OLEDB.12.0;" & _
            "Data Source=" & folderpath & ";" & _
            "Extended Properties=""Text;HDR=Yes;FMT=Delimited;IMEX=1;CharacterSet=" & encoding & """"
    conn.Open connStr
    sql = "SELECT * FROM [" & fileName & "]"
    rs.Open sql, conn, adOpenStatic, adLockReadOnly, adCmdText
    Set PrepareRecordset = rs
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function

Public Sub Connect()
    Const PROC As String = "Connect"
    If m_isConnected Then Exit Sub
    Dim wsName As String
    wsName = "WS_" & Format(Now(), "yyyymmddhhnnss") & "_" & Rnd()
    Set m_ws = DBEngine.CreateWorkspace(wsName, "admin", "")
    Set m_db = m_ws.OpenDatabase(m_path, False, False)
    m_isConnected = True
End Sub

Public Sub Disconnect()
    Const PROC As String = "Disconnect"
    If Not m_db Is Nothing Then
        m_db.Close
        Set m_db = Nothing
    End If
    If Not m_ws Is Nothing Then
        m_ws.Close
        Set m_ws = Nothing
    End If
    m_isConnected = False
End Sub

Public Function ExecuteQuery(ByVal sql As String) As DAO.Recordset
    Const PROC As String = "ExecuteQuery"
    On Error GoTo ErrorHandler
    If Not m_isConnected Then Connect
    Set ExecuteQuery = m_db.OpenRecordset(sql, dbOpenSnapshot)
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function

Public Function ExecuteNonQuery(ByVal sql As String) As Long
    Const PROC As String = "ExecuteNonQuery"
    On Error GoTo ErrorHandler
    If Not m_isConnected Then Connect
    m_db.Execute sql, dbFailOnError
    ExecuteNonQuery = m_db.RecordsAffected
    Exit Function
ErrorHandler:
    ExecuteNonQuery = -1
    LogError CLS, PROC, Err
End Function

Public Function BulkInsert(ByVal tableName As String, ByVal sourceRs As ADODB.Recordset) As Boolean
    Const PROC As String = "BulkInsert"
    On Error GoTo ErrorHandler
    
    Dim targetRs As DAO.Recordset
    Dim dataChunk As Variant
    Dim fetched As Long, total As Long, batch As Long
    Dim i As Long, j As Long, v As Variant
    Dim startTime As Double, lastTime As Double
    Call PreventFreeze
    
    BulkInsert = False
    startTime = Timer
    lastTime = Timer
    total = 0
    batch = 0
    Set targetRs = m_db.OpenRecordset(Name:=tableName, Type:=dbOpenTable)
    sourceRs.MoveFirst
    Do While Not sourceRs.EOF
        batch = batch + 1
        dataChunk = sourceRs.GetRows(CHUNK_SIZE)
        '[欄位索引 x 記錄索引]
        If IsArray(dataChunk) Then
            If UBound(dataChunk, 1) >= 0 Then
                If UBound(dataChunk, 2) >= 0 Then
                    fetched = UBound(dataChunk, 2) + 1
                Else
                    fetched = 1
                End If
            Else
                fetched = 0
            End If
            '批次筆數大於零
            If fetched > 0 Then
                m_ws.BeginTrans
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
                        '檢查空值
                        For j = 0 To UBound(dataChunk, 1)
                            v = dataChunk(j, i)
                            If IsNull(v) Then
                                targetRs.Fields(j).value = Null
                            Else
                                targetRs.Fields(j).value = v
                            End If
                        Next j
                        targetRs.Update
                    Next i
                End If
                m_ws.CommitTrans
                '定期更新事件防止凍結
                If (Timer - lastTime) >= DO_EVENTS_INTERVAL Then
                    DoEvents
                    lastTime = Timer
                End If
                total = total + fetched
                Debug.Print "批次 " & batch & " 完成，累計: " & total & " 筆"
            End If
        End If
        Erase dataChunk
    Loop
    
    targetRs.Close
    Set targetRs = Nothing
    Debug.Print "批次寫入完成，總計: " & total & " 筆"
    Call RestoreExcel
    Application.Wait Now + TimeValue("00:00:01") '等待寫入
    If m_isConnected Then Disconnect
    Debug.Print "寫入時間: " & Format(Timer - startTime, "0.00") & " 秒"
    BulkInsert = True
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function


