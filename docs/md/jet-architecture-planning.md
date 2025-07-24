1. 設計 `專案管理器`
  - 主程序依賴於專案，包括專案組態和專案資料
  - 專案組態包含專案名稱、路徑、資料庫連線字串等
2. 設計 `上下文管理器`
  - 管理當前專案上下文資訊，包括依賴注入的服務和組件
3. 完善 `資料存取層 (DAL)`
  - 提供統一的資料存取接口
  - 當前優先處理 Access 資料庫 及 Excel 資料存取
  - 實現資料庫連線管理、查詢執行、結果集處理等功能
4. 驗證 `Import`, `Validation`, `Filter` 三塊模組
  - 確保 GL 和 TB 的匯入
  - 確保完整性測試
  - 確保借貸不平測試
  - 確保篩選條件邏輯
5. 使用測試資料驗證模組功能

- 由於 VBA 無法將 queryTable 或 Power Query 的查詢結果進行物件操作，因此限定資料來源須先前處理，確保完整後再統一由 ADO/DAO 匯入。
- `DAO` 確實是 ACE/JET 的原生 API，對迴圈式寫入或查詢通常筆 `ADO` 快，但若 VBA 主程式位於 Excel 則單純為了叫用 `DoCmd.TransferText` 而自動化啟動 `Access` 其實會抵銷部分 `DAO` 優勢，改用 **ADO + ACE OLEDB + INSERT...SELECT FROM [TEXT]** 在 Excel 端效能僅慢約10%-20%，省去額外行程、UI 及 COM 繫結開銷。
- 在 Excel 環境最佳實務: `ADO` + `ACE OLEDB 16.0` + `Text Driver` + `BeginTrans`