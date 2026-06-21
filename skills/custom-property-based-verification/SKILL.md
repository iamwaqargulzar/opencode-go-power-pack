---
name: custom-property-based-verification
description: Use when verifying code against a spec. Covers property-based testing with hypothesis (Python) and fast-check (TS/JS). Extracts properties from EARS requirements, generates random test cases, shrinks counter-examples. Trigger on: property-based, PBT, hypothesis, fast-check, random testing, spec verification, counter-example, shrink, EARS, requirements.
---

# Property-Based Verification

## What PBT is

Property-based testing (PBT) generates hundreds/thousands of random test cases to check that a *property* of your code always holds. When a test fails, the framework "shrinks" to find the minimal counter-example. This is the lightweight formal-verification method used by Kiro.

## Properties vs examples

### Example-based testing (traditional)
```python
def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
```
Tests a few specific cases. Might miss edge cases.

### Property-based testing
```python
from hypothesis import given, strategies as st

@given(st.integers(), st.integers())
def test_add_commutative(a, b):
    assert add(a, b) == add(b, a)  # property: addition is commutative

@given(st.integers(), st.integers())
def test_add_zero_is_identity(a, _):
    assert add(a, 0) == a  # property: zero is identity
```
Tests hundreds of random cases. Finds edge cases you didn't think of.

## Extracting properties from EARS requirements

| EARS requirement | Property |
|---|---|
| "The system shall authenticate users via OAuth 2.0" | For any valid token, auth succeeds. For any invalid token, auth fails. |
| "When a user submits the login form, the system shall validate the email format" | For any invalid email, the system rejects it. For any valid email, the system accepts it. |
| "While the rate limit is exceeded, the system shall return HTTP 429" | For any request when rate limit is exceeded, response status is 429. |
| "If the database connection fails, then the system shall return 503" | For any request when DB is down, response status is 503. |

## Python (hypothesis)

```python
from hypothesis import given, strategies as st, settings
import pytest

@given(st.emails())
@settings(max_examples=500)
def test_valid_emails_accepted(email):
    assert validate_email(email) is True

@given(st.text().filter(lambda s: "@" not in s))
def test_invalid_emails_rejected(email):
    assert validate_email(email) is False
```

## TypeScript/JavaScript (fast-check)

```typescript
import fc from 'fast-check';

test('add is commutative', () => {
  fc.assert(fc.property(fc.integer(), fc.integer(), (a, b) => {
    expect(add(a, b)).toBe(add(b, a));
  }));
});
```

## When a property fails

1. The framework shrinks to the minimal counter-example (e.g. `add(0, -1) != add(-1, 0)`).
2. **Decide what's wrong:**
   - Is the implementation wrong? → fix the code.
   - Is the property wrong? → fix the property/test.
   - Is the spec wrong? → fix the spec (EARS requirement) and notify the user.
3. Re-run. Confirm the property holds for all generated cases.

## When to use PBT

- When you have a spec (EARS requirements) — extract properties from each requirement.
- When the function has a mathematical property (commutativity, associativity, idempotency, monotonicity).
- When edge cases are hard to enumerate (unicode, large numbers, empty collections, nested structures).
- When you want higher confidence than example-based tests provide.

## When NOT to use PBT

- Trivial functions where example tests are sufficient.
- Functions with side effects that are hard to randomize (I/O, network, time).
- When the property is hard to express — don't force it. Use example tests instead.
