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
' Class:    ServiceImport
' Purpose:  負責匯入資料，使用 Access 精靈匯入
' Methods:  OpenWizard, ApplyJe, ApplyTb, ProcessJeAmount, ProcessTbAmount,
'           AddLineItem, AddFieldSuffix, IsUserTable, CreateOrReplace
'===============================================================================
Private db As DbAccess
Private m_Schema As DbSchema
Private m_Ace As New Access.Application
Private m_DataType As String
Private m_Method As Long

Public Property Let dType(ByVal Value As String)
    m_DataType = Value
    Debug.Print "Type: " & m_DataType
End Property

Public Sub Initialize(context As ContextManager)
    Set db = context.DbInput
    Set m_Schema = context.DbSchema
End Sub


Public Sub OpenWizard(ByVal target As String)
    '---------------------------------------------------------------------------
    ' 方法: 使用 Access 的操作精靈來匯入資料
    ' 參數:
    '    - target: 定義匯入的目標是 JE 還是 TB
    '---------------------------------------------------------------------------
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
        Case "xlsx"
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
                If oldTables.item(i) = tdf.Name Then
                    found = True
                    If oldTimes.item(i) <> tdf.LastUpdated Then
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
                m_Schema.JE.Name = newTables.item(1)
                Debug.Print "匯入/更新 JE 表：" & m_Schema.JE.Name
            Case "tb"
                m_Schema.TB.Name = newTables.item(1)
                Debug.Print "匯入/更新 TB 表：" & m_Schema.TB.Name
        End Select
        '對匯入的資料表加入後綴
        Call AddFieldSuffix(newTables.item(1), target)
    ElseIf newTables.Count = 0 Then
        Debug.Print "沒有偵測到新表或更新，可能是使用者取消操作"
    Else
        Debug.Print "偵測到多個新表或更新：" & newTables.Count
    End If
    db.Refresh
    '退出 Access 程式
    m_Ace.CloseCurrentDatabase
    m_Ace.Quit
    Set m_Ace = Nothing
End Sub

Public Function ApplyJe(ByVal dict As Dictionary) As Boolean
    '---------------------------------------------------------------------------
    ' 方法: 將 JE 欄位設給資料實體
    ' 參數:
    '   - dict: 將表單傳入的參數設給資料實體
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    ApplyJe = False
    Dim key As Variant
    For Each key In dict.Keys
        m_Schema.JE.SetField key, dict(key)
    Next key
    m_Schema.JE.PrintFields
    '//NOTE: 臨時映射識別碼欄位
    Dim UID As String
    UID = "識別碼_" & m_Schema.JE.Name
    m_Schema.JE.SetField "UID", UID
    '//TODO: 檢查欄位型別
    If Not ProcessJeAmount(m_Schema.JE.Method) Then
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
    Resume Next
End Function

Public Function ApplyTb(ByVal dict As Dictionary) As Boolean
    '---------------------------------------------------------------------------
    ' 方法: 將 TB 欄位設給資料實體
    ' 參數:
    '    - dict: 將表單傳入的參數設給資料實體
    '---------------------------------------------------------------------------
    ApplyTb = False
    '將TB欄位設給資料實體
    Dim key As Variant
    For Each key In dict.Keys
        m_Schema.TB.SetField key, dict(key)
    Next key
    m_Schema.TB.PrintFields
    '//TODO: 檢查欄位型別
    If Not ProcessTbAmount(m_Schema.TB.Method) Then
        'error
        Debug.Print "********** TB 欄位映射及金額處理失敗 **********"
    Else
        'pass
        Debug.Print "********** TB 欄位映射及金額處理成功 **********"
    End If
    ApplyTb = True
End Function

