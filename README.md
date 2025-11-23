# JET VBA Project

## 專案概觀 (Project Overview)

本專案旨在將原有的 Caseware IDEA 腳本 (`ideascript.bas`) 重構為基於 **Microsoft Office 生態系 (Excel VBA + Access Database)** 的現代化解決方案。

目標是建立一個輕量、易於維護且符合 SOLID 原則的 **Journal Entry Testing (JET)** 工具，協助審計人員進行日記帳分錄測試。

## 專案架構 (Project Structure)

本專案採用 **MVP (Model-View-Presenter)** 架構模式，以確保關注點分離 (Separation of Concerns) 與代碼的可測試性。

```text
jet-vba/
├── .github/                # GitHub 配置
├── .vscode/                # VS Code 配置
├── data/                   # 測試資料
├── docs/                   # 專案文件
│   ├── architecture.md     # 架構設計說明
│   ├── user_manual.md      # 使用者手冊
│   └── roadmap.md          # 開發進度與規劃
├── mvp/                    # 主要開發目錄
│   ├── legacy/             # [舊代碼] 來自舊版 .xlsm 的備份 (唯讀)
│   │   ├── v_0822/         # jet-0822.xlsm 匯出代碼
│   │   └── v_1120/         # jet-1120.xlsm 匯出代碼
│   ├── src/                # [新代碼] 目前開發中的原始碼 (Single Source of Truth)
│   │   └── vba-mvp/        # VBA 類別與模組
│   └── jet-mvp-dev.xlsm    # 開發用的 Excel 容器
└── scripts/                # 自動化工具 (Python)
```

## 核心元件 (Core Components)

位於 `mvp/src/vba-mvp/` 的核心類別：

### MVP 架構層
*   **`ViewProject.frm` (View)**: 使用者介面，負責顯示資訊與接收使用者操作。不包含業務邏輯。
*   **`Presenter.cls` (Presenter)**: 協調者。接收 View 的事件，呼叫 Service 處理業務邏輯，並更新 View。
*   **`ManagerProject.cls`**: 專案管理器，負責初始化與協調高層級的專案操作。

### 服務層 (Services)
*   **`ServiceImport.cls`**: 負責將外部資料 (CSV/Excel) 匯入至 Access 資料庫。
*   **`ServiceValidation.cls`**: 執行資料驗證規則 (如借貸平衡、完整性測試)。
*   **`ServiceExport.cls`**: 負責產生測試底稿與報告。

### 資料存取層 (Data Access)
*   **`DbAccess.cls`**: 封裝 ADODB 連線與 SQL 執行邏輯，與 Access 資料庫溝通。
*   **`DbSchema.cls`**: 定義資料庫結構與 Schema。
*   **`SchemaTypes.bas`**: 定義資料型態常數與列舉。

## 開發指南 (Development Guide)

1.  **代碼位置**: 所有新的開發應在 `mvp/src/` 中進行。
2.  **版本控制**: 使用 Python 腳本將 Excel 中的 VBA 匯出為文字檔 (`.cls`, `.bas`) 進行 Git 版控。
3.  **設計原則**:
    *   **單一職責 (SRP)**: 每個類別只做一件事。
    *   **依賴反轉 (DIP)**: 高層模組不應依賴低層模組，兩者都應依賴抽象 (介面)。

## 舊版參考 (Legacy Reference)

舊有的 IDEA 腳本位於 `docs/idea/ideascript.bas`，僅供邏輯參考，不應直接使用。
舊版 Excel VBA 代碼位於 `mvp/legacy/`。