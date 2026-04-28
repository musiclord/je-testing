# JET Frontend Action Contract Manifest

本文件是 JET 前端、WebView2 bridge、C# handler 之間的**唯一 action contract source of truth**。任何 agent 在生成 HTML / UX 或修改 action 之前，應先讀本文件。

## 使用原則

1. 前端**優先重用既有 action**，不要自行發明新 action。
2. 如果 UI 真的需要新資料或新行為，先更新本 manifest，再修改 `ActionDispatcher` 與相關 handler。
3. `docs/jet-template.html` 的 UI 生成應服從這裡的 action name、payload shape、response shape 與 fixed binding assumptions。
4. `Bridge` 只負責 transport，不負責業務判斷。
5. `docs/jet-guide.md` 定義業務語意；本文件定義跨 frontend / bridge / handler 的資料契約。兩者若衝突，先回報並修文件，不要在 UI 或 C# 裡發明新 action。

## Bridge Envelope

前端送到 WebView2 bridge 的標準請求：

```json
{
  "requestId": "<uuid>",
  "action": "<namespace.action>",
  "payload": {}
}
```

Bridge 回傳的標準回應：

```json
{
  "requestId": "<uuid>",
  "ok": true,
  "data": {},
  "error": null
}
```

失敗時：

```json
{
  "requestId": "<uuid>",
  "ok": false,
  "data": null,
  "error": {
    "code": "<error_code>",
    "message": "<human_readable_message>"
  }
}
```

## Current Action Registry

### Shell / Bootstrap

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `system.ping` | `{}` | `{ message, utcNow }` | 基本 host 通訊檢查 |
| `app.bootstrap` | `{}` | `AppBootstrapDto` | 啟動 shell、顯示 DB provider 與 supported actions |
| `project.loadDemo` | `{}` | `DemoProjectDto` (metadata only，不含 rows) | 載入 deterministic demo project metadata |
| `demo.exportGlFile` | `{}` | `{ filePath, fileName }` | 將 deterministic demo GL 寫成 xlsx 檔；前端接 `import.gl.fromFile` |
| `demo.exportTbFile` | `{}` | `{ filePath, fileName }` | 將 deterministic demo TB 寫成 xlsx 檔；前端接 `import.tb.fromFile` |
| `demo.exportAccountMappingFile` | `{}` | `{ filePath, fileName }` | 將 deterministic demo account mapping 寫成 xlsx 檔；前端接 `import.accountMapping.fromFile` |
| `demo.fetchGlRows` | `{}` | `{ fileName, rows, columns }` | **Deprecated legacy fallback only**；正式 demo/test path 不得使用，改用 `demo.exportGlFile` → `import.gl.fromFile` |
| `demo.fetchTbRows` | `{}` | `{ fileName, rows, columns }` | **Deprecated legacy fallback only**；正式 demo/test path 不得使用，改用 `demo.exportTbFile` → `import.tb.fromFile` |
| `demo.fetchAccountMappingRows` | `{}` | `{ fileName, rows }` | **Deprecated legacy fallback only**；正式 demo/test path 不得使用，改用 `demo.exportAccountMappingFile` → `import.accountMapping.fromFile` |

`AppBootstrapDto` 結構：

```json
{
  "applicationName": "JET",
  "startPage": "https://appassets.example/index.html",
  "supportedActions": ["app.bootstrap", "..."],
  "database": {
    "provider": "Sqlite",
    "isAvailable": true,
    "connectionTarget": "...",
    "mode": "Local"
  },
  "demo": {
    "enabled": true
  }
}
```

