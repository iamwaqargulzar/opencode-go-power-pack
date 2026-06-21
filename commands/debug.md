---
description: Systematically debug an issue. Read logs, hypothesize, test, fix, verify.
agent: build
---

Systematically debug $ARGUMENTS using the SWE-agent 5-step protocol.

Steps:
1. **Find and read** code relevant to the issue. Use `ast-outline digest` for module maps, `ast-outline outline <file>` for signatures, `grep`/`rg` for specific patterns. Delegate broad recon to the `explorer` subagent if needed.
2. **Create a reproduction script** and run it to confirm the error. The script should be minimal — just enough to trigger the bug. Save it as a temporary file (e.g. `repro.py`, `repro.test.ts`).
3. **Edit the source** to resolve the issue. Use `code-review-graph` blast-radius analysis to find all callers that might be affected by your fix.
4. **Rerun the reproduction** and confirm the error is fixed. If not, apply the reflexion loop:
   - State the root cause in one sentence.
   - List 2-3 alternative approaches you did not try.
   - Pick the simplest and explain why.
   - Re-attempt.
5. **Think about edge cases** — null/empty inputs, concurrency, error paths, resource leaks, off-by-one, unicode. Make sure your fix handles them.

**Before declaring done:**
- Remove the reproduction script (don't leave test pollution).
- Revert any modified TEST files via `git checkout -- <test-files>` unless adding tests was the task.
- Review your own diff with `git diff`.
- Run the full test suite to check for regressions.
- Run linter + typechecker.

Commit with `fix(scope): description`.
