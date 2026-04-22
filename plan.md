# JET Implementation Plan

本檔是給下一輪 Visual Studio + GitHub Copilot / Copilot Agent Mode 直接接手的臨時開發計畫。

這份計畫基於下列既有規格整理，不應脫離它們另起爐灶：

1. `README.md`
2. `docs/jet-guide.md`
3. `legacy/README.md`
4. `docs/jet-template.html`
5. `src/JET/.github/copilot-instructions.md`
6. `docs/action-contract-manifest.md`
7. `AGENTS.md`

---

## 0. 開發原則

- 前端只送 `action + payload`，不拼 SQL。
- Bridge 只做 parsing / dispatch / response wrapping，不做業務邏輯。
- Application 採 CQRS，Command / Query 分開。
- Domain 只放純邏輯、實體、值物件、規則定義、repository abstractions。
- Infrastructure 才能碰 SQLite / SQL Server / File I/O / Export。
- SQLite 是當前主開發目標，但介面必須保留 SQL Server 相容能力。
- 不可改寫既有業務語意：GL/TB 標準化欄位、V1-V4、R1-R8、A2-A4、進階篩選規格都以 `docs/jet-guide.md` 為準。
- 不可把 SQLite / SQL Server 差異寫進 Application 層。
- 不可擅自改 action 契約；若必要，先更新 `docs/action-contract-manifest.md`。

---

## 1. 這一輪的實作目標

先做資料與邏輯骨架，不先大改 UI。

本輪應聚焦：

1. 資料庫儲存模型
2. DTO 契約
3. Application / Repository 邊界
4. SQLite-first / SQL Server-compatible 架構

不應優先做：

- 大量 HTML / UX 改版
- 大量一次性 business rule 全部塞進一個大 handler
- 把 provider 差異塞到 Application

---

## 2. 系統資料流總覽

### Step 1. Project / Import

- `project.create`
  - 建立 `Project` 與初始 state
- `import.gl`
  - 建 `import batch`
  - 保存 GL raw rows 到 staging
- `import.tb`
  - 建 `import batch`
  - 保存 TB raw rows 到 staging
- `import.accountMapping`
  - 保存 raw mapping rows
  - 寫 current `target.account_mapping`
- `import.holiday`
  - 保存 raw holiday rows
- `import.makeupDay`
  - 保存 raw makeup day rows
  - 與 holiday 合併重建 `target.date_dimension`

### Step 2. Mapping / Standardization

- `mapping.autoSuggest`
  - 根據 raw columns 與 field definition 回傳建議 mapping
- `mapping.commit`
  - 保存 mapping version
  - 將 raw GL/TB 標準化為：
    - `target.gl_entry`
    - `target.tb_balance`
  - 重建：
    - `target.gl_document_summary`
    - `target.gl_account_summary`

### Step 3. Validation

- `validate.run`
  - 以 target tables 執行 V1-V4
  - 保存 run header 與 detail
  - 前端收到 summary + 首屏 detail / count

### Step 4. Prescreen

- `prescreen.run`
  - 以 target GL + account mapping + date dimension 執行 R1-R8 / A2-A4
  - 保存 rule execution / hit rows / summary

### Step 5. Advanced Filter

- `filter.preview`
  - 以 prescreen 結果 + target GL 計算 scenario preview
- `filter.commit`
  - 保存 scenario 與最終測試母體 snapshot

### Step 6. Workpaper Export

- `export.workpaper`
  - 讀 project / mapping / validation / prescreen / scenario commit
  - 組成 workbook model
  - 寫 export manifest / snapshot
  - 由 exporter 產出 Excel

---

## 3. Database Layering

邏輯分四層：

- `config`
- `staging`
- `target`
- `result`

### SQLite 實作方式

SQLite 無 schema，建議用 table name prefix：

- `config_project`
- `staging_gl_raw_row`
- `target_gl_entry`
- `result_validation_run`

### SQL Server 實作方式

SQL Server 可用正式 schema：

- `config.project`
- `staging.gl_raw_row`
- `target.gl_entry`
- `result.validation_run`

Application 不感知命名差異，由 provider 封裝。

---

## 4. 建議資料表

### 4.1 Project metadata

- `config.project`
  - `ProjectId`
  - `ProjectCode`
  - `EntityName`
  - `Industry`
  - `OperatorId`
  - `PeriodStart`
  - `PeriodEnd`
  - `LastAccountingPeriodDate`
  - `CreatedAt`
  - `UpdatedAt`