### Project / Import

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `project.create` | `{ projectCode, entityName, operatorId, industry, periodStart, periodEnd, lastPeriodStart }` | `{ projectId, ok }` | 建立專案；寫入 `config_project` + `config_project_state` |
| `project.load` | `{ projectId }` | `{ project, mapping, latestRuns }` | 從 repository 讀取既有專案的 metadata、mapping cache pointer 與最新 `runId`（validation/prescreen/scenario） |
| `import.gl.fromFile` | `{ filePath, fileName?, mode? }` | `{ batchId, rowCount, columns }` | **Scale-aware**：從 `.xlsx` / `.csv` 檔案路徑串流讀 GL 寫入 `staging_gl_raw_row`；payload 不帶 rows |
| `import.gl` | `{ fileName, rows, columns }` | `{ fileName, rows, columns }` | **Deprecated legacy fallback only**；正式 UI/demo/import path 不得使用，新代碼請改用 `import.gl.fromFile` |
| `import.tb.fromFile` | `{ filePath, fileName?, mode? }` | `{ batchId, rowCount, columns }` | **Scale-aware**：從 `.xlsx` / `.csv` 檔案路徑串流讀 TB 寫入 `staging_tb_raw_row`；payload 不帶 rows。語意對齊 `import.gl.fromFile` |
| `import.tb` | `{ fileName, rows, columns }` | `{ fileName, rows, columns }` | **Deprecated legacy fallback only**；正式 UI/demo/import path 不得使用，新代碼請改用 `import.tb.fromFile` |
| `import.accountMapping.fromFile` | `{ filePath, fileName?, mode? }` | `{ batchId, rowCount, columns }` | **Scale-aware**：從 `.xlsx` / `.csv` 檔案路徑串流讀科目配對表寫入 `staging_account_mapping_raw_row`；payload 不帶 rows。語意對齊 `import.gl.fromFile` |
| `import.accountMapping` | `{ fileName, rows }` | `{ fileName, rows }` | **Deprecated legacy fallback only**；正式 UI/demo/import path 不得使用，新代碼請改用 `import.accountMapping.fromFile` |
| `import.holiday` | `{ dates }` | `{ dates, batchId? }` | 載入假日；當有 `CurrentProjectId` 時寫入 `staging_calendar_raw_day` (replace 語意) |
| `import.makeupDay` | `{ dates }` | `{ dates, batchId? }` | 載入補班日；同上 |

`import.gl.fromFile` 細節：

- `filePath`：本機絕對路徑 (`.xlsx` / `.csv`)；handler 用 `IGlFileReader` 串流讀取。
- `fileName`：可選，預設取自 `filePath`。
- `mode`：`"replace"` (預設) 或 `"append"`；`replace` 會先刪除同 project + dataset_kind=`gl` 的舊批次。
- Response `columns`：實際讀到的 header row，供下一步 `mapping.autoSuggest` / `mapping.commit.gl` 使用。
- **Scale constraint**：response **絕對不**回 rows；明細只透過後續 keyset paging query 取。
- 正式資料、demo/test pipeline、以及任何可能進入 scale path 的匯入都必須走此 action；`import.gl` 僅保留為 legacy fallback。

### Mapping

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `mapping.autoSuggest` | `{ fields, columns }` | `{ suggested }` | 依欄位標籤與關鍵字自動配對 |
| `mapping.commit.gl` | `{ mapping }` | `{ ok, mapping, batchId?, projectedRowCount }` | 提交 GL logical mapping，並將最新 GL staging 批次 set-based 投影到 `target_gl_entry` |
| `mapping.commit.tb` | `{ mapping }` | `{ ok, mapping, batchId?, projectedRowCount }` | 提交 TB logical mapping，並將最新 TB staging 批次 set-based 投影到 `target_tb_balance` |

`fields` 來源通常為 UI 的欄位定義陣列。每個元素：

```json
{
  "key": "docNum",
  "label": "傳票號碼",
  "req": true,
  "type": "mix"
}
```

### Validation

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `validate.run` | `{}` | `{ stats, summary, v1, v2, v3, v4, diffAccounts, resultRef }` | 以 SQL set-based 執行 validation summary；明細寫入 `result_validation_*` |
| `query.validationDetailsPage` | `{ projectId, kind, cursor?, pageSize? }` | `{ rows, nextCursor }` | 從 `result_validation_v{1-4}` 以 keyset paging 讀 validation 明細；`kind` = `v1`~`v4` |

`validate.run` 的 response 應被前端視為：

- `stats`: GL 總筆數、憑證數、借貸合計、淨額
- `summary`: validation card summary
- `v1` ~ `v4`: 各 validation 指標數值
- `diffAccounts`: completeness 差異科目清單
- `resultRef`: `{ runId }`，明細由 `query.validationDetailsPage` keyset paging 讀取（pending §3.3.b）

### Prescreen

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `prescreen.run` | `{}` | `{ r1, r2, r3, r4, r4ZerosThreshold, r5Summary, r6, r7, r8, a2, a3, a4, descNullCount, resultRef }` | 以 SQL set-based 執行 prescreen summary；明細寫入 `result_prescreen_*`，不回完整 rows |
| `query.prescreenPage` | `{ projectId, kind, cursor?, pageSize? }` | `{ rows, nextCursor }` | 從 `result_prescreen_*` 以 keyset paging 讀 prescreen 明細 |

