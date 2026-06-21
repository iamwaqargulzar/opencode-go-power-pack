---
name: custom-opencode-go-workflow
description: Use when working with opencode-go models. Covers cache-friendly prompting, subagent delegation patterns, model selection by task, and provider-lock conventions. Trigger on: opencode-go, model selection, glm, deepseek, kimi, qwen, mimo, provider lock, cache key.
---

# opencode-go Workflow

## Provider lock

You use **only** the `opencode-go` subscription provider. Never configure, reference, or fall back to other providers. The `enabled_providers: ["opencode-go"]` setting in `opencode.json` enforces this.

## Model selection by task

| Task | Model | Why |
|---|---|---|
| Everyday coding (build, frontend) | `opencode-go/glm-5.2` | Newest, 1M ctx, 131K out, full features, $1.40/$4.40 |
| Deep reasoning (plan, devops) | `opencode-go/deepseek-v4-pro` | 1M ctx, 384K out, strong reasoning, $1.74/$3.48 |
| High-quality review | `opencode-go/qwen3.7-max` | Strongest Qwen, $2.50/$7.50 |
| Exploration, titles, summaries, compaction | `opencode-go/deepseek-v4-flash` | Cheap $0.14/$0.28, 1M ctx, 384K out |
| Data/ML/notebooks | `opencode-go/kimi-k2.7-code` | Purpose-built "Code" variant, 262K out |
| Docs (cheap, long context) | `opencode-go/mimo-v2.5` | $0.14/$0.28, 1M ctx |

## Cache-friendly prompting

Prompt caching is enabled (`setCacheKey: true`). To maximize cache hits:
- Keep stable prefixes (system prompt, tool definitions, AGENTS.md) at the top of context.
- Cache reads are ~5x cheaper than fresh input (e.g. GLM-5.2 cache read is $0.26 vs $1.40 input).
- Don't reorder or modify the system prompt / tool defs between turns — that invalidates the cache.
- Put per-request varying content (user messages, tool results) AFTER the stable prefix.

## Subagent delegation patterns

- Delegate broad codebase recon to the `explorer` subagent (cheap model, child session, only result returns).
- Delegate code review to the `reviewer` subagent (high-quality critique, read-only).
- Delegate data/ML to `data-engineer`, frontend to `frontend-engineer`, infra to `devops-engineer`, docs to `doc-writer`.
- Subagents run in child sessions — their intermediate tool calls do NOT bloat your main context.

## Deprecated models (do not use)

`glm-5`, `kimi-k2.5`, `mimo-v2-omni`, `mimo-v2-pro`, `minimax-m2.5`, `qwen3.5-plus` are deprecated. Always use the newest generation.