- `config.project_state`
  - `ProjectId`
  - `CurrentGlBatchId`
  - `CurrentTbBatchId`
  - `CurrentAccountMappingBatchId`
  - `CurrentCalendarBatchId`
  - `CurrentGlMappingVersion`
  - `CurrentTbMappingVersion`
  - `LatestValidationRunId`
  - `LatestPrescreenRunId`

- `config.project_option`
  - `ProjectId`
  - `OptionKey`
  - `OptionValueJson`

- `config.rule_parameter`
  - `ParameterId`
  - `ProjectId`
  - `RuleId`
  - `ParameterScope`
  - `ParameterJson`
  - `IsCurrent`

- `config.field_mapping`
  - `MappingId`
  - `ProjectId`
  - `DatasetKind`
  - `ImportBatchId`
  - `MappingVersion`
  - `StandardField`
  - `SourceColumn`
  - `ExtraJson`
  - `IsCurrent`

### 4.2 Raw import

- `config.import_batch`
  - `ImportBatchId`
  - `ProjectId`
  - `DatasetKind`
  - `FileName`
  - `ImportedAt`
  - `RowCount`
  - `ColumnCount`
  - `ContentHash`
  - `Status`

- `config.import_column`
  - `ImportBatchId`
  - `Ordinal`
  - `ColumnName`
  - `NormalizedName`
  - `SampleValue`

- `staging.gl_raw_row`
  - `RawRowId`
  - `ProjectId`
  - `ImportBatchId`
  - `RowNo`
  - `RawJson`
  - `SourceRowHash`

- `staging.tb_raw_row`
  - `RawRowId`
  - `ProjectId`
  - `ImportBatchId`
  - `RowNo`
  - `RawJson`
  - `SourceRowHash`

- `staging.account_mapping_raw_row`
  - `RawRowId`
  - `ProjectId`
  - `ImportBatchId`
  - `RowNo`
  - `RawJson`

- `staging.calendar_raw_day`
  - `RawCalendarId`
  - `ProjectId`
  - `ImportBatchId`
  - `CalendarType`
  - `DateText`
  - `Description`

### 4.3 Standardized target

- `target.gl_entry`
  - `GlEntryId`
  - `ProjectId`
  - `SourceImportBatchId`
  - `MappingVersion`
  - `DocumentNumber`
  - `LineItem`
  - `Amount`
  - `DebitAmount`
  - `CreditAmount`
  - `DrCr`
  - `AccountCode`
  - `AccountName`
  - `DocumentDescription`
  - `ApprovalDate`
  - `PostDate`
  - `CreatedBy`
  - `ApprovedBy`
  - `SourceModule`
  - `IsManual`
  - `SourceRawRowId`

- `target.tb_balance`
  - `TbBalanceId`
  - `ProjectId`
  - `SourceImportBatchId`
  - `MappingVersion`
  - `AccountCode`
  - `AccountName`
  - `ChangeAmount`
  - `OpeningBalance`
  - `ClosingBalance`
  - `OpeningDebitBalance`
  - `OpeningCreditBalance`
  - `ClosingDebitBalance`
  - `ClosingCreditBalance`
  - `DebitAmount`
  - `CreditAmount`
  - `SourceRawRowId`

- `target.gl_document_summary`
  - `ProjectId`
  - `DocumentNumber`
  - `LineCount`
  - `NetAmount`
  - `DebitTotal`
  - `CreditTotal`
  - `FirstPostDate`
  - `FirstApprovalDate`

- `target.gl_account_summary`
  - `ProjectId`
  - `AccountCode`
  - `LineCount`
  - `AmountSum`
  - `DebitTotal`
  - `CreditTotal`

### 4.4 Mapping / DateDimension

- `target.account_mapping`
  - `AccountMappingId`
  - `ProjectId`
  - `SourceImportBatchId`
  - `AccountCode`
  - `AccountName`
  - `StandardizedCategory`
  - `IsCurrent`

- `target.date_dimension`
  - `ProjectId`
  - `DateKey`
  - `FullDate`
  - `DayOfWeek`
  - `IsWeekend`
  - `IsHoliday`
  - `IsMakeupDay`
  - `HolidayDesc`
  - `MakeupDayDesc`

### 4.5 Validation results

- `result.validation_run`
- `result.validation_v1_detail`
- `result.validation_v2_document`
- `result.validation_v3_sample`
- `result.validation_v4_detail`

### 4.6 Prescreen results

- `result.prescreen_run`
- `result.rule_execution`
- `result.rule_hit_row`
- `result.rule_document_hit`
- `result.rule_summary`

