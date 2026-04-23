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

## Spec Self-Review *(Extracted from: superpowers)*

After writing the plan, check with fresh eyes:
1. **Placeholder scan**: Any "TBD", "TODO", or vague requirements? Fix them now.
2. **Internal consistency**: Do the proposed contract changes match the UI needs? Does the layer assignment align with architecture boundaries?
3. **Scope check**: Is this focused enough for one implementation cycle, or should it be decomposed?
4. **Ambiguity check**: Could any requirement be interpreted two ways? Pick one and make it explicit.
5. **YAGNI check**: Is every proposed change necessary for the current workflow step? Remove anything speculative.
