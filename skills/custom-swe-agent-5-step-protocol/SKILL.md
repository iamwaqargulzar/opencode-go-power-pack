---
name: custom-swe-agent-5-step-protocol
description: Use for bug fixes and issue resolution. Enforces the SWE-agent 5-step protocol: find→reproduce→fix→verify→edge-cases. Proven on SWE-bench. Trigger on: bug, fix, issue, defect, reproduce, reproduction, verify, edge case, SWE-agent, debug.
---

# SWE-Agent 5-Step Protocol

## When to use

When fixing a bug or resolving a GitHub issue. This protocol produced SWE-bench state-of-the-art results.

## The 5 steps

### Step 1: Find and read
Find and read the code relevant to the issue description.

- Use `ast-outline digest` for a module map.
- Use `grep` / `rg` to search for keywords from the issue.
- Use `code-review-graph` to trace dependencies.
- Read the relevant source with `ast-outline show <file> <symbol>` or `read`.

**Do not skip this step.** Editing without understanding the relevant code is the #1 cause of bad fixes.

### Step 2: Create a reproduction script
Create a script that reproduces the error and run it to confirm the error.

```python
# repro.py
from module import function
result = function(input_that_triggers_bug)
# Expected: <correct behavior>
# Actual: <error or wrong output>
```

- The script should be minimal — just enough to trigger the bug.
- Run it: `python repro.py` (or `node repro.js`, `go run repro.go`, etc.)
- Confirm it fails with the expected error.
- **If you can't reproduce it, you can't verify the fix.** Keep trying until you have a reproducing script.

### Step 3: Edit the source
Edit the source code to resolve the issue.

- Use `code-review-graph` blast-radius to check what callers might be affected.
- Use the `think` MCP tool to plan the edit before making it.
- Make the minimum change needed to fix the issue. Don't refactor at the same time.

### Step 4: Rerun the reproduction
Rerun your reproduction script and confirm the error is fixed.

- `python repro.py` — does it now produce the expected output?
- If yes, continue to step 5.
- If no, apply the reflexion loop (see `custom-reflexion-loop` skill):
  1. State root cause.
  2. List 2-3 alternatives.
  3. Pick simplest.
  4. Re-attempt.

### Step 5: Think about edge cases
Think about edge cases and make sure your fix handles them.

- Null/None/undefined inputs.
- Empty strings, arrays, objects.
- Boundary values (0, -1, MAX_INT).
- Concurrent access.
- Error paths (what if DB is down, network fails?).
- Unicode/encoding.
- Large inputs (memory, performance).

For each edge case:
1. Add a test case (or modify your reproduction script).
2. Run it.
3. If it fails, fix the code.

## Cleanup (before declaring done)

1. **Remove the reproduction script** — don't leave test pollution.
2. **Revert any modified TEST files** via `git checkout -- <test-files>` unless adding tests was the task.
3. **Review your own diff** with `git diff` — check every changed line.
4. **Run the full test suite** to check for regressions.
5. **Run linter + typechecker**.

## Commit

`fix(scope): description` — conventional commits format.

## Anti-patterns

- **Don't skip the reproduction.** "I think this fixes it" without a reproduction script is not verification.
- **Don't fix multiple bugs at once.** One reproduction script, one fix, one commit per bug.
- **Don't leave the reproduction script in the repo.** It's test pollution.
- **Don't skip edge cases.** Step 5 is where most fixes fail — the happy path works but an edge case breaks.
