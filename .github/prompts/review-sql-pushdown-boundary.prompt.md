# Review SQL Pushdown Boundary

Review whether a JET change respects large-data execution boundaries.

Read first:

- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md
- #file:../../docs/agent-harness.md
- #file:../../AGENTS.md

Review scope: ${input:review_scope:Which files, PR, or workflow path should be reviewed?}

Check for:

- V / R / Filter / Custom Scenario logic running outside parameterized set-based SQL.
- GL/TB row collections loaded into Application memory for authoritative computation.
- Bridge payloads or responses carrying full GL/TB populations.
- Provider-specific branching outside Infrastructure.
- Frontend JavaScript computing validation, prescreen, filter, or scenario results.
- Workpaper export that loses original source column names or loads large result sets in memory.
- New dependencies that are not justified by the current workflow.

Return:

- Findings first, ordered by severity.
- File references where possible.
- Required contract or docs updates.
- Verification performed or skipped with reasons.
