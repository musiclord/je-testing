# JET Implementation Plan

JET 的 working plan。內容只記**現況、已發現偏差、下一輪 harness cycle、完成壓縮存檔**。  
若本檔與權威文件衝突，以權威文件為準（順序）：

1. `docs/jet-guide.md`
2. `docs/action-contract-manifest.md`
3. `AGENTS.md`
4. `.github/copilot-instructions.md` + `.github/instructions/**` + `.github/skills/**`

> 改實作前若發現契約需要動，**先改權威文件再寫碼**；不要只改本檔。  
> 本檔是工作規劃，不是契約來源。正式 action / payload / response 以 `docs/action-contract-manifest.md` 為準。

---

## 1. Non-negotiable Engineering Maxims

1. **Good Taste** — 消除特殊分支；provider 差異藏在 Infrastructure；規則差異走 Strategy / evaluator。
2. **Don't Break Userspace** — action name / payload field / fixed `data-bind` / `Designer.cs` 只做 additive change。
3. **Simplify Before Extending** — 先看現有 action / handler / repository 是否足夠，再新增契約。
4. **Paranoid About Simplicity** — `Form1` 只做 WebView2 host；Bridge 只做 JSON transport + dispatch。
5. **Surgical Changes** — 只動該動的，不順手重構，不為未來需求寫 code。

**Mission constraint（non-negotiable）**：JET 處理 GL 10 萬～500 萬筆。V/R/Filter 規則必須以 set-based SQL 由 DB 引擎執行；Bridge 不搬 >1000 row；Excel 走 OpenXML SAX streaming。完整規範見 `docs/jet-guide.md` §1.5。

**正式版 UI 邊界（本次新增要求）**：`docs/jet-template.html` 已從 AI 產生 prototype 進入正式系統落地階段。前端只允許：

- 顯示系統狀態、欄位選擇、摘要數字、分頁資料、使用者輸入。
- 呼叫 `window.JetApi.*` facade。
- 維護輕量 UI state（current step、selected mapping、selected scenario draft、resultRef、cursor）。

前端禁止：

- authoritative V/R/Filter 業務規則。
- 用 `computeValidation()` / `computePrescreen()` / `evaluateScenario()` 模擬正式結果。
- 透過 `import.*` 舊 row payload 將 GL/TB/AccountMapping 明細搬過 Bridge。
- 保存完整 GL/TB/AcctMap rows 作為後續步驟的資料來源。

---

## 2. Current System State（已完成且仍有效）

### 2.1 Backend / DB pipeline 已落地

- **Demo data source**：`Application/DemoData/DeterministicDemoProjectDataGenerator` 是獨立測試案例資料來源，不在 WinForms / HTML 內硬編資料。
  - GL：`1100` 張正常傳票 × 2 lines = `2200` 筆正常分錄，外加 invalid rows。
  - TB / AccountMapping：約 `120` 個科目。
  - 例外案例：缺科目、缺傳票號碼、缺摘要、日期超界、借貸不平。
  - 測試：`DemoProjectDataGeneratorTests` 驗證 row/account 規模、正常 GL by voucher 平衡、TB by account 與正常 GL 對齊、invalid rows 存在。
- **Demo export path**：`demo.exportGlFile` / `demo.exportTbFile` / `demo.exportAccountMappingFile` 會將 deterministic demo data 寫成 xlsx temp file。
- **Streaming ingest**：`import.gl.fromFile` / `import.tb.fromFile` / `import.accountMapping.fromFile` 走 `IGlFileReader` + repository，寫入 `staging_*`，response 不回 rows。
- **Projection**：`mapping.commit.gl` / `mapping.commit.tb` 以 set-based SQL 從 `staging_*` 投影到 `target_gl_entry` / `target_tb_balance`。
- **Validation**：`validate.run` 走 `IValidationRepository` / `SqliteValidationRepository`，以 SQL 計算 V1-V4、stats、summary、`resultRef`。
- **Prescreen**：`prescreen.run` 走 `IPreScreenRepository`，R1/R2/R4/R5/R6 SQL pushdown；R3 已有 repository tests；R7/R8/A2-A4 仍 scaffold。
- **Scenario filter**：`filter.preview` 走 `IScenarioRepository`，規則拆成 SQL fragment evaluators，結果寫入 `result_filter_run`，preview rows ≤1000。
- **Paging**：`query.validationDetailsPage` / `query.prescreenPage` / `query.filterPage` keyset paging。
- **Session slim**：`InMemoryProjectSessionStore` 只保留 project pointer、mapping cache、calendar/UI 暫態，不持有 GL/TB/AcctMap raw rows。
- **Scale smoke**：`ValidateRunScaleSmokeTests` 以 200 萬 GL rows 驗證 `validate.run`：SQL <30s、managed memory delta <500MB、response payload <100KB。

