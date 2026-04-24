# JET Implementation Plan (v2, 重寫)

本檔是下一輪 Visual Studio 18.5 + GitHub Copilot / Agent Mode 進場時的臨時 working plan。  
上一版 plan.md 過度偏向「資料庫與 DTO skeleton」，忽略了目前 repo 真實漂移點。本版以 **現況 → 差距 → 收斂順序** 的方式重寫，並且不脫離 `docs/jet-guide.md` 與 `docs/action-contract-manifest.md`。

權威文件順序（衝突時以前者為準）：

1. `docs/jet-guide.md`（業務規則與架構邊界）
2. `docs/action-contract-manifest.md`（前後端契約）
3. `AGENTS.md`（agent 導引地圖）
4. `docs/agent-harness.md` / `docs/copilot-visualstudio-harness-spec.md`（harness 策略）
5. `.github/copilot-instructions.md` + `.github/instructions/**` + `.github/skills/**`
6. 本檔 `plan.md`（臨時 working plan；若與上述衝突，改上述，不要只改這裡）

---

## 0. Engineering Maxims（每次改碼前自問）

遵循 `.github/copilot-instructions.md` 的五條原則，本計畫全部任務皆以此檢核：

1. **Good Taste** — 消除特殊分支。Provider 差異封裝在 Infrastructure，規則差異走 Handler + Strategy，不在 Application 出現 `if provider == Sqlite`。
2. **Don't Break Userspace** — 不改既有 `action name` / `payload field` / fixed `data-bind` / `Designer.cs`。契約只做 additive change。
3. **Simplify Before Extending** — 先確認是否可重用現有 action / handler / repository，再寫新碼。先改 `docs/action-contract-manifest.md`，再改實作。
4. **Paranoid About Simplicity** — `Form1.cs` 只做 WebView2 host；Bridge 只做 JSON transport + dispatch；不建「聰明」的抽象層。
5. **Surgical Changes** — 只動該動的，不順手重構相鄰程式碼。不為未來需求寫 code。

**JET 的業務定位提醒**：JET = 會計師查核用的 Journal Entry Testing 工具。資料量規模是 GL 10 萬～500 萬筆、TB 數千筆科目；輸出是工作底稿 (workpaper)。必須支援 SQLite（單機、查核現場）與 SQL Server（事務所集中）兩種 provider。前端是 WinForms + WebView2 載入 HTML shell，因此前端 fallback 不會有使用者看到——它只是 AI 生成 UI 時的 preview，不應該承擔業務邏輯。

---

## 1. 現況盤點（截至本輪）

### 1.1 已到位的東西

- `src/JET/JET.slnx`：`JET.csproj` + `JET.Tests.csproj` 兩個專案。
- Bridge 層：
  - `Bridge/ActionDispatcher.cs`：actions 以 dictionary 路由，所有既有 action 皆已實作（見 `docs/action-contract-manifest.md`）。
  - `Bridge/JetBridgeScriptFactory.cs`：注入 `window.jet.invoke(action, payload)` 作為 WebView2 → host 的統一入口（已抽象，沒有讓 UI 直接寫 `window.chrome.webview.postMessage`）。
- Application 層：CQRS 命名齊全（`Commands/*` + `Queries/*`）；每個 action 已有對應 handler。
- Domain 層：`IAppStateStore`、`IProjectSessionStore`、`ProjectInfo`、`DatabaseProvider` enum。
- Infrastructure 層：
  - `Persistence/Sqlite/SqliteAppStateStore.cs`（只做 heartbeat 寫入 `AppState`）
  - `Persistence/SqlServer/SqlServerAppStateStore.cs`
  - `Persistence/InMemoryProjectSessionStore.cs`（目前所有 GL/TB/Mapping/Holiday/MakeupDay 資料「全部住在 RAM」）
