# Journal Entry Testing (JET)

審計用的**日記帳分錄測試**工具 — 依 ISA 240 / ISA 330 對管理階層凌駕控制風險進行全母體分錄篩選。

**技術棧**：`.NET 10 + WinForms + WebView2 + HTML/CSS/JS + SQLite + SQL Server`

**深度文件**：所有業務規則、系統架構、資料策略、AI 協作指南與遷移計畫都在 [`docs/jet-guide.md`](docs/jet-guide.md)。**寫程式前讀這個。**

---

## 專案結構

```
je-testing/
├── README.md                 # 本檔：識別、快速開始、目錄
├── global.json               # 固定 .NET 10.0.201 feature band
├── docs/
│   ├── jet-guide.md          # 單一深度指南 (領域 + 架構 + 規則規格 + AI workflow)
│   ├── jet-template.html     # 前端 UI 目標模板 (WebView2 將載入此頁面)
│   └── drawio/               # 架構圖素材
├── data/                     # 範例測試資料 (GL / TB / 假日 / 補班日)
├── src/JET/
│   ├── JET.slnx              # Visual Studio / dotnet 方案檔
│   └── JET/                  # WinForms 專案 (目前僅骨架)
└── legacy/                   # Phase 0 / Phase 1 歷史實作，僅供對照，不再維護
    ├── README.md             # legacy 總說明與規則對照
    ├── ideascript.bas        # Phase 0 (IDEA) 始祖程式
    ├── vba-mvp/              # Phase 1 MVP 版 VBA 原始碼
    ├── vba-mvp.xlsm
    ├── vba-1120/             # Phase 1 早期版
    ├── vba-1120.xlsm
    └── SqlBuilder.xlsm
```

---

## 快速開始

### 建置 WinForms 骨架

1. 以 **Visual Studio 2026** 開啟 [`src/JET/JET.slnx`](src/JET/JET.slnx)
2. 確認已安裝 **.NET 10 SDK** 與 **Windows Desktop / WinForms** workload
3. `dotnet build src/JET/JET.slnx` 或在 VS 直接 F5

> 目前 `Form1` 是空殼。正式實作請依 [`docs/jet-guide.md` §14](docs/jet-guide.md#14-專案結構規劃) 逐層擴充。

### 開發環境建議

| 平台 | 用途 |
|:---|:---|
| Windows + Visual Studio 2026 + Copilot Agent Mode | 主場：WinForms / WebView2 整合、Designer、最終打包 |
| Mac / Linux + VS Code / Claude Code / Codex CLI | 副場：Domain / Application / HTML 前端 / SQL / 測試 |

---

## 技術演進

| 階段 | 技術棧 | 狀態 |
|:---|:---|:---|
| Phase 0 | Caseware IDEA + IDEAScript | 棄用 (不再訂閱 IDEA) |
| Phase 1 | Excel VBA + Access `.accdb` | 歸檔至 [`legacy/`](legacy/) |
| **Phase 2** | **.NET 10 + WinForms + WebView2 + HTML + SQLite + SQL Server** | **當前開發方向** |

棄用背景、替代方案比較、技術決策細節見 [`docs/jet-guide.md` §9-10](docs/jet-guide.md#9-棄用-idea-與-vba-的背景)。

---

## 架構一句話

```
HTML 前端 ─action+payload→ Thin Bridge ─dispatch→ Application (CQRS)
                                                      │
                                                      ▼
                                          Domain (純邏輯 + Repository 介面)
                                                      │
                                   ┌──────────────────┴──────────────────┐
                                   ▼                                     ▼
                           SqliteGlRepository                 SqlServerGlRepository
```

- **Thin-Bridge Action-Dispatcher**：前後端之間只傳 JSON，邏輯不夾在 Bridge 裡
- **Application CQRS**：Commands (變更) 與 Queries (讀取) 分離；每條規則一個 Handler
- **Clean Core**：Domain 無 I/O 依賴；Infrastructure 實作 Domain 介面
- **雙 Provider**：SQLite 與 SQL Server 共用同一 `IGlRepository` 介面，執行期依設定切換；目前先以 SQLite 為主

詳見 [`docs/jet-guide.md` §11-13](docs/jet-guide.md#11-架構總覽)。

---

## 核心原則

1. 業務邏輯不進 `Form1` — Host 極薄
2. 前端只送 `action + payload`，不拼 SQL
3. 每條規則一個 Command/Query + Handler，不做大函式
4. Repository 介面只有一份，Provider 兩份，方言差異在 Infrastructure 處理
5. AI 可自由改 UI 外觀，但**不可改** action 契約 / fixed binding ID / Designer.cs
6. 所有使用者輸入走參數化查詢，拒絕字串拼接 SQL
7. 寫程式前讀 [`docs/jet-guide.md`](docs/jet-guide.md)；別回頭翻 11,000 行的 `legacy/ideascript.bas`
