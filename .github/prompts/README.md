# JET Prompt Files

These prompt files are repeatable JET workflows for GitHub Copilot in VS Code or Visual Studio. Each prompt should read the authoritative docs, keep scope narrow, and report verification evidence.

- `/cleanup-agent-context` for cleaning `.github/agents`, `.github/instructions`, `.github/prompts`, and `.github/skills`
- `/update-action-contract` for planning or reviewing frontend/WebView2/C# action contract changes
- `/update-webview-template` for WebView2 UI changes constrained by the manifest
- `/add-integration-test` for focused integration test planning
- `/review-sql-pushdown-boundary` for checking large-data SQL pushdown and Bridge payload boundaries

For Visual Studio-specific guidance, see `docs/copilot-visualstudio-harness-spec.md`.

Do not use prompt files to bypass `docs/jet-guide.md`, `docs/action-contract-manifest.md`, `docs/agent-harness.md`, `AGENTS.md`, or `.github/copilot-instructions.md`.
