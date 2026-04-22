# JET Agent Harness

本文件定義 JET 專案的長期 agentic 開發「掛載方式」。目標不是綁死某一個工具，而是讓 `Codex`、`GitHub Copilot`、未來可能加入的其他 coding agent 都能共享同一套穩定上下文。

## 為什麼需要這份文件

JET 不是純 Web 專案，而是：

- `WinForms host`
- `WebView2`
- `HTML/CSS/JS frontend`
- `Thin Bridge + Action Dispatcher`
- `Application CQRS`
- `Domain / Infrastructure`

這類專案最怕 agent 在不同對話與不同工具之間漂移，最後出現：

- 前端自己發明 action 名稱
- bridge 偷塞業務邏輯
- WinForms host 越寫越厚
- UI 改了，但契約與文件沒更新

因此本 repo 採用「短 `AGENTS.md` + 深 `docs/` + IDE 原生 instructions/prompts + custom agents + 選配 skills」的組合。

## 採用的持久上下文層

| 層 | 用途 | 主要工具 |
|:---|:---|:---|
| `AGENTS.md` | 給 agent 的地圖與進入順序 | Codex、Copilot agent、其他支援 `AGENTS.md` 的工具 |
| `docs/jet-guide.md` | 業務、架構、規則、遷移、核心 workflow 的系統記錄 | 全部 |
| `docs/action-contract-manifest.md` | 前端 / WebView2 / C# 之間的 action 與資料綱要 | 全部 |
| `.github/copilot-instructions.md` | Copilot repository-wide guidance | GitHub Copilot |
| `.github/instructions/*.instructions.md` | path-specific 自動上下文 | GitHub Copilot in VS Code / Visual Studio |
| `.github/prompts/*.prompt.md` | 可重複工作流與審查流程 | GitHub Copilot in VS Code / Visual Studio |
| `.github/agents/*.agent.md` | 專用 agent profile | Visual Studio 2026 18.4+、其他相容 Copilot agent surfaces |
| `.github/skills/` | skill-capable agent 的專用技能 | Copilot CLI、VS Code agent mode、Visual Studio 2026 18.5+ 依 release notes |

更完整的 Visual Studio 研究與版本分界，見 `docs/copilot-visualstudio-harness-spec.md`。

## 採用策略

### 1. `AGENTS.md` 當索引，不當百科全書

依據 OpenAI 的 harness engineering 做法，`AGENTS.md` 應保持精簡，主要作用是：

- 告訴 agent 先看哪些文件
- 說明不可破壞的架構邊界
- 指向真正的 system of record

詳細知識不塞在 `AGENTS.md`，避免過期與上下文浪費。

### 2. `docs/` 當 system of record

本 repo 的深度真相應集中在既有文件：

- `docs/jet-guide.md`
- `docs/action-contract-manifest.md`
- 本文件 `docs/agent-harness.md`

如果前端流程、bridge 契約、或 agent 工作流有改動，應先更新這些文件，再讓 agent 照文件實作。

### 3. 契約先行，而不是 UI 先行

任何 HTML / UX 變更都應先回答：

1. 這個畫面要讀取哪些資料？
2. 這些資料來自既有 action 還是需要新 action？
3. payload / response shape 是什麼？
4. 哪些固定 binding / state key 不可變？

因此 JET 的前端工作流不是「先畫畫面再補 bridge」，而是：

1. 需求拆成 step data outline
2. 對照 `ActionDispatcher`
3. 更新 `docs/action-contract-manifest.md`
4. 再生成或重構 UI

### 4. IDE 原生機制優先，custom agents / skills 依版本補強

對 GitHub Copilot 來說，官方穩定機制是：

- `.github/copilot-instructions.md`
- `.github/instructions/*.instructions.md`
- `.github/prompts/*.prompt.md`

在 Visual Studio：

- `custom agents` 是 2026 18.4+ 的正式強化面
- `skills` 依 2026-04-14 的 Visual Studio 2026 18.5.0 release notes 已可用

但即使如此，`instructions + prompt files` 仍應是基線，因為這是文件最一致、最穩定的主控制面。

### 5. 保留 `.github/skills`，並新增 `.github/agents`

目前 repo 已經放入一些 skills 副本，這些對 skill-capable agent 有幫助，可以保留。

但 JET 專案真正需要的是一個**專案專屬的 contract-first workflow**，所以另外加上：

- `AGENTS.md`
- action contract manifest
- Copilot instructions / prompt files
- custom agents
- 專案自有 skill

## 外部 repo 的採用方式

### `nextlevelbuilder/ui-ux-pro-max-skill`

採用其**UI/UX 推理方法**，不整套安裝流程硬套進 repo。

用法：

- 透過 prompt file 與 frontend instructions 引導 agent 改善資訊層級、表格、狀態卡片、可讀性與互動
- 但所有 UI 變更都必須服從 action contract 與 fixed binding ID

### `obra/superpowers`

採用其**方法論精華**，不整套把 worktree / mandatory TDD / 強制子代理流程搬進來。

JET 實際採用的是：

- brainstorm before code
- docs 作為真相來源
- 先定契約與計畫，再實作
- 用 prompt file 做 drift review 與 planning

沒有採用的部分：

- 把所有任務都強制變成 worktree workflow
- 在目前工具鏈未統一前強制多 agent orchestration

### `oh-my-claudecode`

目前**不作為主流程**導入。

原因：

- 它是 Claude Code first
- JET 現在主流程是 VS Code Codex 與日後回到 Visual Studio + GitHub Copilot
- 若現在再加一層工具專屬 orchestration，容易讓 repo 出現兩套彼此競爭的 agent 規則

如果未來真的需要 teams-first orchestration，應優先評估對應 Codex 的 sidecar 流程，而不是把 OMC 規則直接塞進主 repo。

## JET 的標準工作流

### A. 前端 / UX 任務

1. 讀 `AGENTS.md`
2. 讀 `docs/jet-guide.md`
3. 讀 `docs/action-contract-manifest.md`
4. 確認是否能完全使用現有 actions
5. 若不能，先更新 contract manifest
6. 再改 `docs/jet-template.html` 或相關 UI

### B. Bridge / Action 任務

1. 保持 `Form1` 與 `Bridge` 極薄
2. 先更新 manifest
3. 再改 `ActionDispatcher` / DTO / handler
4. 最後同步文件

### C. 文件 / 規格任務

1. 優先更新既有 system-of-record 文件
2. 不新增一次性「聊天備忘錄」文件
3. 若是 persistent AI context，應放在：
   - `AGENTS.md`
   - `docs/action-contract-manifest.md`
   - `docs/agent-harness.md`
   - `.github/instructions/`
   - `.github/prompts/`

## 環境政策

### VS Code / Codex

- 以文件、契約、靜態檢查為主
- 不預設跑 `.NET build/test`
- 若當前不是 Visual Studio ready 環境，應明講「這次未驗證 build/test」

### Visual Studio / GitHub Copilot

- 可使用 repository custom instructions 與 prompt files
- 可使用 `.github/agents/*.agent.md` 自訂 agents
- 若版本為 Visual Studio 2026 18.5.0 或更新，依 release notes 可額外使用 repo skills
- 回到 Visual Studio 主場後，再執行：
  - `dotnet build src/JET/JET.slnx`
  - `dotnet test src/JET/tests/JET.Tests/JET.Tests.csproj`

## 維護原則

- `AGENTS.md` 要短
- 深度知識進 `docs/`
- action 契約集中在 manifest
- prompt / instructions 要對應真實 repo 結構，不寫抽象空話
- 新增任何 AI workflow 文件時，都要能回答「哪個工具會吃到它」
