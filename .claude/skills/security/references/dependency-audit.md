# Dependency Audit Reference

## Per-Ecosystem Commands

### PHP (Composer)
```bash
# Audit for known CVEs
composer audit

# Update all dependencies (check breaking changes first)
composer update

# Update single package
composer update vendor/package

# Show outdated packages
composer outdated
```

### Node.js (npm / yarn / pnpm)
```bash
# Audit
npm audit
yarn audit
pnpm audit

# Auto-fix safe updates (no breaking changes)
npm audit fix

# Force fix including breaking changes (review output!)
npm audit fix --force

# Show outdated
npm outdated
```

### Python (pip / uv / poetry)
```bash
# pip-audit (recommended)
pip install pip-audit
pip-audit

# safety (alternative)
pip install safety
safety check

# With uv
uv pip audit

# With poetry
poetry run pip-audit
```

### Go
```bash
# govulncheck (official Go tool)
go install golang.org/x/vuln/cmd/govulncheck@latest
govulncheck ./...

# Nancy (Sonatype)
nancy sleuth < go.sum
```

### Docker images
```bash
# Trivy
trivy image myapp:latest

# Docker Scout (built into Docker Desktop)
docker scout cves myapp:latest
docker scout recommendations myapp:latest

# Grype
grype myapp:latest
```

---

## Severity Levels and Response SLA

| Severity | Response |
|----------|----------|
| **Critical** | Block merge — fix before any deployment |
| **High** | Fix within current sprint |
| **Medium** | Fix within 30 days, track in backlog |
| **Low** | Quarterly review, fix in next dependency update cycle |

---

## Reading audit output

### npm audit output
```
# Severity levels in output
critical  — fix immediately
high      — fix this sprint
moderate  — track and fix
low       — informational

# Path shows how the vulnerability is reached
lodash via express > body-parser > lodash
```

### composer audit output
```
Package: vendor/package
CVE: CVE-2024-XXXXX
Title: Remote code execution via ...
Link: https://github.com/advisories/...
```

---

## Remediation Strategies

### 1. Update the package (preferred)
```bash
# PHP
composer update vendor/package --with-all-dependencies

# Node
npm update package-name
```

### 2. Override transitive dependency
```json
// package.json — force version of transitive dep
{
  "overrides": {
    "vulnerable-package": "^2.0.0"
  }
}
```

```json
// composer.json — force version
{
  "require": {
    "vendor/vulnerable-package": "^2.0"
  }
}
```

### 3. Replace the package
If no fix is available: find an alternative and migrate.

### 4. Ignore with documented justification
```bash
# npm — add to .npmrc or package.json
# Document: WHY it's ignored, WHEN to revisit

# composer.json
{
  "config": {
    "audit": {
      "ignore": {
        "CVE-2024-XXXXX": "Not exploitable — we don't use the affected feature. Review 2025-06-01."
      }
    }
  }
}
```

**Rules for ignoring:**
- Must have a documented reason
- Must have a review date
- Must be tracked in the team's security backlog
- Never ignore Critical severity without security team sign-off

---

## CI Integration (GitHub Actions)

```yaml
# .github/workflows/security.yml
name: Security Audit

on:
  push:
    branches: [main, develop]
  pull_request:
  schedule:
    - cron: '0 8 * * 1'  # weekly Monday 8am

jobs:
  audit-php:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
      - run: composer install --no-dev
      - run: composer audit

  audit-node:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm ci
      - run: npm audit --audit-level=high

  audit-docker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build image
        run: docker build -t myapp:ci .
      - name: Scan with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'myapp:ci'
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```

---

## Automated Dependency Updates

### Dependabot (GitHub)
```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "composer"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
```

### Renovate (alternative — more configurable)
```json
// renovate.json
{
  "extends": ["config:base"],
  "schedule": ["every weekend"],
  "automerge": true,
  "automergeType": "pr",
  "packageRules": [
    {
      "matchUpdateTypes": ["patch"],
      "automerge": true
    },
    {
      "matchUpdateTypes": ["major"],
      "automerge": false,
      "labels": ["major-update"]
    }
  ]
}
```
