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
'Class:ServiceImport
'負責匯入資料，使用 Access 精靈匯入
Private db As DbAccess
Private je As EntityJe
Private tb As EntityTb
Private m_Ace As New Access.Application
Private m_DataType As String
Private m_Method As Long

Public Property Let dType(ByVal Value As String)
    m_DataType = Value
    Debug.Print "Type: " & m_DataType
End Property

Public Sub Initialize(context As ContextManager)
    Set db = context.DbInput
    Set je = context.je
    Set tb = context.tb
End Sub

Public Sub OpenWizard(ByVal target As String)
    ' ============================================================================
    ' 方法: 使用 Access 的操作精靈來匯入資料
    ' 參數:
    '    - target: 定義匯入的目標是 JE 還是 TB
    ' ============================================================================
    Dim oldTables As New Collection
    Dim oldTimes As New Collection
    Dim newTables As New Collection
    Dim tdf As Object, i As Long, found As Boolean, timeChanged As Boolean
    m_Ace.OpenCurrentDatabase db.path
    '記錄匯入前的表名稱和更新時間
    For Each tdf In m_Ace.CurrentDb.TableDefs
        If IsUserTable(tdf.name) Then
            oldTables.Add tdf.name
            oldTimes.Add tdf.LastUpdated
        End If
    Next tdf
    '依資料類型開啟匯入精靈
    Select Case LCase$(m_DataType)
        Case "xlsx"
            m_Ace.DoCmd.RunCommand acCmdImportAttachExcel
        Case "csv"
            m_Ace.DoCmd.RunCommand acCmdImportAttachText
        Case Else
            MsgBox "不支援的資料類型！", vbExclamation, "匯入程序"
    End Select
    '找出新建立或被覆寫的表
    For Each tdf In m_Ace.CurrentDb.TableDefs
        If IsUserTable(tdf.name) Then
            found = False
            timeChanged = False
            
            '檢查是否為新表或現有表被更新
            For i = 1 To oldTables.Count
                If oldTables.Item(i) = tdf.name Then
                    found = True
                    If oldTimes.Item(i) <> tdf.LastUpdated Then
                        timeChanged = True
                    End If
                    Exit For
                End If
            Next i
            '新表或時間變更的表都加入清單
            If Not found Or timeChanged Then
                newTables.Add tdf.name
            End If
        End If
    Next tdf
    '處理匯入結果
    If newTables.Count = 1 Then
        Select Case LCase$(target)
            Case "je"
                je.name = newTables.Item(1)
                Debug.Print "匯入/更新 JE 表：" & je.name
            Case "tb"
                tb.name = newTables.Item(1)
                Debug.Print "匯入/更新 TB 表：" & tb.name
        End Select
        '對匯入的資料表加入後綴
        Call AddFieldSuffix(newTables.Item(1), target)
    ElseIf newTables.Count = 0 Then
        Debug.Print "沒有偵測到新表或更新，可能是使用者取消操作"
    Else
        Debug.Print "偵測到多個新表或更新：" & newTables.Count
    End If
    '等待並刷新資料庫狀態
    Application.Wait Now + TimeValue("00:00:01")
    db.RefreshSchema
    '退出 Access 程式
    m_Ace.CloseCurrentDatabase
    m_Ace.Quit
    Set m_Ace = Nothing
End Sub

Public Function ApplyJe(ByVal dict As Dictionary) As Boolean
    ' ============================================================================
    ' 方法: 將 JE 欄位設給資料實體
    ' 參數:
    '   - dict: 將表單傳入的參數設給資料實體
    ' ============================================================================
    On Error GoTo ErrorHandler
    ApplyJe = False
    Dim key As Variant
    For Each key In dict.Keys
        je.SetField key, dict(key)
    Next key
    je.PrintFields
    '@TEMP: 臨時映射識別碼欄位
    Dim uid As String
    uid = "識別碼_" & je.name
    je.SetField "UID", uid
    '@TODO: 檢查欄位型別
    If Not ProcessJeAmount(je.Method) Then
        'error
        Debug.Print "********** JE 欄位映射及金額處理失敗 **********"
    Else
        'pass
        Debug.Print "********** JE 欄位映射及金額處理成功 **********"
    End If
    ApplyJe = True
    Exit Function
ErrorHandler:
    Debug.Print "ApplyJe 發生錯誤: " & Err.Number & " - " & Err.Description
    ApplyJe = False
    Resume Next
End Function

Public Function ApplyTb(ByVal dict As Dictionary) As Boolean
    ' ============================================================================
    ' 方法: 將 TB 欄位設給資料實體
    ' 參數:
    '    - dict: 將表單傳入的參數設給資料實體
    ' ============================================================================
    ApplyTb = False
    '將TB欄位設給資料實體
    Dim key As Variant
    For Each key In dict.Keys
        tb.SetField key, dict(key)
    Next key
    tb.PrintFields
    '@TODO: 檢查欄位型別
    If Not ProcessTbAmount(tb.Method) Then
        'error
        Debug.Print "********** TB 欄位映射及金額處理失敗 **********"
    Else
        'pass
        Debug.Print "********** TB 欄位映射及金額處理成功 **********"
    End If
    ApplyTb = True
End Function