- Demo Data：`Application/DemoData/DeterministicDemoProjectDataGenerator.cs` 後端生成、`project.loadDemo` 回前端 raw rows，未把計算結果 bake 進前端。
- Harness：`.github/{copilot-instructions.md, instructions, prompts, agents, skills}` 完整，與 `AGENTS.md` 一致。

### 1.2 明確的架構漂移（必須先收斂）

以下為本計畫核心驅動項，**優先順序即為列出順序**：

#### D1. 前端仍保留 business fallback（Thin-Bridge 違規）

`docs/jet-template.html` 內：

- Line 1523-1561：`dispatchAction()` 先判斷 `window.jet` 是否存在，否則 fallback 到 `templatePreviewHandlers`。
- Line 1809-1860：`templatePreviewHandlers` 中對 `validate.run`、`prescreen.run`、`filter.preview` 調用本地 `computeValidation()` / `computePrescreen()` / `evaluateScenario()`。

這代表「同一條業務規則在前端 JS 與後端 C# 同時存在」。任何改了一邊、沒改另一邊，demo 與正式版就會發散。

#### D2. 前端仍以 string action name 直接呼叫 bridge，沒有 typed facade

目前任意 UI code 都可以寫 `window.jet.invoke('validate.run', {})`。這讓：

- 契約變更時沒有編譯期保護（action rename 無法被 linter 抓到）。
- AI 生成新 HTML 時，很容易自行發明 action name（違反 `.github/skills/jet-contract-first-ui/SKILL.md`）。
- 測試用 mock 要攔截也得靠字串匹配。

我們需要一層 `JetApi.*` 的 typed facade，讓 UI 永遠寫 `await JetApi.runValidation()`，而不是 `await window.jet.invoke('validate.run', {})`。

#### D3. 沒有真正的資料庫持久化，所有資料住在 `InMemoryProjectSessionStore`

- `import.gl` / `import.tb` / `import.accountMapping` 的 handler 把整份 rows 丟進 `InMemoryProjectSessionStore`。
- `RunValidationQueryHandler` / `RunPrescreenQueryHandler` 直接讀 `session.GlData`，沒有走 Repository。
- 沒有 schema initialization、沒有 migration、沒有 SQLite/SQL Server 的 DAO。
- 結果：`docs/jet-guide.md` 宣稱的「SQLite-first / SQL Server 相容」目前完全沒實作。

#### D4. `FilterScenarioCommandHandler.cs` ~20KB，把多條 rule 邏輯塞進同一個 handler

違反 Good Taste（單一 handler 多職責）。後續應該按 scenario rule type（`prescreen`、`text`、`dateRange`、`numRange`、`accountPair`、`drCrOnly`、`manualAuto`）拆分成策略類別。

#### D5. Demo 資料注入路徑沒有獨立為「模擬上傳」流程

目前 `project.loadDemo` 一次回一大坨 DTO 給前端，前端再逐步填入各 step 狀態。這讓「測試資料」與「前端 UI 狀態管理」緊耦合。理想：  
demo = 產出與使用者上傳結構一致的 raw rows → 前端走跟使用者一樣的 `import.gl` / `import.tb` / `import.accountMapping` / `project.create` 流程 → 只是資料來源是 seed generator 而已。這樣 demo 才真正測試到 pipeline。

### 1.3 現階段「看起來像問題，其實還好」的部分

- `src/JET/JET/` 目錄結構（`Application` / `Bridge` / `Domain` / `Infrastructure`）**尚未**太複雜，AI 仍能追蹤。暫不需要大重組。
- `ActionDispatcher.cs` 使用 Dictionary routing 目前可接受；待 handler 數量 >30 或 DI 需求浮現時，再考慮轉 MediatR / 手刻 registration。
- `.github/` harness 檔案與 `docs/` system-of-record 沒發現對立資訊。

---

## 2. 本輪目標

**用一句話**：先把前端瘦成純 UI shell + 後端把資料落地到可插拔 Repository，讓 D1～D5 收斂到「下一輪可以放心做 Validation/Prescreen 的完整 DB 實作」。

不做：

- 不重組 `src/JET/JET/` 根目錄。
- 不引入 MediatR / AutoMapper / FluentValidation 等第三方。
- 不在本輪做 workpaper export 實作。
- 不寫 WinForms Designer-level UI。

做：

- Phase 0：收斂 D1、D2（契約 / Thin-Bridge 邊界）
- Phase 1：收斂 D5（Demo 改走正規 import 流程）
- Phase 2：引入 Repository 抽象 + Schema 初始化（D3 骨架）
- Phase 3：把既有 in-memory handler 切換到 Repository（D3 完成）
- Phase 4：拆 `FilterScenarioCommandHandler`（D4）

---

## 3. Phase 0：前端契約收斂（D1 + D2） ✅ **已完成**

已交付（本輪）：

- `docs/action-contract-manifest.md`：新增 `JetApi Typed Facade` 章節（20+ actions 的 camelCase 對照表）；`Anti-Patterns` 加三條禁令（前端不得實作 authoritative 規則、UI 不得直接 `window.jet.invoke` / `postMessage`、規則不得雙份實作）。
- `src/JET/JET/Bridge/JetBridgeScriptFactory.cs`：在 bootstrap script 注入 `window.JetApi`，以 `SupportedActions` 為唯一事實來源自動生成 camelCase 方法；未知方法透過 `Proxy` 丟出帶提示的 Error。
- `docs/jet-template.html`：新增 `AUTHORITATIVE_ACTIONS` 集合；`jetBridge.invoke` 對 authoritative 動作（`validate.run` / `prescreen.run` / `filter.preview` / `filter.commit`）直接丟錯、禁止 silent fallback；`templatePreviewHandlers` 移除 `RUN_VALIDATION` / `RUN_PRESCREEN` / `PREVIEW_FILTER` / `COMMIT_FILTER` entries。IO-echo handlers（import.*、mapping.commit.*、export.*）保留 UI-preview fallback。
- `.github/skills/jet-contract-first-ui/SKILL.md`：加 Backend Access Rule 章節，範例正確/禁止兩側對照。
- `.github/instructions/frontend.instructions.md`：加 `Backend Calls Go Through JetApi` 章節。
- `.github/instructions/bridge.instructions.md`：加 `ActionDispatcher` 不得調用 repository、`JetBridgeScriptFactory` 為 facade 單一來源兩條規則。
- `AGENTS.md` Non-Negotiable Architecture 加入 JetApi facade 一行。
- 順手修復：重建缺失的 `src/JET/JET/Application/Common/GlRowAccess.cs`（pre-existing build break；CS0234 for `JET.Application.Common` 未定義），並把 `RunValidationQueryHandler.cs` 內三處未限定的 `GetVal` / `ParseDecimal` 改為 `GlRowAccess.GetVal` / `GlRowAccess.ParseDecimal`。

Verification：

- `dotnet build src/JET/JET.slnx`：0 errors（僅 WindowsBase 既有 warning）。
- `dotnet test src/JET/JET.slnx`：8/8 pass, 0 failures。
- Grep：`templatePreviewHandlers` 內已無 `RUN_VALIDATION` / `RUN_PRESCREEN` / `PREVIEW_FILTER`；`AUTHORITATIVE_ACTIONS` gate 存在；`JetApi` facade / `toFacadeMethodName` 在 script factory 已注入。

尚未做（延後至下一輪）：

- `docs/jet-template.html` 內 `computeValidation()` / `computePrescreen()` / `evaluateScenario()` 等函式**暫留**。它們仍被 `applyDemoStep3Data`、`applyDemoPayload`、`buildAndSaveValidationReport`、`buildAndSaveWorkPaper` 呼叫；這些是 demo / export 的 UI-preview 路徑，需在 Phase 1（demo 改走正規 import pipeline）/ Phase 3（export 改走 bridge）一併移除，避免違反 Surgical Changes maxim。
- UI code 仍有少數地方直接呼叫 `window.jet.invoke`（Phase 1 會改走 `JetApi.*`）。

### 3.1 原 D1 收斂細節（備查）

**目標**：`docs/jet-template.html` 中，`validate.run` / `prescreen.run` / `filter.preview` **不再有 JS 本地實作**。

步驟：

1. 更新 `docs/action-contract-manifest.md` 的 `Anti-Patterns` 區塊，新增「不可在前端實作 authoritative 業務規則」。
2. 在 `docs/jet-template.html`：
   - 刪除 `computeValidation()`、`computePrescreen()`、`evaluateScenario()`、`applyCondition()` 等函式。
   - 刪除 `templatePreviewHandlers` 中 `validate.run` / `prescreen.run` / `filter.preview` 的 entry。
   - `dispatchAction()` 簡化：只走 `window.jet.invoke`；若 bridge 不存在，顯示 `{ ok: false, error: 'bridge_unavailable' }` 並停在錯誤訊息，不再做 silent fallback。
3. 保留的 fallback 只允許 UI-only 的 template preview（例如純呈現假 layout 的 demo static table）；不可觸及 validation / prescreen / filter 規則。
4. 驗證：`dotnet build src/JET/JET.slnx` + 手動啟動 `JET.csproj`，確認步驟 3/4/5 UI 仍能收到 handler 回傳結果。

### 3.2 引入 `JetApi` typed facade（D2）

**目標**：UI 層不再寫 `window.jet.invoke('xxx', payload)`；改寫 `await JetApi.runValidation()`。

步驟：

1. 在 `docs/action-contract-manifest.md` 新增章節「JetApi Typed Facade」：
   - facade 方法名與 action name 一對一（e.g. `validate.run` → `JetApi.runValidation`）。
   - 每個方法的 TypeScript-style 簽章（即使寫 JS，註解描述 payload/response 形狀）。
   - 規定 AI 生成 UI 時必須呼叫 facade，不得直接呼叫 `window.jet.invoke`。
2. 在 `Bridge/JetBridgeScriptFactory.cs` 產生的 bootstrap script 中，在 `window.jet` 之上再 freeze 一個 `window.JetApi`：
   - 每個 supported action 自動對應一個 camelCase 方法。
   - 以 `SupportedActions` 為單一事實來源自動生成，避免 C# 與 JS 兩邊維護兩份清單。
   - 例：`validate.run` → `JetApi.validateRun()`；`mapping.commit.gl` → `JetApi.mappingCommitGl(payload)`。
   - 若呼叫未知方法，丟出帶有提示「請先在 `docs/action-contract-manifest.md` 新增 action」的 Error。
3. 更新 `docs/jet-template.html` 與 `.github/skills/jet-contract-first-ui/SKILL.md`：UI 範例全部改用 `JetApi.*`。
4. 舊的 `window.jet.invoke` 保留作為 low-level escape hatch，但寫明「正式 UI 不應直接使用」。

### 3.3 驗收標準

- `Select-String -Path docs/jet-template.html -Pattern 'computeValidation|computePrescreen|evaluateScenario'` 回傳空。
- `docs/action-contract-manifest.md` 已記載 JetApi facade 規則。
- UI 內唯一還使用 `window.jet.invoke` 的地方，是 bootstrap 階段的 `app.bootstrap` 呼叫（facade 尚未組裝）。

---

## 4. Phase 1：Demo 資料改走正規 import 流程（D5） ✅ **已完成**

已交付（本輪）：

- `docs/action-contract-manifest.md`：`project.loadDemo` response 改為 metadata-only；新增 `demo.fetchGlRows` / `demo.fetchTbRows` / `demo.fetchAccountMappingRows` 三個 action（payload `{}`，response 對齊 `import.*` 形狀）；補上 `JetApi Typed Facade` 章節（lowerCamelCase 串接規則 + facade 為唯一前端入口）；新增 `Demo Pipeline 對齊原則` 章節。
- `src/JET/JET/Application/Contracts/DemoProjectDto.cs`：移除 `GlRows` / `TbRows` / `AccountMappingRows`（metadata-only）；新增 `DemoGlRowsDto` / `DemoTbRowsDto` / `DemoAccountMappingRowsDto`。
- `src/JET/JET/Application/DemoData/DemoProjectDataBundle.cs`：新增 `Gl` / `Tb` / `AccountMapping` slice；保留 `InvalidGlRows`。
- `src/JET/JET/Application/DemoData/DeterministicDemoProjectDataGenerator.cs`：產生新 bundle 形狀（含 GL/TB columns）。
- `src/JET/JET/Application/Queries/ProjectDemo/`：新增 `FetchDemoGlRowsQuery` / `FetchDemoTbRowsQuery` / `FetchDemoAccountMappingRowsQuery` 與對應 handler；`GetProjectDemoQueryHandler` 自動降級為 metadata。
- `src/JET/JET/Bridge/ActionDispatcher.cs`：註冊三個 `demo.fetch*` 路由；`SupportedActions` 自動帶出，前端 `JetApi.demoFetchGlRows` 等方法無需額外註冊即可使用。
- `docs/jet-template.html`：新增 `FETCH_DEMO_*` ACTIONS 常數；`ensureDemoBundle()` 重寫為「先取 metadata → 平行 fetch 三批 rows → 平行驅動 `project.create` 後再 `import.gl/tb/accountMapping/holiday/makeupDay`」與使用者上傳完全相同的 pipeline；前端 state 仍可繼承既有 `applyDemoStep1Data` 介面（surgical change）。
- `src/JET/tests/JET.Tests/DemoData/DemoProjectDataGeneratorTests.cs`：四個既有測試改用 `bundle.Gl.Rows` / `bundle.Tb.Rows`；新增 `Generate_ShouldExposeColumnsConsistentWithRows` 確保 columns/file-name 與 rows 對齊。

Verification：

- `dotnet build src/JET/JET.slnx`：0 errors（僅 WindowsBase 既有 warning）。
- `dotnet test src/JET/JET.slnx`：9/9 pass, 0 failures。
- Grep：`docs/jet-template.html` 內已含 `FETCH_DEMO_GL_ROWS` / `FETCH_DEMO_TB_ROWS` / `FETCH_DEMO_ACCOUNT_MAPPING_ROWS` 常數與 `ensureDemoBundle` 的 import.* 平行呼叫。

尚未做（延後至下一輪）：

- 「demo 流程等價於使用者上傳」的 application-level integration test（涉及多 handler 串接 + InMemoryProjectSessionStore 端到端比對），會與 Phase 2/3 Repository 切換一起寫，避免本輪寫了等下又重寫。
- `docs/jet-template.html` 內 `computeValidation()` / `computePrescreen()` / `evaluateScenario()` **仍保留**（被 `applyDemoStep3Data` / `applyDemoPayload` / `buildAndSaveValidationReport` / `buildAndSaveWorkPaper` 使用）。Phase 1 只負責 demo 入口與 import pipeline；UI-preview 路徑的 authoritative 化會在後續 phase 隨 export 重構一併處理（Surgical Changes maxim）。

### 4.1 原始步驟（備查）

1. 把 `Application/DemoData/` 的 generator 拆成：
   - `IDemoProjectScenario`：描述一個 demo 案例的 metadata（project 設定、holidays、makeup）。
   - `IDemoGlRowsSource` / `IDemoTbRowsSource` / `IDemoAccountMappingSource`：分別產出 raw rows。
2. 新增 action（contract 變更，先改 manifest）：
   - 保留 `project.loadDemo` 回 metadata（project 欄位、file names、holiday/makeup dates、建議 mapping），但**不再回 rows**。
   - 新增 `demo.fetchGlRows` / `demo.fetchTbRows` / `demo.fetchAccountMappingRows`。
3. 前端的「載入測試資料」按鈕流程改寫為：
   1. 呼叫 `JetApi.projectLoadDemo()` 拿 metadata，填 project form。
   2. 呼叫 `JetApi.projectCreate(metadata)`。
   3. 呼叫 `JetApi.demoFetchGlRows()` → 再用結果呼叫 `JetApi.importGl(rows, columns, fileName)`。
   4. TB / AccountMapping 同理。
   5. Holiday / Makeup 直接用 metadata 中的 dates 呼叫 `JetApi.importHoliday` / `JetApi.importMakeupDay`。
4. 驗收：拔掉 `project.loadDemo` 中 `glRows`、`tbRows`、`accountMappingRows` 欄位後，前端仍能走完整個 pipeline。
5. 單元測試：在 `JET.Tests/DemoData/` 補 integration 測試，驗證 demo 流程等價於「使用者上傳」流程（同一批 rows，經過同一組 handler，產生同一個結果）。

這一步讓 demo 與 production path **完全對齊**，未來 AI 生成新畫面時不會因為「demo 只有前端有」而誤解系統行為。

---

## 5. Phase 2：Repository 抽象 + Schema 初始化（D3 骨架）

### 5.1 設計原則

- Application 層**只依賴 interface**（`IProjectRepository`、`IGlRepository`、`ITbRepository`、`IAccountMappingRepository`、`IDateDimensionRepository`、`IValidationRepository`、`IPreScreenRepository`、`IScenarioRepository`）。
- Infrastructure 層為每個 provider 提供一組實作：`Infrastructure/Persistence/Sqlite/*Repository.cs`、`Infrastructure/Persistence/SqlServer/*Repository.cs`。
- **Schema 名稱差異封裝在 `ISchemaNames`**（對應 legacy `DbSchema.cls` 的精神）：
  - SQLite 實作回傳 `staging_gl_raw_row`（底線串接）。
  - SQL Server 實作回傳 `staging.gl_raw_row`（schema 分離）。
  - Application / Domain 永遠只引用邏輯名稱 `SchemaNames.StagingGlRawRow`，不自拼字串。
- **DbAccess/Connection 差異封裝在 `IDbSession`**（對應 legacy `DbAccess.cls` 的精神）：
  - 提供 `BeginTxAsync` / `CommitAsync` / `RollbackAsync` / `ExecuteNonQueryAsync` / `QueryAsync<T>` / `BulkInsertAsync<T>`。
  - SQLite 實作用 `Microsoft.Data.Sqlite` + `Dapper` + prepared-statement batch insert。
  - SQL Server 實作用 `Microsoft.Data.SqlClient` + `Dapper` + `SqlBulkCopy`。

### 5.2 目錄配置（不破壞既有）

新增（**只在 `Infrastructure` 下增加子資料夾**，不動 `Application` / `Domain` 根結構）：

```
src/JET/JET/
├─ Domain/
│  ├─ Abstractions/
│  │  ├─ Repositories/          ← 新增：IGlRepository 等
│  │  └─ Persistence/           ← 新增：IDbSession、ISchemaNames
│  └─ ...
├─ Infrastructure/
│  ├─ Persistence/
│  │  ├─ Schema/                ← 新增：SqliteSchemaNames、SqlServerSchemaNames
│  │  ├─ Sessions/              ← 新增：SqliteDbSession、SqlServerDbSession
│  │  ├─ Sqlite/
│  │  │  ├─ Repositories/       ← 新增：SqliteGlRepository 等
│  │  │  └─ Migrations/         ← 新增：schema init SQL scripts
│  │  └─ SqlServer/
│  │     ├─ Repositories/
│  │     └─ Migrations/
│  └─ ...
```

