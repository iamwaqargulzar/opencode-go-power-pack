---
name: custom-docs-as-code
description: Use when writing or updating documentation. Covers README sections, ADRs, API docs, inline docs, docs linters/builds. Trigger on: docs, documentation, README, ADR, architecture decision, API docs, inline, docstring, JSDoc, mkdocs, docusaurus.
---

# Docs as Code

## Principles

- **Document the *why*, not the *what*.** The code shows the what. Docs should explain why decisions were made, what edge cases exist, what gotchas to watch for.
- **Never document what the code already says.** If `def add(a, b): return a + b` — don't write "This function adds two numbers."
- **Keep docs next to the code.** ADRs in `docs/adr/`, API docs inline (docstrings/JSDoc), README at the root.
- **Docs are versioned.** Commit docs with the code. PRs that change behavior should update docs in the same PR.

## README structure

```markdown
# Project Name

One-sentence description.

## Quick start
## Usage
## Configuration
## API reference
## Examples
## Troubleshooting
## Contributing
## License
```

Only include sections that are relevant. Don't pad with empty sections.

## ADR format (Nygard)

`docs/adr/ADR-NNNN-title.md`:

```markdown
# ADR-NNNN: Title

## Status
Accepted | Proposed | Deprecated | Superseded by ADR-XXXX

## Context
What is the issue we're facing? What constraints? What forces?

## Decision
What is the change we're making? What did we decide?

## Consequences
What are the trade-offs? What becomes easier? What becomes harder?
```

## API docs

- **Python** — docstrings (Google or NumPy style, follow the repo's convention).
- **TypeScript/JavaScript** — JSDoc/TSDoc.
- **Go** — doc comments directly above declarations.
- **Rust** — `///` doc comments, `cargo doc` to build.

Document: parameters, return values, exceptions, side effects, performance characteristics, thread safety.

## Inline docs

Only where the code is non-obvious:
- Why a specific algorithm was chosen over alternatives.
- Why a seemingly wrong-looking line is actually correct.
- Workarounds for upstream bugs with links to the issue.
- Performance-critical sections with reasoning.

## Verification
- If the repo has a docs linter (`markdownlint`, `vale`, etc.), run it.
- If the repo has a docs build (`mkdocs`, `docusaurus`, etc.), run it and confirm it succeeds.
- Read your own docs — would a new contributor understand them?
