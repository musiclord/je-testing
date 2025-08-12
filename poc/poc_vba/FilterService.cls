VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FilterService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const MODULE_NAME As String = "FilterService"
Private m_AccessDAL As AccessDAL
Private m_MappingService As MappingService
Private m_GLTable As String ' Access 中 GL 資料的實際資料表名稱
Private m_TBTable As String ' Access 中 TB 資料的實際資料表名稱

Public Sub Initialize(ByVal dal As AccessDAL, ByVal ms As MappingService, ByVal glImportTableName As String, ByVal tbImportTableName As String)
    Const METHOD_NAME As String = "Initialize"
    On Error GoTo ErrorHandler

    Set m_AccessDAL = dal
    Set m_MappingService = ms
    m_GLTable = glImportTableName ' 使用傳入的 GL 資料表名稱
    m_TBTable = tbImportTableName ' 使用傳入的 TB 資料表名稱

    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 初始化成功，GL 資料表: " & m_GLTable & ", TB 資料表: " & m_TBTable
    Exit Sub
ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & ": " & Err.Description
    Err.Raise Err.Number, MODULE_NAME & "." & METHOD_NAME, Err.Description ' 將錯誤向上拋給呼叫者
End Sub

Public Function ApplyFilter(ByVal criteriaCollection As Collection, ByVal targetTableName As String) As Object ' ADODB.Recordset
    Const METHOD_NAME As String = "ApplyFilter"
    Dim sql As String
    Dim whereClause As String
    On Error GoTo ErrorHandler
    Set ApplyFilter = Nothing
    ' 確保資料庫已連接
    If Not m_AccessDAL.IsConnected() Then
        If Not m_AccessDAL.Connect() Then
            Err.Raise vbObjectError + 502, MODULE_NAME & "." & METHOD_NAME, "無法連接到資料庫。"
            Exit Function
        End If
    End If
    ' 建構 WHERE 子句
    whereClause = BuildWhereClause(criteriaCollection, METHOD_NAME)
    ' 建構完整 SQL
    If Trim$(whereClause) <> "" Then
        sql = "SELECT * FROM [" & targetTableName & "] WHERE " & whereClause & ";"
    Else
        sql = "SELECT * FROM [" & targetTableName & "];"
    End If
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 執行的 SQL: " & sql
    Set ApplyFilter = m_AccessDAL.GetRecordset(sql)
Exit Function
ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & ": " & Err.Description
    Set ApplyFilter = Nothing
End Function

Public Function CreateTableFromFilter(ByVal criteriaCollection As Collection, ByVal sourceTableName As String, ByVal destinationTableName As String) As Boolean
    Const METHOD_NAME As String = "CreateTableFromFilter"
    Dim sql As String
    Dim whereClause As String
    Dim recordsAffected As Long

    On Error GoTo ErrorHandler
    CreateTableFromFilter = False
    recordsAffected = -1

    If m_AccessDAL Is Nothing Then
        Err.Raise vbObjectError + 501, MODULE_NAME & "." & METHOD_NAME, "AccessDAL 未初始化。"
        Exit Function
    End If

    ' 確保資料庫已連接
    If Not m_AccessDAL.IsConnected() Then
        If Not m_AccessDAL.Connect() Then
            Err.Raise vbObjectError + 502, MODULE_NAME & "." & METHOD_NAME, "無法連接到資料庫。"
            Exit Function
        End If
    End If

    ' 建構 WHERE 子句
    whereClause = BuildWhereClause(criteriaCollection, METHOD_NAME)

    ' 嘗試刪除已存在的目標資料表
    m_AccessDAL.DropTable destinationTableName
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 嘗試刪除舊的資料表: " & destinationTableName

    ' 建構 SELECT INTO SQL
    sql = "SELECT * INTO [" & destinationTableName & "] FROM [" & sourceTableName & "]"
    If Trim$(whereClause) <> "" Then
        sql = sql & " WHERE " & whereClause
    End If
    sql = sql & ";"

    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 執行的 SQL: " & sql

    ' 執行 SQL
    recordsAffected = m_AccessDAL.ExecuteSQL(sql)

    If recordsAffected <> -1 Then
        CreateTableFromFilter = True
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料表 '" & destinationTableName & "' 建立成功，影響記錄數: " & recordsAffected
        MsgBox "篩選條件套用成功！" & vbCrLf & _
           "資料表名稱：" & destinationTableName & vbCrLf & _
           "符合條件記錄數：" & recordsAffected & " 筆", _
           vbInformation, "篩選結果"
    Else
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 建立資料表 '" & destinationTableName & "' 失敗。"
        MsgBox "建立篩選結果資料表失敗！" & vbCrLf & _
           "目標資料表：" & destinationTableName & vbCrLf & _
           "請檢查資料庫連線或篩選條件設定。", _
           vbCritical, "篩選失敗"
    End If

    Exit Function
ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & ": " & Err.Description
    CreateTableFromFilter = False
