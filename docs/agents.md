# Agents

The pack defines 8 main agents + 3 hidden utility agents. All are locked to `opencode-go/*` models.

## Main agents

### build (primary)
- **Model:** `opencode-go/glm-5.2`
- **Mode:** primary (default agent)
- **Steps:** 30
- **Permission:** autonomous (allow everything except catastrophic commands)
- **Purpose:** Everyday coding — implements features, fixes bugs, runs tests, commits.
- **When to use:** Default for all tasks. Switch to others only when you need specialization.

### plan (primary)
- **Model:** `opencode-go/deepseek-v4-pro`
- **Mode:** primary (read-only)
- **Steps:** 20
- **Permission:** `edit: deny`, `bash: read-only commands only`
- **Purpose:** Read-only analysis and planning. Produces step-by-step implementation plans.
- **When to use:** Before complex implementations. Run `/plan <task>` to get a plan without risking edits.

### reviewer (subagent)
- **Model:** `opencode-go/qwen3.7-max`
- **Mode:** subagent (read-only)
- **Steps:** 15
- **Permission:** `edit: deny`, `bash: git diff/log/show, ast-outline, code-review-graph only`
- **Purpose:** Code review and security audit. Reviews diffs, flags bugs, proposes improvements.
- **When to use:** Invoked by the build agent or `/review` command. Not directly selectable.

### explorer (subagent, hidden)
- **Model:** `opencode-go/deepseek-v4-flash`
- **Mode:** subagent (read-only, hidden)
- **Steps:** 15
- **Permission:** `edit: deny`, `bash: read-only commands only`
- **Purpose:** Fast cheap codebase reconnaissance. Finds files, searches code, builds repo maps.
- **When to use:** Invoked by other agents via the Task tool. Runs in a child session — only the result returns to the parent's context, keeping main context lean.

### data-engineer (subagent)
- **Model:** `opencode-go/kimi-k2.7-code`
- **Mode:** subagent
- **Steps:** 25
- **Permission:** autonomous
- **Purpose:** Data/ML/notebooks/SQL/pandas. Handles data pipelines, feature engineering, model training, notebook refactors.

### frontend-engineer (subagent)
- **Model:** `opencode-go/glm-5.2`
- **Mode:** subagent
- **Steps:** 25
- **Permission:** autonomous
- **Purpose:** React/Vue/Next/CSS. Uses Playwright MCP for live browser testing and debugging.

### devops-engineer (subagent)
- **Model:** `opencode-go/deepseek-v4-pro`
- **Mode:** subagent
- **Steps:** 25
- **Permission:** autonomous
- **Purpose:** Docker/K8s/Terraform/CI-CD. Handles infra-as-code, pipeline design, deployment automation.

### doc-writer (subagent)
- **Model:** `opencode-go/mimo-v2.5`
- **Mode:** subagent
- **Steps:** 20
- **Permission:** autonomous
- **Purpose:** Docs/ADRs/READMEs. Long-context cheap model for digesting codebases and producing documentation.

## Hidden utility agents

These are defined inline in `opencode.json` and not selectable from the TUI.

| Agent | Model | Purpose |
|---|---|---|
| `title` | `opencode-go/deepseek-v4-flash` | Generates session titles |
| `summary` | `opencode-go/deepseek-v4-flash` | Generates session summaries |
| `compaction` | `opencode-go/deepseek-v4-flash` | Compacts context when window fills |

## Model rationale

| Model | Cost (in/out per 1M) | Context | Output | Why assigned |
|---|---|---|---|---|
| `glm-5.2` | $1.40/$4.40 | 1M | 131K | Newest, full features — build + frontend |
| `deepseek-v4-pro` | $1.74/$3.48 | 1M | 384K | Deep reasoning — plan + devops |
| `qwen3.7-max` | $2.50/$7.50 | 1M | 65K | Strongest critique — reviewer |
| `deepseek-v4-flash` | $0.14/$0.28 | 1M | 384K | Cheapest — explorer + utility agents |
| `kimi-k2.7-code` | $0.95/$4.00 | 262K | 262K | Purpose-built "Code" — data-engineer |
| `mimo-v2.5` | $0.14/$0.28 | 1M | 128K | Cheap, huge context — doc-writer |

All deprecated models (`glm-5`, `kimi-k2.5`, `mimo-v2-omni`, `mimo-v2-pro`, `minimax-m2.5`, `qwen3.5-plus`) are excluded.