### 2.2 Build / Test baseline

- 最新確認：`dotnet build src\JET\JET.slnx --no-restore --nologo` 成功。
- 最新確認：`dotnet test src\JET\tests\JET.Tests\JET.Tests.csproj --no-build` 成功，`63/63 pass`。
- 已知 warning：WebView2 / `WindowsBase` `MSB3277` 版本衝突仍存在，非本輪功能阻塞。

---

## 3. Discovery: Formal UI/Test Flow Drift（本次盤點發現）

> 重要結論：**後端不是空殼；核心 DB pipeline 已存在。**  
> 但 `docs/jet-template.html` 的 demo / test button / quick-fill path 尚未完整切到正式後端權威流程，仍有 prototype 殘留。

### 3.1 已確認的前端偏差

| 偏差 | 現況 | 風險 |
|:---|:---|:---|
| Demo loader 使用 deprecated rows actions | `ensureDemoBundle()` 仍呼叫 `demo.fetchGlRows` / `demo.fetchTbRows` / `demo.fetchAccountMappingRows` | Bridge 搬 >1000 rows；違反 §1.5.3 |
| Demo ingest 使用 deprecated echo import | `ensureDemoBundle()` 仍呼叫 `import.gl` / `import.tb` / `import.accountMapping` | 後端只是 echo，不會寫 DB staging；UI 看似完成但 DB pipeline 沒跑 |
| User upload 使用 fileBuffer + old import | `handleGLFile()` / `handleTBFile()` / `handleAccMapFile()` 呼叫 `import.*` | 正式 fromFile ingest 無法由一般 browser `File` 取得本機絕對路徑；需要 host file picker / import-path contract |
| 前端保留 local validation | `computeValidation()`、`applyDemoStep3Data()` | 可能用 JS 模擬 V1-V4，繞過 repository SQL |
| 前端保留 local prescreen | `computePrescreen()` | 可能用 JS 模擬 R rules，繞過 repository SQL |
| 前端保留 local scenario evaluator | `evaluateScenario()`、`applyScenarioRule()` | 可能用 JS 模擬 filter，繞過 `IScenarioRepository` |
| Filter response shape drift | 部分 UI 還讀 `resultRows` / `conditions`，正式 contract 是 `previewRows` + `resultRef` | 顯示錯誤或促使後端回完整 rows |
| Export still frontend-generated | `export.validation` / `export.prescreen` / `export.criteria` / `export.workpaper` 仍委派前端 XLSX | 大資料工作底稿違反 streaming writer 原則；G7 未收斂 |

### 3.2 判定

- Backend capability：**已存在且有 tests**。
- Formal UI path：**未完全對齊**。
- Demo/test button：**目前不能保證每一步都真的跑後端 DB pipeline**。
- Plan correction：舊 plan 將 `Demo pipeline` 標為已收斂是 backend contract / handler 層面成立；但 frontend `docs/jet-template.html` 仍有 drift，必須新增正式版收斂 slice。

---

## 4. Open Mission Gaps（目前剩餘）

