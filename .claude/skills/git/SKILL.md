---
name: git
metadata:
  compatible_agents: [claude-code]
  tags: [git, conventional-commits, changelog, semver, release, branching, gitflow]
description: >
  Git workflow assistant covering conventional commits, branch strategy,
  changelog generation, semantic versioning, and release automation.
  Aligns with the gmakef/gmakeh/gff/gfh fish functions in this dotfiles setup.
  Trigger with: "write commit message", "generate changelog", "create release",
  "branch strategy", "write PR description", "what version should this be".
---

## Commands

| Command | Description |
|---------|-------------|
| `/git commit` | Generate a conventional commit message from a diff or description |
| `/git pr` | Generate a PR title and description |
| `/git changelog` | Generate CHANGELOG entries from commits |
| `/git release` | Run the release workflow with version bump |
| `/git branch` | Advise on branch naming and strategy |

---

## `/git commit`

Generate a conventional commit message from staged changes or a description.

**Input:** Run `git diff --staged` and read the output, or accept a description.

**Conventional commit format:**
```
<type>(<scope>): <subject>

[optional body]

[optional footer]
```

**Types:**
| Type | When to use |
|------|------------|
| `feat` | New feature visible to users |
| `fix` | Bug fix visible to users |
| `refactor` | Code change with no user-visible effect |
| `perf` | Performance improvement |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Tooling, deps, config, CI |
| `style` | Formatting only (Pint, Prettier) |
| `build` | Build system, Docker, Terraform |
| `ci` | GitHub Actions changes |
| `revert` | Reverts a previous commit |

**Rules:**
- Subject line: imperative mood, lowercase, no period, max 72 chars
- `feat` and `fix` always trigger a version bump — use carefully
- Breaking changes: add `!` after type (`feat!:`) and `BREAKING CHANGE:` in footer
- Scope is the module/area affected (e.g., `auth`, `billing`, `api`, `ui`)
- Body explains WHY, not WHAT (the diff shows what)

**Examples:**
```
feat(auth): add OAuth2 login via GitHub

fix(billing): prevent double-charge on retry

refactor(api): extract pagination logic to trait

chore(deps): update laravel to 11.x

feat!: remove legacy v1 API endpoints

BREAKING CHANGE: All v1/* routes have been removed. Migrate to v2/*.
```

---

## `/git pr`

Generate a pull request title and description.

**Input:** Current branch name + `git log main..HEAD --oneline` output.

**Output:**

```markdown
## Summary
- [bullet: what changed and why]
- [bullet: notable decisions or trade-offs]

## Changes
- [bullet: specific change 1]
- [bullet: specific change 2]

## Testing
- [ ] Unit tests added/updated
- [ ] Feature tests added/updated
- [ ] Tested locally

## Notes
[anything reviewers should pay attention to, known limitations, follow-up tasks]
```

**PR title format:** same as conventional commit — `type(scope): subject`

**Rules:**
- Title must match the type of change (feat, fix, etc.)
- Summary explains the "why", changes list the "what"
- Link to related issue if applicable (`Closes #123`)
- Flag breaking changes prominently in Notes
- Keep title under 72 characters

---

## `/git changelog`

Generate CHANGELOG entries from commits since the last tag.

**Input:** Run `git log [last-tag]..HEAD --pretty=format:"%h %s"` automatically.

**Output:** CHANGELOG.md entries following Keep a Changelog format:

```markdown
## [Unreleased]

### Added
- feat entries go here

### Changed
- refactor and perf entries go here

### Fixed
- fix entries go here

### Removed
- entries with BREAKING CHANGE

### Security
- security-related fixes
```

**Rules:**
- Only `feat`, `fix`, `perf`, and breaking changes appear in CHANGELOG
- `chore`, `style`, `ci`, `test`, `docs` are omitted (internal changes)
- Group by type, not by date
- Write in past tense, user-facing language (not "fix null pointer" → "fix crash when user has no profile")
- Unreleased section always at top

---

## `/git release`

Run the full release workflow for a new version.

**Input:** Release type — `major`, `minor`, or `patch` (or describe the changes and let the skill decide).

**Version bump rules (semver):**
- `major` (1.0.0 → 2.0.0): breaking changes (`feat!`, `BREAKING CHANGE`)
- `minor` (1.0.0 → 1.1.0): new features (`feat`)
- `patch` (1.0.0 → 1.0.1): bug fixes only (`fix`)

**Release steps:**
1. Determine next version from commits since last tag
2. Update `CHANGELOG.md` — move Unreleased to new version section with today's date
3. Bump version in relevant files (`package.json`, `composer.json`, `config/app.php`)
4. Commit: `chore(release): v[version]`
5. Tag: `git tag [version]` (bare semver, no `v` prefix)
6. Push commits and tag: `git push && git push --tags`

**Output:**
- Updated `CHANGELOG.md`
- Version bump commit
- Git tag ready to push
- GitHub release notes draft

**Rules:**
- Never release from a feature or hotfix branch — always from `main`
- Tag format: `1.2.3` not `v1.2.3`
- CHANGELOG must be updated before tagging
- If version files conflict, flag for manual resolution

---

## `/git branch`

Advise on branch naming and strategy for a given task.

**Branch conventions (aligned with dotfiles fish functions):**

| Branch | Created from | Merges into | Fish function |
|--------|-------------|-------------|---------------|
| `feature/[name]` | `develop` | `develop` | `gmakef` / `gff` |
| `hotfix/[name]` | `main` | `main` + `develop` | `gmakeh` / `gfh` |
| `develop` | — | `main` (via release) | `gdev` / `gdevp` |
| `main` | — | — | `gm` / `gmp` |

**Naming rules:**
- Lowercase, hyphen-separated: `feature/user-authentication`
- No ticket numbers in branch names (use PR description for that)
- Keep names short but descriptive: `feature/oauth-github` not `feature/add-oauth2-login-via-github-provider`
- Hotfixes are urgent by definition — name them clearly: `hotfix/fix-double-charge`

**When to use what:**
- New feature → `gmakef [name]` → develop → `gff [name]` when done
- Production bug → `gmakeh [name]` → `gfh [name]` when done
- Experiment → `feature/experiment-[name]` — delete if abandoned

---

## Trigger Phrases

`write commit message`, `conventional commit`, `commit message`,
`generate changelog`, `update CHANGELOG`, `create release`, `bump version`,
`what version should this be`, `semver`, `write PR description`,
`PR title`, `branch name`, `branch strategy`, `tag release`

---

## Commit Behaviour

- **Never commit unless the user explicitly asks** — do not proactively run `git commit` or `git push`
- **Never add `Co-Authored-By: Claude` footer** to commit messages
- Only stage and commit when the user says "commit", "yes commit", or similar explicit confirmation

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `fix: fixed stuff` | Describe the actual fix: `fix(auth): prevent session fixation on login` |
| Committing directly to `main` | Always use feature or hotfix branches |
| Changelog written manually | Generate from conventional commits |
| `v1.2.3` tag format | Bare semver: `1.2.3` |
| Skipping CHANGELOG on patch | Every release updates CHANGELOG, including patches |
| Breaking changes without `BREAKING CHANGE` footer | Always document breaking changes explicitly |
| Long-lived feature branches | Merge frequently — branches older than 2 weeks need rebase |


---

## Code Style

- Write human-readable code
- No comments unless absolutely necessary — code should be self-explanatory through naming and structure
- Never commit unless the user explicitly asks
