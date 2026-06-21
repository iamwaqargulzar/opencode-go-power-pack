---
name: custom-progressive-refinement
description: Use for multi-step work: draft → review → ship. Enforces incremental implementation with checkpoints. Trigger on: draft, review, ship, refine, incremental, iterate, checkpoint, stages.
---

# Progressive Refinement

## The pattern

For any non-trivial task, work in stages:

1. **Draft** — produce a first version. Focus on correctness, not polish.
2. **Review** — step back and critique. Use the `reviewer` subagent or self-critique.
3. **Refine** — apply the review feedback. Improve quality.
4. **Ship** — final verification (lint, typecheck, tests), commit, push.

## When to use this

- Any task that takes more than a few minutes.
- Tasks where the first attempt might not be the best.
- Tasks where quality matters (production code, public APIs, docs).

## When NOT to use this

- Trivial fixes (one-line changes, typos).
- Mechanical refactors where the outcome is deterministic.
- When the user explicitly says "just do it quickly".

## Draft stage

- Focus on getting something working.
- Don't optimize prematurely.
- Don't add comments unless they're for non-obvious logic.
- Run tests to confirm it works.

## Review stage

- Use the `reviewer` subagent for independent critique. OR
- Self-critique with SWE-Debate (3 reviewers: correctness, edge cases, diff hygiene).
- Check: does it meet the spec? Are there edge cases? Is the diff minimal?
- Check blast radius with `code-review-graph`.

## Refine stage

- Apply review feedback.
- Use `ast-grep` for structural refactors.
- Keep tests green after each change.
- Run lint + typecheck.

## Ship stage

- Run the full quality gate: lint, typecheck, full test suite.
- Review your own diff with `git diff`.
- Commit with conventional-commits message.
- Push (never force-push to main/master).

## Checkpoints

Between each stage, pause and confirm:
- "Is this stage actually done?"
- "Am I ready to move to the next stage?"
- "Should I hand off to the user for approval before continuing?"

For the draft stage, you usually don't need approval. For ship, verify everything passes.
