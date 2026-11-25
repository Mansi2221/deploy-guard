# Deploy Guard

A GitHub Action that blocks merges when deployment readiness checks fail. Catch misconfigurations before they hit production.

## Checks

| Check | What it catches |
|-------|----------------|
| **Environment** | Env vars in `.env.example` not referenced in code |
| **Dockerfile** | No USER (runs as root), no HEALTHCHECK, `:latest` tag, copying secrets, missing `.dockerignore` |
| **Secrets** | Hardcoded API keys, AWS credentials, tokens, passwords in source |
| **CI/CD** | No GitHub Actions, GitLab CI, Jenkins, CircleCI, or other pipeline |

## Quick Start

```yaml
# .github/workflows/deploy-guard.yml
name: Deploy Guard

on:
  pull_request:
    branches: [main]

jobs:
  guard:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: Mansi2221/deploy-guard@v1
```

That's it. PRs that fail checks are blocked from merging.

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `skip-checks` | Comma-separated checks to skip: `env,docker,secrets,ci` | `''` |
| `env-example-path` | Path to `.env.example` | `.env.example` |
| `dockerfile-path` | Path to Dockerfile (auto-detected if empty) | `''` |
| `fail-on-warnings` | Treat warnings as failures | `false` |

## Examples

### Skip specific checks

```yaml
- uses: Mansi2221/deploy-guard@v1
  with:
    skip-checks: 'env,ci'
```

### Custom Dockerfile path

```yaml
- uses: Mansi2221/deploy-guard@v1
  with:
    dockerfile-path: 'docker/Dockerfile.prod'
```

### Strict mode (warnings = failures)

```yaml
- uses: Mansi2221/deploy-guard@v1
  with:
    fail-on-warnings: 'true'
```

## Outputs

| Output | Description |
|--------|-------------|
| `passed` | `true` if all checks passed, `false` otherwise |
| `report` | Full check report as a table |

## How It Works

1. Runs four independent checks against your repository
2. Each check writes a PASS, WARN, or FAIL result
3. Results are displayed in the GitHub Actions step summary
4. If any check FAILs, the action exits with a non-zero code, blocking the merge

## License

MIT
