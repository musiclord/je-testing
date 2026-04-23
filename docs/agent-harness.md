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

JET 採用「方法論萃取」策略，而非直接複製外部 skill 文件。原因：

- **Drift**：副本與上游脫節後變成過期規則墳墓
- **Context Bloat**：數百行通用規則稀釋 agent 的注意力預算
- **Rule Conflict**：外部 skill 的假設（Unix/Claude Code/iOS）與 JET 的 contract-first WebView2 架構不匹配

每個外部 repo 的有價值方法論被萃取成 2-3 條 JET 語境化原則，嵌入已有的 instructions/prompts。

### `nextlevelbuilder/ui-ux-pro-max-skill`

萃取了其 **UI 推理方法**。

| 萃取內容 | 落地位置 |
|:---|:---|
| 5 步 UI Reasoning Protocol（hierarchy → contrast → interaction → consistency → simplicity） | `.github/instructions/frontend.instructions.md` |
| UI 交付前檢查（visual hierarchy + contrast + interaction feedback） | `.github/instructions/frontend.instructions.md` Taste Gate |

沒有採用的部分：

- 整套 iOS/Android 設計系統規範（JET 是 WebView2 + HTML）
- token-driven theming 體系（JET 的 UI 是單一 HTML shell）
- 200+ 行平台特定 checklist

### `obra/superpowers`

萃取了其 **設計先行方法論**。

| 萃取內容 | 落地位置 |
|:---|:---|
| Design-before-code gate（先釐清再動手、先提方案再選擇） | `.github/copilot-instructions.md` Work Discipline |
| YAGNI 作為強制設計原則 | `.github/copilot-instructions.md` Work Discipline |
| Spec self-review checklist（佔位符掃描 + 一致性 + 範圍 + 歧義 + YAGNI） | `.github/prompts/jet-contract-plan.prompt.md` |

沒有採用的部分：

- Mandatory TDD / red-green-refactor 強制流程
- Subagent-driven-development 多 agent 編排
- Git worktree 強制工作流
- Superpowers plugin marketplace 安裝體系

### `Yeachan-Heo/oh-my-claudecode`

維持**不作為主流程導入**。

原因：

- 完全基於 Claude Code CLI + tmux 的 teams-first 多 agent 編排
- JET 主流程是 Visual Studio + GitHub Copilot，agent 模型根本不同
- 其核心有價值的方法論（先充分探索需求再動手）已被 superpowers 的 design-before-code gate 覆蓋

如果未來需要 teams-first orchestration，應優先評估 Visual Studio 自身的 multi-agent 能力或 Codex 的 sidecar 流程。

### `kingkongshot/Pensieve` (Linus 式工程原則)

採用其**可執行工程原則 (maxims) 方法論**，不安裝完整 Pensieve。

| 萃取內容 | 落地位置 |
|:---|:---|
| 4 大 Linus 工程原則（Good Taste / Don't Break Userspace / Simplify Before Extending / Paranoid About Simplicity） | `.github/copilot-instructions.md` Engineering Maxims |
| 可執行批判思考迴路 | `.github/instructions/*.instructions.md` Taste Gate |
| Taste review prompt | `.github/prompts/jet-taste-review.prompt.md` |
| Maxim 交叉檢查 | `.github/agents/jet-architect.agent.md` Maxim Cross-Check |

沒有採用的部分：

- 完整的四層知識模型（maxim / decision / knowledge / pipeline）
- 自動知識圖譜與 hook 機制

### `forrestchang/andrej-karpathy-skills` (Karpathy LLM 編碼陷阱)

萃取了其**外科手術式變更原則與假設管理方法**。

| 萃取內容 | 落地位置 |
|:---|:---|
| Surgical Changes — 只動該動的（每一行變更追溯到請求、不順手改善、匹配現有風格） | `.github/copilot-instructions.md` Engineering Maxims #5 |
| 外科手術式變更檢查 | `.github/instructions/*.instructions.md` Taste Gate（全部 4 個） |
| Surgical Changes review criteria | `.github/prompts/jet-taste-review.prompt.md` |
| State assumptions / push back / stop when confused | `.github/copilot-instructions.md` Work Discipline |

沒有採用的部分：

- Goal-Driven Execution（已被 JET 的 Spec Self-Review + contract-first workflow 覆蓋）
- Simplicity First（已被 Maxim #3 + #4 + YAGNI 覆蓋）
- Think Before Coding 的基礎部分（已被 design-before-code 覆蓋）

### 規則衛生 (Rule Hygiene)

防止 `.github/` 演變成規則墳墓的衛生原則：

1. **不複製外部 skill**：`.github/skills/` 只放 JET 專屬 skills。外部方法論萃取後嵌入 instructions/prompts，不保留原始副本。
2. **能被 linter 處理的就不寫成 instruction**：把 agent 注意力預算留給架構決策。
3. **Reference, Don't Duplicate**：指向 repo 中的真實文件（如 `docs/jet-guide.md`），不在 instruction 裡貼文件摘要。
4. **Progressive Disclosure**：path-specific instructions 只在碰到對應文件時才觸發，避免全局上下文膨脹。
5. **定期修剪**：當規則所對應的程式碼或架構已變更，直接刪除規則。不累積、不「以防萬一」。
6. **溯源標記**：從外部方法論萃取的規則標注 `*(Extracted from: ...)*`，方便日後追溯與修剪。

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
