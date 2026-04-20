# ideascript 拆分總覽

這個目錄的目的不是重寫或修正 [`legacy/ideascript.bas`](../../legacy/ideascript.bas)，而是把它拆成 AI 與人都能快速定位的參照模組。

`ideascript.bas` 是 JET 的始祖代碼。它的 UI、命名、暫存表與控制流程都很舊，但它承載的是當時審計員與會計師對 Journal Entry Testing 的理解，所以這裡的拆分原則是：

1. 保留舊邏輯與舊資料模型，不替 legacy 洗白。
2. 把大檔拆成可局部閱讀的模組卡，降低 token 成本。
3. 每個模組都能追回原始函式與行號。
4. 優先描述流程、暫存表、依賴與關係，而不是翻譯語法細節。

## 建議閱讀順序

1. [01-shell-and-state.md](./01-shell-and-state.md)
2. [02-step1-import-validation.md](./02-step1-import-validation.md)
3. [03-step2-auxiliary-inputs.md](./03-step2-auxiliary-inputs.md)
4. [04-step3-prescreen-routines.md](./04-step3-prescreen-routines.md)
5. [05-step4-criteria-advanced-filter.md](./05-step4-criteria-advanced-filter.md)
6. [06-step5-workpaper-export.md](./06-step5-workpaper-export.md)
7. [07-shared-helpers.md](./07-shared-helpers.md)
8. [08-procedure-index.md](./08-procedure-index.md)

## 如何把它當作參照物

- 想知道「從哪裡進來」：先讀 `01-shell-and-state.md`
- 想知道「GL/TB 怎麼被整理成 JET 標準欄位」：讀 `02-step1-import-validation.md`
- 想知道「Account Mapping / Holiday / Makeup Day 怎麼影響邏輯」：讀 `03-step2-auxiliary-inputs.md`
- 想知道「R1-R8 / A2-A4 怎麼產生 tag」：讀 `04-step3-prescreen-routines.md`
- 想知道「Step4 如何把預篩選 + 日期/文字/金額條件組成 Criteria」：讀 `05-step4-criteria-advanced-filter.md`
- 想知道「最後工作底稿從哪些 CriteriaSelect 組出來」：讀 `06-step5-workpaper-export.md`
- 想知道「某個 helper 函式在幹嘛」：讀 `07-shared-helpers.md`
- 想快速找函式位置：讀 `08-procedure-index.md`

## 模組卡語法

每一張模組卡都盡量維持同一個結構：

- `角色`：這個模組在整體流程中的責任
- `來源`：原始函式與行號
- `讀寫資產`：它會讀哪些 `.IDM` / SQL CE table / Excel template
- `流程`：用接近 DSL 的方式把舊流程攤平
- `輸出`：它會留下什麼暫存表或檔案
- `邊界`：哪些地方只是 legacy 實作習慣，不應被誤認成新架構要求

## 重要邊界

- 這裡描述的是 legacy 真實行為，不代表新系統應照抄 UI 或 goto 寫法。
- `ideascript.bas` 內大量使用 `.IDM` 暫存表、欄位改名、JoinDatabase、Extraction，這些在新系統中應保留「邏輯結果」，不必保留「IDEA API 形狀」。
- 這些文件優先服務於「理解 legacy 真相」，不是服務於「美化 legacy 設計」。

## 與新專案文件的關係

- 規則與新架構的正式語意仍以 [`docs/jet-guide.md`](../jet-guide.md) 為主。
- 當 `jet-guide.md` 與 `ideascript.bas` 有差異時，應把差異視為待決策項，而不是直接假設其中一邊錯。
- 這個目錄是 `jet-guide.md` 與 `ideascript.bas` 之間的橋，不是新的單一真相來源。
