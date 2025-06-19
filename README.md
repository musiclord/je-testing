# JET VBA 專案

## 專案概觀

本專案是一個使用 VBA (Visual Basic for Applications) 開發的 Excel 應用程式，旨在協助處理和分析財務資料，特別是總帳 (GL) 和試算表 (TB) 資料。它提供了一個多步驟的使用者介面，引導使用者完成資料匯入、設定、驗證和分析的流程。後端資料儲存使用 Microsoft Access 資料庫。

## 主要功能

*   **CSV 資料匯入:**
    *   支援匯入 GL 和 TB 的 CSV 檔案。
    *   自動偵測 CSV 檔案編碼 (UTF-8, Big5 等)。
    *   將資料匯入至指定的 Access 資料庫 (`default.accdb`) 中的對應資料表。
*   **資料預覽:**
    *   在 Excel 工作表中預覽從 Access 資料庫載入的資料表內容 (GL 或 TB)。
    *   可設定預覽的最大列數。
*   **欄位對應設定:**
    *   提供使用者介面 (`vTBConfig`, `vGLConfig`) 設定來源 CSV 檔案欄位與目標資料庫欄位的對應關係。
    *   儲存和管理這些對應關係 (`MappingService.cls`)。
*   **資料驗證:**
    *   執行資料驗證程序，例如完整性測試 (`ValidationService.TestCompleteness`)，比較 GL 和 TB 資料。
*   **多步驟使用者介面:**
    *   透過主表單 `vMain` 引導使用者完成各項操作步驟。
    *   包含專案設定、TB/GL 設定、資料驗證、篩選條件設定等階段。

## 核心元件

### 主要類別模組 (Class Modules)

*   **`cApplication.cls`**: 應用程式的主要控制器，負責協調各個服務和使用者介面之間的互動。
*   **`AccessDAL.cls`**: 資料存取層 (Data Access Layer)，封裝了所有與 Access 資料庫的互動邏輯 (連線、執行 SQL、讀取資料等)。
*   **`ImportService.cls`**: 處理 CSV 檔案匯入到 Access 資料庫的邏輯。
*   **`PreviewService.cls`**: 負責從 Access 資料庫讀取資料並在 Excel 工作表中顯示預覽。
*   **`MappingService.cls`**: 管理和儲存 GL 及 TB 的欄位對應關係。
*   **`ValidationService.cls`**: 包含資料驗證的相關邏輯，例如完整性測試。
*   **`GLService.cls` / `TBService.cls`**: 分別處理 GL 和 TB 特定的業務邏輯 (目前較為基礎)。
*   **`GLEntity.cls` / `TBEntity.cls`**: 定義 GL 和 TB 資料的實體結構。
*   **`AppConfig.cls`**: (推測) 用於儲存應用程式的設定和參數。

### 主要表單模組 (Form Modules)

*   **`vMain.frm`**: 應用程式的主視窗，提供各主要功能的入口。
*   **`vProject.frm`**: 專案設定相關的表單。
*   **`vTBConfig.frm`**: TB 資料匯入和欄位對應設定表單。
*   **`vGLConfig.frm`**: GL 資料匯入和欄位對應設定表單。
*   **`vValidation.frm`**: 資料驗證相關操作的表單。
*   **`vCriteria.frm`**: (推測) 用於設定篩選條件的表單。

### 標準模組 (Standard Modules)

*   **`mod_Utility.bas`**: 包含通用的輔助函數，例如 `Start` 程序 (啟動應用程式) 和 `DetectCSVEncoding` (偵測 CSV 編碼)。

## 工作流程 (Workflow)

應用程式的典型工作流程大致如下 (由 `cApplication.cls` 控制)：

1.  **啟動應用程式**: 透過執行 `mod_Utility.Start` 程序來初始化並顯示主介面 `vMain`。
2.  **步驟 1: 專案與資料匯入設定**
    *   使用者透過 `vMain` 進入步驟 1。
    *   **專案設定 (`vProject`)**: (具體功能待確認)
    *   **TB 設定 (`vTBConfig`)**:
        *   匯入 TB CSV 檔案。
        *   預覽匯入的 TB 資料。
        *   設定 TB 欄位對應。
    *   **GL 設定 (`vGLConfig`)**:
        *   匯入 GL CSV 檔案。
        *   預覽匯入的 GL 資料。
        *   設定 GL 欄位對應。
3.  **步驟 2: 資料驗證 (`vValidation`)**
    *   執行各種資料驗證測試，例如：
        *   完整性測試。
        *   文件平衡測試。
        *   RDE 測試。
        *   科目對應。
4.  **步驟 3: 篩選條件 (`vCriteria`)**
    *   設定用於後續分析或報表產生的篩選條件。
5.  **步驟 4: (待定義)**
    *   後續的資料處理或分析步驟。

## 如何使用

1.  開啟 `JET.xlsm` 檔案。
2.  (如果需要) 啟用巨集。
3.  預期會有一個按鈕或方式來觸發 `mod_Utility.Start` 程序以啟動應用程式主介面。

## 注意事項

*   本專案依賴 Microsoft Access Database Engine。請確保已安裝相應版本的 Access Database Engine (例如 Microsoft.ACE.OLEDB.12.0)。
*   部分功能 (如 `PreviewService` 中設定工作表 CodeName) 可能需要啟用 "信任 VBA 專案物件模型存取" (在 Excel 選項 -> 信任中心 -> 信任中心設定 -> 巨集設定中)。
*   資料庫檔案 `default.accdb` 預期與 `JET.xlsm` 檔案位於同一目錄下。

---
*此 README.md 檔案是根據程式碼庫自動產生的初步版本，可能需要進一步的手動調整和補充。*