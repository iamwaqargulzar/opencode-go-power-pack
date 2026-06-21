# Changelog

All notable changes to OpenCode-Go Power Pack are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — 2026-06-21

### Added

- **Tiered installer** (`install.ps1` for Windows, `install.sh` for macOS/Linux) with three profiles:
  - `lean` — 10 MCP servers, superpowers + 15 custom skills, pure config token-reduction.
  - `standard` (default) — 13 MCP servers, +7 reasoning/spec skills, +CodeRabbit skills, +GitHub Spec Kit, +skillgate DoD gate, +ast-outline/ast-grep/gtr CLIs.
  - `full` — 18 MCP servers, +farmage(66)/addyosmani(24)/cherry-pick(10) skill packs, +arbor/provenant/headroom lossless context MCP, +APM multi-agent, +donegate CI gate, +coherence drift detector, +jscodeshift/libcst codemods, +aider.
- **8 custom agents**: build, plan, reviewer, explorer, data-engineer, frontend-engineer, devops-engineer, doc-writer (+ title/summary/compaction hidden agents). All locked to `opencode-go/*` models.
- **7 slash commands**: /review, /plan, /test, /ship, /debug, /refactor, /docs.
- **22 hand-authored skills** covering: opencode-go workflow, Windows PowerShell tooling, autonomous execution, token-budget awareness, repo-context packing, MCP orchestration, git-worktree parallelism, test-first verification, docs-as-code, data-pipeline patterns, docker-compose-first, CI-pipeline design, secrets hygiene, error-recovery protocol, progressive refinement, EARS requirements, property-based verification, reflexion loop, tree-of-thoughts decide, SWE-Debate self-critique, SWE-agent 5-step protocol, submit-time self-review.
- **13 MCP servers** (standard tier): playwright, github, context7, sequential-thinking, think, fetch, filesystem, memory, time, git-utils, repomix, code-review-graph, pakt.
- **Lossless token-reduction stack**: prompt caching (`setCacheKey`), compaction prune, subagent delegation, LSP, ast-outline CLI, code-review-graph MCP (~82x reduction), PAKT MCP (lossless structured-data compression, p=0.50 comprehension).
- **Spec-driven-development spine**: GitHub Spec Kit (`specify init --integration opencode`) + superpowers gated workflow + skillgate deterministic DoD gate.
- **Reasoning disciplines** baked into AGENTS.md: SWE-agent 5-step protocol, submit-time self-review, Anthropic "think" tool usage, reflexion loop, tree-of-thoughts propose-3-score-proceed, SWE-Debate 3-reviewer self-critique.
- **Coding-process patterns** from Aider: diff edit-format, lint-after-edit, test-after-edit, auto-commit with Conventional Commits + dirty-file isolation.
- **Refactor tooling**: ast-grep CLI + ast-grep-essentials rule pack, ast-outline CLI, gtr (git-worktree-runner) with first-class opencode adapter.
- **Model toggle**: `toggle-models.ps1` / `toggle-models.sh` with `multi` / `single [model-id]` / `status` subcommands, backed by `profiles/multi-models.json`.
- **Uninstaller**: `uninstall.ps1` / `uninstall.sh` with `-KeepBackups`, `-RemoveSkills`, `-RemoveMcpDeps`, `-Full`, `-DryRun` flags. Manifest-tracked for safety.
- **Verification scripts**: `verify.ps1` / `verify.sh` post-install smoke tests.
- **Global AGENTS.md** template with autonomous-mode conventions, provider lock, tool budget, reasoning disciplines, code style, git discipline, Windows conventions, skills/MCP reference, token awareness, verification-before-completion.
- **Repo meta**: MIT LICENSE, CONTRIBUTING.md, CHANGELOG.md, issue templates (bug-report, feature-request), CI workflow (verify-install.yml), docs/ folder (8 reference docs), GitHub topics tags.
- **Provider lock**: `enabled_providers: ["opencode-go"]` hard-locks the setup to the opencode-go subscription only. No Anthropic, OpenAI, Google, xAI, or any other provider is referenced.

### Decisions

- **LLMLingua excluded** — lossy (drops tokens), conflicts with the "no capability hindrance" requirement. Replaced by PAKT (truly lossless, comprehension p=0.50), ast-outline (truly lossless signatures + exact source), and code-review-graph (lossless-on-demand, ~82x reduction benchmarked).
- **context-compress moved to full tier only** — overlaps PAKT/code-review-graph; headroom in full tier is stronger.
- **Default tier is `standard`** — best capability/cost balance out of the box. Flip to `lean` for minimal footprint or `full` for maximum capability.
- **Default mode is multi-model** — per-agent orchestration. Flip to single-model anytime with `toggle-models.sh single` (or `single opencode-go/<model-id>` to pick a specific one).