這個增量不會讓 AI 追蹤變難：每個 repository 在兩個 provider folder 下各一個檔，命名完全對應，透過 interface 匯合。

### 5.3 Schema 初始化流程

1. 新增 `Domain/Abstractions/Persistence/ISchemaInitializer`。
2. Infrastructure 各 provider 提供 `SqliteSchemaInitializer` / `SqlServerSchemaInitializer`：
   - 本輪先建：`config_project`、`config_project_state`、`config_import_batch`、`config_import_column`、`staging_gl_raw_row`、`staging_tb_raw_row`、`staging_account_mapping_raw_row`、`staging_calendar_raw_day`。
   - `target_*` / `result_*` 留到下一輪。
3. 在 `Program.cs` 啟動時呼叫 `await schemaInitializer.EnsureAsync()`。若 provider 不可用，記錄 warning 並讓 `app.bootstrap` 透過 `DatabaseStatus.IsAvailable = false` 通知前端。

### 5.4 DI / 註冊

- 不引入 MS.Extensions.DependencyInjection（避免過度）。
- 在 `Program.cs` 用 **手動組裝**（simple factory）：按 `options.Database.Provider` switch 一次，組出所有 repository 實例，注入 `ActionDispatcher`。
- `ActionDispatcher` 建構子需擴充接收 repository 介面集合（保持 Thin-Bridge：dispatcher 只把 repo 傳給 handler，不自己調用 repo）。

---

## 6. Phase 3：Handler 切換到 Repository（D3 完成）

**原則**：每個 action 一個 PR 切換，不一次全切。切換順序按業務流程：

1. `project.create` → `IProjectRepository.CreateAsync`（同時寫 `config_project` + `config_project_state`）。
2. `import.gl` → `IGlRepository.CreateImportBatchAsync` + `StageRawAsync`（SQLite 用 prepared statement batch size 5000~20000；SQL Server 用 `SqlBulkCopy`）。
3. `import.tb` → 同上。
4. `import.accountMapping` → `IAccountMappingRepository.ReplaceCurrentAsync`。
5. `import.holiday` / `import.makeupDay` → `IDateDimensionRepository.ReplaceCalendarInputAsync`。
6. `project.load`（新增）→ 從 repository 讀出目前 session pointers。
7. `validate.run` / `prescreen.run` / `filter.preview` / `filter.commit` 本輪**不切到 DB**，繼續讀 `InMemoryProjectSessionStore` 做 in-memory 計算。下一輪再遷到 `target_*` tables。

這樣 `InMemoryProjectSessionStore` 在本輪末期會縮減為「僅保存 mapping + holidays 的 session cache」，真實大資料已落地到 DB。

### 驗證策略

- `JET.Tests` 為每個 repository 新增 SQLite `:memory:` 測試（快、無副作用）。
- `project.create` → `import.gl` → `mapping.commit.gl` 一條 happy path 的 integration test，跑滿 100 筆 demo GL。
- SQL Server 實作先寫好但暫不跑 CI（需要 local instance）；留 `[Trait("Category", "SqlServer")]` 標籤。

---

## 7. Phase 4：拆 `FilterScenarioCommandHandler`（D4）

`Application/Commands/FilterScenario/` 下新增：

```
Rules/
├─ IScenarioRuleEvaluator.cs
├─ PrescreenRuleEvaluator.cs
├─ TextRuleEvaluator.cs
├─ DateRangeRuleEvaluator.cs
├─ NumRangeRuleEvaluator.cs
├─ AccountPairRuleEvaluator.cs
├─ DrCrOnlyRuleEvaluator.cs
└─ ManualAutoRuleEvaluator.cs
```

`FilterScenarioCommandHandler` 變成 orchestrator：根據 rule type 選 evaluator，把 AND/OR 組合交給 `ScenarioGroupComposer`。  
每個 evaluator ≤ 150 行、單一職責、可獨立測試。  
**本階段不改契約**：payload / response shape 維持現狀（見 manifest Filter 章節）。