備註：

- `r1` ~ `r8` / `a2` ~ `a4` 是 summary counts，不是 row list
- `r5Summary` 為建立人員彙總，不包含明細 rows
- `descNullCount` 是摘要缺漏 count；明細走 `query.prescreenPage`

### Filter / Criteria

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `filter.preview` | `{ scenario }` | `{ scenario: { label, count, voucherCount, summary, previewRows, resultRef } }` | 以 SQL set-based 評估情境，明細寫入 `result_filter_run`；`previewRows` ≤ 1000，`resultRef = { runId }`，後續分頁走 `query.filterPage` |
| `query.filterPage` | `{ projectId, runId?, cursor?, pageSize? }` | `{ rows, nextCursor }` | 從 `result_filter_run` 以 keyset paging 讀情境明細；省略 `runId` 時取最新一次 |
| `filter.commit` | `{ scenarios }` | `{ ok }` | 保留已選條件 |

`scenario` schema：

```json
{
  "name": "情境名稱",
  "groups": [
    {
      "join": "AND",
      "rules": [
        {
          "join": "AND",
          "type": "prescreen | text | dateRange | numRange | accountPair | drCrOnly | manualAuto",
          "prescreenKey": "r1",
          "field": "",
          "keywords": "",
          "mode": "contains",
          "from": "",
          "to": "",
          "debitCategory": "",
          "creditCategory": "",
          "drCr": "debit",
          "isManual": "true"
        }
      ]
    }
  ]
}
```

### Export

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `export.validation` | `{}` | `{ ok, message }` | Current stub：validation 匯出仍委派前端；scale-complete export 需走 backend-controlled path |
| `export.prescreen` | `{}` | `{ ok, message }` | Current stub：prescreen 匯出仍委派前端；scale-complete export 需走 backend-controlled path |
| `export.criteria` | `{}` | `{ ok, message }` | Current stub：criteria 匯出仍委派前端；scale-complete export 需走 backend-controlled path |
| `export.workpaper` | `{ selected }` | `{ ok, message }` | Current stub：workpaper 匯出仍委派前端；正式 large-data path 必須改為 backend streaming writer |

## JetApi Typed Facade

前端**唯一**呼叫 bridge 的管道是 `window.JetApi.*`。此 facade 由 `JetBridgeScriptFactory` 以 `SupportedActions` 為單一事實來源自動產生；action name 與 facade method 對照規則為：

1. 以 `.` 切段。
2. 第一段小寫；後續每段首字母大寫（lowerCamelCase 串接）。
3. 例：`validate.run` → `JetApi.validateRun`；`mapping.commit.gl` → `JetApi.mappingCommitGl`；`demo.exportGlFile` → `JetApi.demoExportGlFile`。

規則：

- UI/demo/workflow code 一律呼叫 `await JetApi.xxx(payload)`，不得直接呼叫 `window.jet.invoke(...)` 或 `window.chrome.webview.postMessage(...)`（除 bootstrap script 本身）。
- 若呼叫未註冊的 method，facade 會丟出 Error，提示先在本 manifest 新增對應 action。
- 新增 action 時必定先改本 manifest、`SupportedActions`、handler，最後才在 UI 使用 `JetApi.<newMethod>`。

## Demo Pipeline 對齊原則

Demo 載入流程**必須**走與使用者上傳相同的 file-based import pipeline，不得再用 row-based demo fallback：

1. `JetApi.projectLoadDemo()` → 取 metadata（專案欄位、file names、holidays、makeup、建議 mapping）。
2. `JetApi.demoExportGlFile()` / `JetApi.demoExportTbFile()` / `JetApi.demoExportAccountMappingFile()` → 取得 host 端 `.xlsx` 檔案路徑。
3. `JetApi.projectCreate(metadata)`。
4. `JetApi.importGlFromFile({ filePath, fileName })` / `JetApi.importTbFromFile(...)` / `JetApi.importAccountMappingFromFile(...)`。
5. `JetApi.importHoliday({ dates })` / `JetApi.importMakeupDay({ dates })`。
6. `JetApi.mappingCommitGl({ mapping })` / `JetApi.mappingCommitTb({ mapping })`，以及任何未來已在本 manifest 登記的 account/classification commit action。
7. `JetApi.validateRun()` / `JetApi.prescreenRun()` / `JetApi.filterPreview({ scenario })`；明細使用 `query.validationDetailsPage` / `query.prescreenPage` / `query.filterPage` 分頁讀取。

