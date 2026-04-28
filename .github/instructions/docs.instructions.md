---
applyTo: "README.md,docs/**/*.md,AGENTS.md,.github/**/*.md"
---

# JET Documentation Instructions

Follow this source-of-truth order:

1. `docs/jet-guide.md`
2. `docs/action-contract-manifest.md`
3. `docs/agent-harness.md`
4. `AGENTS.md`
5. `.github/copilot-instructions.md`
6. `plan.md` as temporary current plan only.

- Keep repository-wide instructions concise and pointer-based.
- Do not duplicate long architecture explanations from `docs/jet-guide.md`.
- Do not duplicate action contract tables from `docs/action-contract-manifest.md`.
- Do not preserve deprecated demo row-fetch paths as current workflow.
- Do not copy external skill text or personality-imitation instructions into repo guidance.
- Avoid creating throwaway docs when an existing source-of-truth file should be updated instead.

## Verification

Before completing a docs edit, verify:
- Does this content belong in an existing system-of-record file? If yes, update that file instead of creating a new one.
- Does this change contradict `docs/jet-guide.md`, `docs/action-contract-manifest.md`, or `docs/agent-harness.md`?
- Run `git diff --check` for documentation/customization-only changes.
