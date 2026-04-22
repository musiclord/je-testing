---
applyTo: "src/JET/JET/Bridge/**/*.cs,src/JET/JET/Application/Contracts/**/*.cs"
---

# JET Bridge Instructions

- Bridge code only owns JSON transport, request validation, and action dispatch.
- Do not put SQL, rule logic, or provider branching in the bridge layer.
- Keep action names in `<namespace>.<action>` form.
- Payloads and responses must stay plain JSON-friendly structures.
- Any action or payload change must be reflected in `docs/action-contract-manifest.md`.
- Prefer additive contract evolution over silent breaking changes.
