# 技術開發指南 (Technical Development Guide)

本文件彙整了 .NET 版本專案的技術決策、開發策略與編碼規範。

> VBA 版本的技術指南已歸檔至 `legacy/docs/technical_guide-vba.md`，供歷史參考。

---

## 1. 技術棧總覽

| 項目 | 選擇 | 替代方案 (已排除) |
|:---|:---|:---|
| 語言 | **C#** | VB.NET — 社群資源少、AI 生成品質差 |
| 框架 | **.NET 10 LTS** | .NET Framework — 不支援現代 CLI/AI workflow |
| 桌面框架 | **WinForms** | WPF — Phase 1 過重；Blazor Hybrid — 多一層 runtime |
| UI 引擎 | **WebView2 + HTML/CSS/JS** | 原生 WinForms UI — AI 不擅長生成 |
| 本機資料庫 | **SQLite** | JSON / 散落本機檔案 — 不利於狀態管理 |
| 主資料庫 | **SQL Server** | Access — 不適合大量資料處理 |
| IDE | **Visual Studio 2026** | VS Code — 對 WinForms/.NET 整合不如 VS |

---

## 2. 架構設計決策

### 2.1 Thin-Bridge Action-Dispatcher 模式

前端與後端透過 WebView2 Bridge 通訊，但 Bridge 只負責協定與分派，不承擔業務邏輯。通訊採用 **action + payload** 模式：

```csharp
// .NET 端 — 註冊 Bridge Method
webView.CoreWebView2.AddHostObjectToScript("jet", bridgeObject);

// JavaScript 端 — 呼叫 .NET 方法
const result = await chrome.webview.hostObjects.jet.ImportFile(jsonPayload);
```

**原則**:
- 前端只送 action 名稱 + JSON payload
- Bridge / Dispatcher 只做分派與錯誤包裝
- Application 層負責驗證、轉換、執行
- 結果以 JSON 格式回傳前端

### 2.2 Application CQRS 設計

命令與查詢分離：

```csharp
public sealed record ImportGlCommand(string ProjectId, string FilePath);

public sealed class ImportGlCommandHandler
{
    private readonly IProjectRepository _projects;
    private readonly IGlImportService _importService;

    public ImportGlCommandHandler(IProjectRepository projects, IGlImportService importService)
    {
        _projects = projects;
        _importService = importService;
    }

    public Task<ImportResult> HandleAsync(ImportGlCommand command, CancellationToken cancellationToken)
    {
        // 驗證 → 呼叫服務 → 寫入狀態 → 回傳結果
    }
}
```

### 2.3 Persistence 策略

資料儲存分成兩層：

- **SQLite**：本機專案狀態、欄位 mapping、前端 session state、暫存結果
- **SQL Server**：大量 GL/TB、預篩選、進階篩選、正式結果與匯出基礎資料

使用 **ADO.NET** 搭配 Repository / Query Service 與 Stored Procedures：

- **為什麼用 ADO.NET?** 對 SQL Server 有最佳控制力，適合大量資料 ETL
- **為什麼用 Stored Procedures?** 篩選規則邏輯適合在 SQL Server 端執行，減少資料傳輸
- **參數化查詢**: 所有使用者輸入必須透過 `SqlParameter` 傳遞，防止 SQL Injection

```csharp
public class DataAccess : IDataAccess
{
    public DataTable ExecuteQuery(string storedProc, SqlParameter[] parameters)
    {
        using var conn = new SqlConnection(_connectionString);
        using var cmd = new SqlCommand(storedProc, conn);
        cmd.CommandType = CommandType.StoredProcedure;
        cmd.Parameters.AddRange(parameters);
        // ...
    }
}
```

### 2.4 依賴注入

使用 .NET 內建的 DI 容器 (`Microsoft.Extensions.DependencyInjection`)：

```csharp
var services = new ServiceCollection();
services.AddSingleton<ISqliteConnectionFactory, SqliteConnectionFactory>();
services.AddSingleton<ISqlServerConnectionFactory, SqlServerConnectionFactory>();
services.AddTransient<IActionDispatcher, ActionDispatcher>();
services.AddTransient<ImportGlCommandHandler>();
services.AddTransient<GetProjectStatusQueryHandler>();
```

---

## 3. SQLite / SQL Server 資料設計

### 3.1 SQLite 的用途

建議先把下列內容放入 SQLite：

- 專案基本資訊
- GL / TB 欄位 mapping
- 前端工作流程狀態
- 使用者已保存的條件組合
- 本機快取與暫存預覽資料

### 3.2 SQL Server 的用途

下列內容仍以 SQL Server 為主：

- 大量 GL / TB 匯入資料
- ETL / 標準化表
- 預篩選與進階篩選查詢
- 匯出工作底稿所需的正式結果集

### 3.3 Schema 分層