'-- 自訂
Private Function ProcessJeAmount(ByVal amountMethod As Long) As Boolean
    '---------------------------------------------------------------------------
    ' 方法: 金額處理邏輯
    ' 參數:
    '    - amountMethod: 金額處理的方法，以數字區別四種模式
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    ProcessJeAmount = False
    '宣告物件
    Dim sql As String
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(m_Schema.JE.Name)
    Debug.Print "********** 開始 JE 金額處理 **********"
    Select Case amountMethod
        Case 1 '直接使用原始金額欄位
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.JeAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.JeAmount & "] = " & vbCrLf & _
                  SanitizeNumericField(m_Schema.JE.Amount) & ";"
            db.ExecuteNonQuery sql
            
        Case 2 '傳票金額 = 借方金額 - 貸方金額
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.JeAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.JeAmount & "] = " & vbCrLf & _
                  SanitizeNumericField(m_Schema.JE.DebitAmount) & " - " & vbCrLf & _
                  SanitizeNumericField(m_Schema.JE.CreditAmount) & ";"
            db.ExecuteNonQuery sql
            
        Case 3 '依借貸別決定金額正負號
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.JeAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.JeAmount & "] = " & vbCrLf & _
                  "IIF(" & vbCrLf & _
                  "    [" & m_Schema.JE.DrCr & "] = '" & m_Schema.JE.IsDebit & "', " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.JE.Amount) & "," & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.JE.Amount) & " * -1" & vbCrLf & _
                  ");"
            db.ExecuteNonQuery sql
            
        Case Else
            Debug.Print "不支援的金額處理方式: " & CStr(amountMethod)
            Exit Function
    End Select
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
    '宣告物件
    Dim sql As String
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Set dbs = db.Database
    Set tdf = dbs.TableDefs(m_Schema.TB.Name)
    Debug.Print "********** 開始 TB 金額處理 **********"
    Select Case amountMethod
        Case 1
            '直接使用變動金額
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.TbAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  SanitizeNumericField(m_Schema.TB.ChangeAmount) & ";"
            db.ExecuteNonQuery sql
            
        Case 2
            '期末 - 期初 = 變動金額
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.TbAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  SanitizeNumericField(m_Schema.TB.ClosingBalance) & " - " & vbCrLf & _
                  SanitizeNumericField(m_Schema.TB.OpeningBalance) & ";"
            db.ExecuteNonQuery sql
            
        Case 3
            '借方 - 貸方 = 變動金額
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.TbAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  SanitizeNumericField(m_Schema.TB.DebitAmount) & " - " & vbCrLf & _
                  SanitizeNumericField(m_Schema.TB.CreditAmount) & ";"
            db.ExecuteNonQuery sql
            
        Case 4
            '(期末借方-期初借方) - (期末貸方-期初貸方) = 變動金額
            Set fld = CreateOrReplace(tdf, m_Schema.Fields.TbAmount)
            tdf.Fields.Append fld
            sql = "UPDATE " & tdf.Name & " SET [" & m_Schema.Fields.TbAmount & "] = " & vbCrLf & _
                  "(" & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.ClosingDebitBalance) & " - " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.OpeningDebitBalance) & vbCrLf & _
                  ") - " & vbCrLf & _
                  "(" & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.ClosingCreditBalance) & " - " & vbCrLf & _
                  "    " & SanitizeNumericField(m_Schema.TB.OpeningCreditBalance) & vbCrLf & _
                  ");"
            db.ExecuteNonQuery sql
            
        Case Else
            Debug.Print "不支援的金額處理方式:" & CStr(amountMethod)
            Exit Function
    End Select
    ProcessTbAmount = True
    Exit Function
ErrorHandler:
    Debug.Print "ProcessTbAmount 發生錯誤:"
    Debug.Print "  - 錯誤代碼: " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    ProcessTbAmount = False
End Function

