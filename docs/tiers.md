# Tiers

The installer supports three tiers. Pick the one that matches your needs.

## Tier comparison

| Component | lean | **standard** (default) | full |
|---|---|---|---|
| **MCP servers** | 10 | 13 | 18 |
| **Custom skills** | 22 | 22 | 22 |
| **Third-party skill packs** | superpowers (plugin) | + CodeRabbit | + farmage(66) + addyosmani(24) + cherry-pick(10) |
| **External CLIs** | gtr | + ast-outline + ast-grep + essentials | + jscodeshift + libcst + aider |
| **Spec-driven spine** | AGENTS.md only | + GitHub Spec Kit | + APM (multi-agent) |
| **DoD gate** | AGENTS.md only | skillgate | + donegate (CI) |
| **Drift detector** | — | — | coherence |
| **Reasoning MCP** | sequential-thinking | + think | + aleph |
| **Lossless context MCP** | repomix | + code-review-graph + PAKT | + arbor + provenant + headroom |
| **RTK plugin** | ✓ | ✓ | ✓ |
| **Pure config techniques** | ✓ | ✓ | ✓ |

## Which tier should I pick?

### lean
- You want a minimal setup with the core agents, custom skills, and basic MCP.
- You're on a slow connection and don't want to prefetch many packages.
- You'll add more later as needed.

### standard (default)
- Best capability/cost balance out of the box.
- Adds the `think` MCP (+1.6% SWE-bench), `code-review-graph` (~82x token reduction), `PAKT` (lossless compression).
- Adds CodeRabbit skills (native opencode support), GitHub Spec Kit, skillgate DoD gate.
- Adds `ast-outline` and `ast-grep` CLIs for structural code navigation and refactoring.

### full
- Maximum capability. Everything from standard plus:
- 4 third-party skill packs (~115 skills total).
- `arbor` (1M LOC → 500 lines), `provenant` (retrieval-based, SWE-bench validated), `headroom` (60-95% reduction).
- `aleph` MCP (Recursive Language Models, 30+ tools).
- APM (Agentic Project Management) for multi-agent architect-builder-verifier workflows.
- `donegate` (CI DoD gate) + `coherence` (drift detector).
- `jscodeshift` + `libcst` codemods + `aider` CLI.

## Switching tiers

To switch tiers, run the installer with the new tier. It will overwrite the config with the new tier's settings:

```powershell
.\install.ps1 -Tier full -Force
```

```bash
./install.sh --tier full --force
```

You don't need to uninstall first — the installer backs up your existing config and overwrites it.
