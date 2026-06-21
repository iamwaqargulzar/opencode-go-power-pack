---
name: custom-test-first-verification
description: Use when implementing a feature or fixing a bug. Enforces test-first (TDD) and verification-before-completion. Trigger on: test, TDD, verify, verification, done, complete, lint, typecheck, passing.
---

# Test-First Verification

## TDD protocol (RED-GREEN-REFACTOR)

1. **RED** — Write a failing test first.
   - The test should fail for the *right* reason (missing behavior, not syntax error or import error).
   - Run it. Confirm it fails.
2. **GREEN** — Implement the minimum code to make the test pass.
   - Run the test. Iterate until green.
3. **REFACTOR** — Clean up the implementation while keeping tests green.
   - Run tests after *each* refactor step. If red, revert and re-plan.

## Verification before completion

"'Seems right' is never sufficient." Before reporting a task done:

1. **Run the linter** — `eslint`, `biome`, `ruff`, `golangci-lint`, etc. Fix any errors.
2. **Run the typechecker** — `tsc`, `mypy`, `pyright`, etc. Fix any errors.
3. **Run the full test suite** — not just your new tests. Check for regressions.
4. **Review your own diff** — `git diff`. Check every changed line.
5. **Confirm the original task is addressed** — not just "I made changes", but "the task is actually done".

## If any check fails
- Fix it and re-verify. Do not report done until all checks pass.
- If a check is inapplicable (e.g. no tests exist), state that explicitly.

## Property-based testing (for features with specs)

If the task has a spec (EARS requirements in `docs/specs/` or `.speckit/`):
- Extract properties from the spec.
- Use `hypothesis` (Python) or `fast-check` (TS/JS) to generate hundreds of random test cases.
- Run them. If a property fails, the framework "shrinks" to find the minimal counter-example.
- Fix the implementation, the test, or the spec — whichever is wrong.

## Cleanup before done
- Remove reproduction scripts (don't leave test pollution).
- Revert any modified TEST files via `git checkout -- <test-files>` unless adding tests was the task.
- Remove debug code (`console.log`, `print`, `debugger`, breakpoints).
