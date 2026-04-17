# Journal Entry Testing (JET) — 領域知識庫與系統開發

## 專案概觀 (Project Overview)

本倉庫維護 **Journal Entry Testing (JET) 的完整領域知識**——涵蓋日記帳分錄測試的業務邏輯、審計流程、資料模型與篩選規則，並作為新一代 JET 系統的開發基地。

### JET 是什麼

日記帳分錄測試 (Journal Entry Testing) 是依據 ISA 240 / ISA 330 所執行的實質性審計程序，針對管理階層凌駕控制 (Management Override of Controls) 的風險，對總帳中的所有日記帳分錄進行全母體分析，辨識高風險或異常的分錄。

### 核心流程

```
資料匯入 → 資料驗證 → 輔助檔案設定 → 預篩選 (R1-R8) → 進階篩選 → 工作底稿產出
```

---

## 技術方向 (Technology Direction)

### 定案方案

**Visual Studio 2026 + C# + .NET 10 + WinForms + WebView2 + HTML/CSS/JS + SQLite + SQL Server**

### 架構概要

| 層級 | 技術 | 職責 |
|:---|:---|:---|
| Frontend | HTML / CSS / JS | UI 操作介面 (由 AI 生成與迭代) |
| Desktop Host | WinForms + WebView2 | 桌面容器、打包為單一 .exe |
| Thin Bridge | C# Bridge + Action Dispatcher | 固定綁定元素、接收前端 action、轉送後端處理 |
| Application | C# / .NET 10 | 以 CQRS 管理命令/查詢、業務流程與驗證 |
| Persistence | SQLite + SQL Server | 本機狀態/設定 + 大量資料運算與正式資料儲存 |

### 為什麼選擇這個方案

- **WinForms + WebView2**：維持桌面應用形式，同時讓 HTML 前端可直接承載於本機 UI
- **Thin-Bridge Action-Dispatcher**：讓前端綁定穩定、後端解耦，不把邏輯塞進 `Form1`
- **Application CQRS**：方便把匯入、驗證、篩選、匯出拆成可維護的命令與查詢
- **SQLite + SQL Server**：本機狀態與快取走 SQLite，大量正式資料與運算走 SQL Server
- **`docs/jet-template.html`**：可作為前端目標模板，方便 AI 直接調整 UI/UX
- **`docs/ideascript.bas`**：保留舊 JE Tool 的規則來源，利於後續遷移盤點

詳細架構設計見 [`docs/jet-architecture.md`](docs/jet-architecture.md)，開發規範見 [`docs/jet-technical-guide.md`](docs/jet-technical-guide.md)，目前整理結論見 [`docs/repo-cleanup-summary.md`](docs/repo-cleanup-summary.md)。

---

## 專案架構 (Project Structure)

```text
je-testing/
├── docs/                              # 文件
│   ├── README.md                      # 文件導覽索引
│   ├── jet-domain-model.md            # [核心] JET 領域知識模型
│   ├── jet-architecture.md            # [核心] 目標系統架構
│   ├── jet-technical-guide.md         # [核心] 技術開發指南
│   ├── repo-cleanup-summary.md        # [核心] 目前整理結論與後續規劃
│   ├── ideascript.bas                 # [參考] 原始 IDEA 腳本
│   ├── drawio/                        # [參考] 架構圖
│   └── jet-template.html              # [參考] 前端目標模板
├── data/                              # 範例測試資料
│   ├── JE.xlsx                        #   GL 範例資料
│   ├── TB.xlsx                        #   TB 範例資料
│   ├── _Holiday_2024_CN.xlsx          #   假日曆範例
│   └── _MakeupDay_2024_CN.xlsx        #   補班日曆範例
├── src/                               # .NET 專案 (Visual Studio 2026)
│   └── JET/
│       ├── JET.slnx                   # Visual Studio / dotnet solution
│       └── JET/                       # WinForms app project
│           ├── JET.csproj
│           ├── Program.cs
│           ├── Form1.cs
│           ├── Form1.Designer.cs
│           └── Form1.resx
├── legacy/                            # 已歸檔的 VBA 實作
│   ├── vba-mvp/                       #   MVP 架構 VBA 原始碼
│   ├── vba-1120/                      #   早期版本 VBA 原始碼
│   ├── docs/                          #   VBA 版本技術文件
│   └── *.xlsm                         #   Excel 工作簿
└── 總結.md                             # 技術方案決策總結
```

---

## 如何使用本倉庫

### 理解 JET 業務邏輯

閱讀 **[`docs/jet-domain-model.md`](docs/jet-domain-model.md)** — 這是本倉庫的核心文件，涵蓋：