Public Function ImportFromSheet( _
    ByVal ws As Worksheet, _
    ByVal dataRange As String, _
    ByVal fieldTypes As Variant, _
    Optional ByVal fieldNames As Variant _
) As DAO.Recordset
    '---------------------------------------------------------------------------
    ' 通用方法：從工作表範圍匯入資料至 Access 暫存表
    ' 目的:
    '   將 Excel 工作表轉換為 Access 資料表，供後續業務邏輯處理。
    '   此方法支援自動偵測欄位名稱或使用自訂欄位名稱，並強制指定欄位型別以確保
    '   資料完整性。適用於 Holidays/MakeUpDays/CustomData 等各類工作表匯入需求。
    '
    ' 參數說明:
    '   ws              - [必要] 來源工作表物件
    '                     範例: HolidaySheet, MakeupDaySheet
    '
    '   dataRange       - [必要] 資料範圍（含標題列或純資料區域）
    '                     格式: "A1:B100" 或 "A2:C50"（若 fieldNames 已提供則不含標題列）
    '
    '   fieldTypes      - [必要] 欄位型別陣列，定義每個欄位的 Access 資料型別
    '                     支援型別: "DATE", "TEXT(n)", "SHORT", "LONG", "CURRENCY", "YESNO"
    '                     範例: Array("DATE", "TEXT(50)", "YESNO")
    '
    '   fieldNames      - [選填] 自訂欄位名稱陣列（若不提供則從 dataRange 第 1 列讀取）
    '                     範例: Array("Date", "Description", "IsActive")
    '                     用途: 當工作表無標題列或需重新命名欄位時使用
    '
    ' 回傳值:
    '   DAO.Recordset   - 指向暫存表的記錄集（已開啟且可直接遍歷）
    '                     失敗時回傳 Nothing
    ' 使用範例:
    '   ' 範例 1: 從工作表自動偵測欄位名稱
    '   Dim types As Variant
    '   types = Array("DATE", "TEXT(50)")
    '   Set rs = importer.ImportFromSheet(HolidaySheet, "A1:B100", types)
    '   ' → 將 A1:B100 匯入，A1/B1 為欄位名稱，A2:B100 為資料
    '
    '   ' 範例 2: 使用自訂欄位名稱（工作表無標題列）
    '   Dim names As Variant, types As Variant
    '   names = Array("Date", "Description")
    '   types = Array("DATE", "TEXT(100)")
    '   Set rs = importer.ImportFromSheet(MakeupDaySheet, "A2:B50", types, names)
    '   ' → 將 A2:B50 匯入，欄位名稱為 Date/Description
    '
    '   ' 範例 3: 混合型別（日期 + 文字 + 布林 + 數字）
    '   Dim types As Variant
    '   types = Array("DATE", "TEXT(50)", "YESNO", "LONG")
    '   Set rs = importer.ImportFromSheet(CustomSheet, "A1:D100", types)
    '
    ' 錯誤處理:
    '   - fieldNames 與 fieldTypes 數量不符 → 拋出錯誤 514
    '   - fieldTypes 與實際欄位數量不符 → 拋出錯誤 514
    '   - 日期格式錯誤 → 該儲存格寫入 NULL
    '   - SQL 執行失敗 → 回傳 Nothing
    '---------------------------------------------------------------------------
    On Error GoTo ErrorHandler
    Dim rng As Range
    Dim headerRow As Range
    Dim dataRows As Range
    Dim sql As String
    Dim i As Long
    Dim colCount As Long
    Dim useCustomNames As Boolean
    
    '-- 刪除既有暫存表
    If db.TableExists(TBL_TEMP) Then
        db.DropTable TBL_TEMP
        Debug.Print "  - 已刪除暫存表 " & TBL_TEMP
    End If
    
    '-- 界定工作表匯入欄位範圍
    Set rng = ws.Range(dataRange)
    useCustomNames = IsArray(fieldNames)
    If useCustomNames Then
        colCount = UBound(fieldNames) - LBound(fieldNames) + 1
        If (UBound(fieldTypes) - LBound(fieldTypes) + 1) <> colCount Then
            Err.Raise vbObjectError + 514, "ImportFromSheet", "fieldNames 與 fieldTypes 數量不符"
        End If
    Else
        Set headerRow = rng.Rows(1)
        colCount = headerRow.Columns.Count
        If (UBound(fieldTypes) - LBound(fieldTypes) + 1) <> colCount Then
            Err.Raise vbObjectError + 514, "ImportFromSheet", "fieldTypes 數量與欄位數量不符"
        End If
    End If
    
    '-- 資料表創建字串
    sql = "CREATE TABLE [" & TBL_TEMP & "] ("
    For i = 1 To colCount
        Dim colName As String
        If useCustomNames Then
            colName = CStr(fieldNames(LBound(fieldNames) + i - 1))
        Else
            colName = Trim$(CStr(headerRow.Cells(1, i).Value))
            If colName = "" Then colName = "Field" & i
        End If
        sql = sql & "[" & colName & "] " & fieldTypes(LBound(fieldTypes) + i - 1)
        If i < colCount Then sql = sql & ", "
    Next i
    sql = sql & ");"
    db.ExecuteNonQuery sql
    
    '-- 界定工作表匯入資料範圍
    If useCustomNames Then
        Set dataRows = rng
    ElseIf rng.Rows.Count > 1 Then
        Set dataRows = rng.Offset(1, 0).Resize(rng.Rows.Count - 1, colCount)
    End If
    If Not dataRows Is Nothing Then
        Dim row As Range
        '-- 每筆資料做一次 INSERT
        For Each row In dataRows.Rows
            Dim allBlank As Boolean
            allBlank = True
            sql = "INSERT INTO [" & TBL_TEMP & "] VALUES ("
            For i = 1 To colCount
                Dim cellValue As Variant
                cellValue = row.Cells(1, i).Value
                If Not IsNull(cellValue) Then
                    If Trim$(CStr(cellValue)) <> "" Then allBlank = False
                End If
                If IsNull(cellValue) Or Trim$(CStr(cellValue)) = "" Then
                    sql = sql & "NULL"
                ElseIf InStr(1, fieldTypes(LBound(fieldTypes) + i - 1), "DATE", vbTextCompare) > 0 Then
                    If IsDate(cellValue) Then
                        sql = sql & "#" & Format(CDate(cellValue), "mm/dd/yyyy") & "#"
                    Else
                        sql = sql & "NULL"
                    End If
                ElseIf InStr(1, fieldTypes(LBound(fieldTypes) + i - 1), "TEXT", vbTextCompare) > 0 Then
                    sql = sql & "'" & Replace(CStr(cellValue), "'", "''") & "'"
                Else
                    sql = sql & cellValue
                End If
                If i < colCount Then sql = sql & ", "
            Next i
            sql = sql & ");"
            If Not allBlank Then db.ExecuteNonQuery sql
        Next row
    End If
    
    '-- 將更新完的日期維度表傳回為記錄集
    Set ImportFromSheet = db.ExecuteQuery("SELECT * FROM [" & TBL_TEMP & "];")
    
    '-- 確認記錄集狀態
    If Not ImportFromSheet Is Nothing Then
        If Not ImportFromSheet.EOF Then
            If ImportFromSheet.recordCount = -1 Then ImportFromSheet.MoveLast
            Debug.Print "  - [" & TBL_TEMP & "] 已匯入 " & ImportFromSheet.recordCount & " 筆資料"
            ImportFromSheet.MoveFirst
        Else
            Debug.Print "  - [" & TBL_TEMP & "]" & TBL_TEMP & " 無資料"
            ImportFromSheet.Close
        End If
    End If
    Exit Function
