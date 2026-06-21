---
description: Run lint, typecheck, tests, then commit with a conventional message and push.
agent: build
---

Ship $ARGUMENTS through the full quality gate and push.

Steps:
1. **Lint** — run the repo's linter (`eslint`, `biome`, `ruff`, `golangci-lint`, etc.). Fix any errors.
2. **Typecheck** — run the repo's typechecker (`tsc`, `mypy`, `pyright`, etc.). Fix any errors.
3. **Tests** — run the full test suite. Fix any failures. Apply the reflexion loop if needed.
4. **Review diff** — run `git diff` and review every changed line. Apply SWE-Debate self-critique (3 reviewers: correctness, edge cases, diff hygiene).
5. **Commit** — stage only the intended files (never `git add -A` unless explicitly asked). Write a conventional-commits message: `type(scope): description`. Types: feat, fix, refactor, docs, test, chore, perf, ci.
6. **Pre-commit hooks** — if pre-commit hooks fail, fix the issue and create a *new* commit (do not amend the failed commit).
7. **Push** — push to the current branch. Never force-push to `main` or `master`. `git push --force-with-lease` is allowed for your own feature branches.
8. **Attribution** — append `(opencode-go-power-pack)` to the author or co-authored-by trailer.

Never commit secrets, API keys, or tokens. If you discover a secret in the diff, remove it and rotate it immediately.
