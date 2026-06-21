---
name: custom-error-recovery-protocol
description: Use when a tool fails, a command errors, or a test fails. Covers diagnosis, root-cause analysis, retry strategies, and reporting. Trigger on: error, fail, failed, exception, crash, bug, retry, fix, recover, diagnose, root cause.
---

# Error Recovery Protocol

## When a tool fails or a command errors

### Step 1: Read the error
- Read the full error message, not just the first line.
- Look for: error type, file path, line number, stack trace, exit code.
- Check if it's a known error type (syntax error, import error, permission denied, network timeout, etc.).

### Step 2: Diagnose
- Form a hypothesis about the root cause in one sentence.
- If the error is unclear, run the command again with verbose/debug flags (`--verbose`, `--debug`, `-v`).
- Check logs, stderr, and any output files.
- Use `code-review-graph` to check if a recent change could have caused it.

### Step 3: Fix
- Apply the fix. One change at a time — don't change multiple things at once.
- Run the failing command again to confirm the fix worked.

### Step 4: If the fix didn't work (Reflexion loop)
1. **State the root cause** in one sentence. (Be honest — if you don't know, say "I don't know yet.")
2. **List 2-3 alternative approaches** you did not try.
3. **Pick the simplest** and explain why.
4. **Re-attempt.** Append this reflection to your working notes.

### Step 5: If all attempts failed
- Report to the user with concrete evidence:
  - The exact error message.
  - What you tried (list each attempt and its outcome).
  - Your best guess at the root cause.
  - Suggested next steps (e.g. "check if the DB is running", "verify the API key is valid").
- Do NOT say "it should work" — if it doesn't work, report that.

## Common error patterns

| Error | Likely cause | First fix |
|---|---|---|
| `ModuleNotFoundError` | Missing dependency or wrong import path | `pip install` / `npm install`; check `sys.path` / `NODE_PATH` |
| `Permission denied` | File permissions or wrong user | `chmod` / `chown`; check if running as right user |
| `Connection refused` | Service not running or wrong port | Check if service is up: `curl localhost:PORT` |
| `Command not found` | Tool not installed or not on PATH | `which <tool>`; install if missing |
| `SyntaxError` | Typo in code | Read the line number in the error, fix the syntax |
| `TypeError: undefined is not a function` | Calling a method on undefined/null | Add null check; trace where the value comes from |
| `EACCES` (npm) | Permission issue in npm cache | `npm cache clean --force`; don't use sudo with npm |

## Anti-patterns

- **Don't retry blindly.** If the command fails for the same reason, retrying won't help. Fix the root cause.
- **Don't suppress errors.** `try: ... except: pass` hides the real problem. Let it fail, then fix it.
- **Don't change unrelated things.** If the test fails, fix the test or the code — don't change the CI config.
- **Don't blame the tool.** "The linter is wrong" is almost never true. Read the lint rule, understand it, fix your code.
