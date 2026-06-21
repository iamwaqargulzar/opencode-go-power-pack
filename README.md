# OpenCode-Go Power Pack

> Make opencode-go as capable as Claude Code or Codex — autonomous agents, 18 MCP servers, spec-driven dev, lossless token reduction, battle-tested coding-agent patterns. One-command install.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform: Windows | macOS | Linux](https://img.shields.io/badge/platform-Windows%20%7C%20macOS%20%7C%20Linux-blue)](#quick-start)
[![Provider: opencode-go](https://img.shields.io/badge/provider-opencode--go-orange)](https://opencode.ai/docs/providers/#opencode-go)
[![Tier: lean | standard | full](https://img.shields.io/badge/tier-lean%20%7C%20standard%20%7C%20full-green)](#tiers)

---

## What this is

A portable, shareable installer that provisions [opencode](https://opencode.ai) with everything it needs to be a top-tier autonomous coding agent — locked to the **[opencode-go](https://opencode.ai/docs/providers/#opencode-go)** subscription only. No Anthropic, OpenAI, Google, or any other provider is referenced.

One command installs:
- **8 custom agents** with per-model orchestration (build, plan, reviewer, explorer, data-engineer, frontend-engineer, devops-engineer, doc-writer)
- **7 slash commands** (/review, /plan, /test, /ship, /debug, /refactor, /docs)
- **13–18 MCP servers** (playwright, github, context7, sequential-thinking, think, fetch, filesystem, memory, time, git-utils, repomix, code-review-graph, pakt, + more in full tier)
- **22 hand-authored skills** covering reasoning disciplines, spec adherence, token awareness, Windows tooling, domain patterns
- **4 third-party skill packs** (superpowers, CodeRabbit, farmage, addyosmani) in full tier
- **Spec-driven-development spine** (GitHub Spec Kit + superpowers gated workflow + skillgate DoD gate)
- **Lossless token-reduction stack** (prompt caching, compaction prune, subagent delegation, ast-outline, code-review-graph ~82x reduction, PAKT lossless compression)
- **External CLIs** (ast-grep, ast-outline, gtr git-worktree-runner)
- **Model toggle** for single↔multi-model switching
- **Uninstaller** that safely reverts to stock opencode

## Quick start

### Prerequisites

- [opencode](https://opencode.ai) installed
- opencode-go subscription authenticated (`/connect` → select OpenCode Go → paste API key)
- `git`, `node`/`npm` (required); `python`/`uvx`, `gh` (recommended)

### Windows (PowerShell 5.1+)

```powershell
git clone https://github.com/iamwaqargulzar/opencode-go-power-pack.git
cd opencode-go-power-pack
.\install.ps1
.\verify.ps1
# Restart opencode
```

### macOS / Linux

```bash
git clone https://github.com/iamwaqargulzar/opencode-go-power-pack.git
cd opencode-go-power-pack
chmod +x install.sh verify.sh
./install.sh
./verify.sh
# Restart opencode
```

### Install options

```powershell
# Windows
.\install.ps1 -Tier full          # maximum capability (18 MCP, 4 skill packs)
.\install.ps1 -Tier lean          # minimal (10 MCP, superpowers + custom skills)
.\install.ps1 -Tier standard      # default (13 MCP, CodeRabbit, Spec Kit, DoD gate)
.\install.ps1 -SkipMcp            # skip MCP prefetch
.\install.ps1 -DryRun             # preview without installing
```

```bash
# macOS / Linux
./install.sh --tier full
./install.sh --tier lean
./install.sh --skip-mcp
./install.sh --dry-run
```

## Tiers

| Component | lean | **standard** (default) | full |
|---|---|---|---|
| MCP servers | 10 | 13 | 18 |
| Custom skills | 22 | 22 | 22 |
| Third-party skill packs | superpowers | + CodeRabbit | + farmage(66) + addyosmani(24) + cherry-pick(10) |
| External CLIs | gtr | + ast-outline + ast-grep | + jscodeshift + libcst + aider |
| Spec-driven spine | AGENTS.md only | + GitHub Spec Kit | + APM (multi-agent) |
| DoD gate | AGENTS.md only | skillgate | + donegate (CI) |
| Drift detector | — | — | coherence |
| Reasoning MCP | sequential-thinking | + think | + aleph |
| Lossless context MCP | repomix | + code-review-graph + PAKT | + arbor + provenant + headroom |

See [docs/tiers.md](docs/tiers.md) for the full breakdown.

## What's included

### Agents (8)

| Agent | Mode | Model | Purpose |
|---|---|---|---|
| `build` | primary | `opencode-go/glm-5.2` | Everyday coding, default agent |
| `plan` | primary | `opencode-go/deepseek-v4-pro` | Read-only analysis & planning |
| `reviewer` | subagent | `opencode-go/qwen3.7-max` | Code review, security audit |
| `explorer` | subagent | `opencode-go/deepseek-v4-flash` | Fast cheap codebase recon |
| `data-engineer` | subagent | `opencode-go/kimi-k2.7-code` | Data/ML/notebooks/SQL |
| `frontend-engineer` | subagent | `opencode-go/glm-5.2` | React/Vue/Next + Playwright |
| `devops-engineer` | subagent | `opencode-go/deepseek-v4-pro` | Docker/K8s/Terraform/CI |
| `doc-writer` | subagent | `opencode-go/mimo-v2.5` | Docs/ADRs/READMEs |

See [docs/agents.md](docs/agents.md) for full agent reference.

### Commands (7)

| Command | Agent | What it does |
|---|---|---|
| `/review` | reviewer | Review diff for bugs, security, style |
| `/plan` | plan | Produce step-by-step implementation plan |
| `/test` | build | TDD — write failing tests, implement, verify |
| `/ship` | build | Lint + typecheck + test + commit + push |
| `/debug` | build | SWE-agent 5-step debug protocol |
| `/refactor` | build | Analyze → propose → apply with ast-grep |
| `/docs` | doc-writer | Generate README sections, ADRs, API docs |

### MCP servers (standard: 13)

| Server | Purpose |
|---|---|
| playwright | Browser automation, screenshots, clicks |
| github | Repo/PR/issue ops (token from `gh auth token`) |
| context7 | Library docs on-demand (never web-search for APIs) |
| sequential-thinking | Structured step-numbered reasoning |
| think | Anthropic "think" tool (+1.6% SWE-bench, d=1.47) |
| fetch | JS-rendered web fetch |
| filesystem | Cross-directory file ops |
| memory | Persistent cross-session knowledge graph |
| time | Current time / timezones |
| git-utils | Git operations via MCP |
| repomix | AST-compressed repo-to-text packing |
| code-review-graph | Blast-radius analysis (~82x token reduction) |
| pakt | Lossless JSON/YAML/CSV/MD compression (p=0.50) |

See [docs/mcp-servers.md](docs/mcp-servers.md) for the full list including full-tier servers.

### Skills (22 custom + 4 packs)

**Custom skills:** opencode-go-workflow, windows-powershell-tooling, autonomous-execution, token-budget-awareness, repo-context-packing, mcp-orchestration, git-worktree-parallelism, test-first-verification, docs-as-code, data-pipeline-patterns, docker-compose-first, ci-pipeline-design, secrets-hygiene, error-recovery-protocol, progressive-refinement, ears-requirements, property-based-verification, reflexion-loop, tot-decide, swe-debate-self-critique, swe-agent-5-step-protocol, submit-time-self-review.

**Third-party packs (standard+):** CodeRabbit (code-review, autofix). **Full tier:** superpowers (14), farmage (66), addyosmani (24), cherry-picked top 10 from skills.sh.

See [docs/skills.md](docs/skills.md) for the full reference.

## Model toggle

Switch between multi-model orchestration and single-model simplicity:

```powershell
# Windows
.\toggle-models.ps1 status                              # show current mode
.\toggle-models.ps1 multi                               # per-agent models (default)
.\toggle-models.ps1 single                              # all agents use top-level model
.\toggle-models.ps1 single opencode-go/kimi-k2.7-code   # single + pick model
```

```bash
# macOS / Linux
./toggle-models.sh status
./toggle-models.sh multi
./toggle-models.sh single
./toggle-models.sh single opencode-go/kimi-k2.7-code
```

See [docs/model-toggle.md](docs/model-toggle.md) for details.

## Uninstall

Safely revert to stock opencode:

```powershell
# Windows
.\uninstall.ps1                # restore config, keep skills
.\uninstall.ps1 -Full          # complete removal
.\uninstall.ps1 -Full -DryRun  # preview
```

```bash
# macOS / Linux
./uninstall.sh                  # restore config, keep skills
./uninstall.sh --full           # complete removal
./uninstall.sh --full --dry-run # preview
```

The uninstaller reads the manifest (`~/.config/opencode/.power-pack-manifest.json`) written by the installer and removes only what was installed. If a backup exists, it restores it; otherwise it writes a minimal stock config.

## Spec-driven development

The standard tier installs GitHub Spec Kit as the spec spine:

```bash
cd your-project
specify init . --integration opencode
```

This adds `/speckit.*` slash commands: constitution → specify → clarify → plan → tasks → implement → converge (reconciles code-vs-spec). Combined with superpowers' gated workflow and skillgate's deterministic DoD gate, this keeps code aligned with spec.

See [docs/spec-driven.md](docs/spec-driven.md) for the full workflow.

## Token reduction (lossless)

The pack uses a layered approach that reduces tokens without hindering capabilities:

1. **Prompt caching** (`setCacheKey: true`) — 90% input cost reduction on cache hits, truly lossless.
2. **Compaction prune** — drops old tool outputs from context.
3. **Subagent delegation** — explorer/reviewer run in child sessions; only results return.
4. **ast-outline** — `digest→outline→show` progressive disclosure (truly lossless, exact signatures + exact source).
5. **code-review-graph** — blast-radius analysis, ~82x median token reduction (38-528x), benchmarked.
6. **PAKT** — lossless JSON/YAML/CSV/MD compression, comprehension-evaluated (p=0.50 sign test).

**Excluded:** LLMLingua (lossy — drops tokens, conflicts with "no capability hindrance" requirement).

See [docs/token-reduction.md](docs/token-reduction.md) for the full stack.

## Provider lock

`enabled_providers: ["opencode-go"]` in `opencode.json` hard-locks the setup to the opencode-go subscription. Even if other provider credentials exist in your environment, opencode ignores them. No Anthropic, OpenAI, Google, xAI, or any other provider is referenced anywhere in the pack.

## Platform notes

- **Windows:** MCP commands use `["cmd","/c","npx",...]` form. The installer handles this automatically.
- **macOS/Linux:** The installer rewrites MCP commands to `["npx",...]` on install.
- **RTK plugin:** On native Windows, the auto-rewrite hook doesn't run (falls back to CLAUDE.md-style injection). Full hook support requires WSL. The `rtk` CLI still works manually.
- **gtr (git-worktree-runner):** On native Windows, may need WSL. The installer prints instructions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add skills, agents, MCP servers, and improve the installer.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## License

MIT — see [LICENSE](LICENSE). Third-party packs bundled by the installer retain their original licenses (MIT, Apache-2.0, MPL-2.0).

## Topics

`opencode` `opencode-go` `ai-agents` `mcp` `skills` `spec-driven` `coding-agent` `llm` `developer-tools`
