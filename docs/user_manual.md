# 使用者手冊 (User Manual)

> [!NOTE]
> 本系統目前處於開發階段 (MVP)，介面與功能可能會隨版本更新而變動。

## 系統需求

*   Microsoft Excel 2016 或更高版本 (需啟用巨集)
*   Microsoft Access Database Engine (通常隨 Office 安裝)
*   Windows 作業系統

## 快速開始

1.  **開啟工具**: 打開 `mvp/jet-mvp-dev.xlsm` (或最新發布的 `.xlsm` 檔案)。
2.  **啟用內容**: 若 Excel 提示安全性警告，請點擊「啟用內容」以允許 VBA 巨集執行。
3.  **啟動主畫面**: 點擊 Excel 功能區中的「JET Tools」按鈕 (或執行 `Start` 巨集) 開啟主控制台。

## 操作流程

### 步驟 1: 建立專案 (Project Setup)
1.  在主畫面點擊 **"New Project"**。
2.  輸入專案名稱與客戶名稱。
3.  系統會自動在背景建立一個新的 Access 資料庫來儲存該專案的資料。

### 步驟 2: 匯入資料 (Import Data)
本系統支援匯入 CSV 或 Excel 格式的總帳 (GL) 與試算表 (TB) 資料。

1.  切換至 **"Import"** 分頁。
2.  **匯入 TB**: 點擊 "Select TB File"，選擇檔案後，設定欄位對應 (Mapping)。
3.  **匯入 GL**: 點擊 "Select GL File"，選擇檔案後，設定欄位對應。
4.  點擊 **"Run Import"** 開始匯入。系統會顯示進度條。

### 步驟 3: 執行驗證 (Validation)
資料匯入後，系統可自動執行一系列的 JET 測試。

1.  切換至 **"Validation"** 分頁。
2.  勾選欲執行的測試項目：
    *   **Completeness Test**: 檢查 GL 匯總金額是否與 TB 平衡。
    *   **Balance Check**: 檢查 GL 借貸是否平衡。
    *   **Date Check**: 檢查交易日期是否在會計期間內。
3.  點擊 **"Run Validation"**。
4.  測試結果將顯示在下方的結果清單中，異常項目會標示為紅色。

### 步驟 4: 匯出報告 (Export)
1.  驗證完成後，點擊 **"Export Report"**。
2.  系統將產生一份 Excel 底稿，包含所有測試結果與異常明細。

## 常見問題 (FAQ)

**Q: 為什麼匯入大檔案時 Excel 會沒有回應？**
A: 這是正常現象。系統正在背景處理大量數據寫入資料庫。請耐心等待進度條完成。

**Q: 如何備份專案資料？**
A: 專案資料儲存在同目錄下的 `.accdb` 檔案中。直接複製該檔案即可備份。