---
applyTo: "docs/**/*.html,docs/**/*.css,docs/**/*.js"
---

# JET Frontend Instructions

- JET frontend runs inside WebView2; it is not a standalone SPA.
- Before changing UI, read `docs/action-contract-manifest.md`, then `docs/jet-guide.md`.
- Reuse documented actions before proposing new ones.
- Do not rename action names, payload fields, or fixed `data-bind` identifiers unless the task explicitly includes a migration.
- If the UI needs new backend data, update `docs/action-contract-manifest.md` before editing code.
- Frontend is UX only: no authoritative validation, prescreen, filter, or custom scenario computation in JavaScript.
- Do not send full GL/TB rows over Bridge on the scale path.
- Formal demo/test flow uses `project.loadDemo` -> `demo.export*File` -> `project.create` -> `import.*.fromFile` -> `mapping.commit.*` -> backend rule actions.
- Prefer clear hierarchy, accessibility, focus states, loading/error states, and audit workflow clarity over cosmetic churn.

## Backend Calls Go Through `JetApi`

- UI code calls backend only via `window.JetApi.<method>()`.
- Do **not** write `window.jet.invoke('xxx', payload)` or `window.chrome.webview.postMessage(...)` in UI code. Only the bootstrap script itself may use the low-level APIs.
- Method name = action name camelCased per `.`-segment (e.g. `validate.run` → `JetApi.validateRun`, `mapping.commit.gl` → `JetApi.mappingCommitGl`).
- Authoritative rule actions (`validate.run`, `prescreen.run`, `filter.preview`, `filter.commit`) have no local fallback; errors from the bridge propagate to the caller. Do not reimplement these rules in JS.

## UI Checklist

- Field mapping distinguishes source column, standard field, and mapping status.
- Advanced filters show AND/OR grouping clearly.
- Long-running imports, validation, prescreen, filters, and exports have busy/error/success states.
- Tables use backend-controlled preview, pagination, or export.
- Workpaper output preserves original source column names for auditors.

## Verification

Before completing a frontend edit, verify:
- Does this UI change rely only on documented actions? If it assumes a backend capability that doesn't exist, stop and update the contract manifest.
- Is authoritative business logic leaking into JavaScript? If yes, move it to backend actions.
- Are deprecated row-based demo/import actions used as current flow? If yes, replace with file-based import.
- Include changed files and verification results before claiming completion.
