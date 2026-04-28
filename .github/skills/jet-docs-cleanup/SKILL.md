---
name: jet-docs-cleanup
description: Use when cleaning JET documentation and AI-agent context files while preserving the source-of-truth hierarchy.
---

# JET Docs Cleanup

Clean persistent guidance without creating new stale guidance.

## Applies When

- Editing `AGENTS.md`, `plan.md`, `docs/agent-harness.md`, `.github/copilot-instructions.md`, `.github/instructions`, `.github/prompts`, `.github/agents`, or `.github/skills`.
- Removing stale roadmap, phase, or demo-path guidance.
- Reconciling source-of-truth conflicts.

## Must Not Apply When

- The task primarily changes application behavior.
- The task needs new action contracts; use `jet-action-contract-review`.

## Read First

1. `docs/agent-harness.md`
2. `AGENTS.md`
3. `.github/copilot-instructions.md`
4. `docs/jet-guide.md`
5. `docs/action-contract-manifest.md`

## Checklist

- `docs/jet-guide.md` owns durable domain, architecture, scale, and audit workflow.
- `docs/action-contract-manifest.md` owns all action contracts.
- `docs/agent-harness.md` owns durable harness loop.
- `AGENTS.md` and `.github/copilot-instructions.md` stay short.
- `plan.md` stays temporary.
- No external skill repo summaries or personality imitation remain.

## Output

- Changed files.
- Removed or merged obsolete guidance.
- Conflicts fixed.
- `git diff --check` result.