End Function

' 修改 BuildWhereClause 方法以支援多值條件
Private Function BuildWhereClause(ByVal criteriaCollection As Collection, ByVal callingMethod As String) As String
    Dim whereClause As String
    Dim criterion As Object
    Dim fieldName As String
    Dim operator As String
    Dim value As String
    Dim formattedValue As String
    Dim firstCondition As Boolean
    
    firstCondition = True
    whereClause = ""
    
    ' 如果沒有條件，返回空字串
    If criteriaCollection Is Nothing Or criteriaCollection.Count = 0 Then
        Debug.Print MODULE_NAME & ".BuildWhereClause - 無篩選條件"
        BuildWhereClause = ""
        Exit Function
    End If

    For Each criterion In criteriaCollection
        fieldName = Trim$(CStr(criterion("Field")))
        operator = Trim$(CStr(criterion("Operator")))
        value = Trim$(CStr(criterion("Value")))

        ' 忽略無效的條件部分
        If fieldName = "" Or operator = "" Or value = "" Then
            Debug.Print MODULE_NAME & ".BuildWhereClause - 忽略空白條件: Field=" & fieldName & ", Op=" & operator & ", Val=" & value
            GoTo NextCriterion
        End If

        ' 檢查是否為多值條件（包含逗號）
        If InStr(value, ",") > 0 And (operator = "HAS" Or operator = "==") Then
            ' 處理多值條件
            formattedValue = BuildMultiValueCondition(fieldName, operator, value)
        Else
            ' 處理單值條件
            formattedValue = FormatValueForOperator(fieldName, operator, value)
        End If
        
        If Not firstCondition Then
            whereClause = whereClause & " AND "
        Else
            firstCondition = False
        End If

        ' 根據運算子建構條件
        Select Case operator
            Case "=="
                If InStr(value, ",") > 0 Then
                    ' 多值等於條件，已在 BuildMultiValueCondition 中處理
                    whereClause = whereClause & formattedValue
                Else
                    ' 單值等於條件
                    whereClause = whereClause & "[" & fieldName & "] = " & formattedValue
                End If
            Case "HAS"
                If InStr(value, ",") > 0 Then
                    ' 多值包含條件，已在 BuildMultiValueCondition 中處理
                    whereClause = whereClause & formattedValue
                Else
                    ' 單值包含條件
                    whereClause = whereClause & BuildLikeCondition(fieldName, value)
                End If
            Case ">="
                whereClause = whereClause & BuildNumericCondition(fieldName, ">=", formattedValue)
            Case "<="
                whereClause = whereClause & BuildNumericCondition(fieldName, "<=", formattedValue)
            Case Else
                Debug.Print MODULE_NAME & ".BuildWhereClause - 警告: 未知的運算子 '" & operator & "'，此條件將被忽略。"
                ' 移除多餘的 AND
                If Right$(whereClause, 5) = " AND " Then
                    whereClause = Left$(whereClause, Len(whereClause) - 5)
                End If
                firstCondition = (Trim$(whereClause) = "")
                GoTo NextCriterion
        End Select
        
        Debug.Print MODULE_NAME & ".BuildWhereClause - 已添加條件: " & formattedValue
NextCriterion:
    Next criterion

    BuildWhereClause = whereClause
    Debug.Print MODULE_NAME & ".BuildWhereClause - 最終 WHERE 子句: " & whereClause
End Function


