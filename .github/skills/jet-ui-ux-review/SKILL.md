---
name: jet-ui-ux-review
description: Use when reviewing JET WebView2 UI/UX clarity, states, accessibility, mapping/filter screens, and audit workflow usability.
---

# JET UI/UX Review

Review UI experience without changing JET's data-processing or business-rule boundaries.

## Applies When

- Reviewing `docs/jet-template.html`.
- Checking import, mapping, validation, prescreen, filter, or export UI states.
- Improving clarity, accessibility, focus states, and interaction feedback.

## Must Not Apply When

- The task changes backend action contracts; use `jet-action-contract-review`.
- The task changes rule semantics or SQL execution; use `jet-sql-pushdown-review`.
- The task asks for decorative redesign, landing page patterns, or a new frontend framework.

## Read First

1. `docs/action-contract-manifest.md`
2. `docs/jet-guide.md`
3. `docs/agent-harness.md`
4. `docs/jet-template.html`

## Checklist

- Long-running actions have loading, busy, success, and error states.
- Field mapping distinguishes source column, standard field, and mapping status.
- Advanced filters show AND / OR grouping clearly.
- Clickable elements have visible affordance and keyboard focus.
- Tables use backend-controlled preview, pagination, or export.
- Frontend does not compute authoritative validation, prescreen, filter, or custom scenario results.
- Formal demo/import flow does not rely on deprecated row-based actions.

## Output

- UI findings by severity.
- Contract assumptions used.
- Any required manifest changes before UI implementation.
- Verification performed or skipped.
