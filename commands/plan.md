---
description: Analyze a task and produce a step-by-step implementation plan. Read-only.
agent: plan
---

Analyze $ARGUMENTS and produce a step-by-step implementation plan.

Steps:
1. Run `ast-outline digest` to get a ~100-line module map of the relevant area.
2. Run `code-review-graph` to understand dependencies and blast radius of the areas you'll touch.
3. Use `grep` / `rg` for targeted searches if you need specific patterns.
4. Use the `think` MCP tool and `sequential-thinking` MCP to decompose the problem.
5. For non-trivial decisions, propose 3 candidate approaches (Tree-of-Thoughts), score each on (simplicity, blast radius, risk of regression), proceed with the highest-scoring.

Output a markdown plan with:
- **Objective** — one paragraph stating what the plan achieves.
- **Files to touch** — list of files with one-line rationale each.
- **Ordered steps** — numbered, each with: what to do, which file, verification step.
- **Risks** — what could go wrong, blast radius.
- **Edge cases** — what the implementation must handle.
- **Spec reference** — if a spec exists in `docs/specs/` or `.speckit/`, reference it.

If the task is a feature, write requirements in EARS form ("THE System SHALL...") so they can be property-tested later.

Do not edit files. Hand off to the build agent for implementation.
