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

## UI Reasoning Protocol *(Extracted from: ui-ux-pro-max)*

Before making UI changes, work through this reasoning order:
1. **Information hierarchy** — What data does the user need most? Make it visually dominant.
2. **Contrast & readability** — Does text meet minimum contrast? Are interactive elements distinguishable from static content?
3. **Interaction feedback** — Does every clickable element have a visible response (hover/focus/active state)?
4. **Consistency** — Do similar elements look and behave the same across all workflow steps?
5. **Simplicity** — Can any visual element be removed without losing information or function?

## Taste Gate

Before completing a frontend edit, verify:
- Does this UI change rely only on documented actions? If it assumes a backend capability that doesn't exist, stop and update the contract manifest.
- Is business logic leaking into HTML event handlers? If yes, move it to Application handlers.
- Is the change simplifying the UI or adding complexity? Prefer the simpler path.
- UI delivery check: Does the change maintain consistent visual hierarchy, readable contrast, and interaction feedback across all affected workflow steps?
- Surgical check: does every changed line trace directly to the user's request? No drive-by refactoring.
