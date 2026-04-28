# JET Copilot Instructions

Read `AGENTS.md`, `docs/jet-guide.md`, and `docs/action-contract-manifest.md` before changing architecture, UI workflow, bridge actions, or rule behavior.

## Hard Rules

- `Form1.cs` must stay a thin WebView2 host.
- WebView2 Bridge code only transports JSON and dispatches actions.
- Frontend code must call backend only through the generated `JetApi` facade.
- Frontend code must not compute authoritative validation, prescreen, filter, or custom scenario results.
- Do not send full GL/TB rows over the Bridge on the scale path.
- Use parameterized SQL for all user-controlled values.
- V / R / Filter / Custom Scenario logic must execute as set-based SQL in the database.
- Provider-specific SQL and I/O differences belong in Infrastructure, not Application or frontend code.
- Do not edit generated `Designer.cs` files unless explicitly required.
- Do not introduce heavy dependencies without clear justification.
- Update `docs/action-contract-manifest.md` before changing frontend/backend action names, payloads, or response shapes.
- Keep patches scoped; do not perform speculative rewrites or unrelated cleanup.
- Run verification commands before claiming completion, or state clearly why they were skipped.

## Source Boundaries

- `docs/jet-guide.md` owns durable domain, architecture, scale, and audit workflow guidance.
- `docs/action-contract-manifest.md` is the only action contract source of truth.
- `plan.md` is temporary planning only and must not become an architecture archive.

## Verification

Preferred commands:

```bash
dotnet restore src/JET/JET.slnx
dotnet build src/JET/JET.slnx --no-restore --nologo
dotnet test src/JET/tests/JET.Tests/JET.Tests.csproj --no-build --nologo
```

For documentation-only changes, confirm that no application code changed and report any remaining doc/action/UI drift.
