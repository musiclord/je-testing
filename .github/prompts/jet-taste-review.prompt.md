# JET Taste Review

Review recent changes against JET's engineering maxims.

Read first:

- #file:../../AGENTS.md
- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md

Focus on: ${input:review_scope:What files or changes should be reviewed?}

## Review Criteria (Linus-style)

### 1. Good Taste

- Are there special-case branches that could be eliminated by a uniform approach?
- Is each handler focused on one rule/command/query?
- Does the code follow existing patterns in the codebase?

### 2. Don't Break Userspace

- Were any action names, payload fields, or fixed bindings changed without a migration?
- Does `docs/action-contract-manifest.md` reflect the current state?
- Would existing frontend code still work after this change?

### 3. Simplify Before Extending

- Could this change reuse an existing action instead of creating a new one?
- Is there a simpler approach that was not considered?
- Was the contract manifest updated before code was written?

### 4. Paranoid About Simplicity

- Is there any "clever" abstraction that could be replaced by straightforward code?
- Is Bridge code doing more than JSON transport + dispatch?
- Is Form1 doing more than hosting WebView2?

### 5. Surgical Changes *(Extracted from: andrej-karpathy-skills)*

- Does every changed line trace directly to the user's request?
- Were any adjacent code, comments, or formatting "improved" without being asked?
- Were any pre-existing unrelated issues refactored as a side effect?
- Did the change create orphaned imports/variables? If so, were only those orphans cleaned up?

Return:

- Taste score (A/B/C/D) with rationale
- Specific violations found (by maxim number)
- Surgical change violations (lines that don't trace to the request)
- Suggested simplifications
