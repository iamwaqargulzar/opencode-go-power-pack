---
name: custom-secrets-hygiene
description: Use for ALL tasks involving credentials, API keys, tokens, or environment variables. Enforces never-commit-secrets, env var references, .gitignore, secret scanning. Trigger on: secret, API key, token, password, credential, .env, GITHUB_TOKEN, env var, environment variable.
---

# Secrets Hygiene

## Absolute rules

1. **Never commit secrets to git.** No API keys, tokens, passwords, private keys, `.env` files.
2. **Never log secrets.** Don't `print(api_key)`, don't `console.log(token)`, don't include secrets in error messages.
3. **Never hardcode secrets in source.** Read from environment variables or a secret manager.
4. **Never put secrets in URLs.** `https://api.example.com?api_key=sk-xxx` is logged by proxies, load balancers, and browser history.

## How to reference secrets

### In code
```python
import os
api_key = os.environ["API_KEY"]  # raises KeyError if missing — fail fast
```

```typescript
const apiKey = process.env.API_KEY;  // undefined if missing — check explicitly
if (!apiKey) throw new Error("API_KEY is required");
```

### In opencode.json
Use `{env:VAR}` interpolation (NOT `${VAR}`):
```json
{
  "mcp": {
    "github": {
      "environment": {
        "GITHUB_TOKEN": "{env:GITHUB_TOKEN}"
      }
    }
  }
}
```

### In docker-compose.yml
Use `env_file:` or environment variables, never inline:
```yaml
services:
  app:
    env_file: .env  # .env is gitignored
    environment:
      DATABASE_URL: postgresql://user:${DB_PASS}@db:5432/app  # ${} is compose interpolation
```

## .gitignore (always include)
```
.env
.env.local
.env.*.local
*.pem
*.key
secrets.json
credentials.json
```

## If you discover a committed secret

1. **Remove it from the code** immediately.
2. **Rotate it** — the secret is compromised. Generate a new one.
3. **Remove it from git history** — `git filter-repo` or BFG Repo-Cleaner (just deleting it in a new commit leaves it in history).
4. **Add it to .gitignore** to prevent re-committing.
5. **Report** to the user that a secret was found, rotated, and cleaned.

## Secret scanning

If the repo has a secret scanner (trufflehog, gitleaks, git-secrets), run it before committing:
```bash
gitleaks detect --source . --no-git
```

## Common pitfalls

- `.env.example` files are OK to commit (they have placeholder values, not real secrets).
- Test fixtures sometimes contain real secrets — review them.
- Docker images can leak secrets in layers — use multi-stage builds and `COPY --from=builder`.
- CI logs can leak secrets — mask them in the CI config (GitHub Actions: `::add-mask::`).
