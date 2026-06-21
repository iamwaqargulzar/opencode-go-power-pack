---
name: custom-repo-context-packing
description: Use when you need to understand a whole repo or large module. Covers repomix, ast-outline digest, code-review-graph, and progressive disclosure patterns. Trigger on: repo map, context, large codebase, understand, repomix, ast-outline, digest, blast radius.
---

# Repo Context Packing

## The problem

Reading every file in a repo to understand it = millions of tokens. Most of those tokens are implementation bodies you don't need yet.

## The solution: progressive disclosure

Load the *shape* first (signatures, structure, dependencies). Only load *bodies* when you need the implementation.

## Techniques (from cheapest to most detailed)

### 1. ast-outline digest (~100 lines, whole module)
```bash
ast-outline digest
```
Gives a one-page module map with size labels and token estimates. Cheapest possible overview.

### 2. ast-outline outline (signatures only, per file)
```bash
ast-outline outline src/handlers/auth.ts
```
Shows all function/class signatures with line ranges, no bodies. ~2-10x smaller than reading the file.

### 3. ast-outline show (exact source, one symbol)
```bash
ast-outline show src/handlers/auth.ts loginHandler
```
Returns the exact source of one named symbol. Use when you've confirmed via the outline that you need this specific implementation.

### 4. code-review-graph (blast radius)
```bash
code-review-graph build
code-review-graph serve  # MCP mode
```
Parses the repo into an AST graph. Shows callers, dependents, tests for any function. ~82x median token reduction vs reading every caller.

### 5. repomix --compress (AST-compressed repo-to-text)
```bash
repomix --compress --token-budget 32k --stdout
```
Tree-sitter AST compression: keeps signatures/types, drops bodies. `--token-budget` caps output. Use when you need the shape of a whole repo.

### 6. Full file read (last resort)
Only `read` a full file when:
- `ast-outline outline` showed it's small enough to need most of it, OR
- You need the implementation of multiple symbols in the file, OR
- The file is non-code (config, markdown, etc.) and `ast-outline` doesn't apply.

## Decision tree

```
Need to understand a whole module/repo?
  → ast-outline digest (~100 lines)

Need to understand one file's structure?
  → ast-outline outline <file> (signatures only)

Need one function's implementation?
  → ast-outline show <file> <symbol> (exact source)

Need to know who calls a function / what it affects?
  → code-review-graph (blast radius)

Need repo-wide context for a plan?
  → repomix --compress --token-budget 32k --stdout

Need the full file?
  → read (last resort)
```
