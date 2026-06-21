---
description: Write and run tests using TDD. Verify all pass before done.
agent: build
---

Write and run tests for $ARGUMENTS using TDD (RED-GREEN-REFACTOR).

Steps:
1. **RED** — Write failing tests first. Run them to confirm they fail for the *right* reason (not a syntax error or import error, but the actual missing behavior).
2. **GREEN** — Implement the minimum code to make the tests pass. Run the tests. Iterate until green.
3. **REFACTOR** — Clean up the implementation while keeping tests green. Run tests after each refactor step.
4. Run the *full* test suite (not just your new tests) to check for regressions.
5. Run the linter and typechecker.
6. **Verification before completion** — all tests pass, lint clean, types clean.

If any test fails, apply the reflexion loop:
1. State the root cause in one sentence.
2. List 2-3 alternative approaches you did not try.
3. Pick the simplest and explain why.
4. Re-attempt.

If the repo has property-based testing (`hypothesis` for Python, `fast-check` for TS/JS), write property tests in addition to example tests. Extract properties from the spec (EARS requirements if they exist).

Commit with `test(scope): description`.
