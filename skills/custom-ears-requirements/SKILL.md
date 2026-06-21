---
name: custom-ears-requirements
description: Use when writing requirements or specs. Covers EARS (Easy Approach to Requirements Syntax) form for unambiguous, testable requirements. Trigger on: requirements, spec, specification, EARS, SHALL, MUST, WHEN, WHILE, IF, THEN, acceptance criteria, user story.
---

# EARS Requirements

## What EARS is

EARS (Easy Approach to Requirements Syntax) is a structured form for writing requirements that are unambiguous and testable. It's the basis for Kiro's spec-driven development and works with property-based testing.

## EARS patterns

| Pattern | Form | When to use |
|---|---|---|
| Ubiquitous | **The system shall** `<response>` | Always true, no conditions |
| Event-driven | **When** `<trigger>`, **the system shall** `<response>` | Triggered by an event |
| State-driven | **While** `<state>`, **the system shall** `<response>` | True while in a state |
| Optional | **Where** `<feature>` is enabled, **the system shall** `<response>` | Conditional on a feature |
| Unwanted | **If** `<trigger>`, **then the system shall** `<response>` | Error/exception handling |

## Examples

### Good (EARS form)
```
The system shall authenticate users via OAuth 2.0.
When a user submits the login form, the system shall validate the email format.
While the rate limit is exceeded, the system shall return HTTP 429.
Where dark mode is enabled, the system shall use the dark color palette.
If the database connection fails, then the system shall return a 503 error and log the incident.
```

### Bad (vague, untestable)
```
The system should handle login.  # "should"? "handle"? No acceptance criteria.
Users can log in.  # No system responsibility, no trigger, no response.
The system must be secure.  # "secure" is not testable.
```

## Writing requirements

1. **Identify the system** — "The system" or name a specific component ("The auth service").
2. **Choose the pattern** — Ubiquitous, Event-driven, State-driven, Optional, Unwanted.
3. **Write the trigger/state/feature** (if applicable) — be specific and testable.
4. **Write the response** — what the system does. Be observable and measurable.
5. **Add acceptance criteria** — how do you verify this requirement is met?

## Storing requirements

- In `docs/specs/YYYY-MM-DD-<topic>-spec.md` (superpowers convention).
- In `.speckit/specs/` (GitHub Spec Kit convention).
- In `requirements.md` (Kiro convention).

Each requirement gets an ID for traceability: `REQ-001`, `REQ-002`, etc.

## Linking to tests

Each requirement should map to at least one test:
```
REQ-001: The system shall authenticate users via OAuth 2.0.
  → test_auth_oauth.py::test_oauth_authentication
  → test_auth_oauth.py::test_invalid_token_rejected
```

This is the basis for `custom-property-based-verification` — extract properties from EARS requirements and test them with random inputs.