| Schema | 用途 |
|:---|:---|
| `staging` | 原始匯入資料 (未經處理) |
| `target` | 標準化後的 GL/TB 資料 |
| `result` | 篩選結果與中間計算表 |
| `config` | 規則定義、科目配對、假日曆 |

### 3.4 ETL 流程

```
原始檔案 (Excel/CSV)
  → .NET 解析 → staging.GL_Raw / staging.TB_Raw
  → Stored Procedure → 欄位映射 + 型別轉換
  → target.GeneralLedger / target.TrialBalance
  → 衍生欄位計算 (DebitAmount, CreditAmount, DrCr)
```

### 3.5 預篩選 Stored Procedures

每項預篩選程序對應一個 Stored Procedure：

| Procedure | 對應規則 |
|:---|:---|
| `sp_PreScreen_R1` | 期末財報準備日後核准之分錄 |
| `sp_PreScreen_R2` | 摘要出現特定描述 |
| `sp_PreScreen_R3` | 未預期借貸組合 |
| `sp_PreScreen_R4` | 整數金額 (連續零尾數) |
| `sp_PreScreen_R5` | 依編製者彙總 |
| `sp_PreScreen_R6` | 較少使用之科目 |
| `sp_PreScreen_R7` | 週末過帳/核准 |
| `sp_PreScreen_R8` | 假日過帳/核准 |

---

## 4. 開發環境與工具

### 4.1 主力開發環境

**Visual Studio 2026 + GitHub Copilot Agent Mode**

Copilot Agent Mode 能力：
- 讀整個 repo 結構
- 跨檔修改
- 執行 `dotnet build` / `dotnet test`
- 自動偵測錯誤並修正

### 4.2 雙機開發策略 (Mac + Windows)

| 工作項目 | Mac (VS Code / Terminal) | Windows (Visual Studio 2026) |
|:---|:---|:---|
| HTML 前端開發 | ✓ | ✓ |
| .NET Service Layer | ✓ (dotnet CLI) | ✓ |
| DTO / Models / Tests | ✓ | ✓ |
| SQL Scripts | ✓ | ✓ |
| WinForms Host | ✗ | ✓ |
| WebView2 整合 | ✗ | ✓ |
| 打包與正式驗證 | ✗ | ✓ |

### 4.3 AI 輔助開發適用範圍

**適合交給 AI**:
- Data Access Layer
- DTO / Model 定義
- Service Layer 業務邏輯
- HTML/CSS/JS 前端 UI
- WebView2 Bridge 方法
- SQL Stored Procedures
- 單元測試
- 重構與命名整理

**不適合完全交給 AI**:
- WinForms Designer.cs (Visual Designer 管理)
- 自訂複雜控制項
- 涉及 Designer 序列化的部分

---

## 5. 專案結構規劃

```
src/
└── JET/
    ├── JET.slnx
    └── JET/
        ├── Program.cs
        ├── Form1.cs
        ├── Bridge/                 # Thin Bridge / Action Dispatcher
        ├── Application/
        │   ├── Commands/
        │   ├── Queries/
        │   └── Contracts/
        ├── Infrastructure/
        │   ├── Persistence/
        │   │   ├── Sqlite/
        │   │   └── SqlServer/
        │   ├── Importing/
        │   └── Exporting/
        └── wwwroot/                # WebView2 載入的 HTML/CSS/JS
```

> 目前實際存在的是最小 WinForms 專案骨架；上表為接下來 planning / development 應逐步落地的目標結構。

### 5.1 前端模板整合原則

- `docs/jet-template.html` 目前是設計模板
- 正式開發時應移入 `src/JET/JET/wwwroot/`
- HTML 中具業務意義的 `id` / `data-*` 綁定元素應盡量穩定
- AI 可以自由調整樣式與版面，但不應任意改掉固定綁定契約

---

## 6. 實務限制與考量

| 限制 | 因應方式 |
|:---|:---|
| 不走內網 web server | 打包為本地 .exe，透過 WebView2 嵌入 HTML |
| 避免額外安裝 | 使用 Windows 內建的 WebView2 Runtime |
| Python 不可作為正式方案 | 全部以 C# / .NET 實作 |
| 資安通報風險 | 單機部署，不開放網路端口 |
| 資料量最大數千萬筆 | SQL Server 負責大量運算，.NET 僅處理結果集 |
| 前端需要利於 AI 直接改 UI | 保持固定綁定元素與 action contract，視覺層可彈性調整 |

---

## 7. 從 `ideascript.bas` 遷移的切分原則

不要直接把 VBA 程式翻成 C#。應先拆成四類：

1. **Domain Rules**：寫回 `jet-domain-model.md`
2. **Application Use Cases**：轉成 Commands / Queries
3. **Infrastructure Logic**：檔案、Excel、資料庫、匯出
4. **UI Workflow**：映射到 `jet-template.html` 與 WebView2 action

如果一段舊程式同時混了 UI、資料處理、資料庫操作、Excel 匯出，表示它需要被拆開，而不是被原樣移植。