---

## 8. Harness / `.github/` 更新清單

本計畫在執行期間，下列 harness 檔需要同步維護（僅在該主題真的改動時才更新）：

- `docs/action-contract-manifest.md`：
  - 新增 **JetApi Typed Facade** 章節（Phase 0.2）
  - 新增 `demo.fetchGlRows` / `demo.fetchTbRows` / `demo.fetchAccountMappingRows`（Phase 1）
  - Anti-Patterns 新增：前端不得實作 authoritative validation / prescreen / filter 規則；UI 不得直接呼叫 `window.jet.invoke`。
- `.github/skills/jet-contract-first-ui/SKILL.md`：補充 JetApi facade 使用範例，並明確禁止寫 `window.chrome.webview.postMessage` 與 `window.jet.invoke`（除 bootstrap）。
- `.github/instructions/frontend.instructions.md`：加入 JetApi facade 規則。
- `.github/instructions/bridge.instructions.md`：加入「ActionDispatcher 不得調用 repository；只能把 repo 傳給 handler」。
- `.github/skills/jet-engineering-maxims/SKILL.md`：如五條原則未涵蓋「前端只看 facade」則補一句；不另立新原則。
- `AGENTS.md`：維持簡短，不加新章節；只在 `Non-Negotiable Architecture` 加一行：「Frontend calls backend exclusively through `JetApi` facade」。
- `.github/copilot-instructions.md`：維持中文精要版；若原則沒變，不動。

**不新增**新的 agent / prompt / skill 檔，除非現有檔真的無處放。

---

## 9. 驗證與交付（Visual Studio 18.5 baseline）

每個 Phase 完成後：

```
dotnet build src/JET/JET.slnx
dotnet test  src/JET/JET.slnx
```

以及：

- Visual Studio F5 啟動 `JET.csproj`，手動確認：
  - 步驟 1/2/3/4/5 UI 仍可正常互動
  - `app.bootstrap` 回傳 `database.provider` 正確
  - 載入 demo → import → mapping → validate → prescreen → filter 能跑完 happy path
- 若使用 Copilot Agent Mode，確認 `.github/skills/*` 被 agent discovery 起效（18.5.0 起自動）。

---

## 10. 本輪「不要做」清單（避免 scope creep）

- 不實作 `target_*` / `result_*` 資料表（下一輪才做，否則這輪會爆）。
- 不做 workpaper exporter（留最末 phase）。
- 不引入第三方 DI / mapper / validation library。
- 不重寫 `Form1.cs`（目前已經夠 thin）。
- 不動 `Form1.Designer.cs`。
- 不合併 `Application/Commands` 與 `Application/Queries`（CQRS 分離仍合理）。
- 不把前端 HTML 拆成多檔 SPA（仍維持單一 shell）。

---

## 11. 下一輪 working plan 的候選題目

待本版 Phase 0～4 完成後，下一版 plan.md 應聚焦：

1. `target_gl_entry` / `target_tb_balance` + mapping 標準化寫入
2. `target_gl_document_summary` / `target_gl_account_summary` 彙總表
3. `target_account_mapping` / `target_date_dimension`
4. Validation V1~V4 與 Prescreen R1~R8 / A2~A4 的 repository 實作（provider-specific SQL）
5. `result_*` 系列表 + keyset paging
6. Workpaper exporter + manifest
7. SQL Server 的 `SqlBulkCopy` 路徑正式跑 CI

---

## 12. 本檔用途

本檔是臨時 working plan，用來讓下一輪 VS 18.5 Copilot / Agent 直接接手。  
若本檔與權威文件（`docs/jet-guide.md`、`docs/action-contract-manifest.md`、`AGENTS.md`、`.github/**`）衝突，以權威文件為準。  
實作時若發現需要修正權威文件（例如 D1~D5 造成契約漂移），**先更新權威文件，再寫碼**；不要只改本檔。
