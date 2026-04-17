# Docs Index

本目錄現在分成四類文件：**領域規格、架構規劃、技術實作指南、整理/遷移說明**。

## 文件清單

| 檔案 | 角色 | 狀態 |
|:---|:---|:---|
| `jet-domain-model.md` | JET 業務規格唯一事實來源 | 核心文件 |
| `jet-architecture.md` | 目標系統架構與分層 | 核心文件 |
| `jet-technical-guide.md` | 開發規範與分工準則 | 核心文件 |
| `repo-cleanup-summary.md` | 當前 repo 整理結論與後續 planning | 核心文件 |
| `jet-template.html` | 前端 UI 目標模板 | 參考模板 |
| `ideascript.bas` | 舊版 JE Tool 始祖程式與規則來源 | 遷移參考 |
| `drawio/` | 架構圖素材 | 補充資料 |

## 建議閱讀順序

1. `jet-domain-model.md`
2. `repo-cleanup-summary.md`
3. `jet-architecture.md`
4. `jet-technical-guide.md`
5. `jet-template.html`
6. `ideascript.bas`

## 文件責任邊界

### `jet-domain-model.md`
只描述：
- JET 的業務流程
- 資料模型
- 篩選規則
- 工作底稿需求

不描述：
- WinForms / WebView2 實作細節
- CQRS 類別切分
- 資料庫連線技術

### `jet-architecture.md`
只描述：
- Thin-Bridge Action-Dispatcher
- Application CQRS
- SQLite / SQL Server 分工
- 前後端互動模型

不描述：
- 細部欄位定義
- 每一項審計規則細節

### `jet-technical-guide.md`
只描述：
- 專案結構
- 命名與分層規範
- 模組切分原則
- 遷移與實作步驟

### `repo-cleanup-summary.md`
只描述：
- 現況盤點
- 文件矛盾點
- 目前 repo 要先整理到什麼程度
- 下一步 planning 順序

## 整理原則

- `docs/` 保留 **當前有效規格與規劃**
- `legacy/` 保留 **歷史 VBA 實作與舊文件**
- 舊名或過時文件內容若仍有價值，應整併到現有文件，不再平行維護另一份
- `jet-template.html` 是前端目標模板，不是最終正式位置；正式整合時應移入 .NET 專案資源目錄
