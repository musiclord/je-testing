# Cleanup Agent Context

Clean JET AI-agent customization files without changing application code.

Read first:

- #file:../../docs/agent-harness.md
- #file:../../AGENTS.md
- #file:../../.github/copilot-instructions.md
- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md

Scope: ${input:cleanup_scope:Which customization files or folders should be cleaned?}

Rules:

- Only edit `.github/agents`, `.github/instructions`, `.github/prompts`, and `.github/skills` unless explicitly asked.
- Keep customization files short and pointer-based.
- Remove stale roadmap, phase, personality-imitation, external skill summary, and deprecated demo row-fetch guidance.
- Do not duplicate long architecture sections or action contract tables from docs.
- Preserve non-negotiable JET rules: thin host, thin bridge, JetApi only, no frontend authoritative rules, no full GL/TB rows over Bridge, set-based SQL pushdown.

Return:

- Inventory of files found.
- Changed, removed, merged, and kept files.
- Conflict fixes.
- Source-of-truth alignment.
- Verification results, including `git diff --check`.
- Remaining risks.
