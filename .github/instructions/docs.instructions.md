---
applyTo: "README.md,docs/**/*.md,AGENTS.md,.github/**/*.md"
---

# JET Documentation Instructions

- `AGENTS.md` is the map; `docs/` is the system of record.
- Keep repository-wide instructions concise and pointer-based.
- Persistent AI workflow guidance belongs in the existing files:
  - `AGENTS.md`
  - `docs/jet-guide.md`
  - `docs/action-contract-manifest.md`
  - `docs/agent-harness.md`
  - `.github/instructions/`
  - `.github/prompts/`
- Avoid creating throwaway docs when an existing system-of-record file should be updated instead.

## Taste Gate

Before completing a docs edit, verify:
- Does this content belong in an existing system-of-record file? If yes, update that file instead of creating a new one.
- Does this change invalidate or contradict anything in `docs/jet-guide.md` or `docs/action-contract-manifest.md`? If yes, fix the contradiction.
- Surgical check: does every changed line trace directly to the user's request? No drive-by edits to unrelated sections.
