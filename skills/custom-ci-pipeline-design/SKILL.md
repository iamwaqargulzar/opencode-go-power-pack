---
name: custom-ci-pipeline-design
description: Use for CI/CD pipeline design. Covers GitHub Actions, GitLab CI, caching, parallelization, matrix builds, security scans. Trigger on: CI, CD, pipeline, GitHub Actions, GitLab CI, workflow, yaml, automation, build, deploy.
---

# CI Pipeline Design

## Principles

- **Fast** — cache dependencies, parallelize independent jobs, use matrix builds.
- **Correct** — run lint + typecheck + tests on every PR. Block merge on failure.
- **Secure** — run security scans (dependabot, trivy, codeql). Never expose secrets in logs.
- **Observable** — clear job names, useful failure messages, artifacts for debugging.

## GitHub Actions

### Basic template
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: 22
          cache: npm
      - run: npm ci
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        node-version: [20, 22]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: npm
      - run: npm ci
      - run: npm test

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npx audit-ci --moderate
```

### Best practices
- Pin action versions: `actions/checkout@v4` (not `@main` or `@latest`).
- Use `actions/cache` or built-in `cache:` input for dependencies.
- Use `needs:` for job dependencies (DAG, not linear).
- Use `if:` to conditionally skip jobs (e.g. skip docs build on code-only changes).
- Use `concurrency:` to cancel stale runs on the same branch.

## GitLab CI

### Basic template
```yaml
stages: [lint, test, security]

lint:
  stage: lint
  image: node:22
  cache:
    paths: [node_modules/]
  script:
    - npm ci
    - npm run lint

test:
  stage: test
  image: node:${NODE_VERSION}
  parallel:
    matrix:
      - NODE_VERSION: [20, 22]
  script:
    - npm ci
    - npm test

security:
  stage: security
  script:
    - npm audit --audit-level moderate
```

### Best practices
- Use `rules:` not `only/except` (deprecated).
- Use `needs:` for DAG dependencies.
- Use `cache:` with `key:` for per-branch caching.
- Use `artifacts:` for passing build outputs between jobs.
- Use `include:` to split large pipelines into files.

## Verification

- GitHub Actions: `actionlint` validates workflow YAML.
- GitLab CI: `gitlab-ci-lint` validates `.gitlab-ci.yml`.
- Run the pipeline on a PR and confirm all jobs pass.
- Check pipeline runtime — if > 10 min, look for caching/parallelization opportunities.
