---
name: jet-action-contract-review
description: Use when reviewing or changing JET frontend/WebView2/C# action names, payloads, response shapes, typed facade behavior, or workflow data needs.
---

# JET Action Contract Review

Keep `docs/action-contract-manifest.md` as the only action contract source of truth.

## Applies When

- Adding, renaming, or changing an action.
- Changing payload or response shape.
- Updating UI workflow data needs.
- Checking drift between `ActionDispatcher`, frontend calls, and the manifest.

## Must Not Apply When

- The task is only internal C# refactoring with no frontend-visible behavior change.
- The task is only visual UI polish inside existing actions.

## Read First

1. `docs/action-contract-manifest.md`
2. `docs/jet-guide.md`
3. `docs/agent-harness.md`
4. `src/JET/JET/Bridge/ActionDispatcher.cs`

## Checklist

- Existing actions were checked before proposing new ones.
- Contract changes are documented before implementation.
- `window.JetApi.<method>()` remains the frontend call path.
- Bridge remains JSON transport and dispatch only.
- Scale path does not send full GL/TB rows over Bridge.
- Formal demo/test flow uses `demo.export*File` and `import.*.fromFile`, not `demo.fetch*Rows`.
- Deprecated actions are identified as legacy fallback only.

## Output

- Contract drift or proposed delta.
- Affected workflow step.
- Owning layer/files.
- Verification expectations.
