# Spec-Driven Development

The pack installs a spec-driven-development spine that keeps code aligned with requirements. This is the answer to "how do I keep the code to spec?"

## The spine (3 layers)

### Layer 1: GitHub Spec Kit (the spine)
- **Install:** `uv tool install specify-cli` (standard+ tier)
- **Per-project setup:**
  ```bash
  cd your-project
  specify init . --integration opencode
  ```
- **Workflow:**
  1. `/speckit.constitution` — governing principles for the project.
  2. `/speckit.specify` — requirements and user stories.
  3. `/speckit.clarify` — resolve ambiguities.
  4. `/speckit.plan` — technical plan.
  5. `/speckit.tasks` — task breakdown.
  6. `/speckit.implement` — execute tasks.
  7. `/speckit.converge` — **reconcile codebase against spec; append remaining work as new tasks.**
  8. `/speckit.checklist` — "unit tests for English" — custom quality checklists.
  9. `/speckit.analyze` — cross-artifact consistency & coverage analysis.

The key command is `/speckit.converge` — it assesses the codebase against the spec/plan/tasks and appends remaining work as new tasks. This is the spec-vs-implementation reconciliation loop.

### Layer 2: superpowers (the gated methodology)
Installed as a plugin. The gated workflow:
1. `brainstorming` — Socratic design refinement, user approval gate, spec saved to `docs/superpowers/specs/`.
2. `using-git-worktrees` — isolated workspace on new branch.
3. `writing-plans` — bite-sized tasks (2-5 min each), exact file paths, verification steps.
4. `subagent-driven-development` / `executing-plans` — fresh subagent per task with **two-stage review** (spec compliance, then code quality).
5. `test-driven-development` — enforced RED-GREEN-REFACTOR.
6. `requesting-code-review` — reviews against plan, critical issues block progress.
7. `finishing-a-development-branch` — verify tests, merge/PR/keep/discard.
8. `verification-before-completion` — "Ensure it's actually fixed."

The **two-stage review** in `subagent-driven-development` is unique: first the reviewer checks spec compliance (does the code match the plan?), then code quality. These are separate concerns assessed separately.

### Layer 3: skillgate (deterministic DoD gate)
- **Install:** per-project — see https://github.com/renezander030/skillgate (standard+ tier)
- **Purpose:** Deterministic, model-independent gate that blocks commit/publish until the Definition of Done passes. Unlike skills (which are prompt-level enforcement), skillgate is code-level — it doesn't rely on the LLM to self-assess.

## EARS requirements

The `custom-ears-requirements` skill teaches the agent to write requirements in EARS (Easy Approach to Requirements Syntax) form:

| Pattern | Form |
|---|---|
| Ubiquitous | **The system shall** `<response>` |
| Event-driven | **When** `<trigger>`, **the system shall** `<response>` |
| State-driven | **While** `<state>`, **the system shall** `<response>` |
| Optional | **Where** `<feature>` is enabled, **the system shall** `<response>` |
| Unwanted | **If** `<trigger>`, **then the system shall** `<response>` |

Example:
```
When a user submits the login form, the system shall validate the email format.
If the database connection fails, then the system shall return a 503 error and log the incident.
```

## Property-based verification

The `custom-property-based-verification` skill extracts properties from EARS requirements and tests them with random inputs:

- **Python:** `hypothesis` — generates hundreds of random test cases, shrinks counter-examples.
- **TypeScript/JavaScript:** `fast-check` — same concept.

Example:
```python
from hypothesis import given, strategies as st

@given(st.lists(st.integers(min_value=0), min_size=1))
def test_no_nulls_after_cleaning(values):
    df = pd.DataFrame({"value": values})
    result = clean_data(df)
    assert result["value"].isnull().sum() == 0
```

When a property fails:
1. The framework shrinks to the minimal counter-example.
2. Decide what's wrong: implementation? property? spec?
3. Fix the appropriate layer.

## Full-tier additions

### APM (Agentic Project Management)
- **Install:** `npm install -g agentic-pm && apm init` (select opencode)
- Multi-agent architect-builder-verifier system:
  - **Planner** — produces Spec, Plan, Rules.
  - **Manager** — coordinates execution, assigns Tasks to Workers.
  - **Workers** — execute Tasks within domains, validate, log to memory, report back.
- Project state lives in structured files *outside any agent's context* — structured Handoff transfers working knowledge to a fresh instance.
- Variants: APM Auto (autonomous subagent dispatch), APM Semi (user claims tasks, agent assists).

### donegate (CI DoD gate)
- Tamper-guarded DoD gate for CI. Stronger enforcement than skillgate.
- Use alongside skillgate: skillgate for local pre-commit, donegate for CI.

### coherence (drift detector)
- Detects when implementation has drifted from documented spec/ADRs/tests.
- Run as a pre-commit hook or opencode hook.
- Closes the loop between living docs and code.
