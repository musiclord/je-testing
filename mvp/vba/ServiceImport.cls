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

Public Property Let dType(ByVal value As String)
    m_DataType = value
End Property

Public Sub Initialize(context As ContextManager)
    Set db = context.DbInput
    Set je = context.je
    Set tb = context.tb
End Sub

Public Sub OpenWizard(ByVal target As String)
    '使用 Access 的匯入精靈來處理
    Dim oldTables As New Collection
    Dim oldTimes As New Collection
    Dim newTables As New Collection
    Dim tdf As Object, i As Long, found As Boolean, timeChanged As Boolean
    m_Ace.OpenCurrentDatabase db.path
    '記錄匯入前的表名稱和更新時間
    For Each tdf In m_Ace.CurrentDb.TableDefs
        If IsUserTable(tdf.Name) Then
            oldTables.Add tdf.Name
            oldTimes.Add tdf.LastUpdated
        End If
    Next tdf
    '依資料類型開啟匯入精靈
    Select Case LCase$(m_DataType)
        Case "excel"
            m_Ace.DoCmd.RunCommand acCmdImportAttachExcel
        Case "csv"
            m_Ace.DoCmd.RunCommand acCmdImportAttachText
        Case Else
            MsgBox "不支援的資料類型！", vbExclamation, "匯入程序"
    End Select
    '找出新建立或被覆寫的表
    For Each tdf In m_Ace.CurrentDb.TableDefs
        If IsUserTable(tdf.Name) Then
            found = False
            timeChanged = False
            
            '檢查是否為新表或現有表被更新
            For i = 1 To oldTables.Count
                If oldTables.Item(i) = tdf.Name Then
                    found = True
                    If oldTimes.Item(i) <> tdf.LastUpdated Then
                        timeChanged = True
                    End If
                    Exit For
                End If
            Next i
            '新表或時間變更的表都加入清單
            If Not found Or timeChanged Then
                newTables.Add tdf.Name
            End If
        End If
    Next tdf
    '處理匯入結果
    If newTables.Count = 1 Then
        Select Case LCase$(target)
            Case "je"
                je.Name = newTables.Item(1)
                Debug.Print "匯入/更新 JE 表：" & je.Name
            Case "tb"
                tb.Name = newTables.Item(1)
                Debug.Print "匯入/更新 TB 表：" & tb.Name
        End Select
    ElseIf newTables.Count = 0 Then
        Debug.Print "沒有偵測到新表或更新，可能是使用者取消操作"
    Else
        Debug.Print "偵測到多個新表或更新：" & newTables.Count
    End If
    Application.Wait Now + TimeValue("00:00:01")
    m_Ace.CloseCurrentDatabase
    m_Ace.Quit
    Set m_Ace = Nothing
End Sub

Public Function ApplyJe(ByVal dict As Dictionary) As Boolean
    On Error GoTo ErrorHandler
    ApplyJe = False
    
    '將 JE 欄位設給資料實體
    Dim key As Variant
    For Each key In dict.Keys
        je.SetField key, dict(key)
    Next key
    je.PrintFields
    
    '對欄位名稱添加後綴，避免欄位同名
    Call AddFieldSuffix(je.Name, "_JE")
    
    '@TODO: 檢查欄位型別
    If Not ProcessJeAmount(je.Method) Then
        'error
        Debug.Print "ProcessJeAmount = False"
    Else
        'pass
        Debug.Print "ProcessJeAMount = True"
    End If
    ApplyJe = True
    Exit Function
ErrorHandler:
    Debug.Print "ApplyJe 發生錯誤: " & Err.Number & " - " & Err.Description
    ApplyJe = False
    Resume Next
End Function

Public Function ApplyTb(ByVal dict As Dictionary) As Boolean
    ApplyTb = False
    
    '將TB欄位設給資料實體
    Dim key As Variant
    For Each key In dict.Keys
        tb.SetField key, dict(key)
    Next key
    tb.PrintFields
    
    '對欄位名稱添加後綴，避免欄位同名
    Call AddFieldSuffix(tb.Name, "_TB")
    
    '如果要避免欄位混淆，語法可以寫為
    'SELECT
    '  A.[Date]
    'FROM
    '  TableA AS A
    'LEFT JOIN TableB AS B
    '  ON A.[Date] = B.[Date]
    '另外，目前在 IDEA 中需要分別欄位的有: 科目名稱, 科目編號, 傳票號碼, 傳票金額, 變動金額
    '並且還需要考量新產生的欄位例如 _SUM 或 _DIFF 等
    '對此他們需要標準化ETL流程，統一所有需要計算的欄位名稱與型別
    
    '@TODO: 檢查欄位型別
    If Not ProcessTbAmount(tb.Method) Then
        'error
        Debug.Print "ProcessTbAmount = False"
    Else
        'pass
        Debug.Print "ProcessTbAmount = True"
    End If
    ApplyTb = True
