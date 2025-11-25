VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceImport"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

'===============================================================================
' Class: ServiceImport
' Purpose: 處理資料匯入與欄位映射
'
' Responsibilities:
'   - 整合 Access 匯入精靈進行 CSV/Excel 匯入
'   - 管理 JE 和 TB 的欄位映射
'   - 處理金額欄位計算邏輯（3種 JE 模式、4種 TB 模式）
'   - 動態新增和更新欄位
'
' Dependencies:
'   - ContextManager (提供 DbAccess, DbSchema, Logger)
'   - Access.Application (用於匯入精靈)
'===============================================================================

Private m_Context As Object  ' ContextManager
Private m_Db As Object       ' DbAccess
Private m_Schema As Object   ' DbSchema
Private m_DataType As String ' "excel" or "csv"

'===============================================================================
' Initialization
'===============================================================================

Public Sub Initialize(ByVal context As Object)
    '初始化服務
    Set m_Context = context
    Set m_Db = context.DbAccess
    Set m_Schema = context.DbSchema
    m_DataType = "excel"  ' 預設為 Excel
End Sub

'===============================================================================
' Import Wizard Integration
'===============================================================================

Public Sub OpenWizard(ByVal target As String)
    '---------------------------------------------------------------------------
    ' 使用 Access 匯入精靈進行資料匯入
    ' 參數:
    '   target: "je" 或 "tb" 指定匯入目標
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    If m_Db Is Nothing Then
        m_Context.Logger.LogError "No database connection"
        Exit Sub
    End If
    
    '儲存匯入前的資料表列表
    Dim oldTables As New Collection
    Dim dbs As DAO.Database
    Set dbs = m_Db.Database
    
    Dim tdf As DAO.TableDef
    For Each tdf In dbs.TableDefs
        If IsUserTable(tdf.Name) Then
            oldTables.Add Array(tdf.Name, tdf.LastUpdated)
        End If
    Next tdf
    
    '開啟 Access 匯入精靈
    Dim aceApp As Object
    Set aceApp = CreateObject("Access.Application")
    
    aceApp.OpenCurrentDatabase m_Db.Path, False
    
    '根據資料類型執行對應的匯入命令
    Select Case LCase(m_DataType)
        Case "excel"
            aceApp.DoCmd.RunCommand 2521  ' acCmdImportAttachExcel
        Case "csv"
            aceApp.DoCmd.RunCommand 2522  ' acCmdImportAttachText
        Case Else
            m_Context.Logger.LogError "Unsupported data type: " & m_DataType
            GoTo Cleanup
    End Select
    
    '等待使用者完成匯入
    Do While aceApp.CurrentProject.AllTables.Count = 0
        DoEvents
    Loop
    
    '辨識新匯入或更新的資料表
    Dim newTables As New Collection
    Dim found As Boolean
    Dim timeChanged As Boolean
    Dim i As Long
    
    For Each tdf In dbs.TableDefs
        If IsUserTable(tdf.Name) Then
            found = False
            timeChanged = False
            
            '檢查是否為新表或更新的表
            For i = 1 To oldTables.Count
                Dim oldInfo As Variant
                oldInfo = oldTables(i)
                
                If tdf.Name = oldInfo(0) Then
                    found = True
                    If tdf.LastUpdated <> oldInfo(1) Then
                        timeChanged = True
                    End If
                    Exit For
                End If
            Next i
            
            If Not found Or timeChanged Then
                newTables.Add tdf.Name
            End If
        End If
    Next tdf
    
    '處理匯入結果
    If newTables.Count = 1 Then
        Dim importedTable As String
        importedTable = newTables(1)
        
        '根據 target 重新命名或設定 schema
        Select Case LCase(target)
            Case "je"
                m_Schema.JE.Name = importedTable
                m_Context.Logger.LogInfo "JE table imported: " & importedTable
            Case "tb"
                m_Schema.TB.Name = importedTable
                m_Context.Logger.LogInfo "TB table imported: " & importedTable
        End Select
    ElseIf newTables.Count = 0 Then
        m_Context.Logger.LogInfo "No tables detected (user may have cancelled)"
    Else
        m_Context.Logger.LogInfo "Multiple tables detected: " & newTables.Count
    End If
    
    m_Db.Refresh
    
Cleanup:
    '關閉 Access
    If Not aceApp Is Nothing Then
        aceApp.CloseCurrentDatabase
        aceApp.Quit
        Set aceApp = Nothing
    End If
    
    Exit Sub
    
ErrorHandler:
    m_Context.Logger.LogError "OpenWizard failed", Err.Number
    Resume Cleanup
End Sub

'===============================================================================
' Field Mapping Application
'===============================================================================

