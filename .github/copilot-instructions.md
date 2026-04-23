# JET Copilot Instructions

## Engineering Maxims (不可違反)

以下五條原則適用於 JET 的所有開發活動。每次產碼前自問這五個問題：

### 1. Good Taste — 消除特殊分支

每條規則一個 Handler；Repository 介面統一，Provider 差異封裝在 Infrastructure。
如果你的程式碼在 Application 層出現 `if (provider == Sqlite)` 或在一個 Handler 裡塞了多條規則邏輯，那就是 bad taste。

### 2. Don't Break Userspace — 不破壞已有契約

不改 action 名稱、payload 欄位、fixed `data-bind` 識別符、Designer.cs。
契約演進只做 additive change，不做 silent breaking change。

### 3. Simplify Before Extending — 先簡化，再擴展

先確認現有 action 是否已足夠。先更新 `docs/action-contract-manifest.md`，再寫碼。
不為一次性對話新增零散文件。如果程式碼看起來很複雜，先退一步問「能不能更簡單」。

### 4. Paranoid About Simplicity — 偏執地追求簡單

Bridge 只做 JSON transport + dispatch。Form1 只做 WebView2 host。
選擇最笨但最清晰的實作。如果你覺得需要寫一個「聰明的」抽象層，先停下來。

### 5. Surgical Changes — 只動該動的 *(Extracted from: andrej-karpathy-skills)*

每一行變更都必須直接追溯到用戶的請求。不「順手改善」相鄰的程式碼、註解或格式。
不重構沒壞的東西。匹配現有風格，即使你會用不同方式寫。
如果你的變更產生了孤兒 import/變數/函式，清理它們；但不要刪除變更前就存在的 dead code，除非被要求。

## Architecture Boundaries

- Read `AGENTS.md` first. Treat it as the map; the detailed system of record lives in `docs/`.
- Respect the `Host -> Bridge -> Application -> Domain -> Infrastructure` boundaries from `docs/jet-guide.md`.
- Before changing UI, bridge actions, or payloads, update `docs/action-contract-manifest.md`.

## Work Discipline

- Design before code: for any non-trivial change, clarify requirements, propose 2-3 approaches, and reach consensus before writing code. If you think "this is too simple to need a design", that is exactly when a design is most needed. *(Extracted from: superpowers/brainstorming, oh-my-claudecode/deep-interview)*
- State assumptions, push back, stop when confused: if uncertain, ask rather than guess. If multiple interpretations exist, present them. If a simpler approach exists, say so. If something is unclear, stop and name what's confusing. *(Extracted from: andrej-karpathy-skills)*
- YAGNI ruthlessly: remove all "just in case" features from designs and implementations. If the current workflow step does not need it, do not build it. *(Extracted from: superpowers)*
- In non-Visual-Studio environments, avoid assuming `.NET` build/test is available unless the user explicitly asks. In Visual Studio workflows, use the documented build/test loop from `docs/jet-guide.md`.
- When behavior or contracts change, update the relevant docs, prompts, instructions, or skills in the same task.
- Do not create throwaway docs. Persistent AI context belongs in existing system-of-record files.
