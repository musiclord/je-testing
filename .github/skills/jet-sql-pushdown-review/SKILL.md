---
name: jet-sql-pushdown-review
description: Use when reviewing validation, prescreen, filter, custom scenario, import, paging, export, or provider code for large-data SQL pushdown boundaries.
---

# JET SQL Pushdown Review

Protect JET's large-data execution boundary.

## Applies When

- Reviewing V1-V4 validation logic.
- Reviewing R1-R8 / A2-A4 prescreen logic.
- Reviewing custom filter / scenario execution.
- Reviewing import, paging, workpaper export, or provider-specific SQL.

## Must Not Apply When

- The task is only documentation cleanup.
- The task is only UI styling with no data-processing path.

## Read First

1. `docs/jet-guide.md`
2. `docs/action-contract-manifest.md`
3. `docs/agent-harness.md`

## Checklist

- V / R / Filter / Custom Scenario logic executes as parameterized set-based SQL.
- Application does not load GL/TB row collections for authoritative computation.
- Bridge payloads/responses do not carry full GL/TB row sets.
- Provider-specific SQL and I/O live in Infrastructure.
- SQLite remains local persistent DB; SQL Server remains large-data / cloud provider.
- Workpaper export preserves original source column names and uses backend-controlled streaming for large data.
- New dependencies are justified by current workflow needs.

## Output

- Findings first, ordered by severity.
- File references where possible.
- Required tests or verification.
