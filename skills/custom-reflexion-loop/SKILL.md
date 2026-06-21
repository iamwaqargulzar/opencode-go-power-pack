---
name: custom-reflexion-loop
description: Use after a failed test run, rejected edit, or any error. Enforces structured self-reflection: state root cause, list alternatives, pick simplest, retry. Trigger on: fail, failed, error, retry, reflect, reflexion, root cause, alternative, attempt, stuck.
---

# Reflexion Loop

## When to use

After any failure:
- A test run fails.
- An edit is rejected.
- A command errors.
- A build breaks.
- You're stuck (tried something and it didn't work).

## The protocol

### 1. State the root cause (one sentence)
Be honest. If you don't know, say "I don't know yet" and investigate more before proceeding.

**Good:** "The test fails because `parseDate('2026-13-45')` returns None instead of raising ValueError — the validator doesn't check month/day ranges."

**Bad:** "The test is wrong." (Don't blame the test without evidence. Tests are usually right.)

### 2. List 2-3 alternative approaches you did NOT try
These must be genuinely different strategies, not minor variations of what you already tried.

**Example:**
1. Add range validation in `parseDate` before parsing.
2. Use `datetime.strptime` which raises `ValueError` on invalid dates.
3. Add a `validate_date` function called before `parseDate`.

### 3. Pick the simplest and explain why
Choose the approach with the smallest blast radius and lowest risk of regression.

**Example:** "I'll use approach 2 (`strptime`) because it delegates validation to the standard library, reducing our custom code and ensuring correct behavior for all edge cases including leap years."

### 4. Re-attempt
Apply the chosen approach. Run the failing test. If it passes, continue. If it fails, repeat the reflexion loop with new information.

### 5. Record the reflection
Append to your working notes:
```
## Reflection (attempt N)
- Root cause: <one sentence>
- Alternatives tried: <list>
- Chose: <approach> because <reason>
- Outcome: <pass/fail>
```

## Anti-patterns

- **Don't retry the exact same thing.** If `fix_A` didn't work, `fix_A` again won't work either.
- **Don't skip the root-cause step.** "Let me just try something else" without understanding why the first attempt failed leads to random changes.
- **Don't list alternatives that are all the same strategy.** "1. Add a check. 2. Add a different check. 3. Add another check" — these are the same approach.
- **Don't pick the most complex alternative.** The simplest fix is usually the best (Occam's razor).

## When to stop the loop

After 3 reflexion cycles (3 failed attempts), stop and:
1. Summarize all attempts and their outcomes.
2. Report to the user with concrete evidence (error logs, test output, file paths).
3. Suggest next steps (e.g. "the issue may be in the upstream library", "I need more context about the expected behavior").

Do NOT keep spinning after 3 failures — you're likely missing information that the user can provide.
