VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ServiceValidation"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit
'===============================================================================
' Class: ServiceValidation
' Purpose: 對客戶資料進行驗證測試
'===============================================================================
Private dbSource As DbAccess
Private dbTarget As DbAccess
Private je As EntityJe
Private tb As EntityTb
Private info As EntityInfo

Public Sub Initialize(ByRef context As ContextManager)
    '來源資料庫為存放原始資料的 input.accdb
    Set dbSource = context.DbInput
    '目標資料庫為存放驗證結果的 valid.accdb
    Set dbTarget = context.DbValid
    Set je = context.je
    Set tb = context.tb
    Set info = context.info
End Sub

Public Function CheckCompleteness() As Boolean
    ' ============================================================================
    ' 完整性檢查 (Completeness/Roll-forward Test)
    '   目的:
    '       - 驗證分錄檔 (JE) 與試算表 (TB) 的資料完整性和一致性
    '   業務邏輯:
    '       1. 從 TB 取得各會計科目的期間變動金額作為基準
    '       2. 從 JE 彙總指定期間內各會計科目的交易總額
    '       3. 計算兩者差異並產出明細供進一步檢查
    '   處理流程:
    '       1. 複製 TB 至目標資料庫
    '       2. 篩選指定期間內的 JE
    '       3. 依會計科目彙總 JE 金額
    '       4. 將 TB 與 JE 彙總做全外部連結
    '       5. 新增合併科目編號欄位及差異欄位
    '       6. 合併科目編號
    '       7. 計算 TB 與 JE 彙總金額之差異
    '       8. 產生完整性檢查明細
    '   相依性:
    '       - dbSource: 來源資料庫 (包含JE和TB原始資料)
    '       - dbTarget: 目標資料庫 (用於產生中間結果和明細)
    '       - je:   JE實體物件 (定義分錄檔欄位名稱)
    '       - tb:   TB實體物件 (定義試算表欄位名稱)
    '       - info: 資訊實體物件 (包含期間設定)
    '   產生的資料表:
    '       - JE_IN_PERIOD:             期間內分錄資料
    '       - JE_ACCOUNT_SUM:           分錄科目彙總資料
    '       - COMPLETENESS_CALCULATED:  完整性比對計算結果
    '       - COMPLETENESS_RESULT:      最終完整性檢查報告
    '   產生的欄位:
    '       - ACCOUNT_MERGED:   統一的會計科目編號 (優先顯示JE科目,無則顯示TB科目)
    '       - TB_JE_DIFF:       TB變動金額與JE彙總金額的差異
    ' ============================================================================
    On Error GoTo ErrorHandler
    '欄位名稱
    Const FLD_ACCOUNT_MERGED As String = "ACCOUNT_MERGED"
    Const FLD_TB_JE_DIFF As String = "TB_JE_DIFF"
    '查詢字串
    Dim sql As String
    CheckCompleteness = False
    Debug.Print "********** 開始完整性檢查流程 **********"
    Debug.Print "檢查期間: " & info.PeriodStart & " ~ " & info.PeriodEnd
    Call CleanupTempTables(dbTarget, Array(tb.Name, TBL_JE_IN_PERIOD, TBL_JE_NOT_IN_PERIOD, TBL_JE_ACCOUNT_SUM, TBL_COMPLETENESS_CALCULATED, TBL_COMPLETENESS_RESULT))
    
    ' ----------------------------------------------------------------------------
    ' 複製 TB 至目標資料庫
    ' 邏輯:
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 複製 TB **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & tb.Name & " IN '" & dbTarget.path & "' " & vbCrLf & _
          "FROM " & tb.Name & " IN '" & dbSource.path & "';"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 篩選指定期間內的 JE
    ' 邏輯: @BetweenDate(je.[PostDate], info.PeriodStart, info.PeriodEnd)
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 篩選期間內資料 **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & TBL_JE_IN_PERIOD & " IN '" & dbTarget.path & "' " & vbCrLf & _
          "FROM " & je.Name & " IN '" & dbSource.path & "' " & vbCrLf & _
          "WHERE [" & je.PostDate & "] " & vbCrLf & _
          "BETWEEN #" & info.PeriodStart & "# AND #" & info.PeriodEnd & "#;"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 篩選指定期間外的 JE
    ' 邏輯: NOT @BetweenDate(je.[PostDate], info.PeriodStart, info.PeriodEnd)
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 篩選期間外資料 **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & TBL_JE_NOT_IN_PERIOD & " IN '" & dbTarget.path & "' " & vbCrLf & _
          "FROM " & je.Name & " IN '" & dbSource.path & "' " & vbCrLf & _
          "WHERE [" & je.PostDate & "] < #" & info.PeriodStart & "# " & vbCrLf & _
          "   OR [" & je.PostDate & "] > #" & info.PeriodEnd & "#;"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 依會計科目彙總 JE 金額
    ' 邏輯: SUM [K_Amount], GROUP BY [AccountNumber]
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 依會計科目彙總金額 **********"
    sql = "SELECT " & vbCrLf & _
          "    [" & je.AccountNumber & "], " & vbCrLf & _
          "    SUM([" & je.K_Amount & "]) AS [" & je.K_Amount_Sum & "] " & vbCrLf & _
          "INTO " & TBL_JE_ACCOUNT_SUM & " " & vbCrLf & _
          "FROM " & TBL_JE_IN_PERIOD & " " & vbCrLf & _
          "GROUP BY [" & je.AccountNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 將 TB 與 JE 彙總做全外部連結
    ' 邏輯: JoinDatabase WI_JOIN_ALL_REC; je.[AccountNumber] = tb.[AccountNumber]
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 資料比對連結 (FULL OUTER JOIN) **********"
    sql = "SELECT * INTO " & TBL_COMPLETENESS_CALCULATED & " " & _
          "FROM( " & vbCrLf & _
          "    SELECT" & vbCrLf & _
          "        P.*, S.* " & vbCrLf & _
          "    FROM " & TBL_JE_ACCOUNT_SUM & " AS P " & vbCrLf & _
          "    LEFT JOIN " & tb.Name & " AS S " & vbCrLf & _
          "        ON P.[" & je.AccountNumber & "] = S.[" & tb.AccountNumber & "] " & vbCrLf & _
          "    UNION " & vbCrLf & _
          "    SELECT " & vbCrLf & _
          "        P.*, S.* " & vbCrLf & _
          "    FROM " & TBL_JE_ACCOUNT_SUM & " AS P " & vbCrLf & _
          "    RIGHT JOIN " & tb.Name & " AS S " & vbCrLf & _
          "        ON P.[" & je.AccountNumber & "] = S.[" & tb.AccountNumber & "] " & vbCrLf & _
          ");"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 新增合併科目編號欄位及差異欄位
    ' 邏輯: ADD COLUMN [ACCOUNT_MERGED], [TB_JE_DIFF]
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 新增差異計算欄位 **********"
    sql = "ALTER TABLE " & TBL_COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ADD COLUMN [" & FLD_ACCOUNT_MERGED & "] TEXT(50);"
    dbTarget.ExecuteNonQuery sql
    
    sql = "ALTER TABLE " & TBL_COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "ADD COLUMN [" & FLD_TB_JE_DIFF & "] CURRENCY;"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 合併科目編號
    ' 邏輯: @If( je.[AccountNumber], je.[AccountNumber], tb.[AccountNumber])
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 計算統一科目編號 **********"
    sql = "UPDATE " & TBL_COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "SET [" & FLD_ACCOUNT_MERGED & "] = " & vbCrLf & _
          "    IIF(ISNULL([" & je.AccountNumber & "]), [" & tb.AccountNumber & "], [" & je.AccountNumber & "]);"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 計算 TB 與 JE 彙總金額之差異
    ' 邏輯: [DIFF] = tb.[K_Amount] - je.[K_Amount_Sum]
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 計算差異金額 **********"
    sql = "UPDATE " & TBL_COMPLETENESS_CALCULATED & " " & vbCrLf & _
          "SET [" & FLD_TB_JE_DIFF & "] = " & Nz(tb.K_Amount) & " - " & Nz(je.K_Amount_Sum) & ";"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 產生完整性檢查明細
    ' 邏輯: 匯出關鍵欄位
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 產生最終結果 **********"
    sql = "SELECT " & vbCrLf & _
          "    [" & FLD_ACCOUNT_MERGED & "], " & vbCrLf & _
          "    [" & tb.AccountName & "], " & vbCrLf & _
          "    [" & tb.K_Amount & "], " & vbCrLf & _
          "    [" & je.K_Amount_Sum & "], " & vbCrLf & _
          "    [" & FLD_TB_JE_DIFF & "] " & vbCrLf & _
          "INTO " & TBL_COMPLETENESS_RESULT & " " & vbCrLf & _
          "FROM " & TBL_COMPLETENESS_CALCULATED & " " & vbCrLf & _
          ""
    dbTarget.ExecuteNonQuery sql
    
    CheckCompleteness = True
    Debug.Print "********** 完整性檢查流程完成 **********"
    Exit Function
