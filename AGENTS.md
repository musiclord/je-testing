# JET Agent Map

Treat this file as the map, not the encyclopedia. Durable system knowledge lives in `docs/`; temporary next-step planning lives in `plan.md`.

## Read Order

1. `README.md`
2. `docs/jet-guide.md`
3. `docs/action-contract-manifest.md`
4. `docs/agent-harness.md`
5. `docs/copilot-visualstudio-harness-spec.md`

## Source Of Truth

1. `docs/jet-guide.md` — domain rules, architecture, data scale, provider strategy, audit workflow.
2. `docs/action-contract-manifest.md` — the only frontend/WebView2/C# action contract source.
3. `AGENTS.md` — short agent map and guardrails.
4. `.github/copilot-instructions.md` — short repository-wide Copilot rules.
5. `plan.md` — temporary current work plan only.

## Non-Negotiable Architecture

- `Form1.cs` is a thin WebView2 host. Do not put business logic in WinForms.
- `Bridge/*.cs` only handles JSON transport and action dispatch.
- Frontend calls backend only through the generated `window.JetApi.<method>()` facade. Raw `window.jet.invoke` / `window.chrome.webview.postMessage` are reserved for bootstrap code.
- `Application/*` owns commands, queries, handlers, and use-case orchestration.
- `Domain/*` stays pure and framework-free.
- `Infrastructure/*` owns file I/O, provider-specific SQL, SQLite, and SQL Server differences.
- Provider branching belongs in Infrastructure, not Application or frontend code.
- V1-V4 / R1-R8 / A2-A4 / custom filters must run as parameterized set-based SQL. Do not load GL/TB row collections into Application memory for LINQ-style computation.
- Bridge payloads/responses must not carry full GL/TB row sets on the scale path.
- Do not edit `Form1.Designer.cs` or other generated designer files unless explicitly asked.

## Harness Loop

1. Read the authoritative docs first.
2. Identify the exact scope and affected workflow step.
3. Make a small implementation or cleanup plan.
4. Prefer small patches over broad rewrites.
5. Update tests when behavior changes.
6. Run build/test/verification commands when the environment supports them.
7. Report changed files and verification evidence.
8. Do not claim success without evidence; state skipped checks clearly.

## Contract-First Workflow

Before changing `docs/jet-template.html`, WebView2 bridge code, or workflow UX:

1. Read `src/JET/JET/Bridge/ActionDispatcher.cs`.
2. Read `docs/action-contract-manifest.md`.
3. Reuse existing actions whenever possible.
4. If new data or behavior is needed, update the manifest before code.
5. Preserve action names, payload fields, and fixed `data-bind` identifiers unless the task explicitly includes a migration.

## UI/UX Boundary

- UI should make audit workflow state clear: import, mapping, validation, prescreen, filter, export.
- Long-running actions need loading, busy, success, and error states.
- Data tables use preview, pagination, or export paths controlled by the backend; never load complete GL/TB populations into the frontend.
- UI improvements must not move authoritative business rules out of Application/Domain/Infrastructure.

## Verification Commands

Preferred local commands:

```bash
dotnet restore src/JET/JET.slnx
dotnet build src/JET/JET.slnx --no-restore --nologo
dotnet test src/JET/tests/JET.Tests/JET.Tests.csproj --no-build --nologo
```

If the current environment cannot run them, say exactly which checks were skipped and why.

## File Map

- `docs/jet-guide.md`: deep domain, architecture, scale, provider, and workflow guidance.
- `docs/action-contract-manifest.md`: action names, payloads, responses, typed facade, step data outline.
- `docs/agent-harness.md`: cross-tool harness loop and rule hygiene.
- `docs/copilot-visualstudio-harness-spec.md`: Visual Studio Copilot setup and version notes.
- `docs/jet-template.html`: canonical WebView2 HTML shell and binding surface.
- `.github/copilot-instructions.md`: short repository-wide Copilot rules.
- `.github/instructions/`: path-specific Copilot guardrails.
- `.github/prompts/`: reusable Copilot workflows.
- `.github/agents/`: custom agents for Visual Studio 2026 18.4+ and compatible surfaces.
- `.github/skills/`: project skills for skill-capable agents.
