---
applyTo: "src/JET/JET/Bridge/**/*.cs,src/JET/JET/Application/Contracts/**/*.cs"
---

# JET Bridge Instructions

Read `docs/action-contract-manifest.md` before changing bridge actions, payloads, responses, or generated facade behavior.

- Bridge code owns JSON transport, request validation, and action dispatch only.
- Do not put SQL, rule logic, file import/export logic, or provider branching in Bridge.
- Keep action names in documented `<namespace>.<action>` form.
- Payloads and responses must stay JSON-friendly and must not carry full GL/TB row sets on the scale path.
- Update `docs/action-contract-manifest.md` before changing any action name, payload shape, or response shape.
- Keep `window.JetApi` generated from supported actions; do not hand-maintain a second facade list.

## Verification

- Confirm changed actions match `docs/action-contract-manifest.md`.
- Run focused build/tests when bridge behavior changes.
- For docs-only customization cleanup, do not run application tests unless application code changed.