ErrorHandler:
    Debug.Print "ImportFromSheet(): " & Err.Number & " - " & Err.Description
    Set ImportFromSheet = Nothing
End Function

Private Function AddLineItem( _
    ByVal tableName As String, _
    ByVal fieldGroupby As String, _
    ByVal fieldLineItem As String _
) As Boolean
    '---------------------------------------------------------------------------
    '逐筆增加分錄項次
    '---------------------------------------------------------------------------
    Dim db As Database
    Dim rs As Recordset
    '//TODO:增加項次欄位
End Function
    

Private Sub AddFieldSuffix( _
    ByVal tableName As String, _
    suffix As String _
)
    '---------------------------------------------------------------------------
    ' 新增欄位後綴字以辨別 _JE 或 _TB
    '---------------------------------------------------------------------------
    Dim dbs As DAO.Database
    Dim tdf As DAO.TableDef
    Dim fld As DAO.Field
    Dim oldName As String
    Dim newName As String
    Set dbs = m_Ace.CurrentDb
    Set tdf = dbs.TableDefs(tableName)
    For Each fld In tdf.Fields
        oldName = fld.Name
        newName = oldName & "_" & UCase(suffix)
        fld.Name = newName
    Next fld
End Sub

Private Function IsUserTable(ByVal tableName As String) As Boolean
    '---------------------------------------------------------------------------
    ' 判斷是否為使用者表
    '---------------------------------------------------------------------------
    Dim Name As String
    Name = LCase$(tableName)
    '排除系統表和例外情況
    IsUserTable = Not (Left$(Name, 4) = "msys" Or _
                      Left$(tableName, 1) = "~" Or _
                      InStr(1, tableName, "匯入錯誤") > 0)
End Function

Private Function CreateOrReplace( _
    tdf As DAO.TableDef, _
    fieldName As String _
) As DAO.Field
    '---------------------------------------------------------------------------
    ' 若欄位存在則刪除
    '---------------------------------------------------------------------------
    If db.FieldExists(tdf, fieldName) Then tdf.Fields.Delete fieldName
    '建立欄位且型別為 CURRENCY
    Set CreateOrReplace = tdf.CreateField(fieldName, dbCurrency)
End Function

