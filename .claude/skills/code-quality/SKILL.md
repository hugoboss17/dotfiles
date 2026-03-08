---
name: code-quality
metadata:
  compatible_agents: [claude-code]
  tags: [php, laravel, typescript, vue, go, python, phaser, game-dev, pest, phpstan, pint, rector, eslint, golangci-lint, ruff, mypy, code-review]
description: >
  Code quality assistant for PHP/Laravel, TypeScript/Vue, Go, Python, and Phaser 3 codebases.
  Runs quality checks, scaffolds tests, generates PR review checklists,
  enforces static analysis, and modernises code. Also handles Phaser 3 game code review,
  JS→TS migration, scene patterns, and object pooling.
  Trigger with: "review this code", "check code quality", "write tests for",
  "run static analysis", "fix code style", "scaffold pest tests", "review my PR",
  "review this scene", "phaser code review", "migrate phaser to typescript".
---

## Commands

| Command | Description |
|---------|-------------|
| `/quality review` | Full code review with actionable feedback |
| `/quality php` | PHP static analysis, style, and modernisation |
| `/quality ts` | TypeScript and Vue quality check |
| `/quality go` | Go static analysis, formatting, and linting |
| `/quality py` | Python type checking, linting, and formatting |
| `/quality phaser` | Phaser 3 scene/game code review and JS→TS migration |
| `/quality test` | Scaffold Pest tests for a class or feature |
| `/quality pr` | Generate a PR review checklist |

---

## `/quality review`

Perform a full code review of a file, class, or diff.

**Input:** File path, code snippet, or git diff.

**Review covers:**
- **Correctness:** logic errors, off-by-one, null handling, type mismatches
- **Security:** injection risks, auth bypasses, mass assignment, exposed secrets
- **Performance:** N+1 queries, missing indexes, unnecessary loops, eager load opportunities
- **Maintainability:** naming clarity, single responsibility, duplication, magic numbers
- **Design patterns:** flag missing patterns (Strategy over if/switch, Observer over tight coupling, etc.) — use `references/design-patterns.md`
- **Test coverage:** what is untested, what edge cases are missing

**Output format:**
```
## Critical
- [issue] → [suggested fix]

## Warnings
- [issue] → [suggested fix]

## Suggestions
- [issue] → [suggested fix]

## Looks Good
- [what is done well]
```

**Rules:**
- Critical = bugs, security issues, data loss risk
- Warnings = correctness concerns, performance problems
- Suggestions = style, maintainability, test gaps
- Always include at least one positive observation
- Provide the corrected code snippet, not just the description

---

## `/quality php`

Run PHP quality checks and apply fixes.

**Steps (run in order):**

1. **Laravel Pint** (code style):
   ```bash
   ./vendor/bin/pint
   ```

2. **PHPStan / Larastan** (static analysis):
   ```bash
   ./vendor/bin/phpstan analyse --memory-limit=512M
   ```
   - If baseline needs update: `phpstan analyse --generate-baseline`
   - Target level: 6 minimum, 8 preferred for new code

3. **Rector** (automated refactoring):
   ```bash
   ./vendor/bin/rector process --dry-run   # preview
   ./vendor/bin/rector process             # apply
   ```
   - Use `references/php-patterns.md` for common Rector rule sets

**For each tool, report:**
- Issues found
- Issues auto-fixed vs requiring manual fix
- Suggested `rector.php` or `phpstan.neon` config changes

**PHP modernisation targets:**
- Replace `array()` with `[]`
- Add return types and property types
- Use named arguments where clarity improves
- Replace string class references with `ClassName::class`
- Use match expressions over switch where appropriate
- Use `readonly` properties (PHP 8.1+)
- Use `enum` over class constants for finite sets (PHP 8.1+)
- Use `first-class callable syntax` (PHP 8.1+)

---

## `/quality go`

Go quality check: formatting, vetting, and static analysis.

**Steps (run in order):**

1. **gofmt** (formatting):
   ```bash
   gofmt -l -w .
   ```

2. **go vet** (correctness):
   ```bash
   go vet ./...
   ```

3. **staticcheck** (static analysis):
   ```bash
   staticcheck ./...
   ```

4. **golangci-lint** (comprehensive linting):
   ```bash
   golangci-lint run ./...
   golangci-lint run --fix ./...   # auto-fix where possible
   ```
   - Use `references/go-patterns.md` for `.golangci.yml` config

