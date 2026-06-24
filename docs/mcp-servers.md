# MCP Servers

The pack configures MCP servers in `opencode.json`. The installer handles platform differences (Windows uses `["cmd","/c","npx",...]`, *nix uses `["npx",...]`).

## Standard tier (13 servers)

### playwright
- **Command:** `npx -y @playwright/mcp@latest`
- **Purpose:** Live browser automation — navigate, click, fill forms, take screenshots, extract text/DOM.
- **Used by:** `frontend-engineer` agent, browser testing workflows.

### github
- **Command:** `npx -y @modelcontextprotocol/server-github`
- **Env:** `GITHUB_TOKEN` (auto-extracted from `gh auth token` by the installer)
- **Purpose:** Repo, PR, issue, workflow operations via MCP.

### context7
- **URL:** `https://mcp.context7.com/mcp` (remote)
- **Purpose:** Fetch up-to-date, version-specific library documentation. Always prefer this over web-searching for APIs. Returns ~2K tokens of relevant docs vs ~20K for a full docs page.

### sequential-thinking
- **Command:** `npx -y @modelcontextprotocol/server-sequential-thinking`
- **Purpose:** Structured multi-step reasoning with revision and branching. Step-numbered thoughts, can revise earlier thoughts, can branch into alternative reasoning paths.

### fetch
- **Command:** `uvx mcp-server-fetch`
- **Purpose:** JS-rendered web fetch. Richer than built-in webfetch for dynamic pages (SPAs, JS-rendered content).

### filesystem
- **Command:** `npx -y @modelcontextprotocol/server-filesystem .`
- **Purpose:** Cross-directory file operations (move, search, multi-file read/write).

### memory
- **Command:** `npx -y @modelcontextprotocol/server-memory`
- **Purpose:** Persistent cross-session knowledge graph. Store facts, decisions, architecture context that survives across sessions.

### time
- **Command:** `uvx mcp-server-time`
- **Purpose:** Current time and timezone information. For timestamps, scheduling, date calculations.

### git-utils
- **Command:** `uvx mcp-server-git`
- **Purpose:** Git operations via MCP (blame, log, diff, status).

### repomix
- **Command:** `npx -y repomix@latest --mcp`
- **Purpose:** AST-compressed repo-to-text packing. Tree-sitter `--compress` keeps signatures, drops bodies. `--token-budget` caps output.

### code-review-graph
- **Command:** `code-review-graph serve`
- **Purpose:** Blast-radius analysis. Parses repo into an AST graph, traces callers/dependents/tests for any function. ~82x median token reduction (38-528x) vs reading every caller. Auto-configures opencode.
- **Install:** `pip install code-review-graph && code-review-graph install`

### pakt
- **Command:** `npx -y @sriinnu/pakt serve --stdio`
- **Purpose:** Lossless JSON/YAML/CSV/Markdown compression. L1-L3 layers are truly reversible. Comprehension-evaluated: p=0.50 sign test (statistically indistinguishable from uncompressed). 27-69% token reduction on structured data.

## Full tier additions (5 more = 18 total)

### arbor
- **Command:** `arbor`
- **Purpose:** Tree-sitter MCP server. 14 surgical tools (boot, skeleton, compact, source, callers, references, dependencies, impact, search, summary, symbols, implementations, reindex, tunnels). 1M LOC → 500 lines.
- **Install:** `curl -fsSL https://raw.githubusercontent.com/nikita-voronoy/arbor/main/scripts/install.sh | bash`

### provenant
- **Command:** `provenant serve .`
- **Purpose:** Wiki-based retrieval MCP for coding agents. Tree-sitter parse → wiki pages → BM25/vector/HyDE retrieval → cited answers. SWE-bench Verified: +24pp File Coverage@5, 60-65x lower context size.
- **Install:** `pip install provenant`

### headroom
- **Command:** `headroom mcp`
- **Purpose:** Compresses tool outputs, logs, files, RAG chunks before the LLM. 6 algorithms incl. CCR (reversible compression with on-demand retrieval). GSM8K ±0.000 (no capability loss). 60-95% token reduction.
- **Install:** `pip install "headroom-ai[all]"`

### aleph
- **Command:** `aleph`
- **Purpose:** Recursive Language Models. 30+ tools including think/evaluate_progress/get_evidence/finalize + server-side Python/JS execution for verification. Ships as MCP server + skill pair.
- **Install:** `pip install "aleph-rlm[mcp]"`

### (context-compress — full tier alternative)
- **Command:** `node /path/to/context-compress/dist/index.js`
- **Purpose:** 4-mode tool-output compression (conservative/balanced/aggressive/auto-LLM-judged). 93% reduction in aggressive mode.

## Lean tier (10 servers)

Lean excludes: `think`, `code-review-graph`, `pakt`. It includes all other standard-tier servers.