Public Function ApplyJe(ByVal fieldMap As Object, Optional ByVal amountMethod As Long = 1) As Boolean
    '---------------------------------------------------------------------------
    ' 套用 JE 欄位映射並處理金額
    ' 參數:
    '   fieldMap: Dictionary 物件，key=邏輯欄位名, value=實際欄位名
    '   amountMethod: 金額處理方式 (1=直接使用, 2=借貸分開, 3=依借貸別)
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ApplyJe = False
    
    '套用欄位映射到 Schema
    Dim key As Variant
    For Each key In fieldMap.Keys
        m_Schema.JE.SetField CStr(key), CStr(fieldMap(key))
    Next key
    
    '設定金額處理方式
    m_Schema.JE.Method = amountMethod
    
    '處理金額欄位
    If Not ProcessJeAmount(amountMethod) Then
        m_Context.Logger.LogError "JE amount processing failed"
        Exit Function
    End If
    
    m_Context.Logger.LogInfo "JE field mapping applied successfully"
    m_Schema.JE.PrintFields
    
    ApplyJe = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "ApplyJe failed", Err.Number
    ApplyJe = False
End Function

Public Function ApplyTb(ByVal fieldMap As Object, Optional ByVal amountMethod As Long = 1) As Boolean
    '---------------------------------------------------------------------------
    ' 套用 TB 欄位映射並處理金額
    ' 參數:
    '   fieldMap: Dictionary 物件
    '   amountMethod: 金額處理方式 (1=變動金額, 2=期末-期初, 3=借-貸, 4=複雜計算)
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ApplyTb = False
    
    '套用欄位映射
    Dim key As Variant
    For Each key In fieldMap.Keys
        m_Schema.TB.SetField CStr(key), CStr(fieldMap(key))
    Next key
    
    '設定金額處理方式
    m_Schema.TB.Method = amountMethod
    
    '處理金額欄位
    If Not ProcessTbAmount(amountMethod) Then
        m_Context.Logger.LogError "TB amount processing failed"
        Exit Function
    End If
    
    m_Context.Logger.LogInfo "TB field mapping applied successfully"
    m_Schema.TB.PrintFields
    
    ApplyTb = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "ApplyTb failed", Err.Number
    ApplyTb = False
End Function

'===============================================================================
' Amount Processing - JE
'===============================================================================

Private Function ProcessJeAmount(ByVal amountMethod As Long) As Boolean
    '---------------------------------------------------------------------------
    ' JE 金額處理邏輯
    ' Mode 1: 直接使用單一金額欄位
    ' Mode 2: 分別使用借方和貸方欄位，計算 Amount = Debit - Credit
    ' Mode 3: 依借貸別欄位決定金額正負號
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ProcessJeAmount = False
    
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim sql As String
    
    Set dbs = m_Db.Database
    Set tdf = dbs.TableDefs(m_Schema.JE.Name)
    
    m_Context.Logger.LogInfo "Processing JE amount (Mode " & amountMethod & ")"
    
    Select Case amountMethod
        Case 1  '直接使用原始金額欄位
            '新增標準化金額欄位
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.JeAmount, dbCurrency)
            tdf.Fields.Append fld
            
            '複製金額
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.JeAmount & "] = " & _
                  SanitizeNumericField(m_Schema.JE.Amount) & ";"
            m_Db.ExecuteNonQuery sql
            
        Case 2  '借方 - 貸方
            '新增標準化金額欄位
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.JeAmount, dbCurrency)
            tdf.Fields.Append fld
            
            '計算 Amount = Debit - Credit
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.JeAmount & "] = " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.JE.DebitAmount) & " - " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.JE.CreditAmount) & ";"
            m_Db.ExecuteNonQuery sql
            
            '新增借貸別欄位
            Call AddDebitCreditField(amountMethod)
            
        Case 3  '依借貸別決定正負號
            '新增標準化金額欄位
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.JeAmount, dbCurrency)
            tdf.Fields.Append fld
            
            '根據借貸別設定正負號
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.JeAmount & "] = " & vbCrLf & _
                  "    IIF([" & m_Schema.JE.DrCr & "] = '借' OR [" & m_Schema.JE.DrCr & "] = 'D', " & vbCrLf & _
                  "        " & SanitizeNumericField(m_Schema.JE.Amount) & ", " & vbCrLf & _
                  "        -" & SanitizeNumericField(m_Schema.JE.Amount) & ");"
            m_Db.ExecuteNonQuery sql
            
            '新增借貸別欄位
            Call AddDebitCreditField(amountMethod)
            
        Case Else
            m_Context.Logger.LogError "Unsupported JE amount method: " & amountMethod
            Exit Function
    End Select
    
    ProcessJeAmount = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "ProcessJeAmount failed", Err.Number
    ProcessJeAmount = False