- 資料實體模型 (GL, TB, Account Mapping, Date Dimension)
- 5 步驟審計工作流程
- 4 項資料驗證規則 (完整性、借貸平衡、INF 抽樣、空值檢查)
- 8 項標準預篩選程序 (R1-R8) 與 3 項自訂擴充 (A2-A4)
- 進階篩選邏輯 (3 種科目配對模式)
- 審計產出物規格
- 台灣在地化考量
- 完整的欄位對照表與術語對照

### 了解系統架構

閱讀 **[`docs/jet-architecture.md`](docs/jet-architecture.md)** — 目前已定案的系統架構：

- WinForms Host + WebView2 + HTML 前端
- Thin-Bridge Action-Dispatcher
- Application CQRS (`Commands` / `Queries`)
- SQLite + SQL Server 的雙資料儲存定位
- `jet-template.html` 與未來桌面專案的整合方式

### 開發指南

閱讀 **[`docs/jet-technical-guide.md`](docs/jet-technical-guide.md)** — .NET 版本開發規範：

- Frontend / Bridge / Application / Infrastructure 分層
- 命令與查詢的切分原則
- 前端固定綁定元素與 AI 協作方式
- SQLite / SQL Server 的職責分工
- 遷移 `ideascript.bas` 的拆解策略

### 目前整理結論

閱讀 **[`docs/repo-cleanup-summary.md`](docs/repo-cleanup-summary.md)**：

- 目前 repo 已整理出的文件定位
- 現階段骨架與缺口
- 後續 planning → development 的銜接順序

### 建置目前的 WinForms 專案

目前 `src/JET/` 已包含可直接開啟的 WinForms 專案：

1. 使用 **Visual Studio 2026** 開啟 `src/JET/JET.slnx`
2. 確認已安裝 **.NET 10 SDK** 與 **Windows Desktop / WinForms** 工作負載
3. 直接執行建置，或使用命令列：`dotnet build src/JET/JET.slnx`

倉庫根目錄的 `global.json` 會固定 SDK 到 `.NET 10.0.201` 的 feature band，降低不同開發機器之間的版本差異。

### 參考歷史實作

VBA 版本的所有原始碼與文件已歸檔至 **[`legacy/`](legacy/)**，包含：

1. **VBA MVP 原型** (`legacy/vba-mvp/`) — 採 MVP 架構的 VBA 實作
2. **早期版本** (`legacy/vba-1120/`) — 較早期的 VBA 版本
3. **VBA 技術文件** (`legacy/docs/`) — VBA 版本的架構設計與開發指南

---

## 技術演進歷程

| 階段 | 技術棧 | 狀態 |
|:---|:---|:---|
| Phase 0 | Caseware IDEA + IDEAScript (~11,000 行) | 已棄用 (不再訂閱 IDEA) |
| Phase 1 | Excel VBA + Access Database (MVP 架構) | 已歸檔至 `legacy/` |
| **Phase 2** | **C# + .NET 10 + WinForms + WebView2 + HTML + SQLite + SQL Server** | **當前開發方向** |

---

## 目前專案狀態

### 已完成

- `src/JET/JET.slnx` 可正常以 `.NET 10` 建置
- `global.json` 已固定 SDK feature band
- `.gitignore` 已補上 Visual Studio / .NET 常見忽略規則
- 文件名稱與目前規劃方向已重新對齊

### 尚未開始的正式開發內容

- WinForms 內嵌 `WebView2`
- 將 `docs/jet-template.html` 納入桌面專案資源
- 建立 Thin Bridge 與 Action Dispatcher
- 建立 `Application` 層的 `Commands` / `Queries`
- 建立 SQLite / SQL Server 雙資料策略
- 依 `docs/ideascript.bas` 盤點並遷移功能

---

## 設計原則

- **領域優先 (Domain First)** — 先釐清業務邏輯，再決定實作技術
- **平台無關 (Platform Agnostic)** — 領域知識文件不綁定任何特定工具或語言
- **單一事實來源 (Single Source of Truth)** — `jet-domain-model.md` 為所有實作的業務規格依據
- **Thin Host** — `Form1` / WinForms host 不承擔業務邏輯
- **固定綁定，彈性前端** — 前端元素命名穩定，方便 AI 直接調整 UI/UX
- **Action over Raw SQL** — 前端只送 action + payload，不直接拼 SQL
- **CQRS Application Layer** — 命令負責變更，查詢負責讀取
- **AI 最大化 (AI-First Development)** — 選擇最適合 AI 自動化開發與測試的技術框架
