---
description: Review the diff/changes for bugs, security, and style. Reports findings as a numbered list.
agent: reviewer
---

Review the changes in $ARGUMENTS for bugs, security issues, style violations, and spec adherence.

Steps:
1. Run `git diff` (or `git diff --staged` if reviewing staged changes) to see the full diff.
2. Run `ast-outline outline` on each changed file to understand the surrounding code structure.
3. Run `code-review-graph` blast-radius analysis on each changed function to trace callers, dependents, and tests that might break.
4. Check for spec adherence: if `docs/specs/` or `.speckit/` exists, compare the changes against the spec.

Report findings as a numbered list:
```
1. [CRITICAL] <file>:<line> — <description of issue> — <suggested fix>
2. [WARNING]  <file>:<line> — <description> — <suggestion>
3. [INFO]     <file>:<line> — <description>
```

End with a one-paragraph summary: "Overall: <approve / request changes / block> — <reason>."

Act as three reviewers in sequence:
- **Reviewer A (correctness):** does the change actually fix the issue / implement the feature?
- **Reviewer B (edge cases):** what regressions could this cause? Check null/empty inputs, error paths, concurrency.
- **Reviewer C (diff hygiene):** is the diff minimal? No unrelated changes? No debug code left in?

Address every objection. Do not edit files — propose fixes as suggestions.
