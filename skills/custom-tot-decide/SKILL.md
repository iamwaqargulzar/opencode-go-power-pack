---
name: custom-tot-decide
description: Use before non-trivial edits or decisions. Proposes 3 candidate approaches, scores each on simplicity/blast-radius/regression-risk, proceeds with the highest-scoring. Tree-of-Thoughts pattern. Trigger on: decide, choose, approach, strategy, option, alternative, brainstorm, plan, refactor strategy, how to fix.
---

# Tree-of-Thoughts Decide

## When to use

Before any non-trivial edit:
- Choosing how to implement a feature.
- Choosing how to fix a bug when multiple fixes are possible.
- Choosing a refactoring strategy.
- Any decision where the first idea might not be the best.

## The protocol

### 1. Propose 3 candidate approaches
Generate three genuinely different approaches. Not minor variations — different strategies.

**Example (fixing a slow query):**
- **A:** Add an index on `user_id`.
- **B:** Rewrite the query to use a JOIN instead of a subquery.
- **C:** Cache the result in Redis with a 5-minute TTL.

### 2. Score each
Score each approach on three dimensions (1-5, higher is better):

| Dimension | What it means |
|---|---|
| **Simplicity** | How easy to implement and understand. Less code, fewer moving parts = higher. |
| **Blast radius** | How much of the codebase is affected. Fewer files, fewer callers affected = higher. |
| **Low regression risk** | How unlikely to break existing behavior. More tested, more isolated = higher. |

**Example:**
| Approach | Simplicity | Blast radius | Low regression risk | Total |
|---|---|---|---|---|
| A: Add index | 5 (one line) | 5 (no code changes) | 4 (might affect write perf) | **14** |
| B: Rewrite query | 3 (moderate) | 3 (changes SQL) | 2 (might change results) | **8** |
| C: Cache in Redis | 2 (adds infra) | 4 (isolated) | 3 (cache invalidation bugs) | **9** |

### 3. Proceed with the highest-scoring
Choose the approach with the highest total. Explain why briefly.

**Example:** "I'll add an index on `user_id` (approach A, score 14). It's the simplest, has no code changes, and the only risk is write performance — which we can monitor."

### 4. Record the others
Keep the other approaches in your working notes in case you need to backtrack:
```
## ToT Decision
- Task: fix slow user query
- A: Add index on user_id — score 14 — CHOSEN
- B: Rewrite query to JOIN — score 8 — fallback if A doesn't help
- C: Cache in Redis — score 9 — fallback if query is still slow after A
```

## When NOT to use this

- Trivial fixes (one-line changes, typos, obvious bugs).
- When only one approach is possible.
- When the user explicitly told you which approach to use.

## Anti-patterns

- **Don't propose 3 approaches that are all the same.** "1. Add a check. 2. Add a check in a different place. 3. Add a check with a different message" — these are the same approach.
- **Don't score before proposing.** Generate all 3 first, then score. Scoring during generation biases the proposals.
- **Don't ignore the scores.** If you score A=14 and B=8, don't pick B because you "like it better." Follow the scores unless there's a compelling reason not to (and state that reason).