' 替換現有的 FormatValueForOperator 方法
Private Function FormatValueForOperator(ByVal fieldName As String, ByVal operator As String, ByVal value As String) As String
    ' 特殊處理需要強制為字串的欄位
    If IsAlwaysTextColumn(fieldName) Then
        FormatValueForOperator = "'" & Replace(value, "'", "''") & "'"
        Exit Function
    End If
    
    ' HAS 運算子單獨處理（在 BuildLikeCondition 中）
    If operator = "HAS" Then
        FormatValueForOperator = value ' 原值返回，由 BuildLikeCondition 處理
        Exit Function
    End If
    
    ' 日期欄位處理
    If IsDateColumn(fieldName) Then
        FormatValueForOperator = FormatDateValue(value)
        Exit Function
    End If
    
    ' 數值運算子嘗試數值格式
    If operator = ">=" Or operator = "<=" Then
        If IsNumeric(value) Then
            FormatValueForOperator = value
        Else
            ' 嘗試日期轉換
            If IsDate(value) Then
                FormatValueForOperator = FormatDateValue(value)
            Else
                ' 非數值且非日期，設為預設值
                FormatValueForOperator = "0"
                Debug.Print MODULE_NAME & ".FormatValueForOperator - 警告: 無法將 '" & value & "' 轉換為數值或日期，使用預設值 0"
            End If
        End If
        Exit Function
    End If
    
    ' 等於運算子：數值、日期或字串
    If IsNumeric(value) Then
        FormatValueForOperator = value
    ElseIf IsDate(value) Then
        FormatValueForOperator = FormatDateValue(value)
    Else
        FormatValueForOperator = "'" & Replace(value, "'", "''") & "'"
    End If
End Function

' 新增：判斷是否為日期欄位
Private Function IsDateColumn(ByVal fieldName As String) As Boolean
    Select Case fieldName
        Case "日期", "PostDate", "ApprovedDate", "CreatedDate", "過帳日期", "核准日期", "建立日期"
            IsDateColumn = True
        Case Else
            ' 檢查欄位名稱是否包含日期相關關鍵字
            If InStr(1, fieldName, "日期", vbTextCompare) > 0 Or _
               InStr(1, fieldName, "Date", vbTextCompare) > 0 Then
                IsDateColumn = True
            Else
                IsDateColumn = False
            End If
    End Select
End Function

' 新增：格式化日期值為 Access 格式
Private Function FormatDateValue(ByVal dateValue As String) As String
    Dim formattedDate As Date
    
    On Error GoTo DateError
    ' 嘗試轉換為日期
    formattedDate = CDate(dateValue)
    ' 轉換為 Access 日期格式 #yyyy-mm-dd#
    FormatDateValue = "#" & Format(formattedDate, "yyyy-mm-dd") & "#"
    Exit Function
    
DateError:
    Debug.Print MODULE_NAME & ".FormatDateValue - 錯誤: 無法轉換 '" & dateValue & "' 為日期格式"
    ' 如果轉換失敗，嘗試直接使用字串格式
    FormatDateValue = "'" & Replace(dateValue, "'", "''") & "'"
End Function

' 新增：建構 LIKE 條件
Private Function BuildLikeCondition(ByVal fieldName As String, ByVal value As String) As String
    ' 對於包含搜尋，使用 LIKE
    Dim escapedValue As String
    escapedValue = Replace(value, "'", "''")
    BuildLikeCondition = "[" & fieldName & "] LIKE '%" & escapedValue & "%'"
End Function

' 修改 BuildNumericCondition 方法以支援日期比較
Private Function BuildNumericCondition(ByVal fieldName As String, ByVal operator As String, ByVal formattedValue As String) As String
    ' 檢查是否為日期欄位
    If IsDateColumn(fieldName) Then
        ' 日期欄位使用 CDate 轉換進行比較
        If Left$(formattedValue, 1) = "#" And Right$(formattedValue, 1) = "#" Then
            ' 已經是 Access 日期格式
            BuildNumericCondition = "CDate([" & fieldName & "]) " & operator & " " & formattedValue
        Else
            ' 嘗試轉換為日期格式
            BuildNumericCondition = "CDate([" & fieldName & "]) " & operator & " CDate(" & formattedValue & ")"
        End If
        Exit Function
    End If
    
    ' 對於數值比較，如果欄位可能是文字格式，使用 CDbl 轉換
    If IsNumeric(formattedValue) Then
        BuildNumericCondition = "CDbl(IIF(IsNumeric([" & fieldName & "]), [" & fieldName & "], 0)) " & operator & " " & formattedValue
    Else
        ' 如果值不是數值，直接字串比較
        BuildNumericCondition = "[" & fieldName & "] " & operator & " " & formattedValue
    End If
