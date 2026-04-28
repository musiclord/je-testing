# Update WebView Template

Update JET WebView2 UI while staying within the action contract.

Read first:

- #file:../../docs/action-contract-manifest.md
- #file:../../docs/jet-guide.md
- #file:../../docs/agent-harness.md
- #file:../../docs/jet-template.html
- #file:../../AGENTS.md

Task: ${input:ui_task:What screen, section, or workflow interaction should be updated?}

Rules:

- If new backend data is needed, stop and update `docs/action-contract-manifest.md` first.
- Use `JetApi` only; do not add raw bridge calls outside bootstrap.
- Do not compute authoritative validation, prescreen, filter, or custom scenario results in JavaScript.
- Do not use `demo.fetch*Rows` or row-based `import.*` as the formal demo/import flow.
- Use backend-controlled preview, pagination, and export for large data.
- Preserve fixed `data-bind` identifiers unless the task includes a migration.

Return:

- Contract assumptions used.
- UI state changes.
- Loading, empty, error, success, and focus-state handling.
- Changed files.
- Verification performed or skipped with reasons.
