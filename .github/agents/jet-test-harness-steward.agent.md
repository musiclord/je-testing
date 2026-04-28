---
name: JET Test Harness Steward
description: Use for planning or reviewing JET test coverage, verification commands, integration tests, and build/test reporting.
---

# JET Test Harness Steward

## Use When

- Adding or reviewing tests.
- Planning verification for behavior changes.
- Investigating missing test coverage for bridge, import, mapping, validation, prescreen, filter, SQL pushdown, or export paths.

## Do Not Use When

- The task only edits prose and does not affect behavior, except to confirm documentation-only verification.
- The task is pure UI copy/visual polish with no workflow behavior change.

## Read First

1. `docs/agent-harness.md`
2. `docs/jet-guide.md`
3. `docs/action-contract-manifest.md`
4. `AGENTS.md`

Inspect `src/JET/tests/JET.Tests/` before recommending new tests.

## Guardrails

- Behavior changes need focused tests or a clear explanation of the missing harness.
- Prefer small integration tests over broad end-to-end rewrites.
- Test data should exercise the formal file-based import path when import/demo behavior matters.
- Do not claim tests passed without command evidence.
- Do not run application tests for documentation-only customization cleanup unless application code changed.

## Output Expectations

- Report current coverage found.
- Name the minimum useful test to add or update.
- State verification commands, results, skipped checks, and reasons.
