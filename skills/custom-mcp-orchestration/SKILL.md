---
name: custom-mcp-orchestration
description: Use when deciding which MCP server to use for a task. Covers playwright, github, context7, sequential-thinking, think, fetch, filesystem, memory, time, git-utils, repomix, code-review-graph, pakt. Trigger on: MCP, tool, playwright, browser, github, context7, docs, fetch, memory, repomix, code-review-graph, pakt.
---

# MCP Orchestration

## Decision table

| Need | MCP server | Why |
|---|---|---|
| Live browser automation, screenshots, clicks, DOM extraction | `playwright` | Only tool that can interact with a running browser |
| Repo, PR, issue, workflow ops on GitHub | `github` | Direct GitHub API access (token auto-extracted from `gh auth token`) |
| Library/SDK documentation | `context7` | Fetches only the relevant doc slice (~2K tokens vs ~20K for a full docs page). Always prefer over web-searching for APIs. |
| Multi-step reasoning with revision and branching | `sequential-thinking` | Step-numbered thoughts, can revise earlier thoughts, can branch into alternatives |
| Pause-and-reflect scratchpad before actions | `think` | Lightweight; just logs a thought. Use before non-trivial edits. |
| JS-rendered web fetch | `fetch` | Richer than built-in webfetch for dynamic pages (SPA, JS-rendered content) |
| Cross-directory file ops | `filesystem` | Move, search, multi-file read/write outside the cwd |
| Persistent cross-session knowledge graph | `memory` | Store facts/decisions across sessions. Use for long-running projects. |
| Current time / timezones | `time` | For timestamps, scheduling, date calculations |
| Git operations via MCP | `git-utils` | Blame, log, diff via MCP (when not using bash git directly) |
| AST-compressed repo-to-text packing | `repomix` | `--compress` for Tree-sitter signatures, `--token-budget` to cap output |
| Blast-radius analysis, caller/dependent/test tracing | `code-review-graph` | ~82x token reduction vs reading every caller. Use before editing any function. |
| Lossless JSON/YAML/CSV/MD compression | `pakt` | Compresses tool outputs 27-69% losslessly (comprehension p=0.50) |

## Common patterns

### Before editing a function
1. `code-review-graph` — who calls this? What tests cover it?
2. `ast-outline outline <file>` — what's the surrounding structure?
3. `think` — plan the edit, check for edge cases.
4. Edit.
5. Run tests.

### When researching a library API
1. `context7` — fetch the relevant doc slice.
2. **Never** web-search for APIs — `context7` is faster, cheaper, and more accurate.

### When debugging a web app
1. `playwright navigate <url>` — go to the page.
2. `playwright screenshot` — see what's rendered.
3. `playwright` click/fill/extract — interact and verify behavior.

### When working with GitHub
1. `github` MCP for PR/issue/workflow ops.
2. `git-utils` MCP for git blame/log/diff.
3. `gh` CLI via bash for anything the MCP doesn't cover.

### When storing cross-session knowledge
1. `memory` MCP — store decisions, architecture facts, project context.
2. Retrieve on next session: `memory` search.
