# Add Integration Test

Plan or implement a focused JET integration test.

Read first:

- #file:../../docs/jet-guide.md
- #file:../../docs/action-contract-manifest.md
- #file:../../docs/agent-harness.md
- #file:../../AGENTS.md
- #file:../../src/JET/tests/JET.Tests/JET.Tests.csproj

Target behavior: ${input:test_scope:What behavior or path needs integration coverage?}

Rules:

- Inspect existing tests under `src/JET/tests/JET.Tests/` before adding new files.
- Prefer the smallest test that locks the behavior.
- For demo/import behavior, use the formal file-based path: export file -> `import.*.fromFile` -> mapping commit -> backend action.
- Do not rely on row-based demo/import fallbacks for new integration coverage.
- Include verification commands and expected results.

Return:

- Existing coverage found.
- Proposed test file and scenario.
- Fixture/data setup.
- Assertions.
- Commands to run.
- Changed-files and verification report.