'***** 自訂
Private Function ProcessJeAmount(ByVal amountMethod As Long) As Boolean
    ' ============================================================================
    ' 方法: 金額處理邏輯
    ' 參數:
    '    - amountMethod: 金額處理的方法，以數字區別四種模式
    ' ============================================================================
    On Error GoTo ErrorHandler
    ProcessJeAmount = False
    Dim sql As String
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(je.name)
    Debug.Print "********** 開始 JE 金額處理 **********"
    Select Case amountMethod
        Case 1 '直接使用原始金額欄位
            Set fld = CreateOrReplace(tdf, je.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.name & " " & _
                  "SET [" & je.K_Amount & "] = " & vbCrLf & _
                  "CDbl(" & Nz(je.Amount) & ");"
            db.ExecuteNonQuery sql
            
        Case 2 '傳票金額 = 借方金額 - 貸方金額
            Set fld = CreateOrReplace(tdf, je.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.name & " " & _
                  "SET [" & je.K_Amount & "] = " & vbCrLf & _
                  "CDbl(" & Nz(je.DebitAmount) & ") - CDbl(" & Nz(je.CreditAmount) & ");"
            db.ExecuteNonQuery sql
            
        Case 3 '依借貸別決定金額正負號
            Set fld = CreateOrReplace(tdf, je.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE [" & tdf.name & "] " & _
                  "SET [" & je.K_Amount & "] = " & vbCrLf & _
                  "IIF(" & vbCrLf & _
                  "  [" & je.DrCr & "] = """ & je.IsDebit & """, " & vbCrLf & _
                  "  CDbl(" & Nz(je.Amount) & ")," & vbCrLf & _
                  "  CDbl(" & Nz(je.Amount) & ") * -1" & vbCrLf & _
                  ");"
            db.ExecuteNonQuery sql
            
        Case Else
            Debug.Print "不支援的金額處理方式: " & CStr(amountMethod)
            Exit Function
    End Select
    Application.Wait Now + TimeValue("00:00:01")
    ProcessJeAmount = True
    Exit Function
    
ErrorHandler:
    Debug.Print "ProcessJeAmount 發生錯誤:"
    Debug.Print "  - 錯誤代碼: " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    ProcessJeAmount = False
End Function

Private Function ProcessTbAmount(ByVal amountMethod As Long) As Boolean
    On Error GoTo ErrorHandler
    ProcessTbAmount = False
    Dim sql As String
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(tb.name)
    Debug.Print "********** 開始 TB 金額處理 **********"
    Select Case amountMethod
        Case 1
            '直接使用變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.name & " " & _
                  "SET [" & tb.K_Amount & "] = " & vbCrLf & _
                  "CDbl(" & Nz(tb.ChangeAmount) & ");"
            db.ExecuteNonQuery sql
            
        Case 2
            '期末 - 期初 = 變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.name & " " & _
                  "SET [" & tb.K_Amount & "] = " & vbCrLf & _
                  "CDbl(" & Nz(tb.ClosingBalance) & ") - CDbl(" & Nz(tb.OpeningBalance) & ");"
            db.ExecuteNonQuery sql
            
        Case 3
            '借方 - 貸方 = 變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.name & " " & _
                  "SET [" & tb.K_Amount & "] = " & vbCrLf & _
                  "CDbl(" & Nz(tb.DebitAmount) & ") - CDbl(" & Nz(tb.CreditAmount) & ");"
            db.ExecuteNonQuery sql
            
        Case 4
            '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.name & " " & _
                  "SET [" & tb.K_Amount & "] = " & vbCrLf & _
                  "(CDbl(" & Nz(tb.ClosingDebitBalance) & ") - CDbl(" & Nz(tb.OpeningCreditBalance) & ")) - " & vbCrLf & _
                  "(CDbl(" & Nz(tb.OpeningDebitBalance) & ") - CDbl(" & Nz(tb.OpeningCreditBalance) & "));"
            db.ExecuteNonQuery sql
            
        Case Else
            Debug.Print "不支援的金額處理方式:" & CStr(amountMethod)
            Exit Function
    End Select
    Application.Wait Now + TimeValue("00:00:01")
    ProcessTbAmount = True
    
    Exit Function
    
ErrorHandler:
    Debug.Print "ProcessTbAmount 發生錯誤:"
    Debug.Print "  - 錯誤代碼: " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    ProcessTbAmount = False
End Function

Private Function AddLineItem(ByVal tableName As String, ByVal fieldGroupby As String, ByVal fieldLineItem As String) As Boolean
    '逐筆增加分錄項次
    Dim db As Database
    Dim rs As Recordset
End Function
    

Private Sub AddFieldSuffix(ByVal tableName As String, suffix As String)
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim oldName As String
    Dim newName As String
    Set dbs = m_Ace.CurrentDb
    Set tdf = dbs.TableDefs(tableName)
    '逐一重新命名欄位
    For Each fld In tdf.Fields
        oldName = fld.name
        newName = oldName & "_" & UCase(suffix)
        fld.name = newName
    Next fld
End Sub

Private Function IsUserTable(ByVal tableName As String) As Boolean
    '排除系統表和例外
    Dim name As String
    name = LCase$(tableName)
    '直接判斷是否為使用者表（排除系統表和例外情況）
    IsUserTable = Not (Left$(name, 4) = "msys" Or _
                      Left$(tableName, 1) = "~" Or _
                      InStr(1, tableName, "匯入錯誤") > 0)
End Function

Private Function CreateOrReplace(tdf As DAO.TableDef, fieldName As String) As DAO.Field
    '若欄位存在則刪除
    If db.FieldExists(tdf, fieldName) Then
        tdf.Fields.Delete fieldName
    End If
    '建立欄位且型別為 CURRENCY
    Set CreateOrReplace = tdf.CreateField(fieldName, dbCurrency)
End Function

