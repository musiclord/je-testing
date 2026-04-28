---
applyTo: "src/JET/JET/**/*.cs"
---

# JET CSharp Instructions

Read `docs/jet-guide.md` for durable architecture and `docs/action-contract-manifest.md` for frontend-visible contracts.

- `Form1.cs` stays thin; do not move domain or application logic into WinForms host code.
- `Bridge/*.cs` stays thin; it does not own SQL, file I/O, or business rules.
- Do not edit `Form1.Designer.cs` or other designer-generated files unless the user explicitly asks.
- Provider-specific branching belongs in Infrastructure, not Application or frontend code.
- V / R / Filter / Custom Scenario logic must execute as parameterized set-based SQL.
- SQLite is the local persistent provider; SQL Server is the large-data / cloud provider.
- If a code change alters frontend-visible behavior or action contracts, update `docs/action-contract-manifest.md` in the same task.
- Avoid unnecessary dependencies and speculative rewrites.

## Verification

Before completing a C# edit, verify:
- The changed code belongs in the correct layer.
- The action manifest is still accurate for frontend-visible behavior.
- Focused tests or a clear skipped-test reason are included before claiming completion.
