# JET Copilot Instructions

- Read `AGENTS.md` first. Treat it as the map; the detailed system of record lives in `docs/`.
- JET is a `.NET 10 + WinForms + WebView2 + HTML/CSS/JS + SQLite + SQL Server` audit tool, not a pure web app.
- Respect the `Host -> Bridge -> Application -> Domain -> Infrastructure` boundaries from `docs/jet-guide.md`.
- For Visual Studio Copilot, the primary repo control surfaces are `.github/copilot-instructions.md`, `.github/instructions/**/*.instructions.md`, `.github/prompts/*.prompt.md`, and `.github/agents/*.agent.md`.
- `Form1.cs` stays thin. Do not put business logic in WinForms host code.
- Do not edit `Form1.Designer.cs` or other designer-generated files unless the user explicitly asks.
- Before changing UI, bridge actions, or payloads, update `docs/action-contract-manifest.md`.
- Frontend should call documented actions only. Do not casually rename action names, payload fields, or fixed `data-bind` identifiers.
- Keep `Bridge/*.cs` thin: JSON transport and dispatch only. No SQL or rule logic there.
- Provider-specific differences belong in Infrastructure, not in Application or frontend code.
- In non-Visual-Studio environments, avoid assuming `.NET` build/test is available unless the user explicitly asks. In Visual Studio workflows, use the documented build/test loop from `docs/jet-guide.md`.
- When behavior or contracts change, update the relevant docs, prompts, instructions, or skills in the same task.
