---
name: custom-submit-time-self-review
description: Use before declaring done or submitting a patch. Enforces SWE-agent's SUBMIT_REVIEW protocol: re-run reproduction, remove repro scripts, revert test edits, review own diff. Trigger on: submit, done, complete, final, review diff, cleanup, revert, reproduction script, test pollution.
---

# Submit-Time Self-Review

## When to use

Immediately before declaring a task done or submitting a patch. This is the final gate — the last thing you do before saying "done."

## The protocol

### 1. Re-run the reproduction (if you changed anything)
If you created a reproduction script during debugging:
- Run it one final time.
- Confirm the error is still fixed.
- If it fails, you broke something — go back and fix it.

### 2. Remove reproduction scripts
Reproduction scripts are test pollution. They should NOT be committed.

```bash
# Remove repro scripts you created
rm -f repro.py repro.js repro.test.ts reproduce.go
```

If you need to keep a test, move it to the proper test directory with a real test name. Don't leave `repro.py` in the repo root.

### 3. Revert modified TEST files
If you modified existing test files during debugging (e.g. added print statements, commented out tests, changed assertions):
```bash
git checkout -- <test-files>
```
Unless adding tests was the task, revert all test file modifications. This prevents accidental test weakening.

### 4. Review your own diff
```bash
git diff
# or for staged changes:
git diff --staged
```

Check every changed line:
- **Is each change related to the task?** No unrelated refactoring, formatting changes, or "while I was here" edits.
- **Is there debug code left in?** Remove `console.log`, `print`, `debugger`, breakpoints, commented-out code.
- **Is there trailing whitespace?** Remove it.
- **Are there changes to formatting that aren't related to the task?** Revert them.
- **Does the commit message follow conventional commits?** `type(scope): description`.

### 5. Run the full quality gate
```bash
# Linter
npm run lint  # or: ruff check . / golangci-lint run / etc.

# Typechecker
npx tsc --noEmit  # or: mypy . / pyright / etc.

# Tests
npm test  # or: pytest / go test ./... / etc.
```

ALL must pass. If any fails, fix it and re-verify. Do not report done until all checks pass.

### 6. Confirm the original task is addressed
Re-read the original task description. Does your diff actually address it?

- Not just "I made changes" — but "the task is actually done."
- If the task was "fix the login bug," is the login bug actually fixed? (Not just "I changed some code in auth.py".)
- If the task was "add a dark mode toggle," is the dark mode toggle actually working? (Not just "I added a CSS variable.")

## Output

```
## Submit-Time Self-Review

- [ ] Reproduction re-run: PASS (or N/A — no repro script)
- [ ] Reproduction scripts removed: YES
- [ ] Test files reverted: YES (or N/A — no test files modified)
- [ ] Diff reviewed: clean (no debug code, no unrelated changes)
- [ ] Linter: PASS
- [ ] Typechecker: PASS
- [ ] Tests: PASS (N passed, 0 failed)
- [ ] Original task addressed: YES — <one sentence confirming>

Ready to commit.
```

## Anti-patterns

- **Don't skip the diff review.** "I know what I changed" is not a review. `git diff` and actually read it.
- **Don't leave repro scripts.** "I might need it again" — if you do, you can recreate it. Don't pollute the repo.
- **Don't keep test modifications.** If you weakened a test to make it pass, that's a bug, not a fix.
- **Don't declare done with failing tests.** "Mostly works" is not done. Fix the failing tests or report why they can't be fixed.
