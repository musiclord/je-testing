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

**Visual Studio 2026 + GitHub Copilot Agent Mode + C# + .NET 10 LTS + WinForms Host + WebView2 + AI 生成 HTML 前端 + SQL Server**

### 架構概要

| 層級 | 技術 | 職責 |
|:---|:---|:---|
| Frontend | HTML / CSS / JS | UI 操作介面 (由 AI 生成與迭代) |
| Desktop Host | WinForms + WebView2 | 桌面容器、打包為單一 .exe |
| Service Layer | C# / .NET 10 | 業務邏輯、參數驗證、流程控制 |
| Database | SQL Server | ETL、規則引擎、大量運算、結果儲存 |

### 為什麼選擇這個方案

- **SQL Server**: 支援數千至數千萬筆 GL/TB 資料處理
- **.NET + WinForms**: 打包成本地 .exe，不需架 web server，符合資安要求
- **WebView2 + HTML**: AI 最擅長生成的前端形式，可快速迭代
- **Visual Studio 2026**: GitHub Copilot Agent Mode 深度整合，支援 AI 全流程開發
- **C#**: 社群資源最豐富、AI 生成品質最佳、現代 .NET 生態主流

詳細架構設計見 [`docs/architecture.md`](docs/architecture.md)，完整決策過程見 [`總結.md`](總結.md)。

---

## 專案架構 (Project Structure)

```text
je-testing/
├── docs/                              # 文件
│   ├── jet-domain-model.md            # [核心] JET 領域知識模型 — 業務邏輯 Single Source of Truth
│   ├── architecture.md                # [核心] 系統架構設計 (.NET)
│   ├── technical_guide.md             # [核心] 技術開發指南 (.NET)
│   ├── ideascript.bas                 # [參考] 原始 IDEA 腳本 — 領域知識原始來源
│   ├── drawio/                        # [參考] 架構圖
│   └── JE_Testing_Tool_1.html         # [參考] HTML UI 原型
├── data/                              # 範例測試資料
│   ├── JE.xlsx                        #   GL 範例資料
│   ├── TB.xlsx                        #   TB 範例資料
│   ├── _Holiday_2024_CN.xlsx          #   假日曆範例
│   └── _MakeupDay_2024_CN.xlsx        #   補班日曆範例
├── src/                               # .NET 專案 (Visual Studio 2026)
│   └── (待建立 — 專案名稱未定)
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

閱讀 **[`docs/architecture.md`](docs/architecture.md)** — 新版 .NET 系統架構設計：

- 五層架構 (Frontend → WinForms Host → Service Layer → Data Access → SQL Server)
- WebView2 Bridge 通訊模式
- 資料流設計
- 技術選型依據

### 開發指南

閱讀 **[`docs/technical_guide.md`](docs/technical_guide.md)** — .NET 版本開發規範：

- WebView2 Bridge 模式
- Service Layer 設計
- SQL Server 資料庫分層設計
- AI 輔助開發範圍
- 雙機開發策略 (Mac + Windows)

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
| **Phase 2** | **C# + .NET 10 + WinForms + WebView2 + SQL Server** | **當前開發方向** |

---

## 設計原則

- **領域優先 (Domain First)** — 先釐清業務邏輯，再決定實作技術
- **平台無關 (Platform Agnostic)** — 領域知識文件不綁定任何特定工具或語言
- **單一事實來源 (Single Source of Truth)** — `jet-domain-model.md` 為所有實作的業務規格依據
- **AI 最大化 (AI-First Development)** — 選擇最適合 AI 自動化開發與測試的技術框架