End Function

'***** 自訂
Private Function ProcessJeAmount(ByVal amountMethod As Long) As Boolean
    On Error GoTo ErrorHandler
    ProcessJeAmount = False
    Dim expr As String
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(je.Name)
    Debug.Print "  - 資料表定義: " & tdf.Name
    
    Select Case amountMethod
        Case 1 '直接使用原始金額欄位
            Set fld = CreateOrReplace(tdf, je.K_Amount)
            expr = "CDbl(" & Nz(je.EntryAmount) & ")"
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "直接使用原始金額欄位"
            fld.Expression = expr
            tdf.Fields.Append fld
            
        Case 2 '傳票金額 = 借方金額 - 貸方金額
            Set fld = CreateOrReplace(tdf, je.K_Amount)
            expr = "CDbl(" & Nz(je.DebitAmount) & ") - CDbl(" & Nz(je.CreditAmount) & ")"
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "傳票金額 = 借方金額 - 貸方金額"
            fld.Expression = expr
            tdf.Fields.Append fld
            
        Case 3 '依借貸別決定金額正負號
            Set fld = CreateOrReplace(tdf, je.K_Amount)
            expr = "IIF(" & _
                   "    [" & je.DrCr & "] = """ & je.IsDebit & """, " & _
                   "    CDbl(" & Nz(je.EntryAmount) & ")," & _
                   "    CDbl(" & Nz(je.EntryAmount) & ") * -1" & _
                   ")"
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "依借貸別決定金額正負號"
            fld.Expression = expr
            tdf.Fields.Append fld
            
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
    Dim expr As String
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(tb.Name)
    Debug.Print "  - 資料表定義: " & tdf.Name
    
    Select Case amountMethod
        Case 1
            '直接使用變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            expr = "CDbl(" & Nz(tb.ChangeAmount) & ")"
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "直接使用變動金額"
            fld.Expression = expr
            tdf.Fields.Append fld
            
        Case 2
            '期末 - 期初 = 變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            expr = "CDbl(" & Nz(tb.ClosingBalance) & ") - CDbl(" & Nz(tb.OpeningBalance) & ")"
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "期末 - 期初 = 變動金額"
            fld.Expression = expr
            tdf.Fields.Append fld
            
        Case 3
            '借方 - 貸方 = 變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            expr = "" & Nz(tb.DebitAmount) & " - " & Nz(tb.CreditAmount) & ""
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "借方 - 貸方 = 變動金額"
            fld.Expression = expr
            tdf.Fields.Append fld
            
        Case 4
            '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
            Set fld = CreateOrReplace(tdf, tb.K_Amount)
            expr = "(CDbl(" & Nz(tb.ClosingDebitBalance) & ") - CDbl(" & Nz(tb.OpeningCreditBalance) & ")) - " & _
                   "(CDbl(" & Nz(tb.OpeningDebitBalance) & ") - CDbl(" & Nz(tb.OpeningCreditBalance) & "))"
            Debug.Print "  - 設定 Expression: " & expr
            Debug.Print "(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額"
            fld.Expression = expr
            tdf.Fields.Append fld
            
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

Private Sub AddFieldSuffix(ByVal tableName As String, suffix As String)
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim oldName As String
    Dim newName As String
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(tableName)
    '逐一重新命名欄位
    For Each fld In tdf.Fields
        oldName = fld.Name
        newName = oldName & suffix
        fld.Name = newName
    Next fld
End Sub
Private Function IsUserTable(ByVal tableName As String) As Boolean
    '排除系統表和例外
    Dim Name As String
    Name = LCase$(tableName)
    '直接判斷是否為使用者表（排除系統表和例外情況）
    IsUserTable = Not (Left$(Name, 4) = "msys" Or _
                      Left$(tableName, 1) = "~" Or _
                      InStr(1, tableName, "匯入錯誤") > 0)
End Function

Private Function CreateOrReplace(tdf As DAO.TableDef, fieldName As String) As DAO.Field
    If db.FieldExists(tdf, fieldName) Then
        tdf.Fields.Delete fieldName
    End If
    Set CreateOrReplace = tdf.CreateField(fieldName, dbCurrency)
End Function



