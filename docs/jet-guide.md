# JET 開發指南 (Journal Entry Testing — Single Source of Truth)

本文件為 JET 新系統的**唯一深度參考**。涵蓋業務領域、規則規格、系統架構、資料策略、AI 協作方式與遷移計畫。

> **讀這份文件，不需要讀 `legacy/ideascript.bas` 的 11,000 行原始碼。**
> 如果你發現本文件有歧義或缺口，修本文件，不要去翻 VBA。

---

## 目錄

- [A. 業務與領域](#a-業務與領域)
  - [1. JET 是什麼](#1-jet-是什麼)
  - [2. 核心資料實體](#2-核心資料實體)
  - [3. 審計工作流程](#3-審計工作流程)
  - [4. 資料驗證規則 (V1-V4)](#4-資料驗證規則-v1-v4)
  - [5. 預篩選規則聲明式規格 (R1-R8 + A2-A4)](#5-預篩選規則聲明式規格-r1-r8--a2-a4)
  - [6. 進階篩選邏輯](#6-進階篩選邏輯)
  - [7. 審計工作底稿](#7-審計工作底稿)
  - [8. 台灣在地化](#8-台灣在地化)
- [B. 技術決策](#b-技術決策)
  - [9. 棄用 IDEA 與 VBA 的背景](#9-棄用-idea-與-vba-的背景)
  - [10. 為什麼選 .NET 10 + WinForms + WebView2 + HTML](#10-為什麼選-net-10--winforms--webview2--html)
- [C. 系統架構](#c-系統架構)
  - [11. 架構總覽](#11-架構總覽)
  - [12. 層級職責](#12-層級職責)
  - [13. SQLite / SQL Server 雙 Provider 策略](#13-sqlite--sql-server-雙-provider-策略)
  - [14. 專案結構規劃](#14-專案結構規劃)
  - [15. 命名與分層原則](#15-命名與分層原則)
- [D. 開發與協作](#d-開發與協作)
  - [16. AI-agent 開發工作流](#16-ai-agent-開發工作流)
  - [17. 從 ideascript.bas 遷移的做法](#17-從-ideascriptbas-遷移的做法)
  - [18. 欄位對照表](#18-欄位對照表)
  - [19. 術語對照](#19-術語對照)

---

# A. 業務與領域

## 1. JET 是什麼

**日記帳分錄測試 (Journal Entry Testing, JET)** 是依 ISA 240 / ISA 330 執行的**實質性審計程序**，用以因應「**管理階層凌駕控制 (Management Override of Controls)**」風險。

實務上，JET 針對一個會計期間內的**全部日記帳分錄**，依風險導向條件進行**全母體篩選**，辨識高風險或異常的分錄，供審計人員後續調查。

**管理階層可能透過以下方式操縱財報**：
- 記錄虛構或不當分錄（特別是期末結帳前後）
- 不當的估計調整
- 隱匿或延遲認列

JET 的工作 = **把「有風險的分錄」從幾十萬筆分錄中篩出來**。

---

## 1.5 資料量規模與處理原則 (Non-Negotiable)

JET 的所有設計決策都受**母體規模**驅動。違反本節原則的程式碼，無論寫得多漂亮，在真實案件上都會崩潰，必須拒絕合入。

### 1.5.1 規模假設

| 維度 | 典型 | 上界 (必須能跑) |
|:---|:---|:---|
| GL rows | 約 **1,000 萬** 以下的 local persistent case | **10 億** rows 的 large-data / cloud case 設計上限 |
| TB accounts | 約 **1,000** | **1 萬** |
| AccountMapping rows | 數百 ～ 數千 | 1 萬 |
| SQLite path | 小於 1,000 萬 GL rows 的本機持久案件 | 不作為 10 億 row 執行引擎 |
| SQL Server path | 大於 1,000 萬 GL rows 或 cloud / shared data case | 10 億 row 等級的 set-based execution target |
| Workpaper Excel 大小 | 數 MB ～ 數百 MB | 需以 streaming writer 控制記憶體 |

ISA 240 要求對**全母體**執行 JET，不允許抽樣替代規則篩選；因此 V1-V4 / R1-R8 / A2-A4 / 自訂 filter 都必須以**全母體**為計算基底。

### 1.5.2 唯一允許的計算位置：DB 引擎 (Set-Based Pushdown)

**禁止**在 Application 層 (C# / LINQ) 對 GL/TB row 集合執行 V/R/Filter 規則。所有規則都必須以 SQL 表達，由 SQLite / SQL Server 引擎以 set-based 方式執行。

理由：
1. **記憶體**：1,000 萬 GL rows × 12 欄 × 平均 50 byte 已是數 GB 等級；C# Dictionary 額外 overhead 再 ×2~3。Application 程序會 OOM。10 億 row 等級只能交給資料庫引擎與分頁/匯出管線處理。
2. **效能**：DB 引擎的 hash join、index scan、parallel aggregation 比手寫 LINQ 快 1-3 個數量級。
3. **可重現**：SQL 規則可以單獨在 DB tool 中重跑驗證，C# LINQ 規則無法。

**正確形狀**（對應 §13 設計）：

```csharp
public interface IGlRepository
{
    Task<RuleResult> RunValidationAsync(ProjectId id, ValidationKind kind, CancellationToken ct);
    Task<RuleResult> RunPrescreenAsync(ProjectId id, RuleSpec rule, CancellationToken ct);
    Task<FilterResult> RunFilterAsync(ProjectId id, ScenarioSpec scenario, CancellationToken ct);
}
```

Repository 內部生成 SQL，例如 V2 借貸不平：

```sql
SELECT doc_num, SUM(amount) AS net
FROM target_gl_entry
WHERE project_id = @projectId
GROUP BY doc_num
HAVING ABS(SUM(amount)) > 0;
```

**反例**（目前 `RunValidationQueryHandler.cs` 的寫法）：

```csharp
var v2NullDocNums = gl.Count(r => string.IsNullOrWhiteSpace(GetGlVal(r, "docNum", mapping)));
// 整個 gl 已經被 InMemoryProjectSessionStore 載入記憶體 → 規模禁忌
```

### 1.5.3 Bridge 不得搬運完整 row 集合

WebView2 ↔ .NET 的 `postMessage` 通道是 JSON-over-string；對 100 萬 row × 數十欄做 `JSON.stringify` 會：

- 在 JS 端 OOM
- 序列化耗時 10+ 秒、阻塞 UI thread
- 反序列化在 .NET 端再耗一次

**規則**：

| 動作 | Prototype 契約 (現況) | 規模化目標契約 (Phase 3+) |
|:---|:---|:---|
| `import.gl` / `import.tb` | `{ fileName, rows, columns }` | `{ filePath, mode, columnMap }` — handler 透過 `IGlFileReader` streaming 直入 DB |
| `validate.run` | 回完整 `diffAccounts` / row counts | 回 summary 數字 + `resultRef` token；明細透過 `query.validationDetailsPage` 分頁拉 |
| `prescreen.run` | 回 r1..r6 完整 row lists | 回每條規則的命中數 + `resultRef`；明細走 `query.prescreenPage` |
| `filter.preview` | 回完整 `resultRows` | 回 count + voucherCount + 前 N 筆 preview + `resultRef` |
| `query.glPage` (新) | — | `{ projectId, cursor, pageSize }` → keyset paging |

**Legacy demo fallback**：示範資料約 2200 GL row，是 deprecated row-based 契約唯一可能存活的情境；正式 demo/test path 仍必須走 file-based streaming import（demo 不應被特別對待，否則違反「demo == upload pipeline」原則）。

### 1.5.4 Excel Workpaper 採 Streaming Writer

`export.workpaper` 預期輸出多工作表、合計可達數百 MB（明細層）。實作必須走 **OpenXML SAX writer**（例如 `DocumentFormat.OpenXml` `OpenXmlWriter`）或 `ClosedXML` 的 streaming API，禁止把整份 result set 載入 `DataTable` / List 後再寫。

### 1.5.5 InMemoryProjectSessionStore 的退場路徑

目前 `InMemoryProjectSessionStore` 是 prototype 過渡品。Phase 3 結束時，它必須只保留**輕量 session pointer**（current projectId、current mappings、UI 篩選暫態），不再持有 GL/TB rows。GL/TB raw rows 一律落地 `staging_*`，標準化後的資料落地 `target_*`，規則結果落地 `result_*`。

### 1.5.6 自我檢查清單

每次新增/修改 handler 時自問：

1. 我有沒有把任何 GL/TB row 集合載入 `List<>` / `Dictionary<>` 然後跑 LINQ？
2. 我有沒有讓 bridge payload 或 response 攜帶超過 1000 row 的明細？
3. 我有沒有建立 in-memory cache 取代 DB 查詢？
4. 我寫的 SQL 在 1,000 萬筆本機 GL 與更大型 SQL Server case 上有合理執行形狀嗎？（有沒有用 index、有沒有避免 SELECT *、有沒有 keyset 分頁？）
5. 我的 Excel 寫入是 streaming 的嗎？

任何一題答 "是 / 否（不安全）" → 設計需要重做。

---

## 2. 核心資料實體

JET 全系統只操作 **5 個核心實體**：GL、TB、AccountMapping、DateDimension、RuleResult。

### 2.1 總帳分錄 (GL — General Ledger)

每筆 = 一張傳票中的一個分錄行。JET 的**主要分析對象**。

#### 必要欄位

| 標準欄位 | 型別 | 必填 | 說明 |
|:---|:---|:---|:---|
| `DocumentNumber` | string | ✅ | 傳票號碼 |
| `LineItem` | string |  | 同傳票內的分錄序號 |
| `Amount` | decimal | ✅ | 分錄金額 (正借負貸，或依金額模式) |
| `AccountCode` | string | ✅ | 會計科目編號 |
| `AccountName` | string |  | 會計科目名稱 |
| `DocumentDescription` | string |  | 傳票摘要 |
| `ApprovalDate` | date |  | 傳票核准日 (R1、R7、R8 必要) |
| `PostDate` | date |  | 總帳日期 |
| `CreatedBy` | string |  | 編製人 (R5 必要) |
| `ApprovedBy` | string |  | 核准人 |
| `SourceModule` | string |  | 來源子系統 (AP、AR、GL…) |
| `IsManual` | bool |  | 是否人工傳票 |

#### 衍生欄位 (匯入後計算)

| 欄位 | 計算 | 用途 |
|:---|:---|:---|
| `DebitAmount` | `Amount >= 0 ? Amount : 0` | R5/R6 彙總 |
| `CreditAmount` | `Amount < 0 ? Amount : 0` | R5/R6 彙總 |
| `DrCr` | `Amount >= 0 ? "DEBIT" : "CREDIT"` | 借貸方向 |

#### 金額模式 (四選一)

不同 ERP 記錄金額的方式不同，匯入時由使用者指定：

| 模式 | 來源欄位 | 轉換為標準 `Amount` 的規則 |
|:---|:---|:---|
| `SignedAmount` | 單一金額欄 | 直接使用 (正=借、負=貸) |
| `AmountWithSide` | 絕對值 + 借貸別欄 | 借貸別 = "D" 取正，"C" 取負 |
| `AmountWithFlag` | 絕對值 + 借方標誌 (0/1) | flag=1 取正，flag=0 取負 |
| `DualAmount` | 借方金額 + 貸方金額 | `Amount = Debit - Credit` |

### 2.2 試算表 (TB — Trial Balance)

各科目在會計期間的餘額彙總。用於**完整性比對 (V1 Completeness Test)**。

| 標準欄位 | 型別 | 說明 |
|:---|:---|:---|
| `AccountCode` | string | 科目代號 |
| `AccountName` | string | 科目名稱 |
| `ChangeAmount` | decimal | 期間淨變動額 |
| `OpeningBalance` / `ClosingBalance` | decimal | 期初 / 期末 |
| `OpeningDebitBalance` / `OpeningCreditBalance` | decimal | 期初借 / 期初貸 |
| `ClosingDebitBalance` / `ClosingCreditBalance` | decimal | 期末借 / 期末貸 |
| `DebitAmount` / `CreditAmount` | decimal | 本期借方 / 貸方合計 |

#### TB 變動金額計算模式 (匯入時決定)

| 模式 | 可用欄位 | `ChangeAmount` 計算 |
|:---|:---|:---|
| `DirectChange` | 變動金額 | 直接採用 |
| `OpenClose` | 期初 + 期末 | `Closing - Opening` |
| `DebitCredit` | 借方 + 貸方 | `Debit - Credit` |
| `OpenCloseBySide` | 期初借貸 + 期末借貸 | `(ClosingDr - ClosingCr) - (OpeningDr - OpeningCr)` |

### 2.3 科目配對表 (AccountMapping)

將企業科目對應至**標準化分類**，用於 R3。

| 欄位 | 說明 |
|:---|:---|
| `AccountCode` | GL 科目代號 |
| `AccountName` | 科目名稱 |
| `StandardizedCategory` | `Revenue` / `Receivables` / `Cash` / `Receipt in advance` / `Others` |

### 2.4 日期維度 (DateDimension)

審計期間每一天的屬性表，用於 R7、R8。

| 欄位 | 說明 |
|:---|:---|
| `DateKey` | YYYYMMDD |
| `FullDate` | 日期 |
| `DayOfWeek` | 1=日 … 7=六 |
| `IsWeekend` | 系統自動 (Sat / Sun) |
| `IsHoliday` | 由使用者上傳的假日曆覆寫 |
| `IsMakeupDay` | 補班日 (假日曆的例外) |
| `HolidayDesc` / `MakeupDayDesc` | 說明 |

### 2.5 規則結果 (RuleResult)

每條規則執行後的**標記 + 狀態**。

| 欄位 | 型別 | 說明 |
|:---|:---|:---|
| `RuleId` | string | `R1` … `R8` / `A2` … `A4` |
| `DocumentNumber` | string | 被標記的傳票 |
| `LineItem` | string | 被標記的分錄行 (可為空，表示整張傳票) |
| `Status` | enum | `V` (有結果) / `N/A` (無結果或未執行) |
| `TagColumn` | string | 結果標記欄名 (例 `PRESCR_R1`) |

---

## 3. 審計工作流程

```
Step 1  資料匯入與驗證   →  GL/TB → 標準化 → V1-V4 驗證
Step 2  輔助檔案設定     →  AccountMapping / Holiday / MakeupDay → DateDimension
Step 3  預篩選           →  R1-R8 + A2-A4 (全母體打標)
Step 4  進階篩選         →  組合 tag + 自訂條件 → 最終測試母體
Step 5  工作底稿產出     →  Excel 多工作表
```

每個步驟的輸入 / 處理 / 產出已併入各節說明。

### 3.1 匯入格式與案件設定

目前正式匯入格式只支援 `.xlsx` 與 `.csv`。若未來新增格式，必須先更新本文件與 `docs/action-contract-manifest.md`，再補 reader/handler。

Case config 必須能重新載入案件參數，至少保存：

- case metadata（客戶、期間、操作者、產業、報表準備基準日）
- field mapping（原始欄位到標準欄位）
- account pairing / classification settings（科目配對與分類設定）
- saved query / filter scenarios（已保存查詢與篩選情境）
- reloadable case parameters（validation / prescreen / export 可重跑所需參數）

---

## 4. 資料驗證規則 (V1-V4)

執行於 Step 1，用以確認母體完整且可信。

### V1 完整性測試 (Completeness Test)

| 項目 | 內容 |
|:---|:---|
| **目的** | GL 按科目加總應等於 TB 期間變動額；不等則代表 GL 母體不完整 |
| **邏輯** | `FULL OUTER JOIN` GL_Sum_ByAccount × TB ON AccountCode；差異 = TB.ChangeAmount − GL.AmountSum |
| **異常條件** | `ABS(差異) > 0` |
| **產出** | 差異科目清單 (科目 / TB 金額 / GL 金額 / 差異) |

### V2 借貸平衡測試 (Document Balance Test)

| 項目 | 內容 |
|:---|:---|
| **目的** | 每張傳票借貸應平衡；不平衡可能為資料品質問題 |
| **邏輯** | 按 `DocumentNumber` 加總 `Amount`，篩 `SUM ≠ 0` 的傳票，取出完整明細 |
| **產出** | 不平衡傳票 + 其所有分錄 |

### V3 INF 抽樣測試 (Information Produced by the Entity)

| 項目 | 內容 |
|:---|:---|
| **目的** | 隨機抽樣供人工驗證非財務欄位 (摘要、日期、科目名等) 可靠性 |
| **邏輯** | 以審計期間的 GL 為母體，隨機抽 N 筆 (預設 60，可設定) |
| **產出** | 抽樣明細 |

### V4 空值紀錄測試 (Null Records Test)

| 項目 | 內容 |
|:---|:---|
| **目的** | 找出關鍵欄位為空的分錄 |
| **邏輯** | 分別篩 `AccountCode IS NULL` / `DocumentNumber IS NULL` / `DocumentDescription IS NULL` |
| **產出** | 三類空值清單與計數 |

---

## 5. 預篩選規則聲明式規格 (R1-R8 + A2-A4)

**每條規則以下列欄位描述**。實作 (Command Handler / Repository Query / SQL) 必須能從這份規格直接生成，無需讀 `ideascript.bas`。

規格欄位解釋：
- **Name**：規則名稱 (中文)
- **Rationale**：風險意義 (為何這是風險指標)
- **Preconditions**：執行前必須滿足的條件，未滿足則 `Status = N/A`
- **Input**：資料來源
- **Predicate / Aggregation**：核心邏輯 (以 SQL-ish 偽碼表示)
- **Output**：回傳結果形式 (tag / 彙總)
- **TagColumn**：標記欄名 (用於 `SUM_BY_DOC` 的 join)
- **N/A When**：明確為 N/A 的條件
- **Work Paper Sheet**：匯出工作底稿的分頁名

### R1 — 期末財報準備日後核准之分錄

| | |
|:---|:---|
| Name | 於期末財務報表準備日後核准之分錄 |
| Rationale | 期末後才核准的分錄可能是操縱期末數字 |
| Preconditions | GL 含 `ApprovalDate`；專案設定 `LastAccountingPeriodDate` |
| Input | GL |
| Predicate | `WHERE ApprovalDate >= LastAccountingPeriodDate` |
| Output | Tag |
| TagColumn | `PRESCR_R1` |
| N/A When | 無 `ApprovalDate` 欄位 OR 0 筆符合 |
| WP Sheet | `R1` |

### R2 — 分錄摘要出現特定描述

| | |
|:---|:---|
| Name | 分錄摘要出現特定描述 |
| Rationale | 摘要含調整 / 沖銷 / 錯誤等關鍵字可能是異常 |
| Preconditions | GL 含 `DocumentDescription` |
| Input | GL |
| Predicate | `WHERE REGEX_MATCH(UPPER(TRIM(DocumentDescription)), KEYWORDS)` |
| Keywords | 見 [附錄：R2 預設關鍵字](#附錄-r2-預設關鍵字) |
| Output | Tag |
| TagColumn | `PRESCR_R2` |
| Mutex | 與 `A2` 互斥 |
| WP Sheet | `R2` |

### R3 — 未預期出現之特定借貸組合

| | |
|:---|:---|
| Name | 未預期出現之特定借貸組合 |
| Rationale | 「Revenue 貸方 + Receivables/Cash/Receipt in advance 借方」為虛假收入最常見模式 |
| Preconditions | AccountMapping 已上傳且包含 Revenue 與至少一個 (Receivables / Cash / Receipt in advance) 類 |
| Input | GL ⨝ AccountMapping |
| Predicate | **Step 1**：子集 CreditSet = `WHERE Category = 'Revenue' AND Amount < 0`<br>**Step 2**：子集 DebitSet = `WHERE Category IN ('Receivables','Cash','Receipt in advance') AND Amount > 0`<br>**Step 3**：同一 `DocumentNumber` 同時出現在 CreditSet 與 DebitSet |
| Output | Tag (標記在符合的那些分錄行上) |
| TagColumn | `PRESCR_R3` |
| Mutex | 與 `A3` 互斥 |
| WP Sheet | `R3` |

### R4 — 分錄金額中有連續零的尾數

| | |
|:---|:---|
| Name | 分錄金額中有連續零的尾數 |
| Rationale | 整數金額 (如 10,000、1,000,000) 可能為估計或人為捏造 |
| Preconditions | 無 |
| Input | GL |
| Predicate | **Step 1**：`N = LEN(AVG(DebitAmount) 去小數位後的整數部分)`<br>**Step 2**：`WHERE RIGHT(FLOOR(ABS(Amount)), N-1) = REPEAT('0', N-1)` |
| Output | Tag |
| TagColumn | `PRESCR_R4` |
| Override | `A4` 可指定固定 N 取代動態計算 |
| WP Sheet | `R4` |

### R5 — 依分錄編製者彙總

| | |
|:---|:---|
| Name | 依分錄編製者彙總分錄 |
| Rationale | 分錄集中於少數人員可能代表職能分離不足 |
| Preconditions | GL 含 `CreatedBy` |
| Input | GL |
| Aggregation | `GROUP BY CreatedBy` (若有 `IsManual` 則 `GROUP BY CreatedBy, IsManual`)<br>`SELECT SUM(DebitAmount), SUM(CreditAmount), COUNT(*)` |
| Output | 彙總表 (非 tag) — 供審計人員判讀 |
| WP Sheet | `R5` |

### R6 — 較少使用之科目

| | |
|:---|:---|
| Name | 較少使用之科目 |
| Rationale | 低頻率使用的科目可能被用來隱藏不當分錄 |
| Preconditions | 無 |
| Input | GL |
| Aggregation | `GROUP BY AccountCode, AccountName`；`SELECT COUNT(*), SUM(DebitAmount), SUM(CreditAmount)`；`ORDER BY COUNT(*) ASC` |
| Output | 彙總表 (非 tag) |
| WP Sheet | `R6` |

### R7 — 週末過帳 / 核准之分錄

| | |
|:---|:---|
| Name | 於週末過帳或核准的分錄 |
| Rationale | 正常企業運作不應週末處理傳票 |
| Preconditions | GL 含 `ApprovalDate` 或 `PostDate` |
| Input | GL ⨝ DateDimension |
| Predicate | `WHERE DateDimension.IsWeekend = TRUE AND DateDimension.IsMakeupDay = FALSE` (台灣：補班日排除) |
| Output | Tag (兩個欄位) |
| TagColumn | `DOC_WEEKEND_JE_T` (核准日週末) / `POST_WEEKEND_JE_T` (總帳日週末) |
| WP Sheet | `R7` |

### R8 — 假日過帳 / 核准之分錄

| | |
|:---|:---|
| Name | 於國定假日過帳或核准的分錄 |
| Rationale | 假日不應處理傳票；含彈性假日 |
| Preconditions | 使用者已上傳假日曆；GL 含 `ApprovalDate` 或 `PostDate` |
| Input | GL ⨝ DateDimension |
| Predicate | `WHERE DateDimension.IsHoliday = TRUE` |
| Output | Tag + 假日名稱 |
| TagColumn | `DOC_HOLIDAY_NAME_JE_T` / `IS_HOLIDAY_DOC_JE_T` / `POST_HOLIDAY_NAME_JE_T` / `IS_HOLIDAY_POST_JE_T` |
| WP Sheet | `R8` |

### A2 — 自訂關鍵字

| | |
|:---|:---|
| Purpose | 補充 R2 的預設關鍵字 |
| Input | 使用者輸入 (逗號分隔) |
| Predicate | 同 R2 但關鍵字為使用者輸入 |
| TagColumn | `PRESCR_A2` |
| Mutex | 與 R2 互斥 |

### A3 — 自訂科目配對

| | |
|:---|:---|
| Purpose | 補充 R3 的預設配對 |
| Input | 使用者定義的借方分類 + 貸方分類 |
| Predicate | 同 R3 但兩側分類為使用者輸入 |
| TagColumn | `PRESCR_A3` |
| Mutex | 與 R3 互斥 |

### A4 — 自訂尾數位數

| | |
|:---|:---|
| Purpose | 指定固定 N 取代 R4 的動態計算 |
| Input | 使用者輸入的位數 (僅接受整數) |
| Predicate | 同 R4 但 N 為使用者輸入 |
| TagColumn | `PRESCR_A4` |

### 規則互斥表

| 對 | 說明 |
|:---|:---|
| R2 ↔ A2 | 預設關鍵字與自訂關鍵字擇一 |
| R3 ↔ A3 | 預設配對與自訂配對擇一 |

### 結果狀態碼

| Status | 意義 |
|:---|:---|
| `V` | 已執行且有結果 |
| `N/A` | 未執行 (缺欄位/設定檔) 或已執行但 0 筆命中 |

### 附錄 R2 預設關鍵字

| 關鍵字 | 語言 | 審計意義 |
|:---|:---|:---|
| ADJ | EN | Adjustment |
| REV | EN | Reversal |
| RECLASS | EN | Reclassification |
| SUSPENSE | EN | Suspense |
| ERROR | EN | Error |
| WRONG | EN | Wrong |
| 調整 | ZH | 調整分錄 |
| 迴轉 | ZH | 迴轉分錄 |
| 沖銷 | ZH | 沖銷分錄 |
| 重分類 | ZH | 科目重分類 |
| 避險 | ZH | 避險交易 |
| 重編 | ZH | 重新編製 |
| 錯誤 | ZH | 錯誤更正 |
| 計畫外 | ZH | 計畫外的調整 |
| 預算外 | ZH | 超出預算的調整 |

比對方式：`REGEX_MATCH(UPPER(TRIM(DocumentDescription)), '<關鍵字 1>|<關鍵字 2>|…')`

---

## 6. 進階篩選邏輯

Step 4。審計人員在預篩選結果上組合條件，得出**最終測試母體**。

### 6.1 科目配對分析 (三種模式)

| Type | 邏輯 | 使用時機 |
|:---|:---|:---|
| **A 精確** | 同一傳票同時有「指定借方分類 + Amount ≥ 0」與「指定貸方分類 + Amount < 0」的分錄 → 兩類分錄行都輸出 | 已知可疑的借+貸組合 |
| **B 借方錨定** | 先找出含「指定借方分類 + Amount ≥ 0」的傳票 → 輸出借方分錄 + 同傳票所有貸方分錄 (Amount < 0) | 已知可疑的借方，想看對方科目 |
| **C 貸方錨定** | 先找出含「指定貸方分類 + Amount < 0」的傳票 → 輸出貸方分錄 + 同傳票所有借方分錄 (Amount ≥ 0) | 已知可疑的貸方，想看對方科目 |

### 6.2 可疊加的自訂條件

| 條件 | 範例 |
|:---|:---|
| 預篩選標記組合 | `R1 AND R3` / `R2 OR R4` |
| 日期區間 | `PostDate BETWEEN … AND …`，最多 2 組 |
| 金額區間 | `ABS(Amount) BETWEEN … AND …` |
| 文字比對 | 任一欄位 `LIKE …`，最多 2 組 |
| 借 / 貸限定 | `DrCr = 'DEBIT'` 或 `'CREDIT'` |
| 人工 / 自動 | `IsManual = TRUE/FALSE` |
| 期內 / 期外 | `PostDate` 在 / 不在會計期間 |

---

## 7. 審計工作底稿

Step 5 匯出 Excel 檔案，包含以下工作表：

| Sheet | 內容 |
|:---|:---|
| `Engagement Overview` | 客戶、期間、財報準備起始日、編製人與編製日 |
| `Data Overview` | GL 筆數/借方/貸方/淨額、TB 科目數 |
| `Validation Overview` | V1-V4 異常計數 |
| `Completeness Detail` | V1 差異明細 |
| `Document Balance Detail` | V2 不平衡傳票 |
| `INF Sample Detail` | V3 抽樣明細 |
| `R1`…`R8` / `A2`…`A4` | 各規則底稿 (Status = V 才有資料) |
| `Account Mapping Info` | 使用的科目配對表 |
| `Field Mapping Info` | 原始欄位 → 標準欄位對應 |

### 7.1 欄位名稱與可追溯性

審計員最終底稿應在需要追溯來源資料時顯示**原始資料欄位名稱**。標準化欄位主要用於內部查詢、完整性測試、預篩選規則、進階篩選與 provider-independent execution。`Field Mapping Info` 必須清楚連結原始欄位與標準欄位，避免底稿只剩內部欄位名稱而難以回查客戶資料。

---

## 8. 台灣在地化

### 8.1 彈性假日與補班日

- **彈性假日**：國定假日遇週二/週四時，前/後的週一或週五放假
- **補班日**：因彈性假日而改為上班的週六

實作：
- R7 (週末) 必須排除 `IsMakeupDay = TRUE` 的日期 (補班週六實為工作日)
- R8 (假日) 必須納入 `IsHoliday = TRUE` 的工作日 (彈性放假的平日)

### 8.2 中文摘要關鍵字

R2 預設關鍵字清單已含台灣審計常見中文字彙 — 見上文附錄。

### 8.3 專案元資料

| 欄位 | 值 |
|:---|:---|
| `Version` | `TW` |
| `Language` | `CHT` |
| `PeriodStartDate` | 會計期間起始 |
| `PeriodEndDate` | 會計期間結束 |
| `LastAccountingPeriodDate` | R1 的基準日 |

---

# B. 技術決策

## 9. 棄用 IDEA 與 VBA 的背景

### Phase 0：Caseware IDEA + IDEAScript (棄用)

- **原因**：不再訂閱 IDEA 授權；無法運行 `.IDM` 專有格式與 `client.OpenDatabase` 專有 API
- **遺產**：`legacy/ideascript.bas` (11,379 行) — **只作為業務規則對照，不再閱讀執行**

### Phase 1：Excel VBA + Access (歸檔)

- **資料量**：Access `.accdb` 單檔 2GB 上限，無法承載數千萬筆 GL
- **AI 協作**：VBA 幾乎無 AI agent 生態，改檔、建置、測試自動化皆不可行
- **測試**：VBA 無主流單元測試框架
- **打包**：`.xlsm` 必須有 Excel 環境且受巨集安全政策影響
- **UI**：UserForms 客製能力低，AI 不擅長生成
- **人才**：VBA 招人困難、官方演進停滯

> **補充**：公司禁用 Python 作為正式方案 (全球資安規範)；MindBridge AI AITS 無法滿足本地自訂條件需求。替代選項實際只剩 .NET 生態。

## 10. 為什麼選 .NET 10 + WinForms + WebView2 + HTML

| 項目 | 選擇 | 被排除的選項與理由 |
|:---|:---|:---|
| 語言 | **C#** | VB.NET — 社群小、AI 品質低 |
| 執行時 | **.NET 10 LTS** | .NET Framework — 不支援現代 CLI / AI workflow |
| 桌面 Host | **WinForms** | WPF — Phase 1 過重、macOS 不能原生開發；Blazor Hybrid — 多一層 runtime 與資安風險 |
| UI 引擎 | **WebView2** | 原生 WinForms 控件 — AI 不擅長生成，UI 迭代慢 |
| 前端語言 | **HTML / CSS / JS** | AI 生產力最高；`docs/jet-template.html` 已有設計模板 |
| 本機資料庫 | **SQLite** | 散落 JSON — 不利狀態管理與查詢統一 |
| 主資料庫 | **SQL Server** | Access — 資料量天花板；PostgreSQL / MySQL — 企業 Windows 環境已標配 SQL Server |
| IDE | **Visual Studio 2026** | VS Code — 對 WinForms Designer 支援不足 |
| AI 主力 | **GitHub Copilot Agent Mode** | — |
| AI 輔助 | Codex CLI / Claude Code | 跨檔重構與大規模改動 |

**為什麼是「WinForms 包 WebView2 再載 HTML」這層夾心結構**：
- WinForms 提供**單一 .exe 打包** — 符合資安與部署限制 (不架 server、不開 port)
- WebView2 承載**AI 最擅長產生的 HTML 前端**
- `Form1` 保持**極薄** — 只當 WebView2 的容器，不放業務邏輯

---

# C. 系統架構

## 11. 架構總覽

```
┌─ WinForms Host (.exe) ──────────────────────────────┐
│ ┌─ WebView2 Runtime ─────────────────────────────┐ │
│ │ ┌─ HTML / CSS / JS Frontend ─────────────────┐ │ │
│ │ │ (source: docs/jet-template.html,           │ │ │
│ │ │  packaged under src/JET/JET/wwwroot/)      │ │ │
│ │ └─────────────────┬──────────────────────────┘ │ │
│ └──────────────────┬┼─────────────────────────────┘ │
│                    ↕ action + payload (JSON)        │
│ ┌─ Thin Bridge + Action Dispatcher ────────────────┐│
│ │   postMessage handler + action → handler map     ││
│ └──────────────────┬───────────────────────────────┘│
│                    ↕                                │
│ ┌─ Application (CQRS) ────────────────────────────┐ │
│ │   Commands / Queries / Handlers                 │ │
│ │   (depend only on Domain interfaces)            │ │
│ └──────────────────┬──────────────────────────────┘ │
│                    ↕                                │
│ ┌─ Domain (pure) ──────────────────────────────────┐│
│ │   Entities / Value Objects / Rule Specs          ││
│ │   IGlRepository / ITbRepository / ...            ││
│ └──────────────────┬───────────────────────────────┘│
│                    ↕                                │
│ ┌─ Infrastructure ────────────────────────────────┐ │
│ │   SqliteProvider     │   SqlServerProvider      │ │
│ │   FileReader (Excel/CSV) / Exporter (ClosedXML) │ │
│ └──────────────────┬──────────────────────────────┘ │
└────────────────────┼────────────────────────────────┘
                     ↕
            ┌────────┴────────┐
         SQLite (本機)    SQL Server (企業)
```

### 架構模式總結

| 模式 | 套用範圍 |
|:---|:---|
| **Thin-Bridge** | WebView2 ↔ .NET 之間只有 `postMessage` + JSON，不夾邏輯 |
| **Action Dispatcher** | 單一進入點 (字典查表) 把 `action` 分派到 Handler |
| **Application CQRS** | Commands (變更) 與 Queries (讀取) 分離，各自有 Handler |
| **Clean Core** | `Domain` 不依賴任何框架、I/O 或 UI；`Application` 只依賴 `Domain`；`Infrastructure` 實作 `Domain` 介面 |
| **Repository 雙 Provider** | 單一 `IGlRepository` 介面，`SqliteGlRepository` 與 `SqlServerGlRepository` 兩個實作同時存在；執行期依設定切換 |

> **不採 Hexagonal / Onion 全套五層**。上面五個角色 (Host / Bridge / Application / Domain / Infrastructure) 已夠用。再多就是為論文服務，不是為 JET 服務。

---

## 12. 層級職責

### Host (WinForms)

- 管理 WebView2 生命週期
- 註冊 Bridge host object
- 處理系統視窗 / 檔案對話框
- `Form1.cs` **極薄**，永遠不放業務邏輯

### Bridge (WebView2 ↔ .NET)

前端以 `postMessage` 送 JSON：
```json
{ "requestId": "<uuid>", "action": "import.gl", "payload": { "filePath": "..." } }
```

Bridge 做三件事：
1. 反序列化
2. 呼叫 `ActionDispatcher.Dispatch(action, payload)`
3. 包成 `{ "requestId", "ok", "data"/"error" }` 回傳

**不內嵌任何 SQL、規則、檔案操作**。

### Action Dispatcher

一個 `Dictionary<string, IActionHandler>`，依 `action` 分派到 Command/Query Handler。建議的 action 命名空間：

| Namespace | 範例 |
|:---|:---|
| `project.*` | `project.create`、`project.load` |
| `import.*` | `import.gl`、`import.tb`、`import.accountMapping`、`import.holiday` |
| `validate.*` | `validate.run` |
| `prescreen.*` | `prescreen.run`、`prescreen.status` |
| `filter.*` | `filter.preview`、`filter.commit` |
| `export.*` | `export.workpaper` |
| `query.*` | `query.glPage`、`query.validationSummary` |

### Application (CQRS)

```csharp
public sealed record ImportGlCommand(ProjectId ProjectId, string FilePath, GlAmountMode Mode);

public sealed class ImportGlCommandHandler(IGlRepository gl, IGlFileReader reader, IProjectRepository projects)
{
    public async Task<ImportResult> HandleAsync(ImportGlCommand cmd, CancellationToken ct)
    {
        // 1. 驗證 project 存在
        // 2. reader.ReadAsync(cmd.FilePath, cmd.Mode) → IAsyncEnumerable<GlEntry>
        // 3. gl.BulkInsertAsync(...)
        // 4. 回傳 ImportResult
    }
}
```

**每條規則一個 Handler**。R1..R8 + A2..A4 + V1..V4 = 16 個小 handler + 對應 Command/Query record。

### Domain (pure)

- `GlEntry` / `TbEntry` / `AccountMapping` / `DateDimension` 等 entity
- `GlAmountMode` / `TbChangeMode` 等 enum
- `RuleSpec` (聲明式規則描述，與第 5 節的表格同構)
- Repository 介面 (`IGlRepository`、`ITbRepository`、`IDateDimensionRepository`、`IProjectRepository`…)
- **無任何 `using System.Data.*`、`Microsoft.Data.*`、`System.IO.*` 之類的框架依賴**

### Infrastructure

- `SqliteGlRepository` / `SqlServerGlRepository`
- `ExcelGlFileReader` / `CsvGlFileReader` (目前正式匯入格式只支援 `.xlsx` / `.csv`)
- `StreamingWorkPaperExporter` (OpenXML SAX writer or equivalent streaming API)
- `IConnectionFactory` (SQLite / SQL Server 各一個實作)

---

## 13. SQLite / SQL Server 雙 Provider 策略

### 核心原則 (使用者已明確界定)

> **SQLite 只是作為本機運算來減輕 SQL Server 的負荷。實務上是同個查詢指令但是根據條件分發給本地 SQLite 或線上 SQL Server 處理而已。目前先以 SQLite 為主，但程式架構必須同時支援 SQL Server。**

所以這**不是雙資料庫架構**，而是**一個 Repository 介面、兩個 Provider，同時共存、依設定切換**。

Provider 的案件定位：

- **SQLite**：小於 1,000 萬 GL rows 的本機持久案件，提供 local persistent DB path。
- **SQL Server**：大於 1,000 萬 GL rows、多人/cloud、或 10 億 row 等級 large-data case 的執行 path。

### 設計落實

```csharp
public interface IGlRepository
{
    Task<int> BulkInsertAsync(ProjectId id, IAsyncEnumerable<GlEntry> rows, CancellationToken ct);
    Task<IReadOnlyList<GlEntry>> QueryAsync(ProjectId id, GlQuerySpec spec, CancellationToken ct);
    Task<RuleResult> RunRuleAsync(ProjectId id, RuleSpec rule, CancellationToken ct);
    // ...
}
```

**兩個實作同時存在**：
- `SqliteGlRepository` — 採用 `Microsoft.Data.Sqlite`
- `SqlServerGlRepository` — 採用 `Microsoft.Data.SqlClient`

### 執行期選擇

DI 註冊時讀 `appsettings.json`：

```json
{
  "Database": {
    "Provider": "Sqlite",          // 或 "SqlServer"
    "SqliteConnectionString": "Data Source=%LOCALAPPDATA%\\JET\\project.db",
    "SqlServerConnectionString": "Server=…;Database=JET;…"
  }
}
```

DI 選擇器：
```csharp
services.AddSingleton<IGlRepository>(sp =>
    sp.GetRequiredService<IOptions<DbOptions>>().Value.Provider == DbProvider.Sqlite
        ? sp.GetRequiredService<SqliteGlRepository>()
        : sp.GetRequiredService<SqlServerGlRepository>());
```

**單次執行只會用一個 Provider**。Provider 可由使用者在 UI 切換（重啟後生效），或由「資料量門檻」觸發 (例如 GL 超過 1,000 萬筆自動建議切 SQL Server)。

### SQL 方言差異的處理

- **盡量用 ANSI SQL** (`INNER JOIN`、`GROUP BY`、`SUM`)
- **方言差異由 Provider 自行封裝**，不讓 Application 層感知：
  - 參數占位符：SQLite `@p`、SQL Server 也可 `@p` (兩者都支援，方便統一)
  - `BULK INSERT`：SQL Server 用 `SqlBulkCopy`；SQLite 用 `transaction + prepared statement batch`
  - 正則 (`REGEX_MATCH`)：SQLite 需 `regexp()` UDF；SQL Server 用 `PATINDEX` + `LIKE` 或 CLR function
- **有差異時優先寫兩版 SQL**，分別放在 `SqliteGlRepository` 與 `SqlServerGlRepository`，不要在 Application 寫動態方言切換

### Schema 分層 (兩 Provider 共通)

| Schema | 內容 |
|:---|:---|
| `staging` | 原始匯入 (未處理) |
| `target` | 標準化後的 GL / TB / AccountMapping / DateDimension |
| `result` | 規則執行結果與彙總表 |
| `config` | 專案設定、欄位映射、規則參數 |

### 目前階段的開發建議

- **先把 SQLite 版做完 MVP**。一個 Provider 能跑，等同於驗證了 Repository 介面。
- **SQL Server Provider 同步建立骨架**，但可晚一步填 SQL 實作。
- **Integration test 兩個 Provider 都跑**。兩邊測試使用同一組 `data/` 小型測試資料，保證語意等價。

---

## 14. 專案結構規劃

```
src/JET/
├── JET.slnx
└── JET/
    ├── JET.csproj
    ├── Program.cs                  # Main + DI composition root
    ├── Form1.cs / Form1.Designer.cs # WebView2 host — 僅此而已
    ├── appsettings.json            # Provider 選擇、連線字串
    ├── wwwroot/                    # 從 docs/jet-template.html 衍生的 HTML/CSS/JS
    ├── Bridge/
    │   ├── JetHostObject.cs        # 暴露給 WebView2 的 host object
    │   ├── ActionDispatcher.cs     # action → handler map
    │   └── BridgeMessage.cs        # 訊息協定 DTO
    ├── Application/
    │   ├── Commands/
    │   │   ├── ImportGl/
    │   │   ├── ImportTb/
    │   │   ├── RunValidation/
    │   │   ├── RunPreScreen/
    │   │   ├── RunAdvancedFilter/
    │   │   └── ExportWorkPaper/
    │   ├── Queries/
    │   │   ├── GetGlPage/
    │   │   ├── GetValidationSummary/
    │   │   └── GetRuleStatus/
    │   └── Contracts/              # DTO (前端可見)
    ├── Domain/
    │   ├── Entities/               # GlEntry, TbEntry, …
    │   ├── ValueObjects/           # ProjectId, AccountCode, DateKey
    │   ├── Enums/                  # GlAmountMode, TbChangeMode, DbProvider
    │   ├── Rules/                  # RuleSpec, RuleId, RuleStatus
    │   └── Abstractions/           # IGlRepository 等介面
    └── Infrastructure/
        ├── Persistence/
        │   ├── Sqlite/             # SqliteGlRepository 等
        │   └── SqlServer/          # SqlServerGlRepository 等
        ├── FileIO/                 # ExcelGlFileReader, CsvGlFileReader
        └── Exporting/              # StreamingWorkPaperExporter

src/JET/tests/JET.Tests/            # xUnit
    ├── Domain/                     # Rule spec 單元測試 (純邏輯)
    ├── Application/                # Handler 測試 (mock repository)
    └── Infrastructure/             # 每 Provider 的 integration test
```

> **目前實際狀態**：上述 Host / Bridge / Application / Domain / Infrastructure / tests 結構已部分落地。以 `rg --files src/JET` 檢查最新檔案，不要依賴舊 phase 記錄判斷完成度。

---

## 15. 命名與分層原則

1. **Form1 只做 host** — `Form1.cs` 內不碰業務邏輯，只初始化 WebView2 與 Bridge
2. **前端只送 `action + payload`** — 不拼 SQL、不呼叫資料庫
3. **Bridge 不做業務** — 只有協定解析與分派
4. **每條規則一個 Handler** — 不要一個大 `ProcessAllRulesCommand`
5. **Command/Query record 為 `sealed record`** — 不可變、易序列化、易測試
6. **Handler 建構子注入介面** — 不 new 具體 class
7. **Domain 無 I/O 依賴** — 任何 `System.IO` / `System.Data` / `Microsoft.Data.*` / `ClosedXml` 等 using 出現在 Domain 就是錯
8. **參數化查詢** — 所有使用者輸入進 SQL 一律走 `SqlParameter` / `SqliteParameter`；拒絕字串拼接
9. **測試金字塔** — Domain 100% 單元測試；Application handler mock repo 測試；Infrastructure 兩 Provider 做整合測試
10. **action 契約穩定** — action 名稱與 payload schema 列入文件化；前端改版不可改 action 契約

### 15.1 業務規則語意的權威位置

- 業務規則語意由 `docs/jet-guide.md` 的 RuleSpec、`Domain` model/spec、以及 `Application` use cases 定義。
- `Infrastructure` 負責把這些語意轉成 SQLite / SQL Server 的 parameterized set-based SQL。
- Repository implementation 不應成為 business rule source of truth。
- SQL 字串不應成為唯一的 business rule source of truth；若 SQL 與 RuleSpec 語意不一致，先修規格與測試，再修 SQL。
- 前端 JavaScript 不得承載 authoritative business rules，只能顯示狀態、收集輸入、呼叫 `JetApi`、呈現 summary/preview/page/export 結果。

---

# D. 開發與協作

## 16. AI-agent 開發工作流

### 16.1 工具鏈分工

| 任務 | 工具 | 備註 |
|:---|:---|:---|
| 主場開發 (WinForms / WebView2 整合、Designer 相關) | **Visual Studio 2026 + Copilot Agent Mode** | 必須用 VS；Designer.cs 不讓外部 AI 動 |
| 跨檔重構、Rule Handler 批次生成 | Copilot Agent Mode / Codex CLI / Claude Code | 三選一都可；優先 Copilot (IDE 原生)，跨 repo 級時用 Codex / Claude Code |
| 單元測試生成 | Copilot / Claude Code | 依 RuleSpec + 小型 fixture 生成 |
| HTML/CSS/JS 前端 | Copilot / Claude Code | 但**不可改 action 契約**與 fixed binding ID |
| SQL 方言調整 | Copilot | SQLite ↔ SQL Server 方言差 |

Visual Studio 內的 Copilot customization 建議層次：

1. `.github/copilot-instructions.md`
2. `.github/instructions/*.instructions.md`
3. `.github/prompts/*.prompt.md`
4. `.github/agents/*.agent.md`（Visual Studio 2026 18.4+）
5. `.github/skills/`（Visual Studio 2026 18.5.0 依 release notes 可用）

完整研究見 `docs/copilot-visualstudio-harness-spec.md`。

### 16.2 讓 AI 提速的關鍵：**穩定契約**

AI 能快是因為**邊界清楚**；AI 會爛是因為**邊界模糊**。

| 穩定邊界 | 放哪 |
|:---|:---|
| Action 名稱與 payload JSON schema | `docs/action-contract-manifest.md` |
| Frontend action contract / step data outline | `docs/action-contract-manifest.md` |
| RuleSpec 表 | 本檔第 5 節 |
| 欄位標準名稱 | 本檔第 18 節欄位對照 |
| Repository 介面 | `Domain/Abstractions/*.cs` |
| Frontend fixed binding ID | `docs/jet-template.html` / packaged `wwwroot/index.html` 的 `data-bind="*"` 屬性 |

建議採用 `AGENTS.md` 當短索引，詳細 AI 協作知識則放在 `docs/`。不要把所有規則都塞進單一 instruction blob。

### 16.3 AI 不該做的事

- **不可自行更改** Action 名稱或 payload 欄位
- **不可自行更改** RuleSpec 的語意 (只能補實作，不能改規則)
- **不可動** `Form1.Designer.cs` 與 `Form1.resx` 以外的 Designer 生成檔
- **不可在 Application 層** 寫 provider 判斷 (`if (isSqlite) ...`) — 方言差異在 Infrastructure 處理
- **不可為了一次性對話新增零散文件**。若需 persistent AI context，優先維護 `AGENTS.md`、`docs/action-contract-manifest.md`、`docs/agent-harness.md` 與既有 `.github/` 客製化檔案

### 16.4 驗證與測試的 loop

AI 每次產碼後應執行：
```
dotnet restore src/JET/JET.slnx
dotnet build src/JET/JET.slnx --no-restore --nologo
dotnet test src/JET/tests/JET.Tests/JET.Tests.csproj --no-build --nologo
```

若 agent 當前不在具備 .NET SDK / Windows Desktop targeting / 可用 package restore 的環境，應明確回報哪些命令失敗或跳過，不要假裝已驗證。

在 VS 2026，Copilot Agent Mode 會自動跑；在 Claude Code / Codex CLI，手動或由 agent 自己觸發。

### 16.5 UI/UX guardrails

JET UI 的目標是讓審計員清楚完成案件建立、檔案匯入、欄位配對、科目配對、完整性測試、進階篩選與底稿輸出。優先清楚、穩定、可追蹤，不追求華麗效果。

- 所有 long-running actions 應有 loading / busy / error / success state。
- validation / import / filter 結果應有可理解的 summary。
- 欄位配對畫面應清楚區分 source column、standard field、mapping status。
- 進階篩選 UI 應清楚呈現 AND / OR grouping。
- clickable elements 應有明確 affordance。
- keyboard focus state 不應被移除。
- data table 不應一次載入完整 GL/TB rows。
- preview / pagination / export 應走 backend-controlled path。
- UI 可以改善互動體驗，但不能改變資料處理與 business rule 邊界。

不要加入 marketing landing page pattern、glassmorphism / neumorphism / cyberpunk 等 aesthetic prescriptions、大量前端套件，或與 WinForms + WebView2 + static HTML 不相容的 UI stack。

---

## 17. 從 ideascript.bas 遷移的做法

**不要逐段翻譯。** 採「**聲明式規格 + 重新實作**」。

### 遷移四分類

| 類別 | 舊位置 (ideascript.bas) | 新位置 |
|:---|:---|:---|
| **Domain Rules** | R1-R8 / A2-A4 的業務邏輯 | 本檔第 5 節 RuleSpec → `Domain/Rules/*.cs` |
| **Application Use Cases** | `Step1_Validation` / `Step2_*` / `Step3_Routines` / `Step4` / `Step5_*` | `Application/Commands/*` |
| **Infrastructure** | `Z_DirectExtractionTable` / `Z_renameFields` / `Z_Rename_DB` / 檔案 I/O | `Infrastructure/*` |
| **UI Workflow** | `Intro_Dlg` / `TBDetail_Dlg` / `GLDetail_Dlg` / `Criteria_Dlg` | `wwwroot/*` + action 綁定 |

### 遷移優先序

1. **Domain 先行** — 把 5 個核心實體與 RuleSpec 寫成 C# 類別，全部單元測試
2. **建立 SqliteGlRepository** — 用 `data/JE.xlsx` 當 fixture 跑 V1-V4 + R1-R8
3. **建立 Bridge 最小閉環** — `action: "ping"` → 回傳 `"pong"`，前端驗證
4. **接通 ImportGl + ImportTb** — 一條真實資料流打通
5. **加一條規則** (R1 最簡單) — 走完 Command → Repository → SQL → Result → 回前端
6. **複製產出其他規則** — AI 依第 5 節 RuleSpec 批次生成
7. **加進階篩選與匯出**
8. **SqlServerGlRepository 補實作** — 直接對照 SqliteGlRepository 的 SQL 方言

### 舊程式 → 新結構對照 (摘要)

詳見 [`legacy/README.md`](../legacy/README.md) 的「Phase 0 規則對照」。

---

## 18. 欄位對照表

### GL (General Ledger)

| 標準 (C#) | IDEA 原名 | MVP VBA 名 |
|:---|:---|:---|
| `DocumentNumber` | 傳票號碼_JE | FLD_DOCUMENT_NUMBER |
| `LineItem` | 傳票文件項次_JE_S | FLD_LINE_ITEM |
| `Amount` | 傳票金額_JE | FLD_AMOUNT |
| `AccountCode` | 會計科目編號_JE | FLD_ACCOUNT_CODE |
| `AccountName` | 會計科目名稱_JE | FLD_ACCOUNT_NAME |
| `DocumentDescription` | 傳票摘要_JE | FLD_DOCUMENT_DESCRIPTION |
| `ApprovalDate` | 傳票核准日_JE | FLD_APPROVAL_DATE |
| `PostDate` | 總帳日期_JE | FLD_POST_DATE |
| `CreatedBy` | 傳票建立人員_JE | FLD_CREATED_BY |
| `ApprovedBy` | 傳票核准人員_JE | FLD_APPROVED_BY |
| `SourceModule` | 分錄來源模組_JE | FLD_SOURCE_MODULE |
| `IsManual` | 人工傳票否_JE_S | FLD_IS_MANUAL |
| `DebitAmount` | DEBIT_傳票金額_JE_T | FLD_DEBIT_AMOUNT |
| `CreditAmount` | CREDIT_傳票金額_JE_T | FLD_CREDIT_AMOUNT |
| `DrCr` | DEBIT_CREDIT_JE_T | FLD_DR_CR |

### TB (Trial Balance)

| 標準 (C#) | IDEA 原名 | MVP VBA 名 |
|:---|:---|:---|
| `AccountCode` | 會計科目編號_TB | FLD_ACCOUNT_CODE |
| `AccountName` | 會計科目名稱_TB | FLD_ACCOUNT_NAME |
| `ChangeAmount` | 試算表變動金額_TB | FLD_CHANGE_AMOUNT |
| `OpeningBalance` | Opening_Balance_TB | FLD_OPENING_BALANCE |
| `ClosingBalance` | Ending_Balance_TB | FLD_CLOSING_BALANCE |
| `OpeningDebitBalance` | — | FLD_OPENING_DEBIT_BALANCE |
| `OpeningCreditBalance` | — | FLD_OPENING_CREDIT_BALANCE |
| `ClosingDebitBalance` | — | FLD_CLOSING_DEBIT_BALANCE |
| `ClosingCreditBalance` | — | FLD_CLOSING_CREDIT_BALANCE |
| `DebitAmount` | — | FLD_DEBIT_AMOUNT |
| `CreditAmount` | — | FLD_CREDIT_AMOUNT |

---

## 19. 術語對照

| 中文 | English | 說明 |
|:---|:---|:---|
| 日記帳分錄 | Journal Entry (JE) | 會計系統的逐筆交易記錄 |
| 總帳 | General Ledger (GL) | 所有 JE 的匯總帳簿 |
| 試算表 | Trial Balance (TB) | 各科目期間餘額彙總 |
| 傳票 | Voucher / Document | 一組同時借貸的分錄集合 |
| 會計科目 | Account | 分類交易性質的編碼 |
| 借方 / 貸方 | Debit (Dr) / Credit (Cr) | 資產增加為借；負債收入增加為貸 |
| 過帳 | Posting | 將分錄記入總帳 |
| 完整性測試 | Completeness Test | GL ↔ TB 勾稽 |
| 預篩選 | Pre-Screening | 基於風險指標的自動篩選 |
| 進階篩選 | Advanced Filtering | 組合條件得出最終測試母體 |
| 工作底稿 | Work Paper | 審計證據的書面記錄 |
| 管理階層凌駕 | Management Override | 管理層繞過內部控制 |
| 職能分離 | Segregation of Duties | 不同人執行不同職能 |
| 科目配對 | Account Mapping | 企業科目對應標準分類 |
| 母體 | Population | 測試範圍內的全部資料 |
| 實質性程序 | Substantive Procedure | 直接測試財報金額的審計程序 |
