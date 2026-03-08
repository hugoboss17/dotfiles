# Branching Strategy

## Branch Map

```
main ──────────────────────────────────── (production, always deployable)
  │
  └── develop ───────────────────────────(integration, staging deploys)
        │
        ├── feature/user-auth ──────────(gmakef user-auth → gff user-auth)
        ├── feature/billing ───────────
        └── feature/notifications ─────

main ─── hotfix/fix-double-charge ───────(gmakeh → gfh, merges to main+develop)
```

---

## Branch Types

| Branch | Base | Merges to | Naming | Fish fn |
|--------|------|-----------|--------|---------|
| `main` | — | — | `main` | `gm` / `gmp` |
| `develop` | `main` | `main` (release) | `develop` | `gdev` / `gdevp` |
| feature | `develop` | `develop` | `feature/[name]` | `gmakef` / `gff` |
| hotfix | `main` | `main` + `develop` | `hotfix/[name]` | `gmakeh` / `gfh` |
| release | `develop` | `main` + `develop` | `release/[version]` | manual |

---

## Workflow: New Feature

```bash
gmakef user-authentication          # creates feature/user-authentication from develop
# ... do work, commit with conventional commits ...
gff user-authentication             # merges to develop, pushes, merges to main, pushes
```

---

## Workflow: Production Hotfix

```bash
gmakeh fix-payment-crash            # creates hotfix/fix-payment-crash from main
# ... fix the bug ...
gfh fix-payment-crash               # merges to main + develop, pushes both
```

---

## Branch Naming Rules

- Lowercase, hyphen-separated only
- Short and descriptive: `feature/oauth-github` not `feature/add-oauth2-login-via-github`
- No ticket numbers in branch name (put in commit or PR)
- Hotfixes use imperative names: `hotfix/fix-double-charge` not `hotfix/double-charge-bug`

---

## Branch Hygiene

- Delete feature branches after merge
- Branches older than 2 weeks need rebase before merge
- Never commit directly to `main` or `develop`
- PRs required for all merges to `main`
- Staging deploys automatically from `develop` pushes
- Production deploys from version tags on `main`

---

## Release Branch (optional, for larger teams)

When stabilisation is needed before release:

```bash
git checkout -b release/1.2.0 develop
# bug fixes only — no new features
# update CHANGELOG, bump version
git checkout main && git merge release/1.2.0
git tag 1.2.0
git checkout develop && git merge release/1.2.0
git branch -d release/1.2.0
```
