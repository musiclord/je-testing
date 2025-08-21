VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ImportService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const CLS As String = "ImportService"

Private m_ctx As ContextManager
Private m_gl As EntityGl
Private m_tb As EntityTb
Private m_db As DbAccess

Public Sub Initialize(ByRef context As ContextManager)
    Set m_ctx = context
    Set m_db = context.dbPbc
    Set m_gl = context.gl
    Set m_tb = context.tb
End Sub

Public Function AddLineItem() As Boolean
    Const PROC As String = "AddLineItem"
    AddLineItem = False
    Dim sql As String
    AddLineItem = True
End Function

Public Function ImportCsvGl(ByVal filepath As String) As Boolean
    Const PROC As String = "ImportCsvGl"
    On Error GoTo ErrorHandler
    ImportCsvGl = False
    '...
    Dim sourceRs As ADODB.Recordset
    Set sourceRs = m_db.PrepareRecordset(filepath)
    '創建資料表
    Dim field As String, fieldType As String
    Dim sql As String, temp As String
    Dim i As Long, affected As Long
    sql = "CREATE TABLE " & m_gl.Name & " (" & vbCrLf
    For i = 0 To sourceRs.Fields.Count - 1
        sql = sql & Space(4) '擴排
        field = sourceRs.Fields(i).Name
        temp = ReverseLookup(field, m_gl.Fields)
        fieldType = m_gl.GetType(temp)
        sql = sql & "[" & field & "] " & fieldType
        If i < sourceRs.Fields.Count - 1 Then
            sql = sql & Chr(44) '逗號
        End If
        sql = sql & vbCrLf '換行
    Next i
    sql = sql & ")"
    Debug.Print "CREATE SQL: " & sql
    affected = m_db.ExecuteNonQuery(sql)
    Call m_db.BulkInsert(tableName:=m_gl.Name, sourceRs:=sourceRs)
    'If ProcessGlAmount() Then
    ImportCsvGl = True
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function

Private Function ProcessGlAmount() As Boolean
    Const PROC As String = "ProcessGlAmount"
    ProcessGlAmount = False
    Select Case m_gl.Method
        Case 1 '直接使用原始金額欄位
            
        Case 2 '借方金額減去貸方金額
        Case 3 '依據借貸別標誌決定金額正負號
        Case Else
            Err.Raise 5, PROC, "不支援的金額處理模式"
    End Select
    ProcessGlAmount = True
End Function

Public Function ImportCsvTb(ByVal filepath As String) As Boolean
    Const PROC As String = "ImportCsvTb"
    On Error GoTo ErrorHandler
    ImportCsvTb = False
    '...
    Dim sourceRs As ADODB.Recordset
    Set sourceRs = m_db.PrepareRecordset(filepath)
    '創建資料表
    Dim field As String, fieldType As String
    Dim sql As String, temp As String
    Dim i As Long, affected As Long
    sql = "CREATE TABLE " & m_tb.Name & " (" & vbCrLf
    For i = 0 To sourceRs.Fields.Count - 1
        sql = sql & Space(4) '擴排
        field = sourceRs.Fields(i).Name
        temp = ReverseLookup(value:=field, dict:=m_tb.Fields)
        fieldType = m_tb.GetType(temp)
        sql = sql & "[" & field & "]" & fieldType
        If i < sourceRs.Fields.Count - 1 Then
            sql = sql & Chr(44) '逗號
        End If
        sql = sql & vbCrLf '換行
    Next i
    sql = sql & ")"
    Debug.Print "CREATE SQL: " & sql
    affected = m_db.ExecuteNonQuery(sql)
    Call m_db.BulkInsert(tableName:=m_tb.Name, sourceRs:=sourceRs)
    'If ProcessTbAmount() Then
    ImportCsvTb = True
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function

Private Function ProcessTbAmount() As Boolean
    Const PROC As String = "ProcessTbAmount"
    ProcessTbAmount = False
    Select Case m_tb.Method
        Case 1 '直接使用變動金額
        Case 2 '期末 - 期初 = 變動金額
        Case 3 '借方 - 貸方 = 變動金額
        Case 4 '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
        Case Else
            Err.Raise 5, PROC, "不支援的金額處理模式"
    End Select
    ProcessTbAmount = True
End Function

Private Function ReverseLookup(ByVal value As String, ByVal dict As Dictionary) As String
    Dim i As Long
    For i = LBound(dict.Items) To UBound(dict.Items)
        If StrComp(CStr(dict.Items(i)), CStr(value), vbTextCompare) = 0 Then
            ReverseLookup = CStr(dict.Keys(i))
            Exit Function
        End If
    Next i
    ReverseLookup = "" '未命中
End Function