`demo.fetch*Rows` 與 row-based `import.*` 只保留為 legacy fallback。正式 UI、測試按鈕、文件範例與新程式碼不得使用它們作為 demo pipeline。

## Current Logical Mapping Keys

### GL Mapping Keys

這些 key 目前被 `docs/jet-template.html` 與 C# handlers 共同使用：

| Key | Label | Required | Notes |
|:---|:---|:---|:---|
| `docNum` | 傳票號碼 | Yes | 憑證聚合主鍵 |
| `lineID` | 傳票文件項次 | Yes | UI mapping key；C# 目前主要依賴 `docNum` |
| `postDate` | 總帳日期 | Yes | validation / filter |
| `docDate` | 傳票核准日 | No | R1 / date-based rules |
| `accNum` | 會計科目編號 | Yes | validation / prescreen / filters |
| `accName` | 會計科目名稱 | Yes | UI / reporting |
| `description` | 傳票摘要 | Yes | R2 / text filters |
| `jeSource` | 分錄來源模組 | No | UI only today |
| `createBy` | 傳票建立人員 | No | R5 |
| `approveBy` | 傳票核准人員 | No | UI only today |
| `manual` | 人工/自動分錄 | No | manualAuto filter |
| `amount` | 傳票金額（單欄） | Conditional | 與 debit/credit 雙欄位互斥 |
| `debitAmount` | 借方金額 | Conditional | 雙欄位模式 |
| `creditAmount` | 貸方金額 | Conditional | 雙欄位模式 |
| `dcField` | 借貸別欄位 | No | prototype UI key |
| `dcDebitCode` | 借方標識代碼 | No | prototype UI key |

### TB Mapping Keys

| Key | Label | Required | Notes |
|:---|:---|:---|:---|
| `accNum` | 會計科目編號 | Yes | completeness diff |
| `accName` | 會計科目名稱 | Yes | UI only today |
| `amount` | 年度變動金額 | Conditional | 直接變動額 |
| `debitAmt` | 借方金額 | Optional | future mode support |
| `creditAmt` | 貸方金額 | Optional | future mode support |

## Step Data Outline

這份綱要是前端生成 UI 前應先對齊的資料模型。

| Step | 前端需要的資料 | 建議 action |
|:---|:---|:---|
| Step 0 Shell | app name, DB provider, supported actions, demo enabled | `app.bootstrap`, `system.ping` |
| Step 1 Project / Import | project metadata, import file names, streaming import columns, holidays, makeup days | `project.create`, `import.*.fromFile`, `project.loadDemo` |
| Step 2 Mapping | GL/TB field definitions, uploaded columns, suggested mappings, committed mappings | `mapping.autoSuggest`, `mapping.commit.gl`, `mapping.commit.tb` |
| Step 3 Validation | stats, summary cards, V1-V4 counts, resultRef, paged detail grids | `validate.run`, `query.validationDetailsPage` |
| Step 4 Prescreen / Criteria | R/A summary counts, resultRef, paged detail grids, scenario preview rows ≤1000 | `prescreen.run`, `query.prescreenPage`, `filter.preview`, `query.filterPage`, `filter.commit` |
| Step 5 Export | selected outputs, export feedback | `export.validation`, `export.prescreen`, `export.criteria`, `export.workpaper` |

## Change Process For New UI Or New Actions

當 agent 被要求新增畫面、重做 UX、或擴充 bridge 時，依序做：

1. 明確指出影響哪一個 workflow step。
2. 先檢查現有 action 是否已足夠。
3. 若不足，先在本 manifest 補齊：
   - action name
   - payload shape
   - response shape
   - owner layer
   - UI caller / fixed bindings
4. 再修改 `ActionDispatcher`、DTO、handler、HTML。
5. 若契約變動會影響 `docs/jet-guide.md`，同步更新。

## Anti-Patterns

