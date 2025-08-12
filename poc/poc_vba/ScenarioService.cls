VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ScenarioService"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private Const MODULE_NAME As String = "ScenarioService"
Private m_DbPath As String
Private m_dal As AccessDAL
Private m_JE1 As String
Private m_JE2 As String
Private m_JE3 As String
Private m_PreviewService As PreviewService ' 新增預覽服務
Private Const MAX_ROWS_TO_SHOW As Long = 1000 ' 預覽最大行數

Public Sub Initialize(ByVal DbPath As String, ByVal je1 As String, ByVal je2 As String, ByVal je3 As String)
    Dim METHOD_NAME As String
    METHOD_NAME = "Initialize"
    
    On Error GoTo ErrorHandler
    Set m_dal = New AccessDAL
    Set m_PreviewService = New PreviewService
    m_DbPath = DbPath
    m_dal.DatabasePath = m_DbPath
    m_dal.EnableDebugPrinting = True
    
    m_JE1 = je1
    m_JE2 = je2
    m_JE3 = je3
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " 初始化成功。使用資料庫: " & m_DbPath
    
    Exit Sub
ErrorHandler:
    Err.Raise Err.Number, Err.Description ' 將錯誤向上拋給呼叫者
End Sub

Public Function ExecuteScenario1( _
    ByVal dailyCountLimit As String, _
    ByVal dailyAmountLimit As String, _
    ByVal weeklyCountLimit As String, _
    ByVal weeklyAmountLimit As String, _
    ByVal monthlyCountLimit As String, _
    ByVal monthlyAmountLimit As String _
) As Boolean
    ' --- 篩選條件1 : 短時間內高頻交易 ---
    '
    '  特徵:
    '    - 在1天/1週/1個月內，對同一個銀行帳戶，進行多次交易且金額累積後龐大
    '    - 對銀行帳戶同一天/連續數天進行相同金額之交易 -> 可能為假交易或重複做分錄之錯誤
    '  假設:
    '    1.「會計科目」欄位先篩有「活存」字眼者之所有分錄
    '    2. 根據審計員輸入之時間區段(1天/1週/1個月)，觸發相對應計算金額/頻率的函式
    '    3. 根據審計員輸入之門檻值，判斷該時間區段之金額/頻率是否超過門檻值
    '    4. 超過門檻值，回報為異常分錄
    
    Const METHOD_NAME As String = "ExecuteScenario1"
    Dim success As Boolean
    success = False
    
    If Not m_dal.Connect Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 錯誤: 無法連接到案例資料庫: " & m_dal.DatabasePath
        Exit Function
    End If '若無例外則連接成功
    
    ' Execute procedure... start
    Dim sql As String
    Dim sttDate As Date
    Dim num As Integer
    Dim currentStartDate As Date
    Dim currentEndDate As Date
    Dim tableToDrop As Variant
    Dim tbl As Variant
    
    On Error GoTo ErrorHandler
    
    ' --- 1 ─ 篩選銀行存款貸方交易紀錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 查詢銀行存款及貸方餘額"
    Dim deposit_credit As String
    deposit_credit = m_JE1 & "_deposit_credit"
    DropExist (deposit_credit)
    
    sql = "SELECT * INTO [" & deposit_credit & "] " & _
          "FROM [" & m_JE1 & "] " & _
          "WHERE [會計科目] = '銀行存款' AND [本幣貸方金額] <> 0;"
    m_dal.ExecuteSQL sql
    
    ' --- 2.1 ─ 計算每日各交易對手交易筆數  ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 同一日同一交易對手交易筆數"
    Dim date_counterparty_count As String
    date_counterparty_count = m_JE1 & "_date_counterparty_count"
    DropExist (date_counterparty_count)
    
    sql = "SELECT [日期], [交易對手帳戶], COUNT(*) " & _
          "AS [同一日同一交易對手交易筆數] INTO [" & date_counterparty_count & "] " & _
          "FROM [" & deposit_credit & "] " & _
          "GROUP BY [日期], [交易對手帳戶];"
    m_dal.ExecuteSQL sql
    
    ' --- 2.2 ─ 標記每日交易筆數異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 標記筆數異常分錄(同一天)"
    Dim day_error_count As String
    day_error_count = m_JE1 & "_day_error_count"
    DropExist (day_error_count)
    
    sql = "SELECT * " & vbCrLf & _
          "INTO [" & day_error_count & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.*, " & vbCrLf & _
          "        t2.[同一日同一交易對手交易筆數], " & vbCrLf & _
          "        IIF(" & vbCrLf & _
          "            t2.[同一日同一交易對手交易筆數] > " & dailyCountLimit & ", " & vbCrLf & _
          "            'V', " & vbCrLf & _
          "            ''" & vbCrLf & _
          "        ) AS [超過筆數門檻之異常分錄_日] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        LEFT JOIN [" & date_counterparty_count & "] AS t2 ON (t1.[交易對手帳戶] = t2.[交易對手帳戶]) " & vbCrLf & _
          "        AND (t1.[日期] = t2.[日期])" & vbCrLf & _
          ") AS A " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    [超過筆數門檻之異常分錄_日] = 'V';"
    m_dal.ExecuteSQL sql
    
    ' --- 3.1 ─ 計算每日各交易對手總交易金額 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 同一日同一交易對手交易金額"
    Dim date_counterparty_sum As String
    date_counterparty_sum = m_JE1 & "_date_counterparty_sum"
    DropExist (date_counterparty_sum)
    
    sql = "SELECT [日期], [交易對手帳戶], SUM([本幣貸方金額]) " & _
          "AS [同一日同一交易對手交易金額]" & _
          "INTO [" & date_counterparty_sum & "] " & _
          "FROM [" & deposit_credit & "]" & _
          "GROUP BY [日期], [交易對手帳戶];"
    m_dal.ExecuteSQL sql
    
    ' --- 3.2 ─ 標記每日交易金額異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 標記金額異常分錄(同一天)"
    Dim day_error_sum As String
    day_error_sum = m_JE1 & "_day_error_sum"
    DropExist (day_error_sum)
    
    sql = "SELECT * " & vbCrLf & _
      "INTO [" & day_error_sum & "] " & vbCrLf & _
      "FROM (" & vbCrLf & _
      "    SELECT " & vbCrLf & _
      "        d1.*, " & vbCrLf & _
      "        t8.[同一日同一交易對手交易金額], " & vbCrLf & _
      "        IIF(" & vbCrLf & _
      "            t8.[同一日同一交易對手交易金額] > " & dailyAmountLimit & ", " & vbCrLf & _
      "            'V', " & vbCrLf & _
      "            ''" & vbCrLf & _
      "        ) AS [超過金額門檻之異常分錄_日] " & vbCrLf & _
      "    FROM " & vbCrLf & _
      "        [" & deposit_credit & "] AS d1 " & vbCrLf & _
      "        LEFT JOIN [" & date_counterparty_sum & "] AS t8 ON (d1.[日期] = t8.[日期]) " & vbCrLf & _
      "        AND (d1.[交易對手帳戶] = t8.[交易對手帳戶])" & vbCrLf & _
      ") AS A " & vbCrLf & _
      "WHERE " & vbCrLf & _
      "    [超過金額門檻之異常分錄_日] = 'V';"
    m_dal.ExecuteSQL sql
    
    ' --- 4.1 ─ 產生週滾動時間區間輔助表 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 產出7+2天迴圈"
    Dim week7plus2cycle As String
    week7plus2cycle = m_JE1 & "_week7plus2cycle"
    DropExist (week7plus2cycle)
    GenerateWeeklyData (week7plus2cycle)
    
    ' --- 4.2 ─ 計算週滾動區間交易筆數與金額 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - week7+2_count&sum"
    Dim week_countandsum As String
    week_countandsum = m_JE1 & "_week_countandsum"
    DropExist (week_countandsum)
    
    sql = "SELECT * " & vbCrLf & _
          "INTO [" & week_countandsum & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.[交易對手帳戶], " & vbCrLf & _
          "        t4.StartDate, " & vbCrLf & _
          "        t4.EndDate, " & vbCrLf & _
          "        COUNT(*) AS [連續7日同一交易對手交易筆數], " & vbCrLf & _
          "        SUM(t1.[本幣貸方金額]) AS [連續7日同一交易對手交易金額] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        INNER JOIN [" & week7plus2cycle & "] AS t4 " & vbCrLf & _
          "            ON (t1.[日期] >= t4.[StartDate]) AND (t1.[日期] <= t4.[EndDate]) " & vbCrLf & _
          "    GROUP BY " & vbCrLf & _
          "        t1.[交易對手帳戶], " & vbCrLf & _
          "        t4.StartDate, " & vbCrLf & _
          "        t4.EndDate " & vbCrLf & _
          ") AS A;"
    m_dal.ExecuteSQL sql
    
    ' --- 4.3 ─ 標記週區間交易筆數異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 標記筆數異常分錄(週)"
    Dim week_error_count As String
    week_error_count = m_JE1 & "_week_error_count"
    DropExist (week_error_count)
    
    sql = "SELECT DISTINCT * " & vbCrLf & _
          "INTO [" & week_error_count & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.*, " & vbCrLf & _
          "        t5.[連續7日同一交易對手交易筆數], " & vbCrLf & _
          "        IIF(" & vbCrLf & _
          "            t5.[連續7日同一交易對手交易筆數] > " & weeklyCountLimit & ", " & vbCrLf & _
          "            'V', " & vbCrLf & _
          "            ''" & vbCrLf & _
          "        ) AS [超過筆數門檻之異常分錄_週] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        LEFT JOIN [" & week_countandsum & "] AS t5 " & vbCrLf & _
          "            ON (t1.[日期] <= t5.[EndDate]) " & vbCrLf & _
          "            AND (t1.[日期] >= t5.[StartDate]) " & vbCrLf & _
          "            AND (t1.[交易對手帳戶] = t5.[交易對手帳戶])" & vbCrLf & _
          ") AS A " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    [超過筆數門檻之異常分錄_週] = 'V';"
    m_dal.ExecuteSQL sql
    
    
    
    ' --- 4.4 ─ 標記週區間交易金額異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 標記金額異常分錄(週)"
    Dim week_error_sum As String
    week_error_sum = m_JE1 & "_week_error_sum"
    DropExist (week_error_sum)
    
    sql = "SELECT DISTINCT * " & vbCrLf & _
          "INTO [" & week_error_sum & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.*, " & vbCrLf & _
          "        t5.[連續7日同一交易對手交易金額], " & vbCrLf & _
          "        IIF(" & vbCrLf & _
          "            t5.[連續7日同一交易對手交易金額] > " & weeklyAmountLimit & ", " & vbCrLf & _
          "            'V', " & vbCrLf & _
          "            ''" & vbCrLf & _
          "        ) AS [超過金額門檻之異常分錄_週] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        LEFT JOIN [" & week_countandsum & "] AS t5 " & vbCrLf & _
          "            ON (t1.[交易對手帳戶] = t5.[交易對手帳戶]) " & vbCrLf & _
          "            AND (t1.[日期] >= t5.[StartDate]) " & vbCrLf & _
          "            AND (t1.[日期] <= t5.[EndDate])" & vbCrLf & _
          ") AS A " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    [超過金額門檻之異常分錄_週] = 'V';"
    m_dal.ExecuteSQL sql
    
    
    ' --- 5.1 ─ 產生月滾動時間區間輔助表 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 產出30+8天迴圈"
    Dim month30plus8cycle As String
    month30plus8cycle = m_JE1 & "_month30plus8cycle"
    DropExist (month30plus8cycle)
    GenerateMonthlyData (month30plus8cycle)
    
    ' --- 5.2 ─ 計算月滾動區間交易筆數與金額 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - month30+8_count&sum"
    Dim month_countandsum As String
    month_countandsum = m_JE1 & "_month_countandsum"
    DropExist (month_countandsum)
    
    sql = "SELECT * " & vbCrLf & _
          "INTO [" & month_countandsum & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.[交易對手帳戶], " & vbCrLf & _
          "        t6.StartDate, " & vbCrLf & _
          "        t6.EndDate, " & vbCrLf & _
          "        COUNT(*) AS [連續30日同一交易對手交易筆數], " & vbCrLf & _
          "        SUM(t1.[本幣貸方金額]) AS [連續30日同一交易對手交易金額] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        INNER JOIN [" & month30plus8cycle & "] AS t6 " & vbCrLf & _
          "            ON (t1.[日期] >= t6.[StartDate]) AND (t1.[日期] <= t6.[EndDate]) " & vbCrLf & _
          "    GROUP BY " & vbCrLf & _
          "        t1.[交易對手帳戶], " & vbCrLf & _
          "        t6.StartDate, " & vbCrLf & _
          "        t6.EndDate " & vbCrLf & _
          ") AS A;"
    m_dal.ExecuteSQL sql
    
    ' --- 5.3 ─ 標記月區間交易筆數異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 標記筆數異常分錄(月)"
    Dim month_error_count As String
    month_error_count = m_JE1 & "_month_error_count"
    DropExist (month_error_count)
    
    sql = "SELECT DISTINCT * " & vbCrLf & _
          "INTO [" & month_error_count & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.*, " & vbCrLf & _
          "        t7.[連續30日同一交易對手交易筆數], " & vbCrLf & _
          "        IIF(" & vbCrLf & _
          "            t7.[連續30日同一交易對手交易筆數] > " & monthlyCountLimit & ", " & vbCrLf & _
          "            'V', " & vbCrLf & _
          "            ''" & vbCrLf & _
          "        ) AS [超過筆數門檻之異常分錄_月] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        LEFT JOIN [" & month_countandsum & "] AS t7 " & vbCrLf & _
          "            ON (t1.[交易對手帳戶] = t7.[交易對手帳戶]) " & vbCrLf & _
          "            AND (t1.[日期] >= t7.[StartDate]) " & vbCrLf & _
          "            AND (t1.[日期] <= t7.[EndDate])" & vbCrLf & _
          ") AS A " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    [超過筆數門檻之異常分錄_月] = 'V';"
    m_dal.ExecuteSQL sql
    
    ' --- 5.4 ─ 標記月區間交易金額異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 標記金額異常分錄(月)"
    Dim month_error_sum As String
    month_error_sum = m_JE1 & "_month_error_sum"
    DropExist (month_error_sum)
    
    sql = "SELECT DISTINCT * " & vbCrLf & _
          "INTO [" & month_error_sum & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        t1.*, " & vbCrLf & _
          "        t7.[連續30日同一交易對手交易金額], " & vbCrLf & _
          "        IIF(" & vbCrLf & _
          "            t7.[連續30日同一交易對手交易金額] > " & monthlyAmountLimit & ", " & vbCrLf & _
          "            'V', " & vbCrLf & _
          "            ''" & vbCrLf & _
          "        ) AS [超過金額門檻之異常分錄_月] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & deposit_credit & "] AS t1 " & vbCrLf & _
          "        LEFT JOIN [" & month_countandsum & "] AS t7 " & vbCrLf & _
          "            ON (t1.[交易對手帳戶] = t7.[交易對手帳戶]) " & vbCrLf & _
          "            AND (t1.[日期] >= t7.[StartDate]) " & vbCrLf & _
          "            AND (t1.[日期] <= t7.[EndDate])" & vbCrLf & _
          ") AS A " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    [超過金額門檻之異常分錄_月] = 'V';"
    m_dal.ExecuteSQL sql
    
    ' Execute procedure... end
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 開始預覽結果資料表"
    
    ' 預覽月份異常金額結果
    If m_dal.tableExists(month_error_sum) Then
        Application.StatusBar = "正在預覽 " & month_error_sum & "..."
        Application.Cursor = xlWait
        If m_PreviewService.ShowPreview(m_DbPath, month_error_sum, month_error_sum & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & month_error_sum & " 預覽成功"
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & month_error_sum & " 預覽失敗"
        End If
    End If
    
    ' 預覽週期異常金額結果
    If m_dal.tableExists(week_error_sum) Then
        Application.StatusBar = "正在預覽 " & week_error_sum & "..."
        If m_PreviewService.ShowPreview(m_DbPath, week_error_sum, week_error_sum & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & week_error_sum & " 預覽成功"
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & week_error_sum & " 預覽失敗"
        End If
    End If
    
    ' 預覽每日異常金額結果
    If m_dal.tableExists(day_error_sum) Then
        Application.StatusBar = "正在預覽 " & day_error_sum & "..."
        If m_PreviewService.ShowPreview(m_DbPath, day_error_sum, day_error_sum & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & day_error_sum & " 預覽成功"
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & day_error_sum & " 預覽失敗"
        End If
    End If
    
    Application.StatusBar = False
    Application.Cursor = xlDefault
    
    MsgBox "Scenario 1 執行完畢，結果已預覽至工作表。", vbInformation
    success = True
    m_dal.Disconnect
    ExecuteScenario1 = success

Cleanup:
    If Not m_dal Is Nothing Then
        If m_dal.IsConnected() Then
            m_dal.Disconnect
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料庫連接已斷開。"
        End If
    End If
    ExecuteScenario1 = success
    Exit Function

ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & " - SQL: " & sql
    Debug.Print "錯誤碼 " & Err.Number & ", 描述: " & Err.Description
    Resume Cleanup ' 跳至清理程序以斷開連接並退出
    
End Function



Public Function ExecuteScenario2( _
    ByVal amountLimit As String, _
    ByVal frequencyLimit As String _
) As Boolean
    ' --- 篩選條件2 : 將單筆大額款項拆分成多筆小金額款項進行交易 ---
    '
    '  特徵:
    '    - 若公司內規規定超過特定金額之大額交易需要特定主管簽名核准，可能透過將大額款項拆分成小筆金額多次交易的方式規避內部控制以進行舞弊。
    '  假設:
    '    1. 根據審計員輸入要檢驗的會計科目 (通常在費用的雜項) 篩出 「會計科目」欄位包含這些會計科目之所有分錄
    '    2. 統計科目拆成相同金額的 (1)分錄有幾筆 or (2)當年累積金額，並視覺化以排名呈現
    '    3. 根據審計員輸入之門檻值，判斷當年之分錄比數/金額是否超過門檻值
    '    4. 超過門檻值者，回報為異常分錄
    
    Const METHOD_NAME As String = "ExecuteScenario2"
    Dim success As Boolean
    success = False
    
    If Not m_dal.Connect Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 錯誤: 無法連接到案例資料庫: " & m_dal.DatabasePath
        Exit Function
    End If '若無例外則連接成功
    
    ' Execute procedure... start
    Dim sql As String
    Dim tableToDrop As Variant
    Dim tbl As Variant
    
    On Error GoTo ErrorHandler
    
    ' --- 1-1 ─ 重複金額抽取（全科目） ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 1-1_same_amount_for_all_account"
    Dim same_amount_for_all_account As String
    same_amount_for_all_account = m_JE2 & "_same_amount_for_all_account"
    DropExist (same_amount_for_all_account)
    
    sql = "SELECT A.[會計科目], A.[本幣借方金額], A.[日期] " & _
          "INTO [" & same_amount_for_all_account & "] " & _
          "FROM [" & m_JE2 & "] AS A " & _
          "WHERE A.[本幣借方金額] > 0 " & _
          "AND A.[本幣借方金額] IN ( " & _
          "  SELECT [本幣借方金額]" & _
          "  FROM [" & m_JE2 & "]" & _
          "  WHERE [會計科目] = A.[會計科目]" & _
          "  AND [本幣借方金額] > 0" & _
          "  GROUP BY [本幣借方金額]" & _
          "  HAVING COUNT(*) > 1" & _
          ") " & _
          "ORDER BY A.[會計科目], A.[本幣借方金額], A.[日期];"
    m_dal.ExecuteSQL sql
    
    ' --- 1-2 ─ 重複金額抽取（指定科目） ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 1-2_same_amount_for_selected_account"
    Dim same_amount_for_selected_account As String
    Dim 會計科目Group As String
    會計科目Group = m_JE2 & "_會計科目Group"
    same_amount_for_selected_account = m_JE2 & "_same_amount_for_selected_account"
    DropExist (same_amount_for_selected_account)
    
    sql = "SELECT A.[會計科目], A.[本幣借方金額], A.[日期] " & _
          "INTO [" & same_amount_for_selected_account & "] " & _
          "FROM [" & m_JE2 & "] AS A " & _
          "WHERE A.[本幣借方金額] > 0 " & _
          "AND A.[會計科目] IN ( SELECT [會計科目] FROM [" & 會計科目Group & "])  " & _
          "AND A.[本幣借方金額] IN ( " & _
          "  SELECT [本幣借方金額] " & _
          "  FROM [" & m_JE2 & "] " & _
          "  WHERE [會計科目] = A.[會計科目]" & _
          "  AND [本幣借方金額] > 0 " & _
          "  GROUP BY [本幣借方金額] " & _
          "  HAVING COUNT(*) > 1 " & _
          ") " & _
          "ORDER BY A.[會計科目], A.[本幣借方金額], A.[日期];"
    m_dal.ExecuteSQL sql
    
    ' --- 2-1 ─ 金額異常偵測（dollar err） ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 2-1_dollar_err"
    Dim dollar_err As String
    dollar_err = m_JE2 & "_dollar_err"
    DropExist (dollar_err)
    
    sql = "SELECT * INTO [" & dollar_err & "] " & _
          "FROM [" & same_amount_for_selected_account & "] " & _
          "WHERE [會計科目] IN (" & _
          "  SELECT 會計科目" & _
          "  FROM [" & same_amount_for_selected_account & "] " & _
          "  GROUP BY [會計科目], YEAR(日期) " & _
          "  HAVING SUM([本幣借方金額]) > " & amountLimit & " " & _
          ") " & _
          "ORDER BY [會計科目], [本幣借方金額], [日期];"
    m_dal.ExecuteSQL sql
    
    ' --- 2-2 ─ 筆數異常偵測（frequency_err） ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 2-2_frequency_err"
    Dim frequency_err As String
    frequency_err = m_JE2 & "_frequency_err"
    DropExist (frequency_err)
    
    sql = "SELECT * INTO [" & frequency_err & "] " & vbCrLf & _
          "FROM [" & same_amount_for_selected_account & "] " & vbCrLf & _
          "WHERE [會計科目] IN ( " & vbCrLf & _
          "  SELECT [會計科目] " & vbCrLf & _
          "  FROM [" & same_amount_for_selected_account & "] " & vbCrLf & _
          "  GROUP BY [會計科目], YEAR(日期) " & vbCrLf & _
          "  HAVING COUNT(*) > " & frequencyLimit & " " & vbCrLf & _
          ") " & vbCrLf & _
          "ORDER BY [會計科目], [本幣借方金額], [日期];"
    m_dal.ExecuteSQL sql
    
    ' --- 3-1 ─ 異常旗標合併（金額） ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 3-1_明細帳_2_dollar_err"
    Dim full_dollar_err As String
    full_dollar_err = m_JE2 & "_full_dollar_err"
    DropExist (full_dollar_err)
    
    sql = "SELECT DISTINCT * INTO [" & full_dollar_err & "] " & vbCrLf & _
          "FROM ( " & vbCrLf & _
          "  SELECT A.*, " & vbCrLf & _
          "  IIf( " & vbCrLf & _
          "    B.[會計科目] IS NOT NULL AND " & vbCrLf & _
          "    B.[本幣借方金額] IS NOT NULL AND " & vbCrLf & _
          "    B.[日期] IS NOT NULL, " & vbCrLf & _
          "    'V', '' " & vbCrLf & _
          "  ) AS error " & vbCrLf & _
          "  FROM [" & m_JE2 & "] AS A " & vbCrLf & _
          "    LEFT JOIN [" & dollar_err & "] AS B " & vbCrLf & _
          "    ON (A.[會計科目] = B.[會計科目]) " & vbCrLf & _
          "    AND (A.[本幣借方金額] = B.[本幣借方金額]) " & vbCrLf & _
          "    AND (A.[日期] = B.[日期]) " & vbCrLf & _
          ") AS [SubQueryAlias];"
    m_dal.ExecuteSQL sql
    
    ' --- 3-2 ─ 異常旗標合併（筆數） ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 3-2_明細帳_2_frequency_err"
    Dim full_frequency_err As String
    full_frequency_err = m_JE2 & "_full_frequency_err"
    DropExist (full_frequency_err)
    
    sql = "SELECT DISTINCT * INTO [" & full_frequency_err & "] " & vbCrLf & _
          "FROM ( " & vbCrLf & _
          "  SELECT A.*, " & vbCrLf & _
          "  IIf(" & vbCrLf & _
          "    B.[會計科目] IS NOT NULL AND " & vbCrLf & _
          "    B.[本幣借方金額] IS NOT NULL AND " & vbCrLf & _
          "    B.[日期] IS NOT NULL," & vbCrLf & _
          "    'V', '' " & vbCrLf & _
          "  ) AS error " & vbCrLf & _
          "  FROM [" & m_JE2 & "] AS A " & vbCrLf & _
          "  LEFT JOIN [" & frequency_err & "] AS B" & vbCrLf & _
          "  ON (A.[會計科目] = B.[會計科目]) " & vbCrLf & _
          "  AND (A.[本幣借方金額] = B.[本幣借方金額]) " & vbCrLf & _
          "  AND (A.[日期] = B.[日期])" & vbCrLf & _
          ") AS [SubQueryAlias];"
    m_dal.ExecuteSQL sql
    
    ' Execute procedure... end
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 開始預覽結果資料表"
    
    ' 預覽金額異常結果
    If m_dal.tableExists(full_dollar_err) Then
        Application.StatusBar = "正在預覽 " & full_dollar_err & "..."
        Application.Cursor = xlWait
        If m_PreviewService.ShowPreview(m_DbPath, full_dollar_err, full_dollar_err & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & full_dollar_err & " 預覽成功"
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & full_dollar_err & " 預覽失敗"
        End If
    End If
    
    ' 預覽頻率異常結果
    If m_dal.tableExists(full_frequency_err) Then
        Application.StatusBar = "正在預覽 " & full_frequency_err & "..."
        If m_PreviewService.ShowPreview(m_DbPath, full_frequency_err, full_frequency_err & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & full_frequency_err & " 預覽成功"
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & full_frequency_err & " 預覽失敗"
        End If
    End If
    
    Application.StatusBar = False
    Application.Cursor = xlDefault
    
    MsgBox "Scenario 2 執行完畢，結果已預覽至工作表。", vbInformation
    success = True
    m_dal.Disconnect
    ExecuteScenario2 = success
    
Cleanup:
    If Not m_dal Is Nothing Then
        If m_dal.IsConnected() Then
            m_dal.Disconnect
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料庫連接已斷開。"
        End If
    End If
    ExecuteScenario2 = success
    Exit Function

ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & " - SQL: " & sql
    Debug.Print "錯誤碼 " & Err.Number & ", 描述: " & Err.Description
    Resume Cleanup ' 跳至清理程序以斷開連接並退出
    
End Function

Public Function ExecuteScenario3( _
    ByVal rateRatioLimit As String, _
    ByVal amountDiffLimit As String _
) As Boolean
    ' --- 篩選條件3 : 涉及外幣之交易分錄 ---
    '
    '  特徵:
    '    - 使用與央行或公開市場明顯不符的匯率，或是同一時期不同交易適用不同匯率，利用匯兌損益操縱財報
    '    - 利用外幣付款給實質不存在或關係密切之供應商以掩蓋資金挪用行為
    '  假設:
    '    1. 「匯率」欄位先篩值不為「0.00000」之所有分錄
    '    2. VB從明細表抓「傳票日期」、「原幣別」、「匯率」欄位，與台銀匯率交叉比對，判斷明細表所使用匯率是否合理
    '    3. 若匯率有差異，計算兩匯率下「傳票金額」差多少
    '    4. 根據審計員輸入之門檻值，判斷該差異是否超過門檻值
    '    5. 超過門檻值者，回報為異常分錄
    
    Const METHOD_NAME As String = "ExecuteScenario3"
    Dim success As Boolean
    success = False
    
    If Not m_dal.Connect Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 錯誤: 無法連接到案例資料庫: " & m_dal.DatabasePath
        Exit Function
    End If '若無例外則連接成功
    
    ' Execute procedure... start
    Dim tableToDrop As Variant
    Dim tbl As Variant
    Dim sql As String
    
    On Error GoTo ErrorHandler
    
    ' --- 1 ─ 爬蟲-台銀匯率 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 爬蟲-台銀匯率"
    Dim ExchangeRates As String
    ExchangeRates = m_JE3 & "_ExchangeRates"
    
    ' 移除原本的 DropExist 呼叫，改為智慧檢查
    If Not m_dal.tableExists(ExchangeRates) Then
        Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料表 " & ExchangeRates & " 不存在，開始執行爬蟲。"
        
        If Not ScrapeExchangeRates(ExchangeRates) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 錯誤: ScrapeExchangeRates 失敗。"
            GoTo Cleanup
        End If
    Else
        ' 檢查資料表是否有足夠的資料
        Dim recordCount As Variant
        Dim minRecordThreshold As Long
        minRecordThreshold = 240 ' 2024年約有365天，設定最小記錄數門檻
        
        recordCount = m_dal.GetScalar("SELECT COUNT(*) FROM [" & ExchangeRates & "]")
        
        If IsNull(recordCount) Or Not IsNumeric(recordCount) Or CLng(recordCount) < minRecordThreshold Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料表 " & ExchangeRates & " 存在但資料不足 (記錄數: " & recordCount & ")，重新執行爬蟲。"
            
            ' 刪除舊資料表並重新爬蟲
            m_dal.DropTable ExchangeRates
            
            If Not ScrapeExchangeRates(ExchangeRates) Then
                Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 錯誤: ScrapeExchangeRates 失敗。"
                GoTo Cleanup
            End If
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料表 " & ExchangeRates & " 已存在且資料充足 (記錄數: " & recordCount & ")，跳過爬蟲程序。"
        End If
    End If
    
    ' --- 2 ─ 整合正確匯率至明細帳 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 將正確匯率及明細帳統整為新表"
    Dim ledger_mix_exchange_rate As String
    ledger_mix_exchange_rate = m_JE3 & "_ledger_mix_exchange_rate"
    DropExist (ledger_mix_exchange_rate)
    
    sql = "SELECT " & vbCrLf & _
          "    A.*, " & vbCrLf & _
          "    IIF(A.[幣別]='USD', E.[USD], " & vbCrLf & _
          "        IIF(A.[幣別]='CNY', E.[CNY], " & vbCrLf & _
          "            IIF(A.[幣別]='JPY', E.[JPY], NULL)" & vbCrLf & _
          "        )" & vbCrLf & _
          "    ) AS CorrectRate " & vbCrLf & _
          "INTO [" & ledger_mix_exchange_rate & "] " & vbCrLf & _
          "FROM " & vbCrLf & _
          "    [" & m_JE3 & "] AS A " & vbCrLf & _
          "LEFT JOIN " & vbCrLf & _
          "    [" & ExchangeRates & "] AS E ON A.[日期] = E.[Date];"
    m_dal.ExecuteSQL sql
    
    ' --- 3 ─ 計算匯率差異金額及比率 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 計算借貸方差異金額及比率"
    Dim different_amount_and_percentage As String
    different_amount_and_percentage = m_JE3 & "_different_amount_and_percentage"
    DropExist (different_amount_and_percentage)
    
    sql = "SELECT * " & vbCrLf & _
          "INTO [" & different_amount_and_percentage & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        A.*, " & vbCrLf & _
          "        ([匯率] - [CorrectRate]) * [原幣借方金額] AS [借方差異金額], " & vbCrLf & _
          "        ([匯率] - [CorrectRate]) * [原幣貸方金額] AS [貸方差異金額], " & vbCrLf & _
          "        IIF(([CorrectRate] IS NOT NULL AND [CorrectRate] <> 0) AND ([原幣借方金額] IS NOT NULL AND [原幣借方金額] <> 0), ([本幣借方金額] / ([CorrectRate] * [原幣借方金額])), NULL) AS [借方差異比率], " & vbCrLf & _
          "        IIF(([CorrectRate] IS NOT NULL AND [CorrectRate] <> 0) AND ([原幣貸方金額] IS NOT NULL AND [原幣貸方金額] <> 0), ([本幣貸方金額] / ([CorrectRate] * [原幣貸方金額])), NULL) AS [貸方差異比率] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & ledger_mix_exchange_rate & "] AS A" & vbCrLf & _
          ") AS B;"
    m_dal.ExecuteSQL sql
    
    ' --- 4 ─ 篩選匯率差異超標分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 先篩選出大於10%再篩選差異金額超過門檻之列"
    Dim abnormal_list As String
    abnormal_list = m_JE3 & "_abnormal_list"
    DropExist (abnormal_list)
    
    sql = "SELECT " & vbCrLf & _
          "    A.[傳票號碼], " & vbCrLf & _
          "    A.[日期], " & vbCrLf & _
          "    A.[匯率], " & vbCrLf & _
          "    A.[CorrectRate], " & vbCrLf & _
          "    A.[借方差異金額], " & vbCrLf & _
          "    A.[貸方差異金額], " & vbCrLf & _
          "    A.[借方差異比率], " & vbCrLf & _
          "    A.[貸方差異比率] " & vbCrLf & _
          "INTO [" & abnormal_list & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        * " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & different_amount_and_percentage & "] AS B " & vbCrLf & _
          "    WHERE " & vbCrLf & _
          "        B.[借方差異比率] > " & rateRatioLimit & " OR B.[貸方差異比率] > " & rateRatioLimit & vbCrLf & _
          ") AS A " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    A.[借方差異金額] > " & amountDiffLimit & " OR A.[貸方差異金額] > " & amountDiffLimit & ";"
    m_dal.ExecuteSQL sql
    
    ' --- 5 ─ 標記並列出所有匯率異常分錄 ---
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 併入明細帳並列出所有異常分錄"
    Dim all_abnormal_entry As String
    all_abnormal_entry = m_JE3 & "_all_abnormal_entry"
    DropExist (all_abnormal_entry)
    
    sql = "SELECT * " & vbCrLf & _
          "INTO [" & all_abnormal_entry & "] " & vbCrLf & _
          "FROM (" & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        A.*, " & vbCrLf & _
          "        IIF(" & vbCrLf & _
          "            A.[傳票號碼] IN ( " & vbCrLf & _
          "                SELECT " & vbCrLf & _
          "                    [傳票號碼] " & vbCrLf & _
          "                FROM " & vbCrLf & _
          "                    [" & abnormal_list & "] " & vbCrLf & _
          "            ), " & vbCrLf & _
          "            'V', " & vbCrLf & _
          "            ''" & vbCrLf & _
          "        ) AS [超過金額門檻之異常分錄] " & vbCrLf & _
          "    FROM " & vbCrLf & _
          "        [" & different_amount_and_percentage & "] AS A " & vbCrLf & _
          "        LEFT JOIN [" & abnormal_list & "] AS B " & vbCrLf & _
          "            ON (A.[借方差異金額] = B.[借方差異金額]) AND (A.[傳票號碼] = B.[傳票號碼])" & vbCrLf & _
          ") AS T " & vbCrLf & _
          "WHERE " & vbCrLf & _
          "    T.[超過金額門檻之異常分錄] = 'V';"
    m_dal.ExecuteSQL sql
    
    ' Execute procedure... end
    
    Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 開始預覽結果資料表"
    
    ' 預覽所有異常分錄結果
    If m_dal.tableExists(all_abnormal_entry) Then
        Application.StatusBar = "正在預覽 " & all_abnormal_entry & "..."
        Application.Cursor = xlWait
        If m_PreviewService.ShowPreview(m_DbPath, all_abnormal_entry, all_abnormal_entry & "_Preview", MAX_ROWS_TO_SHOW) Then
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - " & all_abnormal_entry & " 預覽成功"
            Application.StatusBar = False
            Application.Cursor = xlDefault
            MsgBox "Scenario 3 執行完畢，結果已預覽至工作表。", vbInformation
        Else
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 警告: " & all_abnormal_entry & " 預覽失敗"
            Application.StatusBar = False
            Application.Cursor = xlDefault
            MsgBox "Scenario 3 執行完畢，但預覽失敗。請檢查結果資料表。", vbExclamation
        End If
    Else
        Application.StatusBar = False
        Application.Cursor = xlDefault
        MsgBox "Scenario 3 執行完畢，但未找到結果資料表。", vbExclamation
    End If
    
    success = True
    m_dal.Disconnect
    ExecuteScenario3 = success

Cleanup:
    If Not m_dal Is Nothing Then
        If m_dal.IsConnected() Then
            m_dal.Disconnect
            Debug.Print MODULE_NAME & "." & METHOD_NAME & " - 資料庫連接已斷開。"
        End If
    End If
    ExecuteScenario3 = success
    Exit Function

ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME
    If sql <> "" Then
        Debug.Print "錯誤 SQL (或 SQL 描述): " & sql
    End If
    Debug.Print "錯誤碼 " & Err.Number & ", 描述: " & Err.Description
    success = False
    Resume Cleanup
End Function

Private Sub DropExist(ByVal table As String)
    If m_dal.tableExists(table) Then
        Debug.Print MODULE_NAME & " - " & table & " 已存在，將其刪除。"
        m_dal.DropTable table
    Else
        Debug.Print MODULE_NAME & " - " & table & " 不存在，無須刪除。"
    End If
    
End Sub

Private Sub GenerateWeeklyData(ByVal tableName As String)
    Const METHOD_NAME As String = "GenerateWeeklyData"
    Dim sql As String
    Dim sttDate As Date
    Dim endDate As Date
    Dim currentStartDate As Date
    Dim currentEndDate As Date
    Dim num As Integer
    
    On Error GoTo ErrorHandler
    
    If Not m_dal.tableExists(tableName) Then
        sql = "CREATE TABLE " & tableName & " (StartDate DATETIME, EndDate DATETIME)"
        m_dal.ExecuteSQL sql
    End If
    
    sttDate = #1/1/2024#
    endDate = #12/31/2024#
    num = 0
    m_dal.EnableDebugPrinting = False
    
    Do While (DateAdd("d", num, sttDate) <= endDate) ' 當前範圍未超過結束日期
        currentStartDate = DateAdd("d", num, sttDate) ' 起始日期
        currentEndDate = DateAdd("d", num + 8, sttDate) ' 結束日期 (9天後)
        ' 插入查詢：每次插入9天的範圍
        sql = "INSERT INTO [" & tableName & "] (StartDate, EndDate) " & _
              "SELECT #" & Format(currentStartDate, "yyyy-mm-dd") & "# AS StartDate, " & _
              "#" & Format(currentEndDate, "yyyy-mm-dd") & "# AS EndDate"
        m_dal.ExecuteSQL sql
        num = num + 1
    Loop
    
    m_dal.EnableDebugPrinting = True
    MsgBox "資料已成功插入 " & tableName & "！"
    
Cleanup:
    Exit Sub

ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & ": " & Err.Description
    MsgBox "在 " & METHOD_NAME & " 中發生錯誤: " & Err.Description, vbCritical
    GoTo Cleanup

End Sub

Private Sub GenerateMonthlyData(ByVal tableName As String)
    Const METHOD_NAME As String = "GenerateMonthlyData"
    Dim sql As String
    Dim sttDate As Date
    Dim endDate As Date
    Dim currentStartDate As Date
    Dim currentEndDate As Date
    Dim num As Integer
    
    On Error GoTo ErrorHandler
    
    If Not m_dal.tableExists(tableName) Then
        sql = "CREATE TABLE " & tableName & " (StartDate DATETIME, EndDate DATETIME)"
        m_dal.ExecuteSQL sql
    End If
    
    sttDate = #1/1/2024#
    endDate = #12/31/2024#
    num = 0
    m_dal.EnableDebugPrinting = False
    
    Do While (DateAdd("d", num, sttDate) <= endDate) ' 當前範圍未超過結束日期
        currentStartDate = DateAdd("d", num, sttDate) ' 起始日期
        currentEndDate = DateAdd("d", num + 37, sttDate) ' 結束日期 (39天後)
        ' 插入查詢：每次插入38天的範圍
        sql = "INSERT INTO [" & tableName & "] (StartDate, EndDate) " & _
              "SELECT #" & Format(currentStartDate, "yyyy-mm-dd") & "# AS StartDate, " & _
              "#" & Format(currentEndDate, "yyyy-mm-dd") & "# AS EndDate"
        m_dal.ExecuteSQL sql
        num = num + 1
    Loop
    
    m_dal.EnableDebugPrinting = True
    MsgBox "資料已成功插入 " & tableName & "！"
    
Cleanup:
    Exit Sub

ErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME & ": " & Err.Description
    MsgBox "在 " & METHOD_NAME & " 中發生錯誤: " & Err.Description, vbCritical
    GoTo Cleanup

End Sub

Private Function ScrapeExchangeRates(ByVal tableName As String) As Boolean
    Const METHOD_NAME As String = "ScrapeExchangeRates"
    Dim xmlHttp As MSXML2.XMLHTTP60
    Dim html As Object
    Dim url As String
    Dim rows As Object
    Dim startDate As Date, endDate As Date
    Dim currentDate As Date
    Dim dateString As String
    Dim row As Object
    Dim usdRate As String, cnyRate As String, jpyRate As String
    Dim formattedDate As String
    Dim recordsFound As Long
    Dim insertSQL As String, updateSQL As String
    Dim createTableSQL As String
    Dim sqlForErrorContext As String

    On Error GoTo ScrapeErrorHandler
    ScrapeExchangeRates = False ' Default to failure

    Set xmlHttp = New MSXML2.XMLHTTP60
    
    startDate = DateSerial(2024, 1, 1)
    endDate = DateSerial(2024, 12, 31) ' Adjust for testing if needed
    
    ' --- Ensure table exists before starting the loop ---
    sqlForErrorContext = "Checking/Creating table: " & tableName
    If Not m_dal.tableExists(tableName) Then
        Debug.Print METHOD_NAME & " - Table " & tableName & " does not exist. Creating it."
        createTableSQL = "CREATE TABLE [" & tableName & "] (" & _
                         "[Date] DATETIME PRIMARY KEY, " & _
                         "USD NUMBER, " & _
                         "CNY NUMBER, " & _
                         "JPY NUMBER);"
        sqlForErrorContext = createTableSQL
        m_dal.ExecuteSQL createTableSQL
        Debug.Print METHOD_NAME & " - Table " & tableName & " created successfully."
    Else
        Debug.Print METHOD_NAME & " - Table " & tableName & " already exists."
    End If
    sqlForErrorContext = "" ' Clear context

    currentDate = startDate
    Do While currentDate <= endDate
        dateString = Format(currentDate, "yyyy-mm-dd") ' URL format
        url = "https://rate.bot.com.tw/xrt/all/" & dateString
        sqlForErrorContext = "Fetching URL: " & url
        Debug.Print METHOD_NAME & " - Fetching data for: " & dateString

        xmlHttp.Open "GET", url, False
        xmlHttp.setRequestHeader "User-Agent", "Mozilla/5.0"
        xmlHttp.setRequestHeader "Referer", "https://rate.bot.com.tw/xrt/all"
        xmlHttp.sEnd ' Corrected from sEnd

        If xmlHttp.status = 200 Then ' Standard casing for Status
            Set html = CreateObject("htmlfile")
            html.body.innerHTML = xmlHttp.responseText
            Set rows = html.getElementsByTagName("tr")

            ' Initialize rates for the current date
            usdRate = ""
            cnyRate = ""
            jpyRate = ""

            For Each row In rows
                If InStr(1, row.innerText, "美金 (USD)", vbTextCompare) > 0 Then
                    usdRate = Trim(row.getElementsByTagName("td")(3).innerText)
                ElseIf InStr(1, row.innerText, "人民幣 (CNY)", vbTextCompare) > 0 Then
                    cnyRate = Trim(row.getElementsByTagName("td")(3).innerText)
                ElseIf InStr(1, row.innerText, "日圓 (JPY)", vbTextCompare) > 0 Then
                    jpyRate = Trim(row.getElementsByTagName("td")(3).innerText)
                End If
            Next row

            formattedDate = "#" & Format(currentDate, "yyyy-mm-dd") & "#"
            
            ' Check if record for the date exists using m_dal.GetScalar
            Dim scalarSQL As String
            scalarSQL = "SELECT COUNT(*) FROM [" & tableName & "] WHERE [Date] = " & formattedDate
            sqlForErrorContext = "Checking record existence with GetScalar: " & scalarSQL
            Dim countResult As Variant
            countResult = m_dal.GetScalar(scalarSQL)

            recordsFound = 0 ' Default to 0 if GetScalar fails or returns Null/Error
            If Not IsError(countResult) And Not IsNull(countResult) Then
                If IsNumeric(countResult) Then
                    recordsFound = CLng(countResult)
                End If
            ElseIf IsError(countResult) Then
                ' GetScalar would have raised its own error, which should be caught by ScrapeErrorHandler.
                ' This is an additional check or logging point if needed.
                Debug.Print METHOD_NAME & " - Error from GetScalar for SQL (" & scalarSQL & "): " & CVErr(countResult)
                ' Optionally re-raise or handle, but GetScalar's own Err.Raise should propagate.
            End If
            sqlForErrorContext = "" ' Clear scalarSQL context

            If recordsFound = 0 Then ' Record does not exist, so INSERT
                If IsNumeric(usdRate) Or IsNumeric(cnyRate) Or IsNumeric(jpyRate) Then
                    insertSQL = "INSERT INTO [" & tableName & "] ([Date], USD, CNY, JPY) VALUES (" & _
                                formattedDate & ", " & Val(Nz(usdRate, "0")) & ", " & Val(Nz(cnyRate, "0")) & ", " & Val(Nz(jpyRate, "0")) & ")"
                    sqlForErrorContext = insertSQL
                    Debug.Print "INSERT SQL: " & insertSQL
                    m_dal.ExecuteSQL insertSQL
                Else
                    Debug.Print METHOD_NAME & " - No numeric rates found for " & dateString & " to insert."
                End If
            Else ' Record exists, so UPDATE
                Dim setClauses As String
                setClauses = ""
                If IsNumeric(usdRate) Then setClauses = setClauses & "USD = " & Val(usdRate) & ", "
                If IsNumeric(cnyRate) Then setClauses = setClauses & "CNY = " & Val(cnyRate) & ", "
                If IsNumeric(jpyRate) Then setClauses = setClauses & "JPY = " & Val(jpyRate) & ", "
                
                If Len(setClauses) > 0 Then
                    setClauses = Left(setClauses, Len(setClauses) - 2) ' Remove trailing comma and space
                    updateSQL = "UPDATE [" & tableName & "] SET " & setClauses & " WHERE [Date] = " & formattedDate
                    sqlForErrorContext = updateSQL
                    Debug.Print "UPDATE SQL: " & updateSQL
                    m_dal.ExecuteSQL updateSQL
                Else
                     Debug.Print METHOD_NAME & " - No numeric rates found for " & dateString & " to update existing record."
                End If
            End If
        Else
            Debug.Print METHOD_NAME & " - Failed to fetch data for " & dateString & ". Status: " & xmlHttp.status
        End If
        
        sqlForErrorContext = "" ' Clear context for next iteration
        currentDate = currentDate + 1
        ' DoEvents ' Optional: to keep Excel responsive during long loops
    Loop

    MsgBox "匯率資料已成功插入/更新至資料表 '" & tableName & "'！", vbInformation
    ScrapeExchangeRates = True ' Set to True on successful completion
    
    Set xmlHttp = Nothing
    Set html = Nothing
    Set rows = Nothing
    Set row = Nothing
    Exit Function

ScrapeErrorHandler:
    Debug.Print "錯誤於 " & MODULE_NAME & "." & METHOD_NAME
    If sqlForErrorContext <> "" Then
        Debug.Print "錯誤相關資訊 (SQL 或步驟): " & sqlForErrorContext
    End If
    Debug.Print "錯誤碼 " & Err.Number & ", 描述: " & Err.Description
    MsgBox "在 " & METHOD_NAME & " 中發生錯誤：" & vbCrLf & Err.Description & vbCrLf & "相關資訊: " & sqlForErrorContext, vbCritical, "執行錯誤"
    ' ScrapeExchangeRates remains False (default value)
    Set xmlHttp = Nothing
    Set html = Nothing
    Set rows = Nothing
    Set row = Nothing
    Exit Function

End Function

