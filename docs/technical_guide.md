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
| 資料庫 | **SQL Server** | Access — 不適合大量資料處理 |
| IDE | **Visual Studio 2026** | VS Code — 對 WinForms/.NET 整合不如 VS |

---

## 2. 架構設計決策

### 2.1 WebView2 Bridge 模式

前端與後端透過 WebView2 Bridge 通訊，採用 **action + payload** 模式：

```csharp
// .NET 端 — 註冊 Bridge Method
webView.CoreWebView2.AddHostObjectToScript("jet", bridgeObject);

// JavaScript 端 — 呼叫 .NET 方法
const result = await chrome.webview.hostObjects.jet.ImportFile(jsonPayload);
```

**原則**:
- 前端只送 action 名稱 + JSON payload
- .NET Service Layer 負責驗證、轉換、執行
- 結果以 JSON 格式回傳前端

### 2.2 Service Layer 設計

每個業務模組獨立一個 Service 類別：

```csharp
public class ServiceImport
{
    private readonly IDataAccess _dal;

    public ServiceImport(IDataAccess dal)
    {
        _dal = dal;
    }

    public ImportResult ImportGeneralLedger(ImportPayload payload)
    {
        // 1. 驗證 payload
        // 2. 解析檔案
        // 3. 欄位映射
        // 4. 呼叫 DAL 寫入 SQL Server
        // 5. 回傳結果
    }
}
```

### 2.3 Data Access 策略

使用 **ADO.NET** 搭配 Stored Procedures：

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
services.AddSingleton<IDataAccess, DataAccess>();
services.AddTransient<ServiceImport>();
services.AddTransient<ServiceValidation>();
services.AddTransient<ServiceFilter>();
services.AddTransient<ServiceExport>();
```

---

## 3. SQL Server 資料庫設計

### 3.1 Schema 分層

| Schema | 用途 |
|:---|:---|
| `staging` | 原始匯入資料 (未經處理) |
| `target` | 標準化後的 GL/TB 資料 |
| `result` | 篩選結果與中間計算表 |
| `config` | 規則定義、科目配對、假日曆 |

### 3.2 ETL 流程

```
原始檔案 (Excel/CSV)
  → .NET 解析 → staging.GL_Raw / staging.TB_Raw
  → Stored Procedure → 欄位映射 + 型別轉換
  → target.GeneralLedger / target.TrialBalance
  → 衍生欄位計算 (DebitAmount, CreditAmount, DrCr)
```

### 3.3 預篩選 Stored Procedures

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
├── JET.sln                         # Solution 檔案
├── JET.Desktop/                    # WinForms + WebView2 Host
│   ├── Program.cs
│   ├── MainForm.cs
│   ├── Bridge/                     # WebView2 Bridge 方法
│   └── wwwroot/                    # HTML/CSS/JS 前端資源
├── JET.Core/                       # 業務邏輯層 (Service Layer)
│   ├── Services/
│   ├── Models/
│   └── Interfaces/
├── JET.Data/                       # 資料存取層
│   ├── DataAccess.cs
│   ├── Repositories/
│   └── Scripts/                    # SQL migration scripts
└── JET.Tests/                      # 測試專案
    ├── Services/
    └── Data/
```

> 以上為規劃結構。實際專案將在 Visual Studio 2026 中建立，名稱待定。

---

## 6. 實務限制與考量

| 限制 | 因應方式 |
|:---|:---|
| 不走內網 web server | 打包為本地 .exe，透過 WebView2 嵌入 HTML |
| 避免額外安裝 | 使用 Windows 內建的 WebView2 Runtime |
| Python 不可作為正式方案 | 全部以 C# / .NET 實作 |
| 資安通報風險 | 單機部署，不開放網路端口 |
| 資料量最大數千萬筆 | SQL Server 負責大量運算，.NET 僅處理結果集 |