**Go review checklist:**
- Every error is handled — no `_` discard on `err` returns
- `context.Context` is the first parameter on functions that do I/O
- No goroutine leaks — goroutines have a clear termination path
- `defer` used correctly — no defer inside loops
- Interfaces defined at the point of use (consumer), not the provider
- No global mutable state — use dependency injection
- Structs have proper JSON/DB tags where needed
- No naked returns in long functions

**Go modernisation targets:**
- Use `errors.Is` / `errors.As` over type assertions on errors
- Use `slices` and `maps` packages (Go 1.21+) over manual loops
- Use generics where they reduce duplication without obscuring intent
- Use `slog` over `log` for structured logging (Go 1.21+)
- `any` over `interface{}` (Go 1.18+)

---

## `/quality py`

Python quality check: linting, type checking, and formatting.

**Steps (run in order):**

1. **ruff** (linting + formatting):
   ```bash
   ruff check .
   ruff check . --fix        # auto-fix safe issues
   ruff format .             # format (replaces black)
   ```

2. **mypy** (type checking):
   ```bash
   mypy .
   ```

3. **pytest** (run tests):
   ```bash
   pytest -v --tb=short
   pytest --cov=src --cov-report=term-missing   # with coverage
   ```
   - Use `references/python-patterns.md` for `pyproject.toml` config

**Python review checklist:**
- All public functions and methods have type hints
- No bare `except:` — always catch specific exceptions
- No mutable default arguments (`def f(x=[])` → use `None` sentinel)
- Dataclasses or Pydantic models for structured data, not raw dicts
- `pathlib.Path` over `os.path` string manipulation
- Context managers (`with`) for file and connection handling
- No `import *` — explicit imports only
- Async functions consistently `await`ed — no fire-and-forget without handling

**Python modernisation targets:**
- f-strings over `.format()` or `%` formatting
- `match` statements over complex `if/elif` chains (3.10+)
- `X | Y` union type syntax over `Union[X, Y]` (3.10+)
- `list[str]` over `List[str]` from typing (3.9+)
- Walrus operator `:=` where it clarifies intent (3.8+)
- `tomllib` for TOML parsing (3.11+)

---

## `/quality ts`

TypeScript and Vue 3 quality check.

**Steps:**

1. **TypeScript type check:**
   ```bash
   npx tsc --noEmit
   ```

2. **ESLint:**
   ```bash
   npx eslint . --ext .ts,.vue
   ```

3. **Prettier:**
   ```bash
   npx prettier --check .
   npx prettier --write .   # to fix
   ```

**Vue 3 review checklist:**
- Components use `<script setup>` syntax
- Props defined with `defineProps<{}>()` (typed, not runtime)
- Emits defined with `defineEmits<{}>()` (typed)
- No direct DOM manipulation — use `ref()` and `reactive()`
- Composables extracted for reusable logic (files named `use*.ts`)
- No `any` types — replace with proper generics or union types
- `v-for` always has `:key` with stable, unique value
- No `v-if` and `v-for` on the same element

**For each issue, provide:**
- File and line
- Current code
- Fixed code

---

## `/quality test`

Scaffold Pest tests for a given class, feature, or endpoint.

**Input:** Class name, file path, or feature description.

**Auto-detect:**
- Is this a Model? → Unit test + Factory usage
- Is this a Controller/Action? → Feature test with HTTP assertions
- Is this a Service/Action class? → Unit test with real dependencies where possible; mock only external APIs/services
- Is this a Vue component? → Vitest component test

**PHP/Pest output structure:**
```php
<?php

use App\Models\[Model];
use function Pest\Laravel\{get, post, actingAs};

describe('[ClassName]', function () {

    it('[does the expected thing]', function () {
        // Arrange
        $model = [Model]::factory()->create();

        // Act
        $response = get(route('[route.name]', $model));

        // Assert
        $response->assertOk();
    });

    it('[handles edge case]', function () {
        //
    })->todo();

});
```

**Rules:**
- AAA pattern: Arrange / Act / Assert
- One assertion focus per test (multiple assertions only if they test the same behaviour)
- Use `->todo()` for known missing tests
- Include architecture test: `arch()->preset()->laravel()`
- Factory states for complex scenarios — never raw `Model::create()` in tests
- Use `actingAs()` for authenticated routes
- **Prefer real dependencies over mocks** — use `RefreshDatabase` + factories, real service instances, in-memory queues (`Queue::fake()` only when asserting dispatch)
- **Mock only true external boundaries** — third-party HTTP APIs (`Http::fake()`), payment gateways, email/SMS providers (`Mail::fake()`, `Notification::fake()`)