ErrorHandler:
    Debug.Print "CheckCompleteness(): "; Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
End Function
    
Public Function CheckDocumentBalance() As Boolean
    ' ============================================================================
    ' 傳票借貸平衡檢查 (Document Balance Test)
    '   目的:
    '       - 檢查會計分錄系統中每張傳票的借貸是否平衡
    '   業務邏輯:
    '       1. 依據複式簿記原則，每張傳票的借方總額必須等於貸方總額
    '       2. 若傳票借貸不平衡，表示資料輸入錯誤或系統異常
    '       3. 展開問題傳票的所有明細，以利會計師進行錯誤定位與修正
    '   處理流程:
    '       1. 篩選指定期間內的 JE
    '       2. 依傳票號碼彙總 JE 借貸金額
    '       3. 篩選出借貸總額不為零的異常傳票
    '       4. 展開異常傳票的所有分錄明細
    '   相依性:
    '       - dbSource: 來源資料庫 (包含原始分錄資料)
    '       - dbTarget: 目標資料庫 (用於產生中間結果和明細)
    '       - je: JE實體物件 (定義分錄檔欄位名稱)
    '       - info: 資訊實體物件 (包含檢查期間設定)
    '   產生的資料表:
    '       - DOCUMENT_IN_PERIOD:   指定期間內的所有分錄
    '       - DOCUMENT_SUM:         各傳票的借貸彙總結果
    '       - DOCUMENT_DIFF:        借貸不平衡的異常傳票清單
    '       - DOCUMENT_NOT_BALANCE: 異常傳票的完整明細資料
    ' ============================================================================
    On Error GoTo ErrorHandler
    '查詢字串
    Dim sql As String
    CheckDocumentBalance = False
    Debug.Print "********** 開始完整性檢查流程 **********"
    Debug.Print "檢查期間: " & info.PeriodStart & " ~ " & info.PeriodEnd
    Call CleanupTempTables(dbTarget, Array(TBL_DOCUMENT_IN_PERIOD, TBL_DOCUMENT_SUM, TBL_DOCUMENT_DIFF, TBL_DOCUMENT_NOT_BALANCE))
    
    ' ----------------------------------------------------------------------------
    ' 篩選指定期間內的 JE
    ' 邏輯: @BetweenDate(je.[PostDate], info.PeriodStart, info.PeriodEnd)
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 篩選期間內資料 **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & TBL_DOCUMENT_IN_PERIOD & " IN '" & dbTarget.path & "' " & vbCrLf & _
          "FROM " & je.Name & " IN '" & dbSource.path & "' " & vbCrLf & _
          "WHERE [" & je.PostDate & "] " & vbCrLf & _
          "BETWEEN #" & info.PeriodStart & "# AND #" & info.PeriodEnd & "#;"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 依傳票號碼彙總 JE 金額
    ' 邏輯: SUM [K_Amount], GROUP BY [DocumentNumber]
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 依傳票號碼彙總金額 **********"
    sql = "SELECT " & vbCrLf & _
          "    [" & je.DocumentNumber & "], " & vbCrLf & _
          "    SUM([" & je.K_Amount & "]) AS [" & je.K_Amount_Sum & "] " & vbCrLf & _
          "INTO " & TBL_DOCUMENT_SUM & " " & vbCrLf & _
          "FROM " & TBL_DOCUMENT_IN_PERIOD & " " & vbCrLf & _
          "GROUP BY [" & je.DocumentNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 篩選出借貸總額不為零的異常傳票
    ' 邏輯: WHERE je.[K_Amount_Sum] <> 0
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 篩選出借貸不平衡的分錄 **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & TBL_DOCUMENT_DIFF & " " & vbCrLf & _
          "FROM " & TBL_DOCUMENT_SUM & " " & vbCrLf & _
          "WHERE [" & je.K_Amount_Sum & "] <> 0;"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 展開異常傳票的所有分錄明細
    ' 邏輯: JoinDatabase, WI_JOIN_MATCH_ONLY
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 配對(若有)不平衡分錄之明細 **********"
    sql = "SELECT " & vbCrLf & _
          "    P.*, " & vbCrLf & _
          "    S.[" & je.K_Amount_Sum & "] " & vbCrLf & _
          "INTO " & TBL_DOCUMENT_NOT_BALANCE & " " & vbCrLf & _
          "FROM " & TBL_DOCUMENT_IN_PERIOD & " AS P" & vbCrLf & _
          "INNER JOIN " & TBL_DOCUMENT_DIFF & " AS S " & vbCrLf & _
          "    ON p.[" & je.DocumentNumber & "] = S.[" & je.DocumentNumber & "];"
    dbTarget.ExecuteNonQuery sql
    
    CheckDocumentBalance = True
    Debug.Print "********** 傳票借貸平衡檢查完成 **********"
    Exit Function
