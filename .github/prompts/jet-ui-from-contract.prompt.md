# JET UI From Contract

Design or implement JET UI only after reconciling the action contract.

Read first:

- #file:../../AGENTS.md
- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md
- #file:../../docs/jet-template.html
- #file:../../src/JET/JET/Bridge/ActionDispatcher.cs

Task: ${input:ui_goal:What screen, section, or UX improvement should be produced?}

Rules:

- Reuse existing actions whenever possible.
- If the task needs new backend data, stop and update `docs/action-contract-manifest.md` first.
- Preserve fixed `data-bind` identifiers and existing action names unless the task explicitly includes a migration.
- Improve hierarchy, readability, state feedback, and accessibility.
- Avoid decorative redesign that does not improve the audit workflow.
- Remember this HTML runs inside WebView2 and must cooperate with the C# bridge.

Deliver:

- Contract assumptions used
- Any manifest changes required
- UI structure changes
- State / loading / empty / error handling notes