End Function

'===============================================================================
' Amount Processing - TB
'===============================================================================

Private Function ProcessTbAmount(ByVal amountMethod As Long) As Boolean
    '---------------------------------------------------------------------------
    ' TB 金額處理邏輯
    ' Mode 1: 直接使用變動金額
    ' Mode 2: 期末 - 期初
    ' Mode 3: 借方變動 - 貸方變動
    ' Mode 4: (期末借-期初借) - (期末貸-期初貸)
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    
    ProcessTbAmount = False
    
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim sql As String
    
    Set dbs = m_Db.Database
    Set tdf = dbs.TableDefs(m_Schema.TB.Name)
    
    m_Context.Logger.LogInfo "Processing TB amount (Mode " & amountMethod & ")"
    
    Select Case amountMethod
        Case 1  '直接使用變動金額
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.TbAmount, dbCurrency)
            tdf.Fields.Append fld
            
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.TbAmount & "] = " & _
                  SanitizeNumericField(m_Schema.TB.ChangeAmount) & ";"
            m_Db.ExecuteNonQuery sql
            
        Case 2  '期末餘額 - 期初餘額
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.TbAmount, dbCurrency)
            tdf.Fields.Append fld
            
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.ClosingBalance) & " - " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.OpeningBalance) & ";"
            m_Db.ExecuteNonQuery sql
            
        Case 3  '借方變動 - 貸方變動
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.TbAmount, dbCurrency)
            tdf.Fields.Append fld
            
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.DebitAmount) & " - " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.CreditAmount) & ";"
            m_Db.ExecuteNonQuery sql
            
        Case 4  '(期末借-期初借) - (期末貸-期初貸)
            Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.TbAmount, dbCurrency)
            tdf.Fields.Append fld
            
            sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
                  "SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  "    (" & SanitizeNumericField(m_Schema.TB.ClosingDebitBalance) & " - " & _
                  SanitizeNumericField(m_Schema.TB.OpeningDebitBalance) & ") - " & vbCrLf & _
                  "    (" & SanitizeNumericField(m_Schema.TB.ClosingCreditBalance) & " - " & _
                  SanitizeNumericField(m_Schema.TB.OpeningCreditBalance) & ");"
            m_Db.ExecuteNonQuery sql
            
        Case Else
            m_Context.Logger.LogError "Unsupported TB amount method: " & amountMethod
            Exit Function
    End Select
    
    ProcessTbAmount = True
    Exit Function
    
ErrorHandler:
    m_Context.Logger.LogError "ProcessTbAmount failed", Err.Number
    ProcessTbAmount = False
End Function

'===============================================================================
' Helper Methods
'===============================================================================

Private Sub AddDebitCreditField(ByVal amountMethod As Long)
    '新增借貸別識別欄位
    On Error Resume Next
    
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim sql As String
    
    Set dbs = m_Db.Database
    Set tdf = dbs.TableDefs(m_Schema.JE.Name)
    
    '建立借貸別欄位
    Set fld = CreateOrReplaceField(tdf, m_Schema.Fields.JeDrCr, dbText, 1)
    tdf.Fields.Append fld
    
    '根據金額正負設定借貸別
    sql = "UPDATE [" & tdf.Name & "] " & vbCrLf & _
          "SET [" & m_Schema.Fields.JeDrCr & "] = " & _
          "IIF([" & m_Schema.Fields.JeAmount & "] >= 0, 'D', 'C');"
    m_Db.ExecuteNonQuery sql
    
    m_Context.Logger.LogInfo "Debit/Credit field added"
End Sub

Private Function CreateOrReplaceField(ByRef tdf As DAO.TableDef, _
                                     ByVal fieldName As String, _
                                     ByVal fieldType As DAO.DataTypeEnum, _
                                     Optional ByVal fieldSize As Long = 0) As DAO.Field
    '建立或取代欄位
    On Error Resume Next
    
    '嘗試刪除現有欄位
    tdf.Fields.Delete fieldName
    Err.Clear
    
    '建立新欄位
    Set CreateOrReplaceField = tdf.CreateField(fieldName, fieldType, fieldSize)
    
    On Error GoTo 0
End Function

'===============================================================================
' Properties
'===============================================================================

Public Property Let DataType(ByVal value As String)
    '設定匯入資料類型 ("excel" or "csv")
    m_DataType = LCase(value)
End Property

Public Property Get DataType() As String
    DataType = m_DataType
End Property

'===============================================================================
' Cleanup
'===============================================================================

Private Sub Class_Terminate()
    Set m_Context = Nothing
    Set m_Db = Nothing
    Set m_Schema = Nothing
End Sub
