# JET Agent Map

Treat this file as the map, not the encyclopedia. The durable system of record lives in `docs/`.

## Read Order

1. `README.md`
2. `docs/jet-guide.md`
3. `docs/action-contract-manifest.md`
4. `docs/agent-harness.md`
5. `docs/copilot-visualstudio-harness-spec.md`

## Project Snapshot

- JET is a journal entry testing tool for audit workflows.
- Stack: `.NET 10`, `WinForms`, `WebView2`, `HTML/CSS/JS`, `SQLite`, `SQL Server`.
- The frontend is an HTML shell loaded by WebView2, not a standalone SPA.
- The backend follows `Host -> Bridge -> Application -> Domain -> Infrastructure`.

## Non-Negotiable Architecture

- `Form1.cs` is a thin host only. Do not put business logic in WinForms.
- `Bridge/*.cs` only handles JSON transport and action dispatch.
- Frontend calls backend exclusively through the auto-generated `window.JetApi.<method>()` facade (see `docs/action-contract-manifest.md#jetapi-typed-facade`). Raw `window.jet.invoke` / `window.chrome.webview.postMessage` are reserved for the bootstrap script.
- `Application/*` owns commands, queries, and handlers.
- `Domain/*` stays pure and framework-free.
- `Infrastructure/*` owns provider-specific I/O and SQL differences.
- Provider branching belongs in Infrastructure, not in Application or frontend code.
- Do not edit `Form1.Designer.cs` or other designer-generated files unless the user explicitly asks.

## Contract-First Workflow

Before changing `docs/jet-template.html`, WebView2 bridge code, or workflow UX:

1. Read `src/JET/JET/Bridge/ActionDispatcher.cs`.
2. Read `docs/action-contract-manifest.md`.
3. Reuse existing actions whenever possible.
4. If the UI needs new data or a new action, update `docs/action-contract-manifest.md` first.
5. Preserve fixed action names, payload fields, and `data-bind` identifiers unless the task explicitly includes a contract migration.

## Tooling Surfaces

- OpenAI Codex / VS Code Codex:
  - Rely on `AGENTS.md` plus the referenced `docs/` files for persistent context.
  - Do not assume Visual Studio Designer access, WinForms design-time support, or a ready desktop build environment.
- GitHub Copilot in VS Code:
  - Uses `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `.github/prompts/*.prompt.md`, and `.github/skills/`.
- GitHub Copilot in Visual Studio:
  - Baseline support is `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, and `.github/prompts/*.prompt.md`.
  - Visual Studio 2026 18.4+ also supports `.github/agents/*.agent.md` custom agents.
  - Visual Studio 2026 18.5.0 release notes dated April 14, 2026 state that repository and user `skills` are automatically discovered in agent mode.
  - Do not treat `AGENTS.md` as the primary Visual Studio Copilot mechanism; use it as cross-tool context for Codex, CLI, and other agent-capable tools.

## File Map

- `docs/jet-guide.md`: domain rules, architecture, migration strategy, AI workflow
- `docs/action-contract-manifest.md`: frontend/WebView2 action contracts and step data outline
- `docs/agent-harness.md`: cross-tool harness strategy for Codex, Copilot, and skills/prompts
- `docs/copilot-visualstudio-harness-spec.md`: official-docs research and recommended Visual Studio Copilot setup for JET
- `docs/jet-template.html`: canonical HTML shell and binding surface
- `.github/copilot-instructions.md`: short repository-wide Copilot guidance
- `.github/instructions/`: path-specific Copilot guardrails
- `.github/prompts/`: reusable Copilot workflows
- `.github/agents/`: custom agents for Visual Studio 2026 18.4+ and other compatible Copilot surfaces
- `.github/skills/`: project and imported skills for skill-capable agents

## Verification Policy

- In VS Code / Codex or any environment that is not confirmed to be a ready Visual Studio desktop setup, skip `.NET` build/test unless the user explicitly asks for it.
- In Visual Studio / Copilot sessions with the proper environment available, use the documented build/test loop from `docs/jet-guide.md`.
- If verification is skipped, say so clearly.

## When Docs Must Be Updated

Update the relevant docs in the same task when any of the following change:

- action names, payloads, or response shapes
- workflow step data needs
- fixed binding IDs or UI contract assumptions
- persistent AI workflow files such as prompts, instructions, or skills

## Preferred Change Style

- Keep `AGENTS.md` short and pointer-based.
- Keep deep detail in `docs/`.
- Avoid creating one-off guidance files when the information belongs in the existing system-of-record files.