### 4.7 Scenario / advanced filter

- `config.scenario`
- `config.scenario_group`
- `config.scenario_rule`
- `result.scenario_preview`
- `result.scenario_preview_row`
- `result.scenario_commit`
- `result.scenario_commit_row`

### 4.8 Workpaper snapshot

- `result.workpaper_export_run`
- `result.workpaper_sheet_snapshot`

---

## 5. DTO 分層

### 5.1 Frontend-visible DTO

- `BridgeRequestEnvelope`
- `BridgeResponseEnvelope`
- `BridgeErrorDto`

- `CreateProjectRequestDto`
- `CreateProjectResponseDto`
- `LoadProjectRequestDto`
- `LoadProjectResponseDto`
- `ImportGlRequestDto`
- `ImportGlResponseDto`
- `ImportTbRequestDto`
- `ImportTbResponseDto`
- `ImportAccountMappingRequestDto`
- `ImportAccountMappingResponseDto`
- `ImportCalendarRequestDto`
- `ImportCalendarResponseDto`
- `CommitFieldMappingRequestDto`
- `CommitFieldMappingResponseDto`
- `RunValidationRequestDto`
- `RunValidationResponseDto`
- `RunPrescreenRequestDto`
- `RunPrescreenResponseDto`
- `PreviewScenarioRequestDto`
- `PreviewScenarioResponseDto`
- `CommitScenarioRequestDto`
- `CommitScenarioResponseDto`
- `ExportWorkpaperRequestDto`
- `ExportWorkpaperResponseDto`

### 5.2 Application internal DTO / command / query

- `CreateProjectCommand`
- `LoadProjectQuery`
- `ImportGlCommand`
- `ImportTbCommand`
- `ImportAccountMappingCommand`
- `ImportCalendarCommand`
- `CommitFieldMappingCommand`
- `RunValidationCommand`
- `RunPrescreenCommand`
- `PreviewScenarioQuery`
- `CommitScenarioCommand`
- `ExportWorkpaperCommand`

- `ProjectCreatedResult`
- `ProjectLoadedResult`
- `ImportBatchAcceptedResult`
- `FieldMappingCommittedResult`
- `ValidationRunResult`
- `PrescreenRunResult`
- `ScenarioPreviewResult`
- `ScenarioCommitResult`
- `WorkpaperExportResult`

### 5.3 Export internal DTO

- `WorkpaperWorkbookModel`
- `WorkpaperSheetModel`
- `WorkpaperSectionModel`
- `WorkpaperExportArtifactDto`

---

## 6. Repository Abstractions

### `IProjectRepository`

- `CreateAsync`
- `GetAsync`
- `GetByCodeAsync`
- `GetStateAsync`
- `SaveOptionsAsync`
- `SetCurrentPointersAsync`

### `IGlRepository`

- `CreateImportBatchAsync`
- `StageRawAsync`
- `GetRawColumnsAsync`
- `StandardizeAsync`
- `RebuildDocumentSummaryAsync`
- `RebuildAccountSummaryAsync`
- `GetPageAsync`
- `GetByDocumentAsync`

### `ITbRepository`

- `CreateImportBatchAsync`
- `StageRawAsync`
- `GetRawColumnsAsync`
- `StandardizeAsync`
- `GetPageAsync`

### `IAccountMappingRepository`

- `ReplaceCurrentAsync`
- `GetCurrentAsync`
- `GetCategoryLookupAsync`

### `IDateDimensionRepository`

- `ReplaceCalendarInputAsync`
- `RebuildDateDimensionAsync`
- `GetRangeAsync`

### `IValidationRepository`

- `RunAsync`
- `GetLatestRunAsync`
- `GetSummaryAsync`
- `GetV1DetailPageAsync`
- `GetV2DocumentPageAsync`
- `GetV3SampleAsync`
- `GetV4DetailPageAsync`

### `IPreScreenRepository`

- `RunAsync`
- `GetRunSummaryAsync`
- `GetRuleExecutionAsync`
- `GetRuleHitsPageAsync`
- `GetRuleSummaryRowsAsync`

### `IScenarioRepository`

- `PreviewAsync`
- `SaveAsync`
- `CommitAsync`
- `GetCommittedAsync`

### `IWorkpaperExporter`

- `ExportAsync`
- `CreateManifestAsync`

---

## 7. Provider 差異責任

以下差異必須封裝在 Infrastructure，不可上推到 Application：

- SQLite raw import:
  - prepared statement batch insert
