---
name: custom-git-worktree-parallelism
description: Use when working on multiple features in parallel or when you need an isolated workspace. Covers git worktree, gtr (git-worktree-runner), branch-per-task patterns. Trigger on: worktree, parallel, branch, gtr, isolated, feature branch, multiple tasks.
---

# Git Worktree Parallelism

## Why worktrees?

A git worktree gives you an isolated working directory on its own branch. Multiple worktrees = multiple features in parallel without stashing or branching conflicts.

## gtr (git-worktree-runner)

`gtr` is a CLI that wraps `git worktree` with first-class `opencode` adapter support.

### Create a new worktree with opencode
```bash
git gtr new feature-auth --ai
# Creates a worktree folder, copies config/env files, runs postCreate hooks (e.g. npm install), launches opencode in that worktree
```

### Configure gtr to use opencode by default
```bash
git gtr config set gtr.ai.default opencode
```

### List worktrees
```bash
git gtr list
```

### Clean up merged/closed worktrees
```bash
git gtr clean --merged --closed
```

## Manual git worktree (if gtr isn't installed)
```bash
git worktree add ../feature-auth feature-auth
cd ../feature-auth
opencode
```

## Patterns

### Branch-per-task
- Each task/feature gets its own worktree on its own branch.
- Auto-commits isolate AI edits from pre-existing changes.
- `/undo` is safe because the worktree started clean.

### Parallel agents
- Start opencode in multiple worktrees simultaneously.
- Each session is independent — no context interference.
- Merge back when each feature is done.

### Dependency chains
- `gtr` supports dependency configuration between worktrees.
- If feature B depends on feature A, `gtr` can set up the branch to track A's branch.

## Trust model
`gtr` has a `git gtr trust` security model — shared hooks require explicit approval. This prevents malicious-PR command injection via postCreate hooks.

## When NOT to use worktrees
- Quick one-line fixes — just work on the current branch.
- Tasks that depend on each other and need to share context — use one session.
