---
description: Analyze for refactoring opportunities, propose changes, then apply them.
agent: build
---

Refactor $ARGUMENTS — analyze for opportunities, propose changes, then apply them safely.

Steps:
1. **Analyze** — run `ast-outline digest` and `ast-outline outline <file>` to understand the current structure. Run `code-review-graph` to understand blast radius (callers, dependents, tests).
2. **Identify smells** — look for: duplication (DRY violations), long functions, deep nesting, god classes, feature envy, primitive obsession, dead code, inconsistent naming.
3. **Propose** — list changes as a numbered list with rationale:
   ```
   1. Extract <function> from <file>:<lines> — reduces complexity, improves testability
   2. Inline <function> into <file> — only used once, adds indirection without value
   3. Rename <X> to <Y> — matches domain terminology
   ```
4. **Apply** — use `ast-grep` for structural refactors (pattern-is-code, AST-aware). **Never use `sed` or regex for code refactors** — they break on nested syntax. For Python, use `libcst` if available. For JS/TS, use `jscodeshift` if available.
5. **Verify** — run lint + typecheck + full test suite after each refactor step. If anything breaks, revert and re-plan.
6. **Tree-of-Thoughts** — for non-trivial refactors, propose 3 candidate approaches, score each on (simplicity, blast radius, risk of regression), proceed with the highest-scoring.

Commit with `refactor(scope): description`. Keep diffs minimal — one refactor per commit if possible.