- SQL Server raw import:
  - `SqlBulkCopy`

- V1 completeness:
  - SQLite 用 UNION-based `FULL OUTER JOIN` 模擬
  - SQL Server 用 native `FULL OUTER JOIN`

- R2 / A2 keyword / regex:
  - SQLite 用 UDF 或 token strategy
  - SQL Server 用 `LIKE` / `PATINDEX` / helper function

- V3 sample:
  - 避免 `ORDER BY random()` 全表排序
  - 使用 stable seed / hash

- date series / date dimension rebuild:
  - provider 內處理產生方式

---

## 8. Action 對應 handler

### `project.create`

- Request DTO: `CreateProjectRequestDto`
- Dependencies: `IProjectRepository`
- Write path:
  - `config.project`
  - `config.project_state`
  - `config.project_option`
- Output: `CreateProjectResponseDto`

### `project.load`

- Request DTO: `LoadProjectRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IValidationRepository`
  - `IPreScreenRepository`
  - `IScenarioRepository`
- Read path:
  - project metadata
  - current batch pointers
  - latest run headers
- Output: `LoadProjectResponseDto`

### `import.gl`

- Request DTO: `ImportGlRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IGlRepository`
  - optional file reader abstraction
- Write path:
  - `config.import_batch`
  - `config.import_column`
  - `staging.gl_raw_row`
  - update current GL batch pointer
- Output: `ImportGlResponseDto`

### `import.tb`

