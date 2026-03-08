# API Design Conventions

## URL Structure

```
/v1/{resource}              GET (list), POST (create)
/v1/{resource}/{id}         GET (show), PUT (replace), PATCH (update), DELETE
/v1/{resource}/{id}/{child} Nested resource
```

**Rules:**
- Plural nouns: `/users`, `/invoices`, not `/user`, `/getInvoice`
- No verbs in URLs: use HTTP method to express action
- Nested max 2 levels deep: `/users/{id}/invoices` — not `/users/{id}/invoices/{id}/items`
- Custom actions: `/v1/invoices/{id}/send` (POST) — acceptable for non-CRUD

---

## HTTP Status Codes

| Code | When |
|------|------|
| 200 | Successful GET, PATCH, PUT |
| 201 | Successful POST (resource created) |
| 204 | Successful DELETE (no body) |
| 400 | Bad request (malformed syntax) |
| 401 | Unauthenticated (no/invalid token) |
| 403 | Unauthorised (authenticated but forbidden) |
| 404 | Resource not found |
| 409 | Conflict (duplicate, state violation) |
| 422 | Validation failed |
| 429 | Rate limited |
| 500 | Server error |

---

## Response Envelope

### Success (single)
```json
{
  "data": { "id": 1, "name": "..." }
}
```

### Success (collection)
```json
{
  "data": [...],
  "meta": {
    "current_page": 1,
    "per_page": 15,
    "total": 42,
    "next_cursor": "eyJpZCI6..."
  }
}
```

### Error
```json
{
  "message": "The given data was invalid.",
  "errors": {
    "email": ["The email field is required."]
  },
  "code": "VALIDATION_ERROR"
}
```

---

## Pagination

- Default: cursor-based for large datasets (scalable, consistent)
- Acceptable: page-based for small, stable datasets
- Always include `meta.next_cursor` or `meta.next_page_url`
- Default page size: 15, max: 100

---

## Authentication

| Method | Use case |
|--------|----------|
| Laravel Sanctum (SPA) | First-party Vue SPA |
| Laravel Sanctum (token) | Mobile apps, simple third-party |
| Laravel Passport (OAuth2) | Full OAuth2 flows, public API |
| API key header | Simple server-to-server |

---

## Versioning

- URL prefix: `/v1/`, `/v2/` — simple and explicit
- Increment major version only on breaking changes
- Support previous major version for minimum 6 months after new release
- Document breaking changes in CHANGELOG with migration guide
