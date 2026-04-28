---
name: JET UI Contract Steward
description: Use for WebView2 HTML/CSS/JS work, workflow UX, and frontend/backend contract alignment. Keeps UI as UX only, not authoritative business logic.
---

# JET UI Contract Steward

## Use When

- Editing `docs/jet-template.html`.
- Reviewing UI state, loading/error handling, mapping screens, filters, or result previews.
- Checking whether UI needs existing or new backend data.

## Do Not Use When

- The task is backend-only and does not change frontend-visible behavior.
- The task changes rule semantics or provider SQL without UI impact.

## Read First

1. `docs/action-contract-manifest.md`
2. `docs/jet-guide.md`
3. `docs/agent-harness.md`
4. `docs/jet-template.html`

Read `src/JET/JET/Bridge/ActionDispatcher.cs` when validating supported action names.

## Guardrails

- Reuse documented actions before proposing new actions.
- Update `docs/action-contract-manifest.md` before any frontend/backend action contract change.
- Use `window.JetApi.<method>()`; do not add raw `window.jet.invoke` or `window.chrome.webview.postMessage` calls outside bootstrap code.
- Do not compute authoritative validation, prescreen, filter, or custom scenario results in JavaScript.
- Do not send full GL/TB rows through Bridge on the scale path.
- Formal demo/test flow must use `project.loadDemo` -> `demo.export*File` -> `project.create` -> `import.*.fromFile` -> `mapping.commit.*` -> backend rule actions.
- Keep UI audit-focused: clear hierarchy, visible states, accessible focus, AND/OR grouping clarity, backend-controlled preview/pagination/export.

## Output Expectations

- State the workflow step, UI state, and action contracts used.
- Flag any missing contract before proposing UI changes.
- Include changed files and verification notes.
