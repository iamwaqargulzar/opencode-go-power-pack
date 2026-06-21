# Token Reduction (Lossless)

The pack uses a layered approach that reduces tokens **without hindering the LLM's capabilities**. Every technique here is either truly lossless or lossless-on-demand.

## Why not LLMLingua?

LLMLingua and LLMLingua-2 are **lossy** — they drop tokens based on a small LM's entropy scoring. Despite marketing claims of "faithfulness," the kept tokens are verbatim but tokens ARE discarded. The Gist Token Study (arXiv:2412.17483) confirms lossy compression fails on exact recall.

This pack **excludes LLMLingua** and replaces it with truly lossless alternatives.

## The stack (7 layers)

### 1. Prompt caching (truly lossless, 90% cost reduction)
- **Config:** `provider.opencode-go.options.setCacheKey: true`
- **How:** Caches stable prompt prefixes (system prompt, tool definitions, AGENTS.md). Cache hits cost ~10% of base input price. Output tokens are identical — zero capability degradation.
- **GLM-5.2 example:** cache read $0.26 vs $1.40 input — 5x cheaper on cacheable prefixes.
- **Best practice:** Keep stable prefixes at the top of context. Don't reorder system prompt between turns.

### 2. Compaction prune (drops old tool outputs)
- **Config:** `compaction.prune: true`, `compaction.auto: true`, `compaction.reserved: 10000`
- **How:** When context fills, the hidden `compaction` agent summarizes old context and drops old tool outputs. Recent turns stay verbatim.
- **Lossless?** The summary is lossy, but recent turns are preserved. This is opencode's built-in mechanism — accept it rather than fighting it.

### 3. Subagent delegation (lossless via context partitioning)
- **Config:** `explorer` and `reviewer` subagents in `opencode.json`
- **How:** Delegate broad codebase recon to the `explorer` subagent. It runs in a child session with its own context window. Only the final result returns to the parent's context. The subagent's intermediate tool calls (file reads, grep results, etc.) do NOT bloat the main context.
- **Lossless?** Yes — the subagent sees everything it needs. The parent just doesn't see the intermediate steps (which it doesn't need).

### 4. ast-outline CLI (truly lossless, 2-10x per file)
- **Install:** `uv tool install ast-outline` (standard+ tier)
- **How:** Stateless tree-sitter CLI. Three levels of progressive disclosure:
  - `ast-outline digest` — whole module in ~100 lines (signatures + size labels)
  - `ast-outline outline <file>` — all signatures with line ranges, no bodies
  - `ast-outline show <file> <symbol>` — exact source of one named symbol
- **Lossless?** Yes — signatures are verbatim, `show` returns exact source. No selection bias — the agent asks for exactly what it needs.

### 5. code-review-graph MCP (~82x median reduction, benchmarked)
- **Install:** `pip install code-review-graph && code-review-graph install` (standard+ tier)
- **How:** Parses repo into an AST graph. Before editing a function, query `code-review-graph` to see all callers, dependents, and tests. Returns ~100 tokens of structural context instead of reading every caller.
- **Lossless?** Lossless-on-demand — the graph contains exact AST-extracted symbols. The agent can request full source when needed.
- **Benchmarks:** ~82x median token reduction (range 38-528x) across 6 real repos. fastapi: 951k → 2.2k tokens (528x).

### 6. PAKT MCP (truly lossless, 27-69% on structured data)
- **Install:** `npm install @sriinnu/pakt` (standard+ tier)
- **How:** Pipe-Aligned Kompact Text. Three lossless layers: L1 structural (pipe-delimited), L2 dictionary substitution, L3 tokenizer-aware (real BPE). L4 semantic is opt-in and explicitly lossy.
- **Lossless?** L1-L3 are truly reversible (round-trip verified). Comprehension-evaluated: 36 questions × 4 runs = 144 paired observations through Claude Code, JSON 73.6% vs PAKT 70.8% accuracy, two-sided sign test **p=0.50** — statistically indistinguishable from uncompressed.

### 7. LSP (lossless symbol info)
- **Config:** `lsp: true` in `opencode.json`
- **How:** `goToDefinition`/`findReferences`/`hover` return compact symbols instead of whole-file reads. Experimental in opencode.
- **Lossless?** Yes — LSP returns exact type/symbol information from the language server.

## Full-tier additions

### arbor MCP (1M LOC → 500 lines)
- Tree-sitter MCP, 14 surgical tools. `compact` = lossless signatures; `source` = exact implementation.
- bevy (1,756 files, ~1.1M LOC) → compact skeleton 552 lines (~9k tokens).

### provenant MCP (60-65x context reduction, SWE-bench validated)
- Wiki-based retrieval. Tree-sitter parse → wiki pages → BM25/vector/HyDE retrieval → cited answers.
- SWE-bench Verified: 63.8% File Coverage@5 (+7.6pp over raw BM25).

### headroom (60-95% reduction, GSM8K ±0.000)
- 6 algorithms incl. CCR (reversible compression — originals cached, LLM retrieves on demand).
- GSM8K ±0.000 (100 samples) — no capability loss. TruthfulQA +0.030.

## Decision tree: which technique for which situation?

```
Stable prefix (system prompt, tool defs)?
  → Prompt caching (config, zero effort)

Old tool outputs bloating context?
  → compaction.prune (config, automatic)

Broad codebase recon needed?
  → Delegate to explorer subagent

Need to understand a module's structure?
  → ast-outline digest (~100 lines)

Need one file's signatures?
  → ast-outline outline <file>

Need one function's implementation?
  → ast-outline show <file> <symbol>

Need to know who calls a function?
  → code-review-graph blast-radius

Need repo-wide context for a plan?
  → repomix --compress --token-budget 32k --stdout

Compressing JSON/YAML/CSV/MD tool output?
  → PAKT MCP (lossless, p=0.50 comprehension)

Large repo, need retrieval-based context?
  → provenant MCP (full tier)

Want a full proxy/wrap solution?
  → headroom (full tier)
```
