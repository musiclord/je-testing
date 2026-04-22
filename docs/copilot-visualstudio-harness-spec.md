# JET Copilot Visual Studio Harness Spec

本文件整理 **GitHub Copilot 在 Visual Studio** 的官方能力現況，並將研究結果轉成 JET 專案的實際落地規格。

## 目的

JET 的 AI 協作不能只看抽象概念，必須對齊 Visual Studio 實際支援的客製化表面。否則就會出現：

- 把 VS Code / CLI 的機制誤以為 Visual Studio 一定會吃
- 把 `AGENTS.md` 當成 Visual Studio Copilot 的主入口
- 把 `.github/skills` 當成唯一方案，結果版本不支援

本文件的結論是：**JET 在 Visual Studio 應採「instructions + prompt files 為基線，custom agents 為強化，skills 為版本加成」的多層策略。**

## 官方研究摘要

### 1. Agent mode

- Microsoft Learn 的 **Use Agent Mode - Visual Studio** 文件指出，Visual Studio 的 Copilot agent mode 可自動規劃、編輯、執行工具與命令。
- 文件列出先決條件為 **Visual Studio 2022 version 17.14 or later**。

對 JET 的意義：

- 若你回到 Visual Studio 主場，agent mode 是可以作為主開發流程的。
- 但是否執行 terminal/build/test，仍要看當前 solution 與工具設定。

### 2. Repository custom instructions

GitHub Docs 針對 Visual Studio 明確寫到：

- 支援 repository-wide custom instructions：
  - `.github/copilot-instructions.md`
- 支援 path-specific custom instructions：
  - `.github/instructions/**/*.instructions.md`

對 JET 的意義：

- 這兩層是 **Visual Studio Copilot 可穩定依賴的主機制**。
- 所有架構邊界、WinForms/WebView2 限制、contract-first 規則，都應先落在這兩層。

### 3. Prompt files

GitHub Docs 明確指出：

- `*.prompt.md` prompt files 可用於 **VS Code、Visual Studio、JetBrains**
- Visual Studio 2026 April update 的 release notes 又補充：
  - 可透過 `/` 觸發自訂 prompts
  - 提供 `/generateInstructions`
  - 提供 `/savePrompt`

對 JET 的意義：

- `.github/prompts/*.prompt.md` 不只是補充，而是 Visual Studio 內非常適合做：
  - feature planning
  - contract drift review
  - UI from contract
  - architecture-first kickoff

### 4. AGENTS.md 不是 Visual Studio Copilot Chat 的主要 custom instruction surface

GitHub Docs 的 **Support for different types of custom instructions** 頁面列得很清楚：

- Visual Studio 的 Copilot Chat 支援：
  - `.github/copilot-instructions.md`
  - `.github/instructions/**/*.instructions.md`
- 但該頁**沒有把 `AGENTS.md` 列為 Visual Studio Chat 的支援面**

對 JET 的意義：

- `AGENTS.md` 對 **Codex / Copilot CLI / cross-tool agents** 很重要
- 但對 Visual Studio Copilot，**不能只靠 `AGENTS.md`**
- 因此 JET 必須把真正關鍵規則同步寫進 `.github/copilot-instructions.md` 與 `.github/instructions/`

### 5. Custom agents in Visual Studio

Microsoft Learn 的 **Use built-in and custom agents with GitHub Copilot** 文件指出：

- **Custom agents require Visual Studio 2026 version 18.4 or later**
- 自訂代理以 `.agent.md` 檔案定義在：
  - `.github/agents/`
- 可透過：
  - `@agent-name`
  - 或在某些版本使用 agent picker

該文件也列出 Visual Studio 的內建 agents：

- `@debugger`
- `@profiler`
- `@test`
- `@modernize`

對 JET 的意義：

- 專案可以正式配置 `.github/agents/*.agent.md`
- 而且可以把 JET 的核心流程拆成專用 agents，例如：
  - architecture / planning
  - WebView2 frontend contract
  - CQRS implementation

### 6. Agent skills in Visual Studio：文件存在時間差

這是目前最需要注意的地方。

GitHub Docs 的 feature matrix 與 skills 文件，仍顯示：

- agent skills 支援：
  - VS Code
  - Copilot CLI
  - cloud agent
- 並未把 Visual Studio 列為穩定支援面

但是 Microsoft Learn 的 **Visual Studio 2026 release notes** 在 **2026-04-14** 的 18.5.0 更新中明寫：

- Visual Studio 的 Copilot agents 現在會自動發現並使用 skills
- repo skills 位置包括：
  - `.github/skills/`
  - `.claude/skills/`
  - `.agents/skills/`

對 JET 的意義：

- **以 2026-04-14 的 Visual Studio release notes 來看，skills 已可作為 Visual Studio agent mode 的加成機制**
- 但由於 GitHub Docs 的總表仍有落差，JET 不應只押寶在 `skills`
- 正確做法是：
  1. **instructions + prompts** 當基線
  2. **custom agents** 當強化
  3. **skills** 當可用則加分的補充層

### 7. Visual Studio 的 .NET / WinForms 專案加成

