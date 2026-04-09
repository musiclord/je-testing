# Legacy — VBA 實作歸檔

本目錄包含 JET 工具的歷史 VBA 實作版本，已不再進行維護。保留目的為業務邏輯參考與知識傳承。

## 目錄說明

| 目錄 / 檔案 | 說明 |
|:---|:---|
| `vba-mvp/` | MVP 架構重構版 VBA 原始碼 (36 個類別/模組)，採用 Presenter-Service-DataAccess 分層 |
| `vba-mvp.xlsm` | MVP 版本對應的 Excel 工作簿 |
| `vba-1120/` | 較早期的 VBA 實作版本 |
| `vba-1120.xlsm` | 早期版本對應的 Excel 工作簿 |
| `SqlBuilder.xlsm` | SQL 建構輔助工具 |
| `docs/` | VBA 實作的技術文件 (架構設計、開發指南) |

## 技術棧 (已棄用)

- **前端**: Excel VBA (UserForms)
- **後端**: Microsoft Access Database Engine (.accdb)
- **連線介面**: DAO (Data Access Objects)

## 棄用原因

專案已決定遷移至 **C# + .NET 10 LTS + WinForms + WebView2 + SQL Server** 技術棧，以滿足：

- AI 輔助開發的完整工具鏈支援 (build / test / refactor)
- 大量資料處理需求 (SQL Server 取代 Access)
- 企業部署需求 (單一 .exe，不需架 web server)
- 資安合規 (避免 Python，使用公司核准的 .NET 生態)

詳見主目錄 `docs/architecture.md` 與根目錄 `總結.md`。
