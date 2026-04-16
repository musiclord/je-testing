# JET 進階篩選系統 — 完備開發規格書

> **版本**: 1.0
> **目的**: 本文件為 AI agent 的完備工作規格，整合了篩選系統的設計哲學、資料模型、開發原則與邊界限制。任何實作此系統的 agent 應以本文件為**單一事實來源 (Single Source of Truth)**。
> **關聯文件**: [`jet-domain-model.md`](jet-domain-model.md) (業務邏輯)、[`architecture.md`](architecture.md) (系統架構)、[`technical_guide.md`](technical_guide.md) (開發指南)

---

## 目錄

1. [設計哲學與開發原則](#1-設計哲學與開發原則)
2. [技術框架約束](#2-技術框架約束)
3. [Thin-Bridge Action-Dispatcher 架構](#3-thin-bridge-action-dispatcher-架構)
4. [CQRS 資料處理模式](#4-cqrs-資料處理模式)
5. [篩選條件 AST 模型 (遞迴樹)](#5-篩選條件-ast-模型-遞迴樹)
6. [欄位登記表 (Field Registry)](#6-欄位登記表-field-registry)
7. [單一條件屬性定義 (FilterRule)](#7-單一條件屬性定義-filterrule)
8. [條件組合的層級結構 (FilterGroup)](#8-條件組合的層級結構-filtergroup)
9. [條件邏輯轉換為 SQL](#9-條件邏輯轉換為-sql)
10. [科目配對分析 (Account Pairing)](#10-科目配對分析-account-pairing)
11. [FilterScenario 頂層模型](#11-filterscenario-頂層模型)
12. [持久化策略 (SQLite)](#12-持久化策略-sqlite)
13. [驗證規則](#13-驗證規則)
14. [安全邊界與限制](#14-安全邊界與限制)
15. [前後端資料流全景](#15-前後端資料流全景)
16. [附錄 A：完整型別定義 (TypeScript 語義)](#附錄-a完整型別定義-typescript-語義)
17. [附錄 B：完整型別定義 (C# 語義)](#附錄-b完整型別定義-c-語義)
18. [附錄 C：SQL 生成範例](#附錄-csql-生成範例)

---

## 1. 設計哲學與開發原則

### 1.1 核心設計哲學

| 編號 | 原則 | 說明 |
|:---|:---|:---|
| P1 | **領域優先 (Domain First)** | 所有設計決策以審計業務需求為出發點，技術服務於業務，而非反過來 |
| P2 | **AST 即真理 (AST as Truth)** | 篩選條件的唯一表示法是 AST (抽象語法樹)，JSON 序列化只是其傳輸格式 |
| P3 | **前端無邏輯 (Dumb Frontend)** | HTML/JS 前端是純粹的 UI 殼層，不含業務邏輯、不組 SQL、不做驗證 |
| P4 | **後端為閘門 (Backend as Gatekeeper)** | 所有資料變更與查詢必須經過 .NET Service Layer 的驗證與轉換 |
| P5 | **資料庫為引擎 (DB as Engine)** | SQLite 負責所有大量資料運算，.NET 僅處理結果集 |
| P6 | **CQRS 嚴格分離** | 寫入路徑 (Command) 與讀取路徑 (Query) 在介面、模型與處理邏輯上完全分離 |
| P7 | **安全內建 (Security by Design)** | 白名單驗證 + 參數化查詢，零容忍字串拼接 SQL |
| P8 | **AI 友善 (AI-Friendly)** | 所有 JSON 結構對齊 react-querybuilder 標準，便於 AI 生成與解析 |

### 1.2 開發原則

| 編號 | 原則 | 約束 |
|:---|:---|:---|
| D1 | **Thin-Bridge** | WebView2 Bridge 方法只做 JSON 轉發，不含業務邏輯 |
| D2 | **Action-Dispatcher** | 前後端通訊採用 `{ action, payload }` → `Dispatcher → Handler` 模式 |
| D3 | **不可變條件樹** | 一旦 FilterScenario 提交執行，其 AST 快照不可被修改 |
| D4 | **白名單防護** | 所有進入 SQL 的欄位名與運算子必須經過白名單比對 |
| D5 | **遞迴有限** | AST 巢狀深度硬性上限 ≤ 6 層 |
| D6 | **統一建模** | 預篩選標記 (R1-R8) 與自訂條件使用相同的 FilterRule 模型 |

---

## 2. 技術框架約束

### 2.1 技術棧定義

本系統嚴格在以下框架約束下開發：

```
.NET 10 LTS + WinForms Host + WebView2 + HTML/CSS/JS Frontend + SQLite
```

| 層級 | 技術 | 角色 |
|:---|:---|:---|
| **Frontend** | HTML / CSS / JS (嵌入 WebView2) | 純 UI，由 AI 生成 |
| **Bridge** | WebView2 Interop | 薄橋接層，轉發 action + payload |
| **Desktop Host** | WinForms (.exe) | 容器，管理 WebView2 生命週期 |
| **Service Layer** | C# / .NET 10 | 業務邏輯、CQRS Handlers、驗證、SQL 生成 |
| **Database** | SQLite | 本地資料儲存、篩選運算引擎 |

### 2.2 為什麼是 SQLite 而非 SQL Server

| 考量 | SQLite | SQL Server |
|:---|:---|:---|
| 部署複雜度 | 零 — 單檔案嵌入 | 需要安裝 Server 實例 |
| 打包方式 | 跟隨 .exe 一起分發 | 獨立安裝 |
| 資安摩擦 | 無網路端口 | 需開放 TCP 端口 |
| 適用資料量 | 數千至數百萬筆 (足夠) | 數千萬筆以上 |
| 本地化 | 完全單機 | 可能需要 DBA |

> **邊界**: 如果單一案件的 GL 資料超過 500 萬筆，系統應提示使用者考慮分批處理。SQLite 的寫入鎖特性在單機桌面應用中不成問題。

### 2.3 不可使用的技術

以下技術在本專案中明確排除：

- ❌ Python (全球資安規範禁止)
- ❌ Web Server (不走內網 server 形式)
- ❌ Entity Framework / ORM (使用原生 ADO.NET 搭配 Microsoft.Data.Sqlite)
- ❌ WPF / Blazor Hybrid (Phase 1 過重)
- ❌ .NET Framework (不支援現代 CLI/AI workflow)

---

## 3. Thin-Bridge Action-Dispatcher 架構

### 3.1 架構概念

```
┌─────────────────────────────────────────────────────────┐
│  HTML/JS Frontend (WebView2)                            │
│                                                         │
│  使用者操作 → 組裝 { action, payload } → 呼叫 Bridge    │
└──────────────────────┬──────────────────────────────────┘
                       │ chrome.webview.hostObjects.jet.dispatch(json)
                       ▼
┌──────────────────────────────────────────────────────────┐
│  Thin Bridge Layer (C#)                                  │
│                                                          │
│  public async Task<string> Dispatch(string json)         │
│  {                                                       │
│      // 只做三件事:                                       │
│      // 1. 反序列化 JSON → BridgeRequest                  │
│      // 2. 轉發給 ActionDispatcher                        │
│      // 3. 序列化 result → JSON 回傳                      │
│  }                                                       │
└──────────────────────┬──────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────┐
│  Action Dispatcher (C#)                                  │
│                                                          │
│  根據 action 名稱，路由到對應的 Handler:                   │
│                                                          │
│  "filter.getFields"     → FilterQueryHandler.GetFields() │
│  "filter.execute"       → FilterCommandHandler.Execute() │
│  "filter.preview"       → FilterQueryHandler.Preview()   │
│  "filter.saveScenario"  → FilterCommandHandler.Save()    │
│  "filter.loadScenario"  → FilterQueryHandler.Load()      │
│  "import.gl"            → ImportCommandHandler.ImportGL() │
│  "export.workpaper"     → ExportCommandHandler.Export()   │
└──────────────────────────────────────────────────────────┘
```

### 3.2 Bridge 介面定義

```csharp
/// <summary>
/// WebView2 Bridge — 唯一的前後端通訊接口
/// 此類別註冊為 WebView2 Host Object，供 JS 呼叫
/// 設計原則: 此類別不含任何業務邏輯
/// </summary>
public class JetBridge
{
    private readonly IActionDispatcher _dispatcher;

    public JetBridge(IActionDispatcher dispatcher)
    {
        _dispatcher = dispatcher;
    }

    /// <summary>
    /// 前端呼叫的唯一入口
    /// JS 端: await chrome.webview.hostObjects.jet.Dispatch(jsonString)
    /// </summary>
    public async Task<string> Dispatch(string requestJson)
    {
        var request = JsonSerializer.Deserialize<BridgeRequest>(requestJson);
        var result = await _dispatcher.DispatchAsync(request.Action, request.Payload);
        return JsonSerializer.Serialize(result);
    }
}

/// <summary>
/// 通用請求格式
/// </summary>
public record BridgeRequest(string Action, JsonElement Payload);

/// <summary>
/// 通用回應格式
/// </summary>
public record BridgeResponse(bool Success, object? Data, string? Error);
```

### 3.3 Action 命名規範

所有 action 名稱遵循 `{module}.{verb}` 格式：

| Action | 類型 | Handler | 說明 |
|:---|:---|:---|:---|
| `filter.getFields` | Query | FilterQueryHandler | 取得可用篩選欄位清單 |
| `filter.getOperators` | Query | FilterQueryHandler | 取得欄位對應的運算子 |
| `filter.preview` | Query | FilterQueryHandler | 預覽篩選結果 (COUNT) |
| `filter.execute` | Command | FilterCommandHandler | 執行篩選並寫入結果表 |
| `filter.saveScenario` | Command | FilterCommandHandler | 儲存篩選情境 |
| `filter.loadScenario` | Query | FilterQueryHandler | 載入已儲存的篩選情境 |
| `filter.listScenarios` | Query | FilterQueryHandler | 列出所有已儲存情境 |
| `filter.deleteScenario` | Command | FilterCommandHandler | 刪除篩選情境 |
| `import.gl` | Command | ImportCommandHandler | 匯入 GL 資料 |
| `import.tb` | Command | ImportCommandHandler | 匯入 TB 資料 |
| `validation.run` | Command | ValidationCommandHandler | 執行資料驗證 |
| `prescreen.execute` | Command | PreScreenCommandHandler | 執行預篩選 R1-R8 |
| `export.workpaper` | Command | ExportCommandHandler | 匯出工作底稿 |

> **邊界**: Action 名稱是有限集合，不可由前端動態定義。新增 action 必須同時新增對應的 Handler 類別。

---

## 4. CQRS 資料處理模式

### 4.1 CQRS 在本系統中的定義

**CQRS (Command Query Responsibility Segregation)** 意味著：

- **Command 路徑** (寫入): 改變系統狀態的操作 — 匯入資料、執行篩選、儲存情境
- **Query 路徑** (讀取): 不改變系統狀態的操作 — 查詢欄位清單、預覽結果、載入情境

兩條路徑使用**不同的介面、不同的 DTO、不同的 Handler**。

### 4.2 CQRS 介面定義

```csharp
// ===== Command 路徑 =====

/// <summary>
/// 所有 Command 的基底介面
/// Command 改變系統狀態，回傳操作結果
/// </summary>
public interface ICommand { }

public interface ICommandHandler<TCommand, TResult> where TCommand : ICommand
{
    Task<TResult> HandleAsync(TCommand command);
}

// ===== Query 路徑 =====

/// <summary>
/// 所有 Query 的基底介面
/// Query 不改變系統狀態，只回傳資料
/// </summary>
public interface IQuery { }

public interface IQueryHandler<TQuery, TResult> where TQuery : IQuery
{
    Task<TResult> HandleAsync(TQuery query);
}
```

### 4.3 篩選相關的 CQRS 分離

| 操作 | 路徑 | Command/Query DTO | Handler |
|:---|:---|:---|:---|
| 取得可篩選欄位 | Query | `GetFieldsQuery` | `FilterQueryHandler` |
| 取得欄位運算子 | Query | `GetOperatorsQuery { FieldName }` | `FilterQueryHandler` |
| 預覽篩選筆數 | Query | `PreviewFilterQuery { FilterTree }` | `FilterQueryHandler` |
| 載入篩選情境 | Query | `LoadScenarioQuery { ScenarioId }` | `FilterQueryHandler` |
| 執行篩選 | Command | `ExecuteFilterCommand { FilterTree }` | `FilterCommandHandler` |
| 儲存篩選情境 | Command | `SaveScenarioCommand { Scenario }` | `FilterCommandHandler` |
| 刪除篩選情境 | Command | `DeleteScenarioCommand { ScenarioId }` | `FilterCommandHandler` |

### 4.4 CQRS 邊界規則

| 規則 | 說明 |
|:---|:---|
| Query 不可修改資料庫 | Query Handler 內部只允許 `SELECT` |
| Command 必須回傳結果 | 即使是 void 操作也回傳 `CommandResult { Success, Message }` |
| 同一 Handler 不可混合 | 一個 Handler 類別只處理 Command 或 Query，不可兩者混合 |
| DTO 不可跨路徑共用 | Command DTO 與 Query DTO 不共用，即使結構相似 |
| 前端不知道 CQRS | 前端只發 `action + payload`，CQRS 是後端的內部架構 |

---

## 5. 篩選條件 AST 模型 (遞迴樹)

### 5.1 為什麼選擇 AST 而非固定層級結構

過去曾考慮「三層固定結構」(Project → Scenario → ConditionSet)，其中頂層 OR、內層 AND，即 Disjunctive Normal Form (DNF)。此設計有以下根本問題：

| 問題 | 說明 |
|:---|:---|
| **DNF 膨脹** | `(A OR B) AND (C OR D)` 在 DNF 下展開為 4 組條件 |
| **違反直覺** | 使用者被迫用非自然方式表達意圖 |
| **不符業界標準** | react-querybuilder、Elasticsearch、OData 全部採用遞迴結構 |
| **可擴充性差** | 新增 NOT 邏輯需要結構性改動 |

因此，本系統採用 **遞迴樹 (AST / Abstract Syntax Tree)**，基於以下設計模式：

- **Composite Pattern** (GoF) — 統一 Leaf (Rule) 與 Branch (Group) 的介面
- **Visitor Pattern** (GoF) — 遍歷 AST 產出 SQL，與資料結構解耦
- **Specification Pattern** (DDD) — 可組合的條件表達

### 5.2 AST 節點定義

```
FilterNode (抽象)
├── FilterRule  (葉節點 — 單一條件)
│   例: [Amount] > 100000
│   例: [PRESCR_R1] = true
│   例: [DocumentDescription] LIKE '%調整%'
│
└── FilterGroup (分支節點 — 邏輯組合)
    ├── combinator: 'AND' | 'OR'
    ├── not?: boolean
    └── children: FilterNode[]  ← 遞迴 (子節點可為 Rule 或 Group)
```

### 5.3 與 react-querybuilder 的對齊

本系統的 AST JSON 格式直接對齊 [react-querybuilder](https://react-querybuilder.js.org/) v7/v8 的標準格式：

| react-querybuilder | 本系統 | 說明 |
|:---|:---|:---|
| `combinator: 'and' \| 'or'` | `combinator: 'AND' \| 'OR'` | 邏輯運算子 (大小寫映射) |
| `rules: (Rule \| Group)[]` | `children: FilterNode[]` | 子節點陣列 |
| `field` | `field` | 欄位名稱 |
| `operator` | `operator` | 運算子名稱 |
| `value` | `value` | 條件值 |

> **重要**: 前端使用 react-querybuilder 元件時，其輸出 JSON 可直接作為本系統的 `FilterGroup` 輸入，僅需將 `combinator` 轉為大寫、`rules` 重命名為 `children`。此映射在 Thin-Bridge 層完成。

---

## 6. 欄位登記表 (Field Registry)

### 6.1 設計理由

欄位定義與條件實例**分離**，遵循 Specification Pattern 精神：

- 欄位的資料型別、允許的運算子、顯示名稱**集中定義一次** (Field Registry)
- 每個 FilterRule 只需引用 `field` 名稱，不重複攜帶型別資訊
- 新增可篩選欄位只需更新 Registry，不需改動條件模型

### 6.2 FieldDefinition 結構

```
FieldDefinition
├── name: string              // 系統欄位名 (唯一鍵) e.g., "Amount"
├── label: string             // 顯示名稱 e.g., "傳票金額"
├── dataType: DataType        // 'string' | 'number' | 'date' | 'boolean'
├── category: FieldCategory   // 分類 (見下方)
├── operators: OperatorDef[]  // 該欄位允許的運算子清單
├── valueEditor: string       // UI 提示: 'text' | 'number' | 'date' | 'select' | 'multiselect'
├── values?: SelectOption[]   // 固定值清單 (用於 select/multiselect)
└── dbColumn: string          // 對應的 SQLite 欄位名 (可與 name 不同)
```

### 6.3 欄位分類 (FieldCategory)

| Category | 說明 | 範例欄位 |
|:---|:---|:---|
| `gl_core` | GL 核心欄位 (匯入時就存在) | Amount, AccountCode, DocumentNumber |
| `gl_derived` | 衍生計算欄位 (ETL 產生) | DebitAmount, CreditAmount, DrCr |
| `gl_metadata` | GL 中繼欄位 | CreatedBy, ApprovedBy, SourceModule |
| `date_field` | 日期欄位 | ApprovalDate, PostDate |
| `prescreen_tag` | 預篩選結果標記 | PRESCR_R1, PRESCR_R2, ... PRESCR_R8 |
| `date_flag` | 日期屬性標記 | DOC_WEEKEND_JE_T, IS_HOLIDAY_DOC_JE_T |
| `custom` | 使用者自訂 | (保留) |

### 6.4 運算子與 DataType 的相容性

| DataType | 允許的運算子 |
|:---|:---|
| `string` | equals, notEquals, contains, notContains, beginsWith, endsWith, isEmpty, isNotEmpty, in, notIn |
| `number` | equals, notEquals, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, between, notBetween |
| `date` | equals, notEquals, greaterThan, greaterThanOrEqual, lessThan, lessThanOrEqual, between |
| `boolean` | equals |

> **邊界**: 前端 UI 在使用者選擇欄位後，必須只顯示該欄位 DataType 對應的合法運算子。後端在 SQL 生成前也會再次驗證此相容性。

### 6.5 預篩選標記作為欄位 — 統一建模

**關鍵設計決策**: 預篩選結果 (R1-R8, A2-A4 的標記) 不使用特殊結構，而是統一定義為 `category = 'prescreen_tag'` 的欄位：

```
FieldDefinition {
  name: "PRESCR_R1",
  label: "#1 期末後核准",
  dataType: "boolean",
  category: "prescreen_tag",
  operators: [{ name: "equals", label: "是" }],
  valueEditor: "select",
  values: [
    { name: "true", label: "符合 (Y)" },
    { name: "false", label: "不符合" }
  ],
  dbColumn: "PRESCR_R1"
}
```

如此，「Amount > 100000」和「R1 = Y」使用完全相同的 FilterRule 結構，不需要 `isPreScreenTag` 特殊分支。

---

## 7. 單一條件屬性定義 (FilterRule)

### 7.1 FilterRule 結構

```
FilterRule
├── type: "rule"           // 固定值，識別為葉節點
├── id: string             // UUID，前端生成，用於 UI 追蹤
├── field: string          // 引用 FieldDefinition.name (e.g., "Amount")
├── operator: string       // 引用 OperatorDef.name (e.g., "greaterThan")
└── value: RuleValue       // 條件值
```

### 7.2 RuleValue 型別定義

`value` 欄位的型別根據運算子而定：

| 運算子 | value 型別 | 範例 |
|:---|:---|:---|
| equals, notEquals, greaterThan, lessThan, ... | `string \| number \| boolean` | `100000`, `"調整"`, `true` |
| contains, notContains, beginsWith, endsWith | `string` | `"調整"` |
| between, notBetween | `[number, number]` 或 `[string, string]` | `[50000, 200000]`, `["2024-01-01", "2024-06-30"]` |
| in, notIn | `string[]` | `["AP", "AR", "GL"]` |
| isEmpty, isNotEmpty | `null` | `null` (不需要值) |

### 7.3 FilterRule 不可變性

一旦 FilterRule 建立後，其 `field` 和 `operator` 的組合確定了值的型別。前端在使用者改變 `field` 時，應：

1. 重置 `operator` 為該欄位的預設運算子
2. 清空 `value`

### 7.4 FilterRule 的邊界與限制

| 限制 | 說明 |
|:---|:---|
| `field` 必須存在於 Field Registry | 不存在的欄位名會被後端拒絕 |
| `operator` 必須與欄位 DataType 相容 | 不相容的運算子會被後端拒絕 |
| `value` 不可為 `undefined` | 除 isEmpty/isNotEmpty 外，value 必須有值 |
| `value` 型別必須與 DataType 匹配 | string 欄位不接受 number 值 (反之亦然) |
| 文字值最大長度 | 500 字元 |
| in/notIn 清單最大項數 | 100 個值 |
| between 的 min ≤ max | 後端驗證並報錯 |

---

## 8. 條件組合的層級結構 (FilterGroup)

### 8.1 FilterGroup 結構

```
FilterGroup
├── type: "group"              // 固定值，識別為分支節點
├── id: string                 // UUID
├── combinator: "AND" | "OR"   // 邏輯運算子
├── not?: boolean              // 可選，支援 NOT 反轉
└── children: FilterNode[]     // 子節點陣列 (可包含 Rule 或 Group)
```

### 8.2 遞迴與深度限制

```
根節點 (FilterGroup, depth=0)
├── Rule: Amount > 100000                              (depth=1)
├── Group (OR, depth=1)
│   ├── Rule: PRESCR_R1 = true                         (depth=2)
│   ├── Rule: PRESCR_R3 = true                         (depth=2)
│   └── Group (AND, depth=2)
│       ├── Rule: PostDate BETWEEN [2024-12-01, 2024-12-31]  (depth=3)
│       └── Rule: IsManual = true                            (depth=3)
└── Rule: DocumentDescription CONTAINS '調整'          (depth=1)
```

| 深度控制 | 規則 |
|:---|:---|
| 建議深度 | ≤ 4 層 (UI 層面的軟性引導) |
| 硬性上限 | ≤ 6 層 (後端驗證，超過拒絕) |
| 實務觀察 | 審計篩選 99% 的情境用 2-3 層即足夠 |

### 8.3 空群組處理

| 情況 | 處理方式 |
|:---|:---|
| children 為空陣列 | SQL 生成時產出 `1=1` (無條件) |
| children 僅有一個元素 | 正常處理，外層括號保留 |
| 整棵樹為空 | 等同「不套用進階篩選」 |

### 8.4 FilterGroup 的邊界與限制

| 限制 | 說明 |
|:---|:---|
| combinator 只接受 "AND" / "OR" | 其他值被拒絕 |
| children 不可包含 null | 陣列中的每個元素必須是合法的 FilterNode |
| 同一層級的 children 數量上限 | 50 個 (防止過度複雜) |
| NOT 反轉僅作用於當前 Group | 不影響子節點的內部邏輯 |

---

## 9. 條件邏輯轉換為 SQL

### 9.1 轉換架構 (Visitor Pattern)

```
FilterNode (AST)
    │
    ▼
SqlVisitor (遍歷器)
    │
    ├── 白名單驗證 (WhitelistValidator)
    │   ├── 欄位名是否在允許清單中？
    │   └── 運算子名是否合法？
    │
    ├── SQL 片段生成
    │   ├── FilterRule → "[Column] op @param"
    │   └── FilterGroup → "(clause1 AND/OR clause2 ...)"
    │
    └── 參數收集
        └── List<SqliteParameter>
    │
    ▼
輸出: (string whereSql, SqliteParameter[] parameters)
```

### 9.2 白名單驗證 (Security Layer)

**所有進入 SQL 的識別符必須經過白名單比對**，這是安全的第一道防線：

```
AllowedColumns = {
  "DocumentNumber", "Amount", "AccountCode", "AccountName",
  "DocumentDescription", "ApprovalDate", "PostDate",
  "CreatedBy", "ApprovedBy", "SourceModule", "IsManual",
  "DebitAmount", "CreditAmount", "DrCr",
  "PRESCR_R1", "PRESCR_R2", "PRESCR_R3", "PRESCR_R4",
  "PRESCR_R7", "PRESCR_R8", "PRESCR_A2", "PRESCR_A4",
  "DOC_WEEKEND_JE_T", "POST_WEEKEND_JE_T",
  "IS_HOLIDAY_DOC_JE_T", "IS_HOLIDAY_POST_JE_T"
}

OperatorMapping = {
  "equals"              → "=",
  "notEquals"           → "!=",
  "greaterThan"         → ">",
  "greaterThanOrEqual"  → ">=",
  "lessThan"            → "<",
  "lessThanOrEqual"     → "<=",
  "contains"            → "LIKE",      // value → '%value%'
  "notContains"         → "NOT LIKE",  // value → '%value%'
  "beginsWith"          → "LIKE",      // value → 'value%'
  "endsWith"            → "LIKE",      // value → '%value'
  "between"             → "BETWEEN",
  "notBetween"          → "NOT BETWEEN",
  "in"                  → "IN",
  "notIn"               → "NOT IN",
  "isEmpty"             → "IS NULL",
  "isNotEmpty"          → "IS NOT NULL"
}
```

> **安全原則**: 如果欄位名不在 `AllowedColumns` 中，或運算子不在 `OperatorMapping` 中，SqlVisitor **必須拋出 SecurityException**，終止整個查詢。

### 9.3 SQL 生成規則 (逐運算子)

| 運算子 | 生成的 SQL 片段 | 參數 |
|:---|:---|:---|
| equals | `[Col] = @p0` | `@p0 = value` |
| notEquals | `[Col] != @p0` | `@p0 = value` |
| greaterThan | `[Col] > @p0` | `@p0 = value` |
| greaterThanOrEqual | `[Col] >= @p0` | `@p0 = value` |
| lessThan | `[Col] < @p0` | `@p0 = value` |
| lessThanOrEqual | `[Col] <= @p0` | `@p0 = value` |
| contains | `[Col] LIKE @p0` | `@p0 = '%' + value + '%'` |
| notContains | `[Col] NOT LIKE @p0` | `@p0 = '%' + value + '%'` |
| beginsWith | `[Col] LIKE @p0` | `@p0 = value + '%'` |
| endsWith | `[Col] LIKE @p0` | `@p0 = '%' + value` |
| between | `[Col] BETWEEN @p0 AND @p1` | `@p0 = min, @p1 = max` |
| notBetween | `[Col] NOT BETWEEN @p0 AND @p1` | `@p0 = min, @p1 = max` |
| in | `[Col] IN (@p0, @p1, @p2)` | `@p0..@pN = values[]` |
| notIn | `[Col] NOT IN (@p0, @p1, @p2)` | `@p0..@pN = values[]` |
| isEmpty | `[Col] IS NULL` | (無參數) |
| isNotEmpty | `[Col] IS NOT NULL` | (無參數) |

### 9.4 遞迴 SQL 生成的虛擬碼

```
function visit(node):
    if node is FilterRule:
        validate(node.field ∈ AllowedColumns)
        validate(node.operator ∈ OperatorMapping)
        sqlOp = OperatorMapping[node.operator]
        columnName = "[" + node.field + "]"
        
        match node.operator:
            "isEmpty"    → return columnName + " IS NULL"
            "isNotEmpty" → return columnName + " IS NOT NULL"
            "between"    → p1, p2 = nextParam(), nextParam()
                           addParam(p1, node.value[0])
                           addParam(p2, node.value[1])
                           return columnName + " BETWEEN " + p1 + " AND " + p2
            "in"/"notIn" → params = [nextParam() for each v in node.value]
                           for each (p, v) in zip(params, node.value): addParam(p, v)
                           return columnName + " " + sqlOp + " (" + join(params, ", ") + ")"
            "contains"   → p = nextParam()
                           addParam(p, "%" + node.value + "%")
                           return columnName + " LIKE " + p
            default      → p = nextParam()
                           addParam(p, node.value)
                           return columnName + " " + sqlOp + " " + p

    if node is FilterGroup:
        if node.children is empty:
            return "1=1"
        
        clauses = [visit(child) for child in node.children]
        separator = " AND " if node.combinator == "AND" else " OR "
        combined = "(" + join(clauses, separator) + ")"
        
        if node.not:
            return "NOT " + combined
        return combined
```

### 9.5 SQL 生成的邊界與限制

| 限制 | 說明 |
|:---|:---|
| 參數數量上限 | SQLite 預設上限 999 個參數 (SQLITE_MAX_VARIABLE_NUMBER) |
| 欄位名引用方式 | 一律使用 `[ColumnName]` 方括號引用 |
| SQL 關鍵字保護 | 運算子映射表已確保只產出安全的 SQL 片段 |
| NULL 值處理 | `IS NULL` / `IS NOT NULL` 是獨立運算子，不與 `=` 混用 |
| LIKE 跳脫 | 使用者輸入的 `%` 和 `_` 字元在 LIKE 運算中需跳脫 |
| Unicode | SQLite 原生支援 UTF-8，中文關鍵字直接作為參數值傳入 |

---

## 10. 科目配對分析 (Account Pairing)

### 10.1 為什麼獨立於條件樹

科目配對分析在語意上是**傳票層級 (Document-level)** 的操作 — 它查看的是「同一傳票內借貸科目的組合」，而非「單一分錄行的屬性」。這與一般的欄位條件篩選 (分錄行層級) 本質不同。

將科目配對獨立出來的理由：

| 理由 | 說明 |
|:---|:---|
| SQL 結構不同 | 科目配對使用 `EXISTS` + 子查詢，而非 `WHERE` 條件 |
| 語意不同 | 它是「傳票包含 X 借方且包含 Y 貸方」，不是「這筆分錄的欄位等於某值」 |
| 執行順序 | 可先執行科目配對產生中間結果，再用條件樹做進一步篩選 |
| UX 分離 | 在 UI 上，科目配對是獨立的功能區塊，不應混入條件建構器 |

### 10.2 AccountPairing 結構

```
AccountPairing
├── mode: "typeA" | "typeB" | "typeC"
├── debitCategories: string[]     // 借方科目分類名稱
└── creditCategories: string[]    // 貸方科目分類名稱
```

| Mode | 名稱 | 邏輯 |
|:---|:---|:---|
| typeA | 精確配對 | 傳票同時包含指定借方分類 + 指定貸方分類 |
| typeB | 借方錨定 | 找到指定借方分類的傳票，取出所有貸方分錄 |
| typeC | 貸方錨定 | 找到指定貸方分類的傳票，取出所有借方分錄 |

> **邊界**: 科目配對必須有已上傳的科目配對表才能執行。若無科目配對表，此功能不可用。

---

## 11. FilterScenario 頂層模型

### 11.1 完整結構

```
FilterScenario
├── id: string                    // UUID
├── name: string                  // 使用者命名 (e.g., "Phase 1 — 期末異常")
├── description?: string          // 選填描述
├── projectId: string             // 所屬專案 ID
├── createdBy: string             // 建立者
├── createdAt: string             // ISO 8601 時間戳
├── modifiedAt: string            // 最後修改時間
│
├── rootGroup: FilterGroup        // AST 根節點 (進階篩選條件樹)
│
├── accountPairing?: AccountPairing  // 科目配對設定 (可選)
│
├── executionHistory: ExecutionRecord[]  // 執行歷史 (唯讀)
│   ├── executedAt: string
│   ├── resultCount: number
│   └── filterTreeSnapshot: string    // 執行時的 AST JSON 快照
│
└── status: "draft" | "executed"      // 狀態
```

### 11.2 生命週期

```
建立 (draft)
  │
  ├─→ 編輯 rootGroup / accountPairing (仍為 draft)
  │
  ├─→ 預覽 (Query: 只回傳 COUNT，不改狀態)
  │
  ├─→ 執行 (Command: 寫入結果表，狀態 → executed)
  │     └─→ executionHistory 新增一筆紀錄
  │          包含 filterTreeSnapshot (AST 快照不可變)
  │
  ├─→ 修改後重新執行 (允許，產生新的 history record)
  │
  └─→ 刪除
```

### 11.3 邊界與限制

| 限制 | 說明 |
|:---|:---|
| name 最大長度 | 200 字元 |
| description 最大長度 | 1000 字元 |
| 單一專案最多情境數 | 100 個 (軟性限制) |
| 執行歷史保留 | 每個情境最多保留 20 筆執行紀錄 |
| AST 快照不可變 | 一旦寫入 executionHistory，快照不可被修改或刪除 |

---

## 12. 持久化策略 (SQLite)

### 12.1 資料庫檔案結構

```
{AppDataFolder}/
└── JET/
    ├── jet_system.db          // 系統設定、專案清單
    └── projects/
        └── {projectId}.db    // 每個專案一個 SQLite 檔案
            ├── staging.*     // 原始匯入資料
            ├── target.*      // 標準化 GL/TB
            ├── result.*      // 篩選結果
            └── config.*      // 篩選情境、科目配對、假日曆
```

### 12.2 篩選情境表 (DDL)

```sql
CREATE TABLE IF NOT EXISTS config_filter_scenarios (
    Id                TEXT PRIMARY KEY,         -- UUID
    Name              TEXT NOT NULL,
    Description       TEXT,
    FilterTreeJson    TEXT NOT NULL,            -- 完整 AST JSON
    AccountPairingJson TEXT,                    -- 科目配對設定 JSON
    Status            TEXT NOT NULL DEFAULT 'draft',  -- 'draft' | 'executed'
    CreatedBy         TEXT,
    CreatedAt         TEXT NOT NULL DEFAULT (datetime('now')),
    ModifiedAt        TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS config_filter_execution_history (
    Id                TEXT PRIMARY KEY,         -- UUID
    ScenarioId        TEXT NOT NULL REFERENCES config_filter_scenarios(Id),
    ExecutedAt        TEXT NOT NULL DEFAULT (datetime('now')),
    ResultCount       INTEGER NOT NULL,
    FilterTreeSnapshot TEXT NOT NULL,           -- 執行時的 AST 快照
    FOREIGN KEY (ScenarioId) REFERENCES config_filter_scenarios(Id) ON DELETE CASCADE
);
```

### 12.3 為什麼用 JSON 欄位而非關聯式表

| 理由 | 說明 |
|:---|:---|
| 遞迴結構天然適合 JSON | 用關聯式表儲存樹需要 CTE 遞迴查詢，複雜且效能差 |
| 讀寫模式是整棵樹 | 操作模式是「整棵樹讀取 → 整棵樹寫入」，不需要 SQL 層級的部分查詢 |
| SQLite JSON 支援 | SQLite 3.38+ 內建 `json()`, `json_extract()`, `json_valid()` 函數 |
| 前端格式直接兼容 | JSON 格式與 react-querybuilder 的輸出直接對應 |

### 12.4 SQL 結果表

進階篩選執行後的結果寫入獨立的結果表：

```sql
CREATE TABLE IF NOT EXISTS result_advanced_filter (
    ScenarioId        TEXT NOT NULL,
    ExecutionId       TEXT NOT NULL,
    GL_RowId          INTEGER NOT NULL,        -- 引用 target_gl 的 rowid
    PRIMARY KEY (ScenarioId, ExecutionId, GL_RowId)
);
```

> **設計**: 結果表只儲存 `rowid` 引用，不複製 GL 資料。查看結果時 JOIN target_gl 即可。

---

## 13. 驗證規則

### 13.1 驗證時機

| 階段 | 驗證者 | 驗證內容 |
|:---|:---|:---|
| 前端 (UI 層) | JavaScript | 基本格式、必填項、運算子相容性 (UX 引導) |
| Bridge 層 | C# BridgeRequest | JSON 格式合法性 |
| Handler 層 | C# FilterCommandHandler | 完整 AST 驗證 (深度、欄位、運算子、值) |
| SQL 生成層 | C# SqlVisitor | 白名單最終檢查 |

> **原則**: 前端驗證是 UX 優化 (非必要)，後端驗證是安全保障 (必要)。即使前端被繞過，後端驗證仍能攔截非法輸入。

### 13.2 AST 驗證規則清單

| 編號 | 規則 | 錯誤碼 | 嚴重性 |
|:---|:---|:---|:---|
| V1 | 巢狀深度 ≤ 6 | `TOO_DEEP` | Error |
| V2 | 群組 children 不可有 null 元素 | `NULL_CHILD` | Error |
| V3 | 群組 children 數量 ≤ 50 | `TOO_MANY_CHILDREN` | Error |
| V4 | Rule 的 field 必須存在於 Field Registry | `UNKNOWN_FIELD` | Error |
| V5 | Rule 的 operator 必須與欄位 DataType 相容 | `INCOMPATIBLE_OPERATOR` | Error |
| V6 | Rule 的 value 型別必須與 DataType 匹配 | `TYPE_MISMATCH` | Error |
| V7 | between 的 min ≤ max | `INVALID_RANGE` | Error |
| V8 | in/notIn 清單不可為空 | `EMPTY_LIST` | Error |
| V9 | in/notIn 清單項數 ≤ 100 | `LIST_TOO_LONG` | Warning |
| V10 | 文字值長度 ≤ 500 | `VALUE_TOO_LONG` | Error |
| V11 | combinator 只接受 "AND" / "OR" | `INVALID_COMBINATOR` | Error |
| V12 | 空群組 (children.length == 0) | `EMPTY_GROUP` | Warning |

### 13.3 驗證回傳格式

```
ValidationResult
├── valid: boolean
└── errors: ValidationError[]
    ├── nodeId: string        // 問題節點的 ID
    ├── errorCode: string     // e.g., "UNKNOWN_FIELD"
    ├── severity: "error" | "warning"
    └── message: string       // 人類可讀訊息 (中文)
```

---

## 14. 安全邊界與限制

### 14.1 SQL Injection 防護 (三重機制)

| 層級 | 防護機制 | 說明 |
|:---|:---|:---|
| 第一層 | **白名單驗證** | 欄位名/運算子必須在預定義集合中 |
| 第二層 | **方括號引用** | 欄位名一律以 `[ColumnName]` 引用，防止保留字衝突 |
| 第三層 | **參數化查詢** | 所有使用者值透過 `SqliteParameter` 傳遞，永不拼接字串 |

### 14.2 系統層級限制

| 限制項目 | 值 | 理由 |
|:---|:---|:---|
| GL 資料量建議上限 | 500 萬筆 / 案件 | SQLite 單檔效能邊界 |
| AST 巢狀深度 | ≤ 6 層 | 防止遞迴爆炸 |
| 單一群組子節點數 | ≤ 50 | 防止過度複雜 |
| SQL 參數數量 | ≤ 999 | SQLite SQLITE_MAX_VARIABLE_NUMBER |
| in/notIn 清單項數 | ≤ 100 | 參數數量管理 |
| 文字值長度 | ≤ 500 字元 | 合理範圍 |
| 篩選情境數 / 專案 | ≤ 100 | 避免無限增長 |
| 執行歷史 / 情境 | ≤ 20 筆 | 只保留最近記錄 |
| 檔案上傳大小 | ≤ 200 MB | .NET 記憶體管理 |

### 14.3 不在此系統範圍內的功能

| 功能 | 不包含的原因 |
|:---|:---|
| 多使用者同時操作 | 本系統為單機桌面應用 |
| 使用者權限管理 | 單機不需要 ACL |
| 即時推播通知 | 桌面應用無此需求 |
| 網路存取 | 無網路端口開放 |
| 自動排程 | Phase 1 不需要 |
| AI/ML 異常偵測 | 超出 Phase 1 範圍 |

---

## 15. 前後端資料流全景

### 15.1 進階篩選完整流程

```
┌──────────────────────────────────────────────────────────┐
│  1. 使用者打開「進階篩選」面板                              │
│     前端發送: { action: "filter.getFields", payload: {} }  │
│                                                          │
│  2. 後端回傳 FieldDefinition[] (含欄位、運算子、值類型)      │
│     前端用此資料初始化 react-querybuilder                   │
│                                                          │
│  3. 使用者在 UI 建構條件樹 (拖拉、選擇、輸入)               │
│     react-querybuilder 維護 JSON AST 狀態                  │
│                                                          │
│  4. 使用者按「預覽」                                       │
│     前端發送: { action: "filter.preview",                  │
│                payload: { filterTree: <AST JSON> } }       │
│                                                          │
│  5. 後端:                                                  │
│     a. 反序列化 JSON → FilterGroup                         │
│     b. 驗證 AST (V1-V12)                                   │
│     c. SqlVisitor 轉換為 WHERE clause + SqliteParameter[]  │
│     d. 執行 SELECT COUNT(*) FROM target_gl WHERE ...        │
│     e. 回傳: { count: 1234 }                               │
│                                                          │
│  6. 使用者看到「1,234 筆符合」→ 決定執行或調整條件            │
│                                                          │
│  7. 使用者按「執行篩選」                                    │
│     前端發送: { action: "filter.execute",                   │
│                payload: { filterTree: <AST JSON>,           │
│                           scenarioId: "...",                │
│                           scenarioName: "Phase 1 期末" } }  │
│                                                          │
│  8. 後端 (Command Handler):                                │
│     a. 驗證 AST                                            │
│     b. 生成 SQL WHERE                                      │
│     c. 執行 INSERT INTO result_advanced_filter              │
│          SELECT rowid FROM target_gl WHERE ...              │
│     d. 儲存 FilterScenario (含 AST 快照)                    │
│     e. 回傳: { success: true, resultCount: 1234 }          │
│                                                          │
│  9. 前端顯示結果統計，使用者可匯出工作底稿                    │
└──────────────────────────────────────────────────────────┘
```

### 15.2 Action-Payload 範例

#### 範例 1: 取得欄位清單

```json
// 請求
{ "action": "filter.getFields", "payload": {} }

// 回應
{
  "success": true,
  "data": [
    {
      "name": "Amount",
      "label": "傳票金額",
      "dataType": "number",
      "category": "gl_core",
      "operators": [
        { "name": "equals", "label": "等於" },
        { "name": "greaterThan", "label": "大於" },
        { "name": "between", "label": "介於" }
      ],
      "valueEditor": "number",
      "dbColumn": "Amount"
    },
    {
      "name": "PRESCR_R1",
      "label": "#1 期末後核准",
      "dataType": "boolean",
      "category": "prescreen_tag",
      "operators": [
        { "name": "equals", "label": "是" }
      ],
      "valueEditor": "select",
      "values": [
        { "name": "true", "label": "符合 (Y)" },
        { "name": "false", "label": "不符合" }
      ],
      "dbColumn": "PRESCR_R1"
    }
  ]
}
```

#### 範例 2: 預覽篩選

```json
// 請求
{
  "action": "filter.preview",
  "payload": {
    "filterTree": {
      "type": "group",
      "id": "root-1",
      "combinator": "AND",
      "children": [
        {
          "type": "rule",
          "id": "rule-1",
          "field": "PRESCR_R1",
          "operator": "equals",
          "value": true
        },
        {
          "type": "group",
          "id": "group-1",
          "combinator": "OR",
          "children": [
            {
              "type": "rule",
              "id": "rule-2",
              "field": "Amount",
              "operator": "greaterThan",
              "value": 100000
            },
            {
              "type": "rule",
              "id": "rule-3",
              "field": "DocumentDescription",
              "operator": "contains",
              "value": "調整"
            }
          ]
        },
        {
          "type": "rule",
          "id": "rule-4",
          "field": "PostDate",
          "operator": "between",
          "value": ["2024-12-01", "2024-12-31"]
        }
      ]
    }
  }
}

// 後端生成的 SQL (內部):
// SELECT COUNT(*) FROM target_gl
// WHERE (
//     [PRESCR_R1] = @p0
//     AND ([Amount] > @p1 OR [DocumentDescription] LIKE @p2)
//     AND [PostDate] BETWEEN @p3 AND @p4
// )
// Parameters: @p0=1, @p1=100000, @p2='%調整%', @p3='2024-12-01', @p4='2024-12-31'

// 回應
{ "success": true, "data": { "count": 1234 } }
```

#### 範例 3: 儲存篩選情境

```json
// 請求
{
  "action": "filter.saveScenario",
  "payload": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "Phase 1 — 期末異常分錄",
    "description": "R1 標記 + 大金額或調整摘要 + 12月",
    "filterTree": { ... },
    "accountPairing": null
  }
}

// 回應
{ "success": true, "data": { "id": "550e8400-e29b-41d4-a716-446655440000" } }
```

---

## 附錄 A：完整型別定義 (TypeScript 語義)

此型別定義用於前端 (HTML/JS) 與 JSON 序列化格式的參考。

```typescript
// ===== 核心 AST 節點 =====

type FilterNode = FilterRule | FilterGroup;

interface FilterRule {
  type: 'rule';
  id: string;
  field: string;
  operator: string;
  value: RuleValue;
}

interface FilterGroup {
  type: 'group';
  id: string;
  combinator: 'AND' | 'OR';
  not?: boolean;
  children: FilterNode[];
}

type RuleValue =
  | string
  | number
  | boolean
  | null                  // for isEmpty / isNotEmpty
  | string[]              // for in / notIn
  | [number, number]      // for between (number)
  | [string, string];     // for between (date)

// ===== 欄位定義 =====

type DataType = 'string' | 'number' | 'date' | 'boolean';

type FieldCategory =
  | 'gl_core'
  | 'gl_derived'
  | 'gl_metadata'
  | 'date_field'
  | 'prescreen_tag'
  | 'date_flag'
  | 'custom';

interface FieldDefinition {
  name: string;
  label: string;
  dataType: DataType;
  category: FieldCategory;
  operators: OperatorDef[];
  valueEditor: 'text' | 'number' | 'date' | 'select' | 'multiselect';
  values?: SelectOption[];
  dbColumn: string;
}

interface OperatorDef {
  name: string;
  label: string;
}

interface SelectOption {
  name: string;
  label: string;
}

// ===== 篩選情境 =====

interface FilterScenario {
  id: string;
  name: string;
  description?: string;
  projectId: string;
  createdBy: string;
  createdAt: string;       // ISO 8601
  modifiedAt: string;
  rootGroup: FilterGroup;
  accountPairing?: AccountPairing;
  status: 'draft' | 'executed';
}

interface AccountPairing {
  mode: 'typeA' | 'typeB' | 'typeC';
  debitCategories: string[];
  creditCategories: string[];
}

// ===== 驗證 =====

interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

interface ValidationError {
  nodeId: string;
  errorCode: string;
  severity: 'error' | 'warning';
  message: string;
}

// ===== Bridge 通訊 =====

interface BridgeRequest {
  action: string;
  payload: unknown;
}

interface BridgeResponse {
  success: boolean;
  data?: unknown;
  error?: string;
}
```

---

## 附錄 B：完整型別定義 (C# 語義)

此型別定義用於 .NET Service Layer 的實作參考。

```csharp
// ===== 核心 AST 節點 =====

using System.Text.Json.Serialization;

[JsonDerivedType(typeof(FilterRule), "rule")]
[JsonDerivedType(typeof(FilterGroup), "group")]
public abstract record FilterNode(string Type, string Id);

public record FilterRule(
    string Id,
    string Field,
    string Operator,
    JsonElement Value   // 使用 JsonElement 延遲解析，支援多種值型別
) : FilterNode("rule", Id);

public record FilterGroup(
    string Id,
    string Combinator,          // "AND" | "OR"
    List<FilterNode> Children,
    bool Not = false
) : FilterNode("group", Id);

// ===== 欄位定義 =====

public enum DataType { String, Number, Date, Boolean }

public enum FieldCategory
{
    GlCore, GlDerived, GlMetadata,
    DateField, PrescreenTag, DateFlag, Custom
}

public record FieldDefinition(
    string Name,
    string Label,
    DataType DataType,
    FieldCategory Category,
    List<OperatorDef> Operators,
    string ValueEditor,
    string DbColumn,
    List<SelectOption>? Values = null
);

public record OperatorDef(string Name, string Label);
public record SelectOption(string Name, string Label);

// ===== 篩選情境 =====

public record FilterScenario
{
    public required string Id { get; init; }
    public required string Name { get; init; }
    public string? Description { get; init; }
    public required string ProjectId { get; init; }
    public required FilterGroup RootGroup { get; init; }
    public AccountPairing? AccountPairing { get; init; }
    public string Status { get; init; } = "draft";
    public string? CreatedBy { get; init; }
    public DateTime CreatedAt { get; init; } = DateTime.UtcNow;
    public DateTime ModifiedAt { get; init; } = DateTime.UtcNow;
}

public record AccountPairing(
    string Mode,                    // "typeA" | "typeB" | "typeC"
    List<string> DebitCategories,
    List<string> CreditCategories
);

// ===== CQRS 介面 =====

public interface ICommand { }
public interface IQuery { }

public interface ICommandHandler<in TCommand, TResult> where TCommand : ICommand
{
    Task<TResult> HandleAsync(TCommand command);
}

public interface IQueryHandler<in TQuery, TResult> where TQuery : IQuery
{
    Task<TResult> HandleAsync(TQuery query);
}

// ===== CQRS DTOs =====

// Commands
public record ExecuteFilterCommand(FilterGroup FilterTree, string ScenarioId) : ICommand;
public record SaveScenarioCommand(FilterScenario Scenario) : ICommand;
public record DeleteScenarioCommand(string ScenarioId) : ICommand;

// Queries
public record GetFieldsQuery() : IQuery;
public record PreviewFilterQuery(FilterGroup FilterTree) : IQuery;
public record LoadScenarioQuery(string ScenarioId) : IQuery;
public record ListScenariosQuery() : IQuery;

// Results
public record CommandResult(bool Success, string? Message = null);
public record PreviewResult(int Count);

// ===== 驗證 =====

public record ValidationResult(bool Valid, List<ValidationError> Errors);

public record ValidationError(
    string NodeId,
    string ErrorCode,
    string Severity,    // "error" | "warning"
    string Message
);

// ===== Bridge 通訊 =====

public record BridgeRequest(string Action, JsonElement Payload);
public record BridgeResponse(bool Success, object? Data = null, string? Error = null);

// ===== Action Dispatcher =====

public interface IActionDispatcher
{
    Task<BridgeResponse> DispatchAsync(string action, JsonElement payload);
}
```

---

## 附錄 C：SQL 生成範例

### 範例 1: 簡單 AND 條件

**AST:**
```json
{
  "type": "group", "combinator": "AND",
  "children": [
    { "type": "rule", "field": "Amount", "operator": "greaterThan", "value": 100000 },
    { "type": "rule", "field": "PRESCR_R1", "operator": "equals", "value": true }
  ]
}
```

**生成 SQL:**
```sql
([Amount] > @p0 AND [PRESCR_R1] = @p1)
-- @p0 = 100000, @p1 = 1
```

### 範例 2: 巢狀 AND + OR

**AST:**
```json
{
  "type": "group", "combinator": "AND",
  "children": [
    { "type": "rule", "field": "PRESCR_R1", "operator": "equals", "value": true },
    {
      "type": "group", "combinator": "OR",
      "children": [
        { "type": "rule", "field": "Amount", "operator": "greaterThan", "value": 100000 },
        { "type": "rule", "field": "DocumentDescription", "operator": "contains", "value": "調整" }
      ]
    }
  ]
}
```

**生成 SQL:**
```sql
([PRESCR_R1] = @p0 AND ([Amount] > @p1 OR [DocumentDescription] LIKE @p2))
-- @p0 = 1, @p1 = 100000, @p2 = '%調整%'
```

### 範例 3: BETWEEN + IN

**AST:**
```json
{
  "type": "group", "combinator": "AND",
  "children": [
    { "type": "rule", "field": "PostDate", "operator": "between", "value": ["2024-12-01", "2024-12-31"] },
    { "type": "rule", "field": "SourceModule", "operator": "in", "value": ["AP", "AR", "GL"] }
  ]
}
```

**生成 SQL:**
```sql
([PostDate] BETWEEN @p0 AND @p1 AND [SourceModule] IN (@p2, @p3, @p4))
-- @p0 = '2024-12-01', @p1 = '2024-12-31', @p2 = 'AP', @p3 = 'AR', @p4 = 'GL'
```

### 範例 4: NOT 群組

**AST:**
```json
{
  "type": "group", "combinator": "AND",
  "children": [
    { "type": "rule", "field": "Amount", "operator": "greaterThan", "value": 50000 },
    {
      "type": "group", "combinator": "OR", "not": true,
      "children": [
        { "type": "rule", "field": "SourceModule", "operator": "equals", "value": "AP" },
        { "type": "rule", "field": "SourceModule", "operator": "equals", "value": "AR" }
      ]
    }
  ]
}
```

**生成 SQL:**
```sql
([Amount] > @p0 AND NOT ([SourceModule] = @p1 OR [SourceModule] = @p2))
-- @p0 = 50000, @p1 = 'AP', @p2 = 'AR'
```

### 範例 5: 空群組 (無條件)

**AST:**
```json
{ "type": "group", "combinator": "AND", "children": [] }
```

**生成 SQL:**
```sql
1=1
-- (無參數)
```

---

> **文件結束**
>
> 本文件為 JET 進階篩選系統的完備開發規格。實作時應同時參考：
> - [`jet-domain-model.md`](jet-domain-model.md) — 業務邏輯與審計規則
> - [`architecture.md`](architecture.md) — 系統架構全景
> - [`technical_guide.md`](technical_guide.md) — 開發環境與編碼規範