| 編號 | 差距 | 嚴重性 | 收斂 slice |
|:---|:---|:---|:---|
| ~~G1~~ | ~~`import.accountMapping` payload 帶完整 rows~~ | ~~Blocker~~ | ✅ §3.1.b/c/d |
| ~~G2~~ | ~~session / commit / validate / prescreen 依賴 raw rows~~ | ~~Blocker~~ | ✅ §3.2 + §3.3 + §3.4 |
| ~~G3~~ | ~~V/R/Filter LINQ over session rows~~ | ~~Blocker~~ | ✅ §3.3 |
| ~~G4~~ | ~~V/R/Filter response 回完整明細 rows~~ | ~~Blocker~~ | ✅ §3.3 paging + resultRef |
| ~~G5~~ | ~~`mapping.commit.gl/tb` 未投影 target tables~~ | ~~High~~ | ✅ §3.2.b |
| ~~G6~~ | ~~`FilterScenarioCommandHandler` 過大、多規則混雜~~ | ~~Medium~~ | ✅ §3.3.d |
| **G7** | `export.workpaper` 仍是前端/handler stub，未走 OpenXML SAX streaming | High (§1.5.4) | Phase 5 |
| **G8** | `docs/jet-template.html` 保留 `computeValidation()` / `computePrescreen()` / `evaluateScenario()` 等 JS business rules | High（正式版邊界） | Phase 4 |
| **G9** | Demo/test buttons 仍使用 `demo.fetch*Rows` + deprecated `import.*` echo path | Blocker (§1.5.3 / 正式測試可信度) | Phase 4 |
| **G10** | 使用者上傳流程仍以 browser `fileBuffer` 進 deprecated `import.*`；正式 `fromFile` 需要 host file path contract | Blocker (§1.5.3) | Phase 4 |
| **G11** | 缺少完整端到端測試：demo export → fromFile ingest → mapping projection → validation/prescreen/filter → paging | High | Phase 4 |
| **G12** | R7/R8/A2/A3/A4 prescreen 仍 scaffold，缺權威 SQL 規格 | Medium | Phase 6（需先補規格） |

---

## 5. Next Harness Cycle: Phase 4 — Formal UI / Backend Boundary Alignment

**目標**：把 `docs/jet-template.html` 從 prototype demo shell 收斂成正式版 WebView2 UI。前端只顯示狀態與資料，不再模擬業務邏輯；demo/test buttons 必須驅動真實後端 DB pipeline。

**Phase 4 DoD**：

- ✅ `docs/action-contract-manifest.md` 先更新並反映所有 UI 需要的正式 action。
- ✅ `docs/jet-template.html` 不再使用 `demo.fetch*Rows` / `import.*` 作為 demo/test path。
- ✅ 正式 UI 不再呼叫 `computeValidation()` / `computePrescreen()` / `evaluateScenario()` 取得 authoritative result。
- ✅ 前端 state 不保存完整 GL/TB/AcctMap rows；只保存 `{ fileName, rowCount, columns, batchId, resultRef, cursor, previewRows≤1000 }`。
- ✅ Demo/test button path：`project.loadDemo` → `demo.export*File` → `project.create` → `import.*.fromFile` → `mapping.commit.*` → `validate.run` / `prescreen.run` / `filter.preview`。
- ✅ 使用者上傳 path 有正式 host file path contract，不再靠 browser `fileBuffer` 搬 rows。
- ✅ 新增端到端 integration test 鎖住正式 path。
- ✅ `dotnet build src\JET\JET.slnx` 成功。
- ✅ `dotnet test src\JET\tests\JET.Tests\JET.Tests.csproj` 全綠。
- ✅ 更新 `plan.md` archive。

### 5.1 Sub-slices

| Sub-slice | 目的 | 交付物 | 狀態 |
|:---|:---|:---|:---|
| §4.1 Contract correction | 修正 manifest 與 UI data outline，明確禁止正式 UI 使用 deprecated row actions / JS rules | `[contract]` `docs/action-contract-manifest.md` | pending |
| §4.2 File path ingress contract | 定義使用者上傳如何取得 host file path；優先重用/擴充現有 action，必要時 additive 新增 host file picker/import action | `[contract]` + `[bridge]` + `[app]` | pending |
| §4.3 Demo/test button pipeline | 改 `ensureDemoBundle()` / `quickFillStep()` / 測試按鈕走 `demo.export*File` + `import.*.fromFile` + commit + backend rules | `[ui]` `docs/jet-template.html` | pending |
| §4.4 UI state slimming | 移除正式流程對 `state.glData` / `state.tbData` / `state.accMapData` 的依賴，改成 metadata/resultRef/page state | `[ui]` | pending |
| §4.5 Remove local business rules | 移除或隔離 `computeValidation()` / `computePrescreen()` / `evaluateScenario()`；template preview 不得在 WebView2 正式模式使用 | `[ui]` | pending |
| §4.6 Response shape alignment | `filter.preview` UI 改讀 `previewRows` / `resultRef`，validation/prescreen 明細改用 paging query | `[ui]` + `[bridge]` if needed | pending |
| §4.7 End-to-end harness test | 新增 deterministic E2E test：demo export → fromFile ingest → mapping commit → validate/prescreen/filter → details paging | `[tests-integration]` | pending |
| §4.8 Archive | build/test 綠後同步 `plan.md` | `[plan]` | pending |