Microsoft Learn 在 custom agents 文件中還指出：

- .NET 團隊維護了 `CSharpExpert` 與 `WinFormsExpert` 自訂 agents
- 並提到 Visual Studio 有一個選項：
  - `Enable project specific .NET instructions such as Windows Forms development when applicable`

對 JET 的意義：

- 你的專案是 `.NET + WinForms + WebView2`
- 回到 Visual Studio 時，應優先確認這個設定已開啟
- 然後再疊加 JET 自己的 repository instructions / custom agents / skills

## JET 的官方落地策略

### A. 必備基線

這些是 **不依賴 Visual Studio 新功能時間差** 也應存在的檔案：

- `.github/copilot-instructions.md`
- `.github/instructions/**/*.instructions.md`
- `.github/prompts/*.prompt.md`
- `docs/action-contract-manifest.md`
- `docs/jet-guide.md`

原因：

- 它們是最穩定、最官方、版本相容面最好的 Copilot customization 表面。

### B. Visual Studio 18.4+ 強化層

加入：

- `.github/agents/*.agent.md`

用途：

- 讓 Visual Studio Copilot Agent Mode 有專用人格與邊界，而不是每次都從一般 agent 開始。

### C. Visual Studio 18.5+ 加成層

保留與擴充：

- `.github/skills/`

用途：

- 讓 Visual Studio agent 在適當情境下自動載入專用工作流
- 但不把它當成唯一或第一層控制面

## JET 專案建議的 Visual Studio Copilot 工作流

### 1. 規劃與架構

優先使用：

- custom prompt file：`/jet-contract-plan`
- custom agent：JET architect agent

目標：

- 先確認受影響 workflow step
- 先確認現有 action 能否重用
- 先更新 contract manifest

### 2. 前端 / WebView2 / HTML

優先使用：

- custom prompt file：`/jet-ui-from-contract`
- custom agent：JET WebView2 UI agent

目標：

- 僅在既有 contract 內做 UI/UX
- 若要增 action，先回寫 manifest
- 絕不讓 HTML 自己長出未記錄的 API 想像

### 3. C# / CQRS / bridge 實作

優先使用：

- repository instructions
- path-specific instructions
- custom agent：JET CQRS implementer

目標：

- `Form1` 極薄
- `Bridge` 極薄
- provider 差異留在 Infrastructure
- 不碰 Designer 生成檔

### 4. 除錯 / 測試 / 效能

優先考慮內建 agents：

- `@debugger`
- `@test`
- `@profiler`

因為這些 agents 是 Visual Studio 原生工具整合能力，不應重新發明。

## 對 JET 的最終決策

### 採用

- `AGENTS.md`：保留，作為 Codex 與跨工具入口
- `.github/copilot-instructions.md`：保留並作為 Visual Studio 主入口之一
- `.github/instructions/`：強化，這是 Visual Studio 非常重要的 path-specific context
- `.github/prompts/`：強化，Visual Studio 可直接用 slash prompt
- `.github/agents/`：新增，作為 Visual Studio 2026 18.4+ 的專案專屬 agent
- `.github/skills/`：保留並逐步增補，作為 Visual Studio 2026 18.5+ 的可選增強

### 不採用

- 把 `AGENTS.md` 當成 Visual Studio Copilot 唯一入口
- 把 `.github/skills` 當成唯一方案
- 在還沒確定版本前依賴太多 VS Code 專屬自訂 agent / handoff 做法

## 對使用者的 Visual Studio 設定建議

回到 Visual Studio 開發時，建議至少確認：

1. Visual Studio 版本：
   - agent mode：17.14+
   - custom agents：2026 18.4+
   - skills discovery：依 2026-04-14 release notes，2026 18.5.0+
2. `Tools > Options > GitHub > Copilot`
   - 開啟 custom instructions
   - 開啟 path-specific instructions
   - 若有該選項，開啟 project-specific .NET / Windows Forms instructions
3. 在 Copilot Chat：
   - 會看到 `.github/copilot-instructions.md` 參考
   - 可用 `/` 呼叫 prompt files
   - 可用 `@agent-name` 呼叫 custom agents

## 研究來源

- GitHub Docs: repository custom instructions in Visual Studio  
  https://docs.github.com/en/copilot/how-tos/configure-custom-instructions/add-repository-instructions?tool=visualstudio
- GitHub Docs: support for different custom instruction types  
  https://docs.github.com/en/copilot/reference/custom-instructions-support
- GitHub Docs: prompt files  
  https://docs.github.com/en/copilot/tutorials/customization-library/prompt-files
- GitHub Docs: customization cheat sheet  
  https://docs.github.com/en/copilot/reference/customization-cheat-sheet
- Microsoft Learn: agent mode in Visual Studio  
  https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-mode?view=visualstudio
- Microsoft Learn: built-in and custom agents in Visual Studio  
  https://learn.microsoft.com/en-us/visualstudio/ide/copilot-specialized-agents?view=vs-2022
- Microsoft Learn: Visual Studio 2026 release notes  
  https://learn.microsoft.com/en-us/visualstudio/releases/2026/release-notes