End Function

' 更新 IsAlwaysTextColumn 方法，排除日期欄位
Private Function IsAlwaysTextColumn(ByVal fieldName As String) As Boolean
    ' 先檢查是否為日期欄位，日期欄位不強制為文字
    If IsDateColumn(fieldName) Then
        IsAlwaysTextColumn = False
        Exit Function
    End If
    
    Select Case fieldName
        Case "科目代碼", "傳票號碼", "帳戶", "統一編號", "文件號碼", "會計項目"
            IsAlwaysTextColumn = True
        Case Else
            IsAlwaysTextColumn = False
    End Select
End Function

' 新增：建構多值條件的方法
Private Function BuildMultiValueCondition(ByVal fieldName As String, ByVal operator As String, ByVal multiValue As String) As String
    Dim values() As String
    Dim i As Integer
    Dim condition As String
    Dim trimmedValue As String
    Dim formattedValue As String
    
    ' 將多值字串分割為陣列
    values = Split(multiValue, ",")
    
    Select Case operator
        Case "=="
            ' 建構 IN 條件: [欄位] IN ('值1', '值2', '值3')
            condition = "[" & fieldName & "] IN ("
            For i = 0 To UBound(values)
                trimmedValue = Trim$(values(i))
                If trimmedValue <> "" Then
                    ' 格式化每個值
                    formattedValue = FormatSingleValueForIN(fieldName, trimmedValue)
                    If i = 0 Then
                        condition = condition & formattedValue
                    Else
                        condition = condition & ", " & formattedValue
                    End If
                End If
            Next i
            condition = condition & ")"
            
        Case "HAS"
            ' 建構 OR 條件: ([欄位] LIKE '%值1%' OR [欄位] LIKE '%值2%' OR [欄位] LIKE '%值3%')
            condition = "("
            For i = 0 To UBound(values)
                trimmedValue = Trim$(values(i))
                If trimmedValue <> "" Then
                    If i = 0 Then
                        condition = condition & BuildLikeCondition(fieldName, trimmedValue)
                    Else
                        condition = condition & " OR " & BuildLikeCondition(fieldName, trimmedValue)
                    End If
                End If
            Next i
            condition = condition & ")"
            
        Case Else
            ' 不支援的多值運算子，回退到單值處理
            Debug.Print MODULE_NAME & ".BuildMultiValueCondition - 警告: 運算子 '" & operator & "' 不支援多值，將使用第一個值"
            If UBound(values) >= 0 Then
                trimmedValue = Trim$(values(0))
                condition = FormatValueForOperator(fieldName, operator, trimmedValue)
            Else
                condition = ""
            End If
    End Select
    
    BuildMultiValueCondition = condition
    Debug.Print MODULE_NAME & ".BuildMultiValueCondition - 多值條件: " & condition
End Function

' 新增：為 IN 條件格式化單一值
Private Function FormatSingleValueForIN(ByVal fieldName As String, ByVal value As String) As String
    ' 特殊處理需要強制為字串的欄位
    If IsAlwaysTextColumn(fieldName) Then
        FormatSingleValueForIN = "'" & Replace(value, "'", "''") & "'"
        Exit Function
    End If
    
    ' 日期欄位處理
    If IsDateColumn(fieldName) Then
        FormatSingleValueForIN = FormatDateValue(value)
        Exit Function
    End If
    
    ' 數值或字串處理
    If IsNumeric(value) Then
        FormatSingleValueForIN = value
    ElseIf IsDate(value) Then
        FormatSingleValueForIN = FormatDateValue(value)
    Else
        FormatSingleValueForIN = "'" & Replace(value, "'", "''") & "'"
    End If
End Function

