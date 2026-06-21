---
name: custom-swe-debate-self-critique
description: Use before submitting a patch or declaring a task done. Simulates 3 independent reviewers (correctness, edge cases, diff hygiene) and addresses every objection. SWE-Debate pattern. Trigger on: submit, done, complete, review, critique, self-critique, debate, patch, PR, pull request, verify, final.
---

# SWE-Debate Self-Critique

## When to use

Before declaring a task done or submitting a patch. This is the final quality gate before "done."

## The protocol

Simulate 3 independent reviewers, each with a specific focus. For each reviewer, generate objections, then address them.

### Reviewer A: Correctness
**Question:** Does the change actually fix the issue / implement the feature?

Check:
- Does the diff address the original task description?
- Are there any logical errors?
- Does it handle the happy path correctly?
- Does it match the spec (if one exists)?

**Objection example:** "The fix handles the null case but doesn't handle empty strings. An empty string would pass the null check but crash in the substring operation."

**Address:** "Added an empty-string check: `if not value or value.strip() == ''`."

### Reviewer B: Edge cases
**Question:** What regressions could this cause?

Check:
- Null/undefined/None inputs.
- Empty collections (strings, arrays, objects).
- Boundary values (0, -1, MAX_INT, very large strings).
- Concurrency (race conditions, thread safety).
- Error paths (what if the DB is down, network fails, disk full?).
- Unicode/encoding issues.

**Objection example:** "The new caching layer doesn't set a TTL, so cached values never expire. If the underlying data changes, users will see stale data forever."

**Address:** "Added a 5-minute TTL to the cache entry."

### Reviewer C: Diff hygiene
**Question:** Is the diff minimal and clean?

Check:
- No unrelated changes (the diff should only touch files relevant to the task).
- No debug code left in (`console.log`, `print`, `debugger`).
- No commented-out code.
- No trailing whitespace.
- No changes to formatting that aren't related to the task.
- Conventional commit message follows the format.

**Objection example:** "The diff includes changes to `package.json` that add an unrelated dev dependency. This should be a separate commit."

**Address:** "Reverted the unrelated `package.json` change. Will add it in a separate commit if needed."

## Output format

```
## SWE-Debate Self-Critique

### Reviewer A (Correctness)
- Objection: <description>
- Addressed: <fix>

### Reviewer B (Edge cases)
- Objection: <description>
- Addressed: <fix>

### Reviewer C (Diff hygiene)
- Objection: <description>
- Addressed: <fix>

### Verdict
All objections addressed. Ready to submit.
```

## When to skip

- Trivial fixes (one-line changes with no edge cases).
- When the `reviewer` subagent already reviewed the diff (it covers the same ground, but independently).

## Anti-patterns

- **Don't rubber-stamp.** "Reviewer A: looks good. Reviewer B: looks good. Reviewer C: looks good." — this is useless. Actually generate objections.
- **Don't ignore objections.** If a reviewer raises an objection, address it. Don't dismiss it without reasoning.
- **Don't merge reviewers.** Each reviewer has a specific focus. Don't let Reviewer A's correctness check bleed into edge cases — that's Reviewer B's job.
