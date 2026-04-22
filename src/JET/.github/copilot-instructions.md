# JET Solution Instructions

- If this folder is opened as the workspace root, first read `../../AGENTS.md`, `../../docs/jet-guide.md`, and `../../docs/action-contract-manifest.md`.
- Keep the WinForms host thin and the WebView2 bridge thinner.
- Before changing any frontend-visible action or payload, update the contract manifest first.
- Do not edit designer-generated files unless the user explicitly asks.
- In non-Visual-Studio environments, do not assume `.NET` build/test is available.
