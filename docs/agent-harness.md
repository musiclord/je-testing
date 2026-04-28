# JET Agent Harness

This document defines the durable development loop for AI agents working in JET. It is intentionally procedural: agents should be able to follow it as a repeatable loop, not as abstract advice.

## Source-Of-Truth Hierarchy

1. `docs/jet-guide.md` — deep system reference: domain rules, architecture, audit workflow, data scale, provider strategy.
2. `docs/action-contract-manifest.md` — only source of truth for frontend/WebView2/C# action names, payloads, response shapes, and step data needs.
3. `AGENTS.md` — short map for agents: read order, guardrails, harness loop.
4. `.github/copilot-instructions.md` — short repository-wide Copilot rules.
5. `plan.md` — temporary current work plan; not durable guidance.

When files conflict, fix the lower-priority file or report the conflict. Do not invent a new contract in code or UI to bypass the docs.

## Harness Loop

1. **Read authoritative docs first**: start with `AGENTS.md`, then `docs/jet-guide.md` and `docs/action-contract-manifest.md`.
2. **Identify exact scope**: name the workflow step, layer, files, and contracts affected.
3. **Create a small plan**: prefer one narrow implementation or cleanup slice with clear non-goals.
4. **Patch narrowly**: avoid speculative rewrites, broad formatting churn, and unrelated cleanup.
5. **Update contracts/docs first when behavior crosses boundaries**: action names, payloads, response shapes, fixed bindings, persistent workflow assumptions.
6. **Test behavior changes**: add or update focused tests when code behavior changes.
7. **Run verification**: build/test when the environment supports it; otherwise state precisely why not.
8. **Report evidence**: changed files, verification commands, skipped checks, and remaining conflicts.

Agents must not claim completion without evidence from file inspection, tests, build output, or an explicit skipped-check explanation.

## Engineering Principles Adopted

JET borrows only compact engineering habits from external agent and engineering-methodology work:

- Clarify design before changing code.
- Use isolated branches/worktrees when the tool supports them and the task is risky.
- Prefer small plans and small patches.
- Use RED-GREEN-REFACTOR when changing tested behavior.
- Review for simplicity, data structure shape, and unnecessary special cases.
- Avoid AI overreach: no speculative rewrites, no invented APIs, no personality-driven style rules.

Do not copy external skill text into this repository. Extract only stable, JET-specific rules into this file, `AGENTS.md`, `.github/copilot-instructions.md`, or path-specific instructions.

## Contract-First Workflow

For frontend, WebView2, or workflow UX work:

1. Read `src/JET/JET/Bridge/ActionDispatcher.cs`.
2. Read `docs/action-contract-manifest.md`.
3. Check whether existing actions satisfy the requirement.
4. If a new action or shape is needed, update the manifest first.
5. Then update dispatcher/DTO/handler/UI in that order.
6. Preserve fixed action names, payload fields, response fields, and `data-bind` identifiers unless the task is a deliberate contract migration.

The frontend must use `window.JetApi.<method>()`. Direct `window.jet.invoke` or `window.chrome.webview.postMessage` calls are reserved for bootstrap code.

## Architecture Guardrails

- `Form1.cs` is only a host.
- Bridge is JSON transport plus dispatch only.
- Application owns commands, queries, and orchestration.
- Domain stays pure and framework-free.
- Infrastructure owns SQLite, SQL Server, file I/O, provider-specific SQL, and export mechanics.
- Provider branching belongs in Infrastructure.
- V1-V4 / R1-R8 / A2-A4 / custom filters must execute as parameterized set-based SQL.
- Bridge payloads and responses must not carry full GL/TB row sets on the scale path.
- Do not design around demo shortcuts; demo must follow the same formal pipeline as user data.

## UI/UX Guardrails

JET UI should help auditors complete case creation, file import, field mapping, account mapping, validation, prescreening, advanced filtering, and workpaper export. It should be clear, stable, and traceable rather than decorative.

- Long-running actions need loading, busy, success, and error states.
- Import, validation, prescreen, and filter results need understandable summaries.
- Field mapping must distinguish source column, standard field, and mapping status.
- Advanced filters must show AND/OR grouping clearly.
- Clickable elements need visible affordance.
- Keyboard focus states must not be removed.
- Data tables must use backend-controlled preview, pagination, or export; they must not load complete GL/TB populations into the frontend.
- UI changes must not alter business-rule ownership or data-processing boundaries.

Do not add marketing page patterns, aesthetic prescriptions, or frontend stacks incompatible with WinForms + WebView2 + static HTML.

## Verification Policy

Preferred commands:

```bash
dotnet restore src/JET/JET.slnx
dotnet build src/JET/JET.slnx --no-restore --nologo
dotnet test src/JET/tests/JET.Tests/JET.Tests.csproj --no-build --nologo
```

For documentation-only changes, verification can be limited to:

- No application code changed.
- Action manifest and agent docs agree on source-of-truth hierarchy.
- Deprecated row-based actions are not recommended for the formal demo/import pipeline.
- Any remaining UI/template drift is explicitly reported.

If the current machine lacks the required SDK, Windows Desktop workload, restored packages, or network access, say which command was skipped or failed and why.

## Tooling Surfaces

- `AGENTS.md`: cross-tool map for Codex, CLI agents, and compatible IDE agents.
- `.github/copilot-instructions.md`: repository-wide Copilot baseline.
- `.github/instructions/*.instructions.md`: path-specific Copilot rules.
- `.github/prompts/*.prompt.md`: reusable planning/review workflows.
- `.github/agents/*.agent.md`: Visual Studio 2026 18.4+ custom agents and compatible surfaces.
- `.github/skills/`: project skills for skill-capable agents.

Visual Studio support details and version notes live in `docs/copilot-visualstudio-harness-spec.md`.