- 先生成很完整的 UI，事後才補 action 契約
- 在 HTML 裡拼 SQL 或內嵌業務規則
- 把 bridge 當 application service 寫
- 改了 action payload，卻不更新 manifest
- 對同一需求同時發明 `query.*`、`load.*`、`fetch.*` 三種名稱空間
- 在前端實作 authoritative 的 validation / prescreen / filter 規則（必須走 handler）
- UI code 直接呼叫 `window.jet.invoke('xxx', payload)` 或 `window.chrome.webview.postMessage(...)`；一律改走 `JetApi.*`
- 同一條業務規則在 HTML/JS 與 C# handler 各寫一份（必然發散）
- Demo/test path 使用 `demo.fetch*Rows` 或 row-based `import.*` 模擬正式 pipeline
- **Bridge payload / response 攜帶超過 1000 筆明細 row**（大型 GL 母體會炸 JS 端與 postMessage；違反 `docs/jet-guide.md` §1.5）
- **在 Application/Bridge 層對 GL/TB row 集合做 LINQ 計算 V/R/Filter 規則**（必須由 DB 引擎 set-based 處理；違反 §1.5.2）

## Scale-First Contract Evolution (Roadmap)

本章記錄目前 prototype 契約 → 規模化目標契約的 **additive 演進路徑**。Phase 3+ 切換時遵循「先在 manifest 加 v2 contract，舊契約保留為 deprecated alias 一段時間」的順序，避免 silent break（Maxim #2）。完整背景見 `docs/jet-guide.md` §1.5。

### Ingest 契約演進

| 動作 | Prototype (現況) | 規模化目標 | 切換策略 |
|:---|:---|:---|:---|
| `import.gl` | `{ fileName, rows[], columns[] }` | `{ filePath, mode, columnMap }` — 後端透過 `IGlFileReader` streaming 讀檔，直接 `BulkInsert` 進 `staging_gl_raw_row` | 新增 `import.gl.fromFile`，舊版只作 legacy fallback |
| `import.tb` | `{ fileName, rows[], columns[] }` | `{ filePath, mode, columnMap }` | 同上，新增 `import.tb.fromFile` |
| `import.accountMapping` | `{ fileName, rows[] }` | `{ filePath }` | 同上 |

### Query 契約演進（Result Reference + Paging）

| 動作 | Prototype 回傳 | 規模化目標回傳 | 切換策略 |
|:---|:---|:---|:---|
| `validate.run` | `{ stats, summary, v1, v2, v3, v4, diffAccounts[] }` | `{ stats, summary, v1, v2, v3, v4, resultRef }` — `diffAccounts` 改走分頁 | 新增 `query.validationDetailsPage` |
| `prescreen.run` | `{ r1[], r2[], ..., r6[], descNull[] }` | `{ counts: { r1, r2, ... }, resultRef }` | 新增 `query.prescreenPage` (按 ruleKey + cursor) |
| `filter.preview` | `{ scenario: { resultRows[], count, voucherCount, summary } }` | `{ scenario: { count, voucherCount, summary, previewRows[≤1000], resultRef } }` | 同 action 內欄位演進；前端讀取改用 `previewRows` + `query.filterPage` |
| `filter.commit` | `{ ok }` | `{ ok, savedRef }` | additive 加 `savedRef` |

### 新增動作（規模化必備）

| 動作 | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `query.glPage` | `{ projectId, cursor, pageSize, sort? }` | `{ rows[], nextCursor }` | GL keyset paging（給 step 1 預覽 / step 5 工作底稿明細） |
| `query.validationDetailsPage` | `{ projectId, kind, cursor, pageSize }` | `{ rows[], nextCursor }` | V1-V4 明細分頁 |
| `query.prescreenPage` | `{ projectId, ruleKey, cursor, pageSize }` | `{ rows[], nextCursor }` | R1-R8 / A2-A4 明細分頁 |
| `query.filterPage` | `{ projectId, scenarioId, cursor, pageSize }` | `{ rows[], nextCursor }` | 自訂篩選明細分頁 |
| `export.workpaperStream` | `{ projectId, sheets[], outputPath }` | `{ ok, bytesWritten, sheetStats }` | 走 OpenXML SAX writer 直接寫檔 |

### Result Reference 概念

`resultRef = { projectId, runId, generatedUtc }`。用途：

1. 後續分頁 query 以 `runId` 鎖定同一次執行的結果（避免重跑時資料不一致）。
2. Workpaper export 以 `runId` 確認匯出的是哪一次規則執行。
3. 結果落地 `result_*` 表時 `runId` 是 partition key。
