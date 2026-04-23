---
applyTo: "src/JET/JET/**/*.cs"
---

# JET CSharp Instructions

- Respect the `Host -> Bridge -> Application -> Domain -> Infrastructure` boundaries in `docs/jet-guide.md`.
- `Form1.cs` stays thin; do not move domain or application logic into WinForms host code.
- Do not edit `Form1.Designer.cs` or other designer-generated files unless the user explicitly asks.
- Provider-specific branching belongs in Infrastructure, not Application or frontend code.
- If a code change alters frontend-visible behavior or action contracts, update `docs/action-contract-manifest.md` in the same task.
- In non-Visual-Studio environments, do not assume `.NET` build/test is available unless the user explicitly asks.

## Taste Gate

Before completing a C# edit, verify:
- Does the change belong in the correct layer? (Domain has no I/O; Application has no provider branching; Infrastructure owns SQL dialects)
- Is each handler focused on a single rule/command/query? If a handler is growing large, split it.
- Would Linus call this "good taste"? Eliminate special-case branches in favor of uniform paths.
- Surgical check: does every changed line trace directly to the user's request? No drive-by refactoring.
