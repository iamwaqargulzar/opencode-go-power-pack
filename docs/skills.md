# Skills

The pack installs 22 hand-authored custom skills + third-party skill packs (standard+ tiers).

## Custom skills (22)

### Operating conventions
| Skill | Trigger keywords | Purpose |
|---|---|---|
| `custom-opencode-go-workflow` | opencode-go, model selection, cache key, provider lock | Cache-friendly prompting, subagent delegation, model selection by task |
| `custom-autonomous-execution` | any task, autonomous, permission, ask, confirm | Never ask for permission, verify with tests, report concisely |
| `custom-token-budget-awareness` | token, context, budget, delegate, compress, cache | Keep main context lean — delegate, use ast-outline, prompt caching |
| `custom-mcp-orchestration` | MCP, playwright, github, context7, fetch, memory, repomix | Which MCP server to use for each task type |
| `custom-windows-powershell-tooling` | Windows, PowerShell, cmd, native, chaining | PS 5.1 idioms — no `&&`, use `; if ($?) {}`, full cmdlet names |

### Workflow patterns
| Skill | Trigger keywords | Purpose |
|---|---|---|
| `custom-repo-context-packing` | repo map, context, large codebase, repomix, ast-outline | Progressive disclosure: digest → outline → show → read |
| `custom-git-worktree-parallelism` | worktree, parallel, branch, gtr, isolated | Branch-per-task with gtr, parallel agents |
| `custom-test-first-verification` | test, TDD, verify, done, lint, typecheck | RED-GREEN-REFACTOR + verification-before-completion |
| `custom-docs-as-code` | docs, README, ADR, API docs, docstring, mkdocs | Document the *why*, ADRs, docs linters/builds |
| `custom-progressive-refinement` | draft, review, ship, refine, incremental, stages | Multi-stage work: draft → review → refine → ship |

### Domain patterns
| Skill | Trigger keywords | Purpose |
|---|---|---|
| `custom-data-pipeline-patterns` | data, pipeline, ETL, pandas, SQL, notebook, ML | Data inspection, pipeline design, notebook hygiene, PBT |
| `custom-docker-compose-first` | Docker, docker-compose, container, Dockerfile | Multi-stage builds, .dockerignore, non-root, healthcheck |
| `custom-ci-pipeline-design` | CI, CD, pipeline, GitHub Actions, GitLab CI | Caching, parallelization, matrix builds, security scans |
| `custom-secrets-hygiene` | secret, API key, token, password, .env, env var | Never commit secrets, env var references, .gitignore |
| `custom-error-recovery-protocol` | error, fail, exception, crash, retry, fix, diagnose | Read error → diagnose → fix → reflexion loop if needed |

### Reasoning disciplines
| Skill | Trigger keywords | Purpose |
|---|---|---|
| `custom-ears-requirements` | requirements, spec, EARS, SHALL, WHEN, acceptance criteria | EARS form for unambiguous, testable requirements |
| `custom-property-based-verification` | property-based, PBT, hypothesis, fast-check, counter-example | Extract properties from EARS reqs, test with random inputs, shrink |
| `custom-reflexion-loop` | fail, failed, error, retry, reflect, root cause | State root cause → list alternatives → pick simplest → retry |
| `custom-tot-decide` | decide, choose, approach, strategy, alternative, brainstorm | Propose 3 approaches, score on simplicity/blast-radius/risk, proceed |
| `custom-swe-debate-self-critique` | submit, done, review, critique, debate, patch | 3 reviewers (correctness, edge cases, diff hygiene) before submit |
| `custom-swe-agent-5-step-protocol` | bug, fix, issue, reproduce, verify, edge case | Find → reproduce → fix → verify → edge-cases (SWE-bench SoTA) |
| `custom-submit-time-self-review` | submit, done, complete, cleanup, revert, reproduction | Re-run repro, remove scripts, revert test edits, review diff |

## Third-party skill packs

### superpowers (all tiers)
Installed as a plugin in `opencode.json`: `superpowers@git+https://github.com/obra/superpowers.git`.

14 skills: test-driven-development, systematic-debugging, brainstorming, writing-plans, executing-plans, requesting-code-review, receiving-code-review, using-git-worktrees, dispatching-parallel-agents, subagent-driven-development, verification-before-completion, finishing-a-development-branch, writing-skills, using-superpowers.

### CodeRabbit (standard+)
Installed via `npx skills add coderabbitai/skills`. Native opencode support.

Skills: `code-review` (runs coderabbit CLI, groups findings by severity), `autofix` (fetches unresolved PR review threads, applies fixes after validation).

### farmage/opencode-skills (full only)
Cloned to `~/.config/opencode/skills/farmage/`. 66 skills + 9 commands + 365 reference docs.

Covers: 12 languages (Python, TS, JS, Go, Rust, C++, C#, Java, PHP, Swift, Kotlin, SQL), 14 frameworks (React, Next, Vue, Angular, NestJS, Django, FastAPI, Spring Boot, Laravel, Rails, .NET, React Native, Flutter, WordPress), 8 infra/DevOps, 8 architecture, 6 specialized.

### addyosmani/agent-skills (full only)
Cloned to `~/.config/opencode/skills/addyosmani/`. 24 skills + 8 commands + 4 agent personas.

SDLC lifecycle: define (interview-me, idea-refine, spec-driven-development), plan (planning-and-task-breakdown), build (incremental-implementation, TDD, context-engineering, source-driven-development, doubt-driven-development, frontend-ui-engineering, api-and-interface-design), verify (browser-testing-with-devtools, debugging-and-error-recovery), review (code-review-and-quality, code-simplification, security-and-hardening, performance-optimization), ship (git-workflow-and-versioning, ci-cd-and-automation, deprecation-and-migration, documentation-and-adrs, observability-and-instrumentation, shipping-and-launch).

### Cherry-picked from skills.sh (full only)
Installed via `npx skills add`. 10 skills: anthropics/frontend-design, mattpocock/tdd, mattpocock/diagnose, mattpocock/triage, mattpocock/improve-codebase-architecture, vercel-labs/next-best-practices, vercel-labs/vercel-react-best-practices, supabase/supabase-postgres-best-practices, shadcn/ui/shadcn, anthropics/skill-creator.
