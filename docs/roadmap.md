# 開發進度與規劃 (Roadmap)

## 專案狀態
*   **目前階段**: MVP (Minimum Viable Product) 開發中
*   **目標**: 完成從 Caseware IDEA 到 Excel VBA 的核心功能遷移

## 待辦事項 (To-Do List)

### Phase 1: 基礎建設 (Infrastructure) - [進行中]
- [x] 建立專案目錄結構 (`mvp/src`, `mvp/legacy`, `docs`)
- [x] 定義 MVP 架構 (View, Presenter, Service, DAL)
- [x] 建立基礎 VBA 類別 (`DbAccess`, `ServiceImport` 等)
- [ ] 實作 Python 自動匯出/匯入腳本 (`scripts/export_vba.py`)

### Phase 2: 核心功能遷移 (Core Migration)
- [ ] **資料匯入 (Import)**
    - [ ] 實作 CSV 讀取與編碼偵測 (取代 `ideascript.bas` 的匯入邏輯)
    - [ ] 實作欄位對應 (Mapping) UI
- [ ] **資料驗證 (Validation)**
    - [ ] 移植完整性測試 (Completeness Test) 邏輯
    - [ ] 移植借貸平衡測試 (Balance Check) 邏輯
    - [ ] 移植日期範圍測試 (Date Check) 邏輯
- [ ] **報告輸出 (Export)**
    - [ ] 實作 Excel 底稿產生功能

### Phase 3: 優化與擴充 (Optimization)
- [ ] 效能優化 (大數據量匯入速度)
- [ ] 增加更多 JET 測試規則 (如：週末分錄、整數分錄)
- [ ] 使用者介面美化

## 已知問題 (Known Issues)
*   目前尚未實作完整的錯誤處理機制。
*   Access 資料庫路徑目前為寫死 (Hardcoded)，需改為動態設定。
