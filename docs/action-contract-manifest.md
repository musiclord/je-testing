# JET Frontend Action Contract Manifest

本文件是 JET 前端、WebView2 bridge、C# handler 之間的**契約總表**。任何 agent 在生成 HTML / UX 或修改 action 之前，應先讀本文件。

## 使用原則

1. 前端**優先重用既有 action**，不要自行發明新 action。
2. 如果 UI 真的需要新資料或新行為，先更新本 manifest，再修改 `ActionDispatcher` 與相關 handler。
3. `docs/jet-template.html` 的 UI 生成應服從這裡的 action name、payload shape、response shape 與 fixed binding assumptions。
4. `Bridge` 只負責 transport，不負責業務判斷。

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
| `demo.fetchGlRows` | `{}` | `{ fileName, rows, columns }` | 取得 demo GL raw rows（驅動與使用者一致的 `import.gl` 流程） |
| `demo.fetchTbRows` | `{}` | `{ fileName, rows, columns }` | 取得 demo TB raw rows（驅動 `import.tb`） |
| `demo.fetchAccountMappingRows` | `{}` | `{ fileName, rows }` | 取得 demo account mapping rows（驅動 `import.accountMapping`） |

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
| `project.create` | `{ projectCode, entityName, operatorId, industry, periodStart, periodEnd, lastPeriodStart }` | `{ projectId, ok }` | 建立記憶體中的專案 session |
| `import.gl` | `{ fileName, rows, columns }` | `{ fileName, rows, columns }` | 載入 GL 主檔到 session |
| `import.tb` | `{ fileName, rows, columns }` | `{ fileName, rows, columns }` | 載入 TB 主檔到 session |
| `import.accountMapping` | `{ fileName, rows }` | `{ fileName, rows }` | 載入科目配對表 |
| `import.holiday` | `{ dates }` | `{ dates }` | 載入假日 |
| `import.makeupDay` | `{ dates }` | `{ dates }` | 載入補班日 |

備註：

- 目前 prototype 直接傳 `rows` 陣列，不是檔案路徑。
- `rows` 為 `Array<Record<string, string | number | boolean | null>>`。

### Mapping

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `mapping.autoSuggest` | `{ fields, columns }` | `{ suggested }` | 依欄位標籤與關鍵字自動配對 |
| `mapping.commit.gl` | `{ mapping }` | `{ ok, mapping }` | 提交 GL logical mapping |
| `mapping.commit.tb` | `{ mapping }` | `{ ok, mapping }` | 提交 TB logical mapping |

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
| `validate.run` | `{}` | `{ stats, summary, v1, v2, v3, v4, diffAccounts }` | 執行 prototype validation summary |

`validate.run` 的 response 應被前端視為：

- `stats`: GL 總筆數、憑證數、借貸合計、淨額
- `summary`: validation card summary
- `v1` ~ `v4`: 各 validation 指標數值
- `diffAccounts`: completeness 差異科目清單

### Prescreen

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `prescreen.run` | `{}` | `{ r1, r2, r3, r4, r4ZerosThreshold, r5, r5Summary, r6, descNull }` | 執行 prototype prescreen 結果 |

備註：

- `r1` ~ `r6` 目前多為 row list
- `r5Summary` 為建立人員彙總
- `descNull` 是摘要缺漏 row list

### Filter / Criteria

| Action | Payload | Response | 用途 |
|:---|:---|:---|:---|
| `filter.preview` | `{ scenario }` | `{ scenario: { label, resultRows, count, voucherCount, summary } }` | 預覽單一情境篩選結果 |
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
| `export.validation` | `{}` | `{ ok, message }` | validation 匯出委派前端 |
| `export.prescreen` | `{}` | `{ ok, message }` | prescreen 匯出委派前端 |
| `export.criteria` | `{}` | `{ ok, message }` | criteria 匯出委派前端 |
| `export.workpaper` | `{ selected }` | `{ ok, message }` | workpaper 匯出委派前端 |

## JetApi Typed Facade

前端**唯一**呼叫 bridge 的管道是 `window.JetApi.*`。此 facade 由 `JetBridgeScriptFactory` 以 `SupportedActions` 為單一事實來源自動產生；action name 與 facade method 對照規則為：

1. 以 `.` 切段。
2. 第一段小寫；後續每段首字母大寫（lowerCamelCase 串接）。
3. 例：`validate.run` → `JetApi.validateRun`；`mapping.commit.gl` → `JetApi.mappingCommitGl`；`demo.fetchGlRows` → `JetApi.demoFetchGlRows`。

規則：

- UI/demo/workflow code 一律呼叫 `await JetApi.xxx(payload)`，不得直接呼叫 `window.jet.invoke(...)` 或 `window.chrome.webview.postMessage(...)`（除 bootstrap script 本身）。
- 若呼叫未註冊的 method，facade 會丟出 Error，提示先在本 manifest 新增對應 action。
- 新增 action 時必定先改本 manifest、`SupportedActions`、handler，最後才在 UI 使用 `JetApi.<newMethod>`。

## Demo Pipeline 對齊原則

Demo 載入流程**必須**走與使用者上傳完全相同的 `import.*` pipeline：

1. `JetApi.projectLoadDemo()` → 取 metadata（專案欄位、file names、holidays、makeup、建議 mapping）。
2. `JetApi.projectCreate(metadata)`。
3. `JetApi.demoFetchGlRows()` → `JetApi.importGl({ fileName, rows, columns })`。
4. `JetApi.demoFetchTbRows()` → `JetApi.importTb(...)`。
5. `JetApi.demoFetchAccountMappingRows()` → `JetApi.importAccountMapping(...)`。
6. `JetApi.importHoliday({ dates })` / `JetApi.importMakeupDay({ dates })`。

Demo 與 production path 從此完全對齊；任何 pipeline 變更必須同時通過 demo。

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
| Step 1 Project / Import | project metadata, import file names, raw rows/columns, holidays, makeup days | `project.create`, `import.*`, `project.loadDemo` |
| Step 2 Mapping | GL/TB field definitions, uploaded columns, suggested mappings, committed mappings | `mapping.autoSuggest`, `mapping.commit.gl`, `mapping.commit.tb` |
| Step 3 Validation | stats, summary cards, V1-V4 counts, diff account grid | `validate.run` |
| Step 4 Prescreen / Criteria | R1-R6 row sets, scenario preview counts, voucher counts, saved scenarios | `prescreen.run`, `filter.preview`, `filter.commit` |
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
