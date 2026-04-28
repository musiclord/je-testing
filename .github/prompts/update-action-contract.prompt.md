# Update Action Contract

Plan or review a frontend/WebView2/C# action contract change.

Read first:

- #file:../../docs/action-contract-manifest.md
- #file:../../docs/jet-guide.md
- #file:../../docs/agent-harness.md
- #file:../../AGENTS.md
- #file:../../src/JET/JET/Bridge/ActionDispatcher.cs

Scope: ${input:contract_scope:Which workflow step, action, payload, or response shape is changing?}

Rules:

- Reuse existing actions before proposing new ones.
- Update `docs/action-contract-manifest.md` before UI or backend code changes.
- Keep Bridge thin; business logic belongs outside Bridge.
- Frontend uses `window.JetApi.<method>()` only.
- Do not make deprecated row-based demo/import actions part of the formal flow.
- Do not introduce full GL/TB row payloads on the scale path.

Return:

- Affected workflow step.
- Existing actions that can be reused.
- Minimal contract delta, if any.
- Owning layer and files to change.
- Tests or verification commands required.
- Changed-files and verification report expectations.