---

## `/quality pr`

Generate a PR review checklist based on the diff or PR description.

**Input:** PR description, diff, or `gh pr view [number]`.

**Output:**

```markdown
## PR Review Checklist

### Correctness
- [ ] Logic matches the described intent
- [ ] Edge cases handled (null, empty, boundary values)
- [ ] No unintended side effects

### Security
- [ ] No hardcoded secrets or credentials
- [ ] Authorization checks present on all routes
- [ ] User input validated and sanitised

### Database
- [ ] Migrations are backward-compatible
- [ ] No N+1 queries introduced
- [ ] Indexes added for new query patterns

### Tests
- [ ] New behaviour covered by tests
- [ ] Edge cases tested
- [ ] No tests deleted without reason

### Code Quality
- [ ] Pint passes
- [ ] PHPStan passes (no new ignores without comment)
- [ ] No dead code or commented-out code

### Documentation
- [ ] Complex logic commented
- [ ] CHANGELOG updated (if public API change)
- [ ] README updated (if setup/config changed)
```

---

## `/quality phaser`

Review Phaser 3 game code or migrate a JS project to TypeScript.

**Input:** Scene file, game object class, or project directory.

**Review covers:**
- Scene lifecycle correctness (init/preload/create/update/shutdown)
- Object pooling — no `new` / `add.*()` calls inside `update()`
- Event listener cleanup in `shutdown`
- Asset loading strategy (atlases vs individual images)
- Frame-rate independence (delta-based movement)
- Logic separation — game rules in plain classes, not Scene methods
- TypeScript typing — no untyped properties, no `any`

**JS → TS migration steps:**
1. Add `tsconfig.json` with `"allowJs": true, "checkJs": false`
2. Rename entry point(s) to `.ts`
3. Enable `// @ts-check` per JS file to surface errors gradually
4. Rename remaining `.js` → `.ts`, fix type errors
5. Enable `"strict": true` when all files are `.ts`

**Output format:** same as `/quality review` (Critical / Warnings / Suggestions / Looks Good)

Use `references/phaser-patterns.md` for all patterns and examples.

---

## Trigger Phrases

`review this code`, `code review`, `check code quality`, `write tests`,
`scaffold pest tests`, `generate tests`, `run static analysis`, `fix code style`,
`PHPStan errors`, `Pint fix`, `Rector refactor`, `TypeScript errors`,
`Vue component review`, `review my PR`, `PR checklist`,
`golangci-lint`, `go vet`, `gofmt`, `Go code review`,
`ruff`, `mypy`, `Python type hints`, `Python code review`,
`review this scene`, `phaser code review`, `phaser scene`, `game object`,
`migrate phaser to typescript`, `phaser JS to TS`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `phpstan ignore` without explanation | Always add a comment explaining why it's ignored |
| Tests with no assertions | Every test must assert something |
| `Model::create()` in tests | Always use factories |
| `any` type in TypeScript | Use proper types or generics |
| `v-if` + `v-for` on same element | Use a wrapper element or computed filter |
| Testing implementation details | Test behaviour and outcomes, not internals |
| Skipping Rector dry-run | Always preview with `--dry-run` first |
| PHPStan level < 6 | Minimum level 6, target level 8 for new code |
| Ignoring `err` in Go with `_` | Always handle errors explicitly |
| Bare `except:` in Python | Catch specific exceptions |
| No type hints on Python functions | Type-hint all public APIs |
| Global mutable state in Go | Use dependency injection and struct receivers |

---

## References

| File | Purpose |
|------|---------|
| `references/php-patterns.md` | PHPStan config, Rector rule sets, Pint presets, PHP 8.x modernisation |
| `references/typescript-patterns.md` | TypeScript strict config, Vue 3 patterns, ESLint rules |
| `references/pest-patterns.md` | Pest test structure, dataset patterns, architecture testing |
| `references/go-patterns.md` | golangci-lint config, Go project structure, testing patterns |
| `references/python-patterns.md` | ruff/mypy config, pytest patterns, Python modernisation |
| `references/design-patterns.md` | GoF design patterns catalog with Laravel/TS/Go examples and SOLID principles |
| `references/phaser-patterns.md` | Phaser 3.90+ scene patterns, object pooling, asset management, JS→TS migration |
