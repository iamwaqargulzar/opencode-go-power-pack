---
description: Generate or update documentation. ADRs for decisions, README sections for usage.
agent: doc-writer
---

Generate or update documentation for $ARGUMENTS.

Steps:
1. **Understand the code** — run `ast-outline digest` for module maps. Use `code-review-graph` to understand dependencies and blast radius. Read key files to understand the architecture. Delegate broad recon to the `explorer` subagent if needed.
2. **Check existing docs** — look for `docs/`, `README.md`, `docs/adr/`, `.speckit/`. Follow the repo's existing doc format and conventions.
3. **Produce documentation:**
   - **README sections** — usage, API, examples, installation, configuration, troubleshooting. Clear table of contents for long docs.
   - **ADRs** — one file per architectural decision in `docs/adr/`. Format: `ADR-NNNN-title.md` with sections: Context, Decision, Status, Consequences.
   - **API docs** — document the *why*, not the *what* (the code shows the what). Document edge cases, gotchas, performance characteristics.
   - **Inline docs** — only where the code is non-obvious. Never document what the code already says. Explain *why*, not *what*.
   - **Examples** — runnable code snippets that actually work. Test them.

4. **Verify** — if the repo has a docs linter (`markdownlint`, `vale`, etc.), run it. If the repo has a docs build (`mkdocs`, `docusaurus`, etc.), run it and confirm it succeeds. Read your own docs — do they make sense?

5. **Conventional commits** — `docs(scope): description`.

Keep output focused. Don't write 500-line READMEs unless asked. Prefer concise, well-structured docs over verbose ones.
