# JET Current Work Plan

This file is a temporary work plan, not a source of truth. Durable rules live in `docs/jet-guide.md` and action contracts live in `docs/action-contract-manifest.md`.

## Current State

- Backend support exists for deterministic demo export files, `import.*.fromFile` streaming ingest, GL/TB target projection, SQL-backed validation, prescreen summaries, filter preview, and result paging.
- Tests exist under `src/JET/tests/JET.Tests`.
- `docs/jet-template.html` still needs a formal UI/backend boundary pass: it references deprecated row-based demo/import paths and keeps local JavaScript validation, prescreen, and scenario evaluation helpers.
- This plan should track only the next active cleanup or implementation slice. Historical phase details belong in git history, not here.

## Next Phase

Formal UI/backend boundary alignment:

1. Confirm required UI data against `docs/action-contract-manifest.md` before editing UI or bridge code.
2. Move demo/test flow to `project.loadDemo` -> `demo.export*File` -> `project.create` -> `import.*.fromFile` -> `mapping.commit.*` -> `validate.run` / `prescreen.run` / `filter.preview`.
3. Define or reuse a host-controlled file path contract for user uploads so production import does not send GL/TB rows through the bridge.
4. Remove authoritative validation, prescreen, and filter computation from frontend JavaScript.
5. Use `resultRef`, preview limits, and backend-controlled paging/export for large result sets.

## Open Gaps

- Formal UI/demo path still needs to stop using `demo.fetch*Rows` and deprecated row-based `import.*` actions.
- User upload flow still needs a production-safe host file path contract.
- `export.workpaper` still needs a backend streaming writer path.
- R7/R8/A2/A3/A4 prescreen implementation status needs review before claiming full rule coverage.
- An end-to-end test should cover demo export -> fromFile ingest -> mapping commit -> validation/prescreen/filter -> paging.

## Definition of Done

- Source-of-truth docs are updated before any contract or workflow change.
- Patches are small and scoped to the requested slice.
- Behavior changes include focused tests or an explicit explanation of the missing harness.
- Build/test/verification commands are run before completion when the environment supports them.
- The final report states what changed, what was verified, and what remains unverified.

## Non-goals

- Do not rewrite `Form1.cs`, `Form1.Designer.cs`, or generated designer files.
- Do not introduce a SPA framework or heavy frontend dependency.
- Do not remove deprecated backend actions until a separate breaking-change cleanup is planned.
- Do not treat this plan as durable architecture guidance.
- Do not add historical archives or long-term system rules to this file.

## Verification Commands

Use the smallest command set that fits the change:

```bash
dotnet restore src/JET/JET.slnx
dotnet build src/JET/JET.slnx --no-restore --nologo
dotnet test src/JET/tests/JET.Tests/JET.Tests.csproj --no-build --nologo
```

For documentation-only changes, also confirm:

- No application code changed.
- The action manifest no longer recommends deprecated row-based actions for the formal demo pipeline.
- Remaining UI/manifest drift is reported instead of silently papered over.

## Archive Note

Completed phase logs and old implementation history were intentionally removed from this file. Use git history and the durable docs for context.