ErrorHandler:
    Debug.Print "CheckDocumentBalance(): "; Err.Number
    Debug.Print "  - 錯誤描述: "; Err.Description
End Function

Public Function CheckINF() As Boolean
    ' ============================================================================
    ' 評估INF可靠性之抽樣程序
    '   背景:
    '       - INF Testing：測試控制所依賴的資訊是否可靠，通常與 ITGC、應用控制有關。
    '       - INF: Information used in the performance of controls
    '   目的:
    '       - 從總帳分錄 (JE) 中依據定義的風險隨機抽取指定數量的樣本，並排序後產出明細。
    '   業務邏輯:
    '       1. 從指定期間內的 JE 中使用隨機排序和 TOP 語法，抽取 60 筆樣本。
    '       2. 將抽取的樣本依傳票號碼排序，以利檢閱。
    '   處理流程:
    '       1. 篩選指定期間內的 JE。
    '       2. 隨機抽取 60 筆樣本
    '       3. 將樣本依傳票號碼排序
    '   產生的資料表:
    '       - JE_IN_PERIOD: 期間內分錄。
    '       - INF_RANDOM:   隨機抽取的 60 筆樣本。
    '       - INF_SORTED:   排序後的明細。
    ' ============================================================================
    On Error GoTo ErrorHandler
    '查詢字串
    Dim sql As String
    CheckINF = False
    Debug.Print "********** 開始隨機抽樣流程 **********"
    Debug.Print "檢查期間: " & info.PeriodStart & " ~ " & info.PeriodEnd
    Call CleanupTempTables(dbTarget, Array(TBL_JE_IN_PERIOD, TBL_INF_RANDOM, TBL_INF_SORTED))
    ' ----------------------------------------------------------------------------
    ' 篩選指定期間內的 JE
    ' 邏輯: @BetweenDate(je.[PostDate], info.PeriodStart, info.PeriodEnd)
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 篩選期間內資料 **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & TBL_JE_IN_PERIOD & " IN '" & dbTarget.path & "' " & vbCrLf & _
          "FROM " & je.Name & " IN '" & dbSource.path & "' " & vbCrLf & _
          "WHERE [" & je.PostDate & "] " & vbCrLf & _
          "BETWEEN #" & info.PeriodStart & "# AND #" & info.PeriodEnd & "#;"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 隨機抽取 60 筆樣本
    ' 邏輯: 使用 RND() 函數產生隨機排序，再用 TOP 60 選取樣本。
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 隨機抽取 60 筆樣本 **********"
    Randomize
    sql = "SELECT TOP 60 * " & vbCrLf & _
          "INTO " & TBL_INF_RANDOM & " " & vbCrLf & _
          "FROM " & TBL_JE_IN_PERIOD & " " & vbCrLf & _
          "ORDER BY Rnd([" & je.K_UID & "]);"
    dbTarget.ExecuteNonQuery sql
    
    ' ----------------------------------------------------------------------------
    ' 將樣本依傳票號碼排序
    ' 邏輯: ORDER BY je.[DocumentNumber] ASC
    ' ----------------------------------------------------------------------------
    Debug.Print "********** 依傳票號碼排序樣本 **********"
    sql = "SELECT * " & vbCrLf & _
          "INTO " & TBL_INF_SORTED & " " & vbCrLf & _
          "FROM " & TBL_INF_RANDOM & " " & vbCrLf & _
          "ORDER BY [" & je.DocumentNumber & "] ASC;"
    dbTarget.ExecuteNonQuery sql
    
    CheckINF = True
    Debug.Print "********** 隨機抽樣流程完成 **********"
    Exit Function
