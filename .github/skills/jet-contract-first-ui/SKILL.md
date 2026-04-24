---
name: jet-contract-first-ui
description: Use when changing JET HTML/CSS/JS, WebView2 bridge actions, workflow step UX, or frontend data needs. Read docs/action-contract-manifest.md first, reuse existing actions, and update the manifest before inventing new contracts.
---

# JET Contract-First UI

JET is not a free-form web UI project. It is a contract-bound WebView2 frontend on top of a thin C# bridge.

## Use This Skill When

- changing `docs/jet-template.html`
- redesigning workflow steps or screens
- adding frontend state that depends on backend data
- renaming or extending bridge actions
- adjusting payload or response shapes

## Mandatory Read Order

1. `AGENTS.md`
2. `docs/jet-guide.md`
3. `docs/action-contract-manifest.md`
4. `src/JET/JET/Bridge/ActionDispatcher.cs`

## Workflow

1. Identify the affected workflow step.
2. List the data the UI needs.
3. Map that need to existing actions.
4. If existing actions are not enough, update `docs/action-contract-manifest.md` first.
5. Only then edit the HTML/CSS/JS or the C# bridge/app code.

## Guardrails

- Do not invent action names casually.
- Do not change fixed `data-bind` surfaces casually.
- Do not move business logic into the frontend or bridge.
- Prefer the smallest contract change that satisfies the workflow.
- If the request is only visual polish, keep the contract untouched.

## Backend Access Rule

UI code must call backend through `window.JetApi.<method>()` only. Example:

```js
// ✅ Correct — typed facade, one per action
const result = await JetApi.validateRun();
renderValidationSummary(result);

const suggest = await JetApi.mappingAutoSuggest({ fields, columns });
```

Forbidden forms (except inside the bootstrap script itself):

```js
// ❌ Raw low-level bridge call
await window.jet.invoke('validate.run', {});

// ❌ Raw WebView2 postMessage
window.chrome.webview.postMessage({ action: 'validate.run' });

// ❌ Local reimplementation of authoritative rules
const result = computeValidation(); // there is no such function in the authoritative UI
```

When adding a new action: update `docs/action-contract-manifest.md` and `ActionDispatcher` first — the facade method will appear automatically on `window.JetApi` because `JetBridgeScriptFactory` derives it from `SupportedActions`.
