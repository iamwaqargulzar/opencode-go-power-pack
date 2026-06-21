---
name: custom-token-budget-awareness
description: Use when context is getting large, token usage matters, or you need to decide between doing work yourself vs delegating to a subagent. Trigger on: token, context, budget, large, expensive, delegate, subagent, compress, cache.
---

# Token Budget Awareness

## The main context window is expensive and finite

Every token in the main context costs money and latency. Keep it lean.

## Techniques (ranked by impact)

### 1. Delegate to subagents (biggest win)
- Broad codebase recon → `explorer` subagent (cheap model, child session, only result returns).
- Code review → `reviewer` subagent (raw file contents stay in child context).
- The subagent's intermediate tool calls do NOT bloat your main context.

### 2. Use ast-outline before read
- `ast-outline digest` — whole module in ~100 lines.
- `ast-outline outline <file>` — signatures only, no bodies.
- `ast-outline show <file> <symbol>` — exact source of one symbol.
- Only `read` a full file when you've confirmed via the outline that you need most of it.

### 3. Use code-review-graph for blast-radius
- Before editing a function, `code-review-graph` shows all callers/dependents/tests.
- This is lossless structural context — far cheaper than reading every caller.

### 4. Use repomix --compress for repo-wide context
- `repomix --compress --token-budget 32k --stdout` — Tree-sitter AST compression (signatures, no bodies).
- Use when you need the shape of a whole repo/module, not individual files.

### 5. Use context7 for library docs
- Never web-search for library APIs — `context7` fetches only the relevant doc slice.
- A `context7` call returns ~2K tokens vs ~20K for a full docs page scrape.

### 6. Prompt caching
- Keep stable prefixes (system prompt, tool defs, AGENTS.md) at the top of context.
- Cache reads are ~5x cheaper than fresh input.
- Don't reorder or modify the system prompt between turns.

### 7. Compaction
- `compaction.prune: true` drops old tool outputs from context.
- `compaction.auto: true` summarizes context when the window fills.
- Don't fight compaction — let it work. Recent turns stay verbatim.

### 8. PAKT for structured data
- `pakt` MCP compresses JSON/YAML/CSV/Markdown tool outputs losslessly (27-69% reduction).
- Comprehension-evaluated: p=0.50 (statistically indistinguishable from uncompressed).

## Decision tree: do it yourself vs delegate?

```
Is the task broad codebase recon (find files, search code, build repo map)?
  YES → delegate to explorer subagent
  NO ↓

Is the task code review / security audit?
  YES → delegate to reviewer subagent
  NO ↓

Is the task data/ML/notebooks?
  YES → delegate to data-engineer subagent
  NO ↓

Is the task frontend (React/Vue/CSS + browser testing)?
  YES → delegate to frontend-engineer subagent
  NO ↓

Is the task infra (Docker/K8s/Terraform/CI)?
  YES → delegate to devops-engineer subagent
  NO ↓

Is the task documentation?
  YES → delegate to doc-writer subagent
  NO → do it yourself (build agent)
```