ErrorHandler:
    Debug.Print "CheckINF(): "; Err.Number
    Debug.Print "  - 錯誤描述: "; Err.Description
End Function

Public Function CheckNullRecords() As Boolean
    ' ============================================================================
    ' 空值記錄檢查 (Check Null Records)
    '   目的:
    '       - 檢查會計分錄中關鍵欄位是否有空值或空白記錄
    '   業務邏輯:
    '       1. 檢查會計科目編號是否為空 - 影響科目分類統計
    '       2. 檢查傳票號碼是否為空 - 影響傳票追蹤和平衡檢查
    '       3. 檢查傳票摘要是否為空 - 影響交易內容理解
    '   處理流程:
    '       1. 分別檢查三個關鍵欄位的空值情況
    '       2. 產生對應的異常記錄明細表
    '   產生的資料表:
    '       - NULL_ACCOUNT_RECORDS:     會計科目編號為空的記錄
    '       - NULL_DOCUMENT_RECORDS:    傳票號碼為空的記錄
    '       - NULL_DESCRIPTION_RECORDS: 傳票摘要為空的記錄
    ' ============================================================================
    On Error GoTo ErrorHandler
    CheckNullRecords = False
    Debug.Print "********** 開始空值記錄檢查 **********"
    Call CleanupTempTables(dbTarget, Array(TBL_NULL_ACCOUNT, TBL_NULL_DOCUMENT, TBL_NULL_DESCRIPTION))
    Debug.Print "********** 檢查會計科目編號空值 **********"
    If Not dbSource.ExtractNullRecords(je.Name, je.AccountNumber, TBL_NULL_ACCOUNT, destinationDb:=dbTarget.path) Then
        Debug.Print "會計科目編號空值檢查失敗"
        Exit Function
    End If
    Debug.Print "********** 檢查傳票號碼空值 **********"
    If Not dbSource.ExtractNullRecords(je.Name, je.DocumentNumber, TBL_NULL_DOCUMENT, destinationDb:=dbTarget.path) Then
        Debug.Print "傳票號碼空值檢查失敗"
        Exit Function
    End If
    Debug.Print "********** 檢查傳票摘要空值 **********"
    If Not dbSource.ExtractNullRecords(je.Name, je.EntryDescription, TBL_NULL_DESCRIPTION, destinationDb:=dbTarget.path) Then
        Debug.Print "傳票摘要空值檢查失敗"
        Exit Function
    End If
    CheckNullRecords = True
    Debug.Print "********** 空值記錄檢查完成 **********"
    Exit Function
ErrorHandler:
    Debug.Print "CheckNullRecords(): " & Err.Number
    Debug.Print "  - 錯誤描述: " & Err.Description
    CheckNullRecords = False
End Function

'--自訂方法
Private Sub CleanupTempTables(ByRef db As DbAccess, ByRef tableNames As Variant)
    ' 清理暫存資料表的輔助方法
    On Error Resume Next
    Dim i As Long
    For i = LBound(tableNames) To UBound(tableNames)
        If db.TableExists(CStr(tableNames(i))) Then
            db.DropTable CStr(tableNames(i))
        End If
    Next i
    On Error GoTo 0
    dbTarget.Refresh
End Sub