### 5.2 Phase 4 不做

- 不重寫 `Form1.cs` / `Form1.Designer.cs`。
- 不拆 HTML 成 SPA 或引入 frontend framework。
- 不做 OpenXML workpaper exporter（Phase 5）。
- 不重新設計 repository / DB schema，除非 E2E test 暴露必須修的 schema bug。
- 不移除 deprecated backend action；只保證正式 UI 不再使用。移除需另開 breaking-change phase。

---

## 6. Phase 5 — Workpaper Exporter + Report Boundary

**目標**：收斂 G7，讓 export 不再由前端 XLSX 模擬，改由後端 OpenXML SAX streaming writer 產生檔案。

候選 sub-slices：

1. `[contract]` 定義 `export.workpaper` / possible `export.workpaperStream` response shape。
2. `[domain]` 定義 export sheet specs / result refs。
3. `[infra]` OpenXML SAX writer。
4. `[app]` Workpaper export handler 讀 `resultRef` + paging/streaming DB reader。
5. `[ui]` 前端只選擇輸出內容、顯示進度與 output path。
6. `[tests]` 小檔 correctness + 大檔 streaming smoke。

---

## 7. Later Candidates（Phase 6+）

1. 補 R7/R8/A2/A3/A4 權威 SQL 規格與 repository 實作。
2. `target_gl_document_summary` / `target_gl_account_summary` 彙總表。
3. `target_account_mapping` / `target_date_dimension` 完整 dimension。
4. `result_*` index tuning（profiling 後）。
5. SQL Server `SqlBulkCopy` path 正式跑 CI。
6. `IDbSession` 抽象（只有在第三個 repository 連線管理痛點浮現後才做）。

---

## 8. Completed Archive（壓縮）

- **Phase 0 — Frontend contract baseline**：`JetApi` facade from `SupportedActions`；`AUTHORITATIVE_ACTIONS` gate；harness docs/instructions established。
- **Phase 1 — Initial demo metadata/data source**：`DeterministicDemoProjectDataGenerator` 產生 2200+ GL rows、120 accounts、invalid rows；`project.loadDemo` metadata path；row fetch actions 保留為 deprecated。
- **Phase 2 — Schema skeleton**：`ISchemaInitializer` / `ISchemaNames` / `JetTable`；SQLite schema bootstrap；SqlServer scaffold。
- **Phase 3.1 — Streaming ingest**：`IGlFileReader` + `SylvanGlFileReader`；`import.gl.fromFile` / `import.tb.fromFile` / `import.accountMapping.fromFile`；repositories write `staging_*` + import metadata；demo export file actions added。
- **Phase 3.2 — Staging to target projection**：`TargetGlEntry` / `TargetTbBalance` schema；`mapping.commit.gl/tb` set-based projection repositories；projection tests。
- **Phase 3.3 — SQL pushdown V/R/Filter**：`IValidationRepository` + V1-V4 SQL + validation paging；`IPreScreenRepository` + R1/R2/R4/R5/R6 SQL + prescreen paging；`IScenarioRepository` + SQL fragment evaluators + filter paging。
- **Phase 3.4 — Session slim**：`InMemoryProjectSessionStore` no longer holds raw GL/TB/AcctMap rows。
- **Phase 3.5 — Scale validation**：2M-row `validate.run` smoke test；SQLite validation indexes and V4 indexed range query；`63/63 pass` baseline。

---

## 9. Current Test Inventory Snapshot

- `DemoProjectDataGeneratorTests`：測試案例規模與例外資料。
- `ExportDemoFilesQueryHandlerTests`：demo xlsx 可由 streaming reader 讀取。
- `Import*FromFileCommandHandlerTests`：fromFile handlers。
- `Sqlite*RepositoryTests`：project/date/gl/tb/accountMapping/projection/validation/prescreen/scenario repositories。
- `LoadProjectQueryHandlerTests`：project rehydrate。
- `ValidateRunScaleSmokeTests`：2M-row validation scale smoke。

**Missing after discovery**：正式 UI/test button E2E test，需在 Phase 4 §4.7 新增。
