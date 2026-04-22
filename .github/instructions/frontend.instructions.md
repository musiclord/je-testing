---
applyTo: "docs/**/*.html,docs/**/*.css,docs/**/*.js"
---

# JET Frontend Instructions

- JET frontend runs inside `WebView2`; it is not a standalone SPA.
- Before changing UI, read `docs/action-contract-manifest.md` and `docs/jet-guide.md`.
- Reuse documented actions before proposing new ones.
- Do not rename action names, payload fields, or fixed `data-bind` identifiers casually.
- If the UI needs new backend data, update `docs/action-contract-manifest.md` before editing code.
- Keep business logic out of HTML event handlers when it belongs in C# Application handlers.
- Prefer clearer hierarchy, accessibility, and workflow clarity over cosmetic churn.
