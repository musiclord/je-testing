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
Private gl As EntityGl
Private tb As EntityTb
Private m_db As DbAccess

Public Sub Initialize(ByRef context As ContextManager)
    Set m_ctx = context
    Set m_db = context.dbPbc
    Set gl = context.gl
    Set tb = context.tb
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
    sql = "CREATE TABLE " & gl.Name & " (" & vbCrLf
    For i = 0 To sourceRs.Fields.Count - 1
        sql = sql & Space(4) '擴排
        field = sourceRs.Fields(i).Name
        temp = ReverseLookup(field, gl.Fields)
        fieldType = gl.GetType(temp)
        sql = sql & "[" & field & "] " & fieldType
        If i < sourceRs.Fields.Count - 1 Then
            sql = sql & Chr(44) '逗號
        End If
        sql = sql & vbCrLf '換行
    Next i
    sql = sql & ")"
    Debug.Print "CREATE SQL: " & sql
    affected = m_db.ExecuteNonQuery(sql)
    Call m_db.BulkInsert(tableName:=gl.Name, sourceRs:=sourceRs)
    'Call ProcessGlAmount
    ImportCsvGl = True
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function

Private Sub ProcessGlAmount()
    Const PROC As String = "ProcessGlAmount"
    
    Dim sql As String
    Dim f_EntryAmount As String
    Dim affected As Long
    
    Select Case gl.Method
        Case 1 '直接使用原始金額欄位
            f_EntryAmount = "[金額JE]"
            affected = m_db.ExecuteNonQuery( _
                "UPDATE " & gl.Name & " " & _
                "SET " & f_EntryAmount & " = Nz(" & gl.EntryAmount & ", 0);" _
            )
            Call gl.SetMapping(key:="EntryAmount", value:=f_EntryAmount)
        Case 2 '借方金額 - 貸方金額
            f_EntryAmount = "[金額JE]"
            '新增欄位
            affected = m_db.ExecuteNonQuery( _
                "ALTER TABLE " & gl.Name & " " & _
                "ADD COLUMN " & f_EntryAmount & " CURRENCY;" _
            )
            '計算欄位
            affected = m_db.ExecuteNonQuery( _
                "UPDATE " & gl.Name & " " & _
                "SET " & f_EntryAmount & " = " & _
                Nz(gl.DebitAmount, 0) & " - " & Nz(gl.CreditAmount, 0) & ";" _
            )
            
        Case 3 '依據借貸別標誌決定金額正負號
        Case Else
            Err.Raise 5, PROC, "不支援的金額處理模式"
    End Select
End Sub

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
    sql = "CREATE TABLE " & tb.Name & " (" & vbCrLf
    For i = 0 To sourceRs.Fields.Count - 1
        sql = sql & Space(4) '擴排
        field = sourceRs.Fields(i).Name
        temp = ReverseLookup(value:=field, dict:=tb.Fields)
        fieldType = tb.GetType(temp)
        sql = sql & "[" & field & "]" & fieldType
        If i < sourceRs.Fields.Count - 1 Then
            sql = sql & Chr(44) '逗號
        End If
        sql = sql & vbCrLf '換行
    Next i
    sql = sql & ")"
    Debug.Print "CREATE SQL: " & sql
    affected = m_db.ExecuteNonQuery(sql)
    Call m_db.BulkInsert(tableName:=tb.Name, sourceRs:=sourceRs)
    'If ProcessTbAmount() Then
    ImportCsvTb = True
    Exit Function
ErrorHandler:
    LogError CLS, PROC, Err
End Function

Private Function ProcessTbAmount() As Boolean
    Const PROC As String = "ProcessTbAmount"
    ProcessTbAmount = False
    Select Case tb.Method
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
