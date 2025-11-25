VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceAccountMapping"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ServiceAccountMapping
' Purpose: 管理科目配對與標準化
'===============================================================================

Private m_Context As Object
Private m_Db As Object
Private m_Schema As Object

Public Sub Initialize(ByVal context As Object)
    Set m_Context = context
    Set m_Db = context.DbAccess
    Set m_Schema = context.DbSchema
End Sub

Public Function ImportMappingFromSheet(ByVal ws As Object, ByVal dataRange As String) As Boolean
    '---------------------------------------------------------------------------
    ' 從工作表匯入科目配對資料
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ImportMappingFromSheet = False
    
    '刪除舊的配對表
    If m_Db.TableExists(m_Schema.AccountMapping.Name) Then
        m_Db.DropTable m_Schema.AccountMapping.Name
    End If
    
    '建立配對表結構
    Dim sql As String
    sql = "CREATE TABLE [" & m_Schema.AccountMapping.Name & "] (" & vbCrLf & _
          "    ID AUTOINCREMENT PRIMARY KEY, " & vbCrLf & _
          "    [" & m_Schema.AccountMapping.AccountNumber & "] TEXT(50), " & vbCrLf & _
          "    [" & m_Schema.AccountMapping.AccountName & "] TEXT(255), " & vbCrLf & _
          "    [" & m_Schema.AccountMapping.AccountStandardized & "] TEXT(100)" & vbCrLf & _
          ");"
    m_Db.ExecuteNonQuery sql
    
    '匯入資料
    Dim rng As Range
    Set rng = ws.Range(dataRange)
    
    Dim  i As Long
    Dim rowData As Range
    
    m_Db.BeginTrans
    
    For i = 2 To rng.Rows.Count  ' 跳過標題列
        Set rowData = rng.Rows(i)
        
        sql = "INSERT INTO [" & m_Schema.AccountMapping.Name & "] " & vbCrLf & _
              "([" & m_Schema.AccountMapping.AccountNumber & "], " & _
              "[" & m_Schema.AccountMapping.AccountName & "], " & _
              "[" & m_Schema.AccountMapping.AccountStandardized & "]) " & vbCrLf & _
              "VALUES ('" & m_Db.EscapeString(CStr(rowData.Cells(1, 1).Value)) & "', " & _
              "'" & m_Db.EscapeString(CStr(rowData.Cells(1, 2).Value)) & "', " & _
              "'" & m_Db.EscapeString(CStr(rowData.Cells(1, 3).Value)) & "');"
        
        m_Db.ExecuteNonQuery sql, False
    Next i
    
    m_Db.CommitTrans
    
    m_Context.Logger.LogInfo "Account mapping imported: " & (rng.Rows.Count - 1) & " rows"
    ImportMappingFromSheet = True
    Exit Function
    
ErrorHandler:
    m_Db.RollbackTrans
    m_Context.Logger.LogError "ImportMappingFromSheet failed", Err.Number
    ImportMappingFromSheet = False
End Function

Public Function ApplyStandardization() As Boolean
    '---------------------------------------------------------------------------
    ' 套用科目標準化到 JE 表
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ApplyStandardization = False
    
    '新增標準化科目欄位到 JE
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    
    Set dbs = m_Db.Database
    Set tdf = dbs.TableDefs(m_Schema.JE.Name)
    
    '建立欄位
    On Error Resume Next
    tdf.Fields.Delete "AccountStandardized"
    Err.Clear
    On Error GoTo ErrorHandler
    
    Set fld = tdf.CreateField("AccountStandardized", dbText, 100)
    tdf.Fields.Append fld
    
    '更新標準化科目
    Dim sql As String
    sql = "UPDATE [" & m_Schema.JE.Name & "] AS J " & vbCrLf & _
          "INNER JOIN [" & m_Schema.AccountMapping.Name & "] AS M " & vbCrLf & _
          "    ON J.[" & m_Schema.JE.AccountNumber & "] = M.[" & m_Schema.AccountMapping.AccountNumber & "] " & vbCrLf & _
          "SET J.AccountStandardized = M.[" & m_Schema.AccountMapping.AccountStandardized & "];"
    
    m_Db.ExecuteNonQuery sql
    
    m_Context.Logger.LogInfo "Account standardization applied"
    ApplyStandardization = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "ApplyStandardization failed", Err.Number
    ApplyStandardization = False
End Function

Private Sub Class_Terminate()
    Set m_Context = Nothing
    Set m_Db = Nothing
    Set m_Schema = Nothing
End Sub
