# 系統架構設計 (System Architecture)

## 設計理念

本專案從傳統的 "Smart UI" (邏輯寫在 Form 或 Sheet 事件中) 轉型為 **MVP (Model-View-Presenter)** 架構。這使得業務邏輯與 UI 顯示分離，讓代碼更易於測試、維護與擴充。

## 架構圖 (Architecture Diagram)

```mermaid
graph TD
    User((User)) --> View[ViewProject.frm <br/> (UI Layer)]
    
    subgraph "VBA Application (Frontend)"
        View <-->|Events / Update UI| Presenter[Presenter.cls]
        Presenter -->|Call| Manager[ManagerProject.cls]
        
        Manager -->|Use| SvcImport[ServiceImport.cls]
        Manager -->|Use| SvcValid[ServiceValidation.cls]
        Manager -->|Use| SvcExport[ServiceExport.cls]
        
        SvcImport -->|Query| DAL[DbAccess.cls]
        SvcValid -->|Query| DAL
        SvcExport -->|Query| DAL
    end
    
    subgraph "Data Layer (Backend)"
        DAL <-->|ADO / SQL| AccessDB[(Access Database <br/> .accdb)]
    end
```

## 模組職責說明

### 1. View (視圖層)
*   **檔案**: `ViewProject.frm`
*   **職責**: 
    *   純粹的顯示層，不包含任何業務邏輯。
    *   將使用者的操作 (點擊按鈕、選擇檔案) 轉發給 Presenter。
    *   提供公開方法 (Public Methods) 供 Presenter 更新畫面 (例如 `ShowMessage`, `UpdateProgress`)。

### 2. Presenter (展示層)
*   **檔案**: `Presenter.cls`
*   **職責**:
    *   作為 View 與 Model/Service 之間的橋樑。
    *   處理 View 的事件，決定要呼叫哪個 Service。
    *   接收 Service 的執行結果，並格式化後回傳給 View 顯示。

### 3. Service (服務層 / 業務邏輯層)
*   **檔案**: `ServiceImport.cls`, `ServiceValidation.cls`, `ServiceExport.cls`
*   **職責**:
    *   包含核心業務邏輯。例如：解析 CSV 檔案、執行借貸平衡檢查、計算完整性測試差異。
    *   不依賴任何 UI 元件 (MsgBox, UserForm)。
    *   發生錯誤時拋出錯誤 (Err.Raise) 或回傳錯誤物件，而非直接顯示訊息。

### 4. Data Access (資料存取層)
*   **檔案**: `DbAccess.cls`, `DbSchema.cls`
*   **職責**:
    *   處理所有與資料庫的低階互動 (Connection string, SQL Command)。
    *   提供高階 API (例如 `ExecuteQuery`, `InsertBatch`) 供 Service 使用。
    *   確保 SQL 注入防護 (雖然在 Access 環境較少見，但仍應注意參數化查詢)。

## 資料流 (Data Flow)

1.  **匯入資料**:
    *   使用者在 `ViewProject` 選擇檔案 -> `Presenter` 接收路徑 -> 呼叫 `ServiceImport` -> `ServiceImport` 解析檔案並透過 `DbAccess` 寫入 Access 資料庫。
2.  **驗證資料**:
    *   使用者點擊驗證 -> `Presenter` 呼叫 `ServiceValidation` -> `ServiceValidation` 透過 `DbAccess` 查詢資料並執行規則檢查 -> 回傳結果給 `Presenter` -> `Presenter` 更新 `ViewProject` 顯示結果。

## 技術選型

*   **前端**: Excel VBA (UserForms)
*   **後端**: Microsoft Access Database Engine (.accdb)
*   **連線介面**: ADODB (Microsoft ActiveX Data Objects)
*   **版本控制**: Git (透過 Python 腳本匯出 VBA 原始碼)