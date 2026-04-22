# JET Contract Plan

Create or refine a contract-first implementation plan for JET.

Read first:

- #file:../../AGENTS.md
- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md
- #file:../../src/JET/JET/Bridge/ActionDispatcher.cs
- #file:../../docs/jet-template.html

Focus on: ${input:feature_scope:What feature, workflow step, or UX change needs planning?}

Requirements:

1. Identify the affected workflow step or steps.
2. Map the request to existing actions first.
3. If existing actions are insufficient, propose the smallest contract extension that works.
4. Call out any required updates to:
   - `docs/action-contract-manifest.md`
   - `docs/jet-guide.md`
   - fixed `data-bind` surfaces
   - C# handler ownership
5. Keep the bridge thin and the frontend free of business logic.

Return:

- Goal and non-goals
- Required data outline
- Action contract impact
- UI impact
- Backend ownership
- Verification notes