- Request DTO: `ImportTbRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `ITbRepository`
- Write path:
  - `config.import_batch`
  - `config.import_column`
  - `staging.tb_raw_row`
  - update current TB batch pointer
- Output: `ImportTbResponseDto`

### `import.accountMapping`

- Request DTO: `ImportAccountMappingRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IAccountMappingRepository`
- Write path:
  - `config.import_batch`
  - `staging.account_mapping_raw_row`
  - `target.account_mapping`
- Output: `ImportAccountMappingResponseDto`

### `import.holiday` / `import.makeupDay`

- Request DTO: `ImportCalendarRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IDateDimensionRepository`
- Write path:
  - `config.import_batch`
  - `staging.calendar_raw_day`
  - rebuild `target.date_dimension`
- Output: `ImportCalendarResponseDto`

### `mapping.commit`

- Request DTO: `CommitFieldMappingRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IGlRepository`
  - `ITbRepository`
- Write path:
  - `config.field_mapping`
  - rebuild `target.gl_entry` or `target.tb_balance`
  - rebuild summaries
- Output: `CommitFieldMappingResponseDto`

### `validate.run`

- Request DTO: `RunValidationRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IValidationRepository`
- Read path:
  - `target.gl_entry`
  - `target.tb_balance`
  - target summaries
- Write path:
  - `result.validation_*`
- Output: `RunValidationResponseDto`

### `prescreen.run`

- Request DTO: `RunPrescreenRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IPreScreenRepository`
- Read path:
  - `target.gl_entry`
  - `target.account_mapping`
  - `target.date_dimension`
  - `config.rule_parameter`
- Write path:
  - `result.prescreen_*`
- Output: `RunPrescreenResponseDto`

### `filter.preview`

- Request DTO: `PreviewScenarioRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IScenarioRepository`
- Read path:
  - target GL
  - prescreen hits
- Optional write path:
  - `result.scenario_preview*`
- Output: `PreviewScenarioResponseDto`

### `filter.commit`

- Request DTO: `CommitScenarioRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IScenarioRepository`
- Write path:
  - `config.scenario*`
  - `result.scenario_commit*`
- Output: `CommitScenarioResponseDto`

### `export.workpaper`

- Request DTO: `ExportWorkpaperRequestDto`
- Dependencies:
  - `IProjectRepository`
  - `IValidationRepository`
  - `IPreScreenRepository`
  - `IScenarioRepository`
  - `IAccountMappingRepository`
  - `IWorkpaperExporter`
- Read path:
  - config + target + result
- Write path:
  - `result.workpaper_export_run`
  - `result.workpaper_sheet_snapshot`
- Output: `ExportWorkpaperResponseDto`

---

## 9. SQLite-first 效能策略

### Bulk insert

- 正式版不要透過 WebView2 JSON 直接傳 100 萬到 500 萬筆 rows。
- Host 應提供 `fileToken` / `sourceHandle`，Infrastructure 直接讀檔。
- SQLite:
  - prepared statement
  - batched insert
  - chunk size 約 `5,000 ~ 20,000`
- SQL Server:
  - `SqlBulkCopy`

### Transaction

- raw import: 一個 outer transaction
- 超大檔可 chunk transaction + batch finalize
- standardize rebuild: 一個 dataset 一個 transaction
- validation / prescreen / scenario commit / export manifest:
  - 每次 run 一個 transaction

### Index

- raw staging 只保留最小索引：
  - `(ProjectId, ImportBatchId, RowNo)`
- target 完成後建立：
  - `DocumentNumber`
  - `AccountCode`
  - `PostDate`
  - `ApprovalDate`
  - `CreatedBy`

### Paging

- 大表一律 keyset paging
- 不做深頁 OFFSET
- `validate.run` / `prescreen.run` 回 summary，不回完整大明細

### Materialized strategy

建議 materialize：

- `target.gl_document_summary`
- `target.gl_account_summary`
- `result.rule_document_hit`

### Raw vs summarized

- raw rows 必留，因為 mapping 可能重做
- standardized target tables 必留，因為後續所有流程都依賴它
- repeated aggregation 應以 summary table 保存

### 建議切 SQL Server 的情況

- 單專案 GL 穩定超過 500 萬且反覆 rerun
- 多使用者並行
- 長期保留大量 snapshot
- 大量全文條件反覆掃描
- 匯出與查詢同時密集發生

---

## 10. 建議實作順序

### Phase 1. Import 最小閉環

1. 建：
   - `config.project`
   - `config.project_state`
   - `config.import_batch`
   - `config.import_column`
   - `staging.gl_raw_row`
   - `staging.tb_raw_row`
2. 完成 `project.create`
3. 完成 `import.gl`
4. 完成 `import.tb`
5. 完成 `project.load`

### Phase 2. Standardized schema

1. 建 `config.field_mapping`
2. 建 `target.gl_entry`
3. 建 `target.tb_balance`
4. 建 `target.gl_document_summary`
5. 建 `target.gl_account_summary`
6. 完成 `mapping.commit`

### Phase 3. Validation

1. 建 `result.validation_run`
2. 先做 V2
3. 再做 V4
4. 再做 V1
5. 最後做 V3

### Phase 4. Prescreen

1. 建 `target.account_mapping`
2. 建 `target.date_dimension`
3. 建 `result.prescreen_run`
4. 建 `result.rule_execution`
5. 建 `result.rule_hit_row`
6. 建 `result.rule_summary`
7. 先做：
   - `R1`
   - `R2`
   - `R4`
8. 再做：
   - `R5`
   - `R6`
9. 再做：
   - `R3`
   - `R7`
   - `R8`
10. 最後補：
   - `A2`
   - `A3`
   - `A4`

### Phase 5. Advanced filter

1. 建 `config.scenario*`
2. 建 `result.scenario_preview*`
3. 建 `result.scenario_commit*`
4. 完成 `filter.preview`
5. 完成 `filter.commit`

### Phase 6. Workpaper export

1. 建 `result.workpaper_export_run`
2. 建 `result.workpaper_sheet_snapshot`
3. 建 workbook model
4. 先輸出：
   - `Engagement Overview`
   - `Data Overview`
   - `Validation Overview`
5. 再輸出 validation details
6. 再輸出 rules sheets
7. 再輸出 mapping info / field mapping info

---

## 11. 建議交給 AI 的小任務拆法

1. 建 project/config/import batch schema 與 repository skeleton
2. 做 GL raw import pipeline
3. 做 TB raw import pipeline
4. 做 project.load state DTO
5. 做 GL mapping commit + standardization
6. 做 TB mapping commit + standardization
7. 做 V2 + V4
8. 做 V1
9. 做 V3
10. 做 account mapping import
11. 做 holiday / makeup day import + date dimension rebuild
12. 做 R1 / R2 / R4
13. 做 R5 / R6
14. 做 R3 / R7 / R8
15. 做 A2 / A3 / A4
16. 做 scenario schema + preview engine
17. 做 scenario commit snapshot
18. 做 workpaper manifest + first 3 sheets
19. 做 full workpaper export

---

## 12. 本檔用途

本檔是臨時開發計畫，用來讓下一輪 Visual Studio 的 GitHub Copilot 直接依照這裡開始實作。

若本計畫與 `docs/jet-guide.md`、`docs/action-contract-manifest.md` 發生衝突：

- 以 `docs/jet-guide.md` 與正式規格文件為準
- 實作時若修正本計畫，應同步更新正式文件，而不是只改這份臨時計畫
