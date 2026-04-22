# JET Contract Drift Review

Audit JET for drift between the documented contract and the implemented one.

Read first:

- #file:../../AGENTS.md
- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md
- #file:../../docs/jet-template.html
- #file:../../src/JET/JET/Bridge/ActionDispatcher.cs
- #file:../../src/JET/JET/Application/Contracts/BridgeRequest.cs
- #file:../../src/JET/JET/Application/Contracts/BridgeResponse.cs

Focus on: ${input:drift_scope:Which area should be checked, or leave broad for a full audit?}

Review for:

- undocumented actions
- payload mismatch
- response mismatch
- fixed binding drift
- UI assumptions that are no longer true
- opportunities to simplify the contract before adding new code

Return findings first, ordered by severity, with file references when possible.
