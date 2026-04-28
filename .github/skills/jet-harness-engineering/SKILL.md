---
name: jet-harness-engineering
description: Use when changing JET AI workflow surfaces such as AGENTS.md, docs/agent-harness.md, .github/agents, .github/instructions, .github/prompts, or .github/skills.
---

# JET Harness Engineering

Maintain JET's AI-agent customization surfaces without turning them into a second architecture manual.

## Applies When

- Updating `.github/agents`, `.github/instructions`, `.github/prompts`, or `.github/skills`.
- Cleaning stale agent guidance.
- Reconciling customization files with the source-of-truth hierarchy.
- Updating `AGENTS.md` or `docs/agent-harness.md` for persistent AI workflow changes.

## Must Not Apply When

- The task is application implementation.
- The task is only UI review, SQL pushdown review, or action contract review; use the narrower JET skill.
- The requested change would copy external skill content wholesale.

## Read Order

1. `docs/agent-harness.md`
2. `AGENTS.md`
3. `.github/copilot-instructions.md`
4. `docs/jet-guide.md`
5. `docs/action-contract-manifest.md`

## Checklist

- Keep customization files short and concrete.
- Point to authoritative docs instead of duplicating them.
- Remove roadmap, phase archive, and temporary plan content from persistent guidance.
- Remove personality imitation and external repo summaries.
- Keep verification-before-completion explicit.
- Run `git diff --check` for customization-only cleanup.

## Output

- Inventory of files reviewed.
- Changed / removed / merged / kept files.
- Conflicts fixed.
- Remaining risks.
