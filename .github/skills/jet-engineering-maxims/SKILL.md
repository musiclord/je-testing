---
name: jet-engineering-maxims
description: Use when reviewing code quality, planning architecture, or making design decisions in JET. Contains the project's non-negotiable engineering principles derived from Linus Torvalds-style critical thinking and Andrej Karpathy's LLM coding observations.
---

# JET Engineering Maxims

These are JET's non-negotiable engineering principles. They apply to every change, regardless of scope.

## The Five Maxims

### 1. Good Taste — 消除特殊分支

- Uniform paths over special cases
- One handler per rule, one responsibility per layer
- Repository interface is singular; provider variation stays in Infrastructure
- If Application code branches on provider type, it's bad taste

### 2. Don't Break Userspace — 不破壞已有契約

- Action names, payload shapes, and fixed bindings are stable contracts
- Contract evolution is additive only
- Designer-generated files are untouchable unless explicitly requested
- Every contract change must be reflected in `docs/action-contract-manifest.md`

### 3. Simplify Before Extending — 先簡化，再擴展

- Reuse existing actions before inventing new ones
- Update contract manifest before writing code
- Don't create throwaway files when existing docs should be updated
- If the code looks complex, step back and ask "can this be simpler?"

### 4. Paranoid About Simplicity — 偏執地追求簡單

- Bridge: JSON transport + dispatch only
- Form1: WebView2 host only
- Choose the dumbest-but-clearest implementation
- If you need a "clever" abstraction, stop and reconsider

### 5. Surgical Changes — 只動該動的 *(Extracted from: andrej-karpathy-skills)*

- Every changed line must trace directly to the user's request
- Don't "improve" adjacent code, comments, or formatting uninvited
- Don't refactor things that aren't broken
- Match existing style, even if you'd do it differently
- Clean up orphans YOUR changes created; don't delete pre-existing dead code unless asked

## How to Apply

Before any code edit:
1. Which maxim does this change serve?
2. Which maxim might this change violate?
3. Is there a simpler alternative?

After any code edit:
1. Would the `/jet-taste-review` prompt flag anything?
2. Is the contract manifest still accurate?
3. Would a new contributor understand this without explanation?
