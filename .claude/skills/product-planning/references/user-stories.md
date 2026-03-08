# User Story Patterns

## Format

```
As a [persona], I want to [action] so that [outcome].

Acceptance Criteria:
- Given [context], when [action], then [result]
- Given [context], when [edge case], then [result]
```

---

## Good vs Bad Examples

### Bad
```
As a user, I want a dashboard so that I can see things.
```
Problems: vague persona, vague action, vague outcome, no criteria.

### Good
```
As a registered user, I want to see my last 5 invoices on the dashboard
so that I can quickly check my billing history without navigating away.

Acceptance Criteria:
- Given I am logged in, when I visit /dashboard, then I see up to 5 invoices sorted by date descending
- Given I have no invoices, when I visit /dashboard, then I see "No invoices yet"
- Given I have 10 invoices, when I visit /dashboard, then only the 5 most recent are shown
```

---

## Story Sizing

| Size | Effort | Examples |
|------|--------|---------|
| S | < 1 day | UI label change, config flag, single validation rule |
| M | 1–3 days | New form with validation, simple API endpoint |
| L | 3–5 days | Feature with multiple endpoints, complex business logic |
| XL | > 1 week | Split into smaller stories |

XL stories must be broken down before sprint commitment.

---

## Epic → Story → Task

```
Epic: User Authentication
  Story: Register with email
    Task: Create registration form
    Task: Write validation logic
    Task: Send verification email
  Story: Login with email
  Story: Password reset
  Story: OAuth login (GitHub)
```

---

## Anti-Patterns

| Anti-Pattern | Fix |
|---|---|
| "As a user..." for every story | Use specific personas: admin, guest, subscriber |
| Stories referencing UI elements | Describe intent, not implementation |
| Acceptance criteria in future tense | Use Given/When/Then only |
| Stories without unhappy path | Always add at least one negative case |
| Combining two behaviours in one story | Split — one behaviour per story |
