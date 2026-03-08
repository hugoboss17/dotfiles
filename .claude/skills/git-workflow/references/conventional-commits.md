# Conventional Commits Reference

## Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer(s)]
```

---

## Types

| Type | Version bump | Changelog | When |
|------|-------------|-----------|------|
| `feat` | minor | yes | New user-facing feature |
| `fix` | patch | yes | Bug fix visible to users |
| `perf` | patch | yes | Performance improvement |
| `refactor` | none | no | Code change, no behaviour change |
| `test` | none | no | Adding or fixing tests |
| `docs` | none | no | Documentation only |
| `style` | none | no | Formatting (Pint, Prettier) |
| `chore` | none | no | Tooling, deps, config |
| `build` | none | no | Docker, Makefile, bundler |
| `ci` | none | no | CI/CD workflow changes |
| `revert` | patch | yes | Reverts a previous commit |

Breaking changes add `!` after type and `BREAKING CHANGE:` footer → major bump.

---

## Scopes (examples for Laravel + Vue stack)

| Area | Scope |
|------|-------|
| Authentication | `auth` |
| Billing / payments | `billing` |
| REST API | `api` |
| Frontend / Vue | `ui` |
| Database migrations | `db` |
| Background jobs | `queue` |
| Notifications | `notifications` |
| Admin panel | `admin` |
| Terraform | `infra` |
| CI/CD | `ci` |

---

## Examples

```
feat(auth): add magic link login

fix(billing): prevent double-charge on failed webhook retry

perf(api): add index on users.email for faster lookup

refactor(auth): extract token validation to TokenService

test(billing): add edge case for zero-amount invoices

docs(api): update authentication section with token expiry

chore(deps): update laravel/framework to 11.28

ci: add PHP 8.3 to test matrix

feat!: remove v1 API endpoints

BREAKING CHANGE: All /v1/* routes removed. Use /v2/* equivalents.
Upgrade guide: docs/migration-v2.md
```

---

## Subject Line Rules

- Imperative mood: "add feature" not "added feature" or "adds feature"
- Lowercase first letter
- No period at end
- Max 72 characters
- Describe what the commit does, not what you did

---

## Body Rules

- Separate from subject with a blank line
- Explain WHY, not WHAT (the diff shows what)
- Wrap at 72 characters
- Use bullet points for multiple reasons

---

## Footer Rules

- `BREAKING CHANGE: <description>` — always with migration path
- `Closes #123` — closes a GitHub issue
- `Co-authored-by: Name <email>` — pair programming
- `Refs #456` — references without closing
