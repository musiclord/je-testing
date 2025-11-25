# 技術開發指南 (Technical Development Guide)

本文件彙整了專案開發過程中的技術決策、最佳實務與編碼規範。

## 架構設計決策

### 1. 資料存取策略 (DAO)
在 Excel VBA 環境中，我們選擇使用 **DAO (Data Access Objects)** 來操作 Access 資料庫。

*   **為什麼使用 DAO?**
    *   DAO 對 Access 資料庫有原生最佳化，效能優於 ADO。
    *   TableDefs 和 Fields 集合提供完整的 DDL 支援，易於動態建立表結構。
    *   緩存機制 (TableDefs.Refresh) 讓 schema 變更即時可見。
    *   Transaction 支援完善 (Workspace.BeginTrans / CommitTrans / Rollback)。
*   **DAO 的優勢**:
    *   原生支援 Access .accdb/.mdb 檔案格式。
    *   RecordSet 操作簡潔高效。
    *   與 VBA 整合度高，無需額外參考設定。
    *   **最佳實務**: 使用 `DBEngine.OpenDatabase` + `TableDefs` 進行 schema 管理 + `Workspace.BeginTrans` 進行批次寫入。

### 2. 依賴注入 (Dependency Injection)
為了克服 VBA 類別不支援建構子參數 (Constructor Arguments) 的限制，我們採用 **模擬建構子** 或 **屬性注入** 的方式來實現 IoC (控制反轉)。

**範例：模擬建構子注入**
```vb
' Service.cls
Private m_Dal As DbAccess

Public Sub Initialize(ByVal dal As DbAccess)
    Set m_Dal = dal
End Sub
```

**範例：屬性注入**
```vb
' Service.cls
Private m_Dal As DbAccess

Public Property Set Dal(ByVal value As DbAccess)
    Set m_Dal = value
End Property
```

### 3. 命名慣例 (Naming Conventions)

| 前綴 | 意義 | 範例 |
|:---|:---|:---|
| `m_` | 類別成員變數 (Member) | `m_dal`, `m_Name` |
| `p_` | 函式參數 (Parameter) | `p_FilePath` |
| `i_` | 介面 (Interface) | `i_Repository` |
| `c_` | 控制器 (Controller) | `c_MainController` |
| `v_` | 視圖 (View) | `v_MainForm` |

*   **變數**: 小寫開頭 (如 `m_name`)。
*   **物件/類別**: 大寫開頭 (如 `m_Project`)。

## 效能優化技巧

1.  **資料庫交易 (Transactions)**: 進行大量寫入時，務必使用 `BeginTrans` / `CommitTrans`，可提升效能並確保資料一致性。
2.  **避免 Excel 物件操作**: 盡量減少在迴圈中讀寫 Excel 儲存格。應使用陣列 (Array) 進行記憶體內處理，或直接透過 ADO 對工作表進行 SQL 查詢。
3.  **大數據處理**:
    *   使用 `GetRows` 將 Recordset 轉為陣列處理。
    *   若資料量超過百萬筆，避免一次載入記憶體，改用 `Do While Not rs.EOF` 逐筆或分批處理。

## 專案模組規劃

1.  **專案管理器 (ManagerProject)**: 負責持有專案組態 (Config) 與資料庫連線字串。
2.  **上下文管理器 (Context Manager)**: 管理依賴注入的服務實體，確保單例 (Singleton) 或生命週期管理。
3.  **資料存取層 (DAL)**: 統一封裝 SQL 執行邏輯，避免業務邏輯層直接依賴 ADODB 物件。

## 常見陷阱

*   **DAO 緩存**: 透過同一連線建立新資料表後，DAO 可能不會立刻看到新表，需刷新 TableDefs。
*   **VBA 括號**:
    *   `Call Sub(arg)` 或 `Sub arg` (無回傳值)。
    *   `result = Func(arg)` (有回傳值)。
*   **物件指派**: 務必使用 `Set` 關鍵字 (如 `Set rs = New ADODB.Recordset`)，否則會報錯或變為預設屬性指派。
