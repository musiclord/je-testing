---
name: jet-harness-engineering
description: Use when changing JET's AI workflow surfaces such as AGENTS.md, docs/agent-harness.md, docs/copilot-visualstudio-harness-spec.md, .github/instructions, .github/prompts, .github/agents, or .github/skills. Keeps the repo aligned with Visual Studio Copilot support and contract-first development.
---

# JET Harness Engineering

This skill is for maintaining the AI operating framework of the JET repository.

## Use This Skill When

- updating Copilot customization files
- adding or revising prompt files
- adding or revising custom agents
- changing project skills
- refining AGENTS.md or system-of-record docs for agent workflows
- reconciling differences between Visual Studio, VS Code, Codex, and Copilot CLI behavior

## Read Order

1. `AGENTS.md`
2. `docs/agent-harness.md`
3. `docs/copilot-visualstudio-harness-spec.md`
4. `docs/action-contract-manifest.md`
5. `.github/copilot-instructions.md`

## Key Rules

- For Visual Studio Copilot, treat repository instructions and path-specific instructions as the baseline control surface.
- Use prompt files for repeatable workflows.
- Use `.github/agents/*.agent.md` for Visual Studio 2026 18.4+ specialized agent personas.
- Treat `.github/skills/` as a useful layer, but not the only layer.
- Keep `AGENTS.md` short and cross-tool.
- Put durable detail in `docs/`.
- If you add a new AI workflow file, make it clear which tool is expected to consume it.
