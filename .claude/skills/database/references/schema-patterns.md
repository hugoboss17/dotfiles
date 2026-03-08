# Schema Patterns Reference

## Naming Conventions

| Object | Convention | Example |
|--------|-----------|---------|
| Table | `snake_case`, plural | `users`, `team_members` |
| Column | `snake_case`, singular | `first_name`, `created_at` |
| Primary key | `id` | `id` |
| Foreign key | `{table_singular}_id` | `user_id`, `team_id` |
| Boolean | `is_` or `has_` prefix | `is_active`, `has_verified_email` |
| Timestamp | `_at` suffix | `created_at`, `deleted_at` |
| Junction table | `{a}_{b}` alphabetical | `role_user`, `post_tag` |
| Index | `idx_{table}_{columns}` | `idx_orders_user_id` |
| FK constraint | `fk_{table}_{column}` | `fk_orders_user_id` |

---

## Standard Column Set

Every table should have:
```sql
id          UUID (or BIGSERIAL)  PRIMARY KEY
created_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW()
updated_at  TIMESTAMPTZ          NOT NULL DEFAULT NOW()
-- optional:
deleted_at  TIMESTAMPTZ          NULL  -- soft delete
```

---

## Common Schema Patterns

### Users + Teams (multi-tenancy)
```sql
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT NOT NULL UNIQUE,
    name        TEXT NOT NULL,
    password    TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at  TIMESTAMPTZ
);

CREATE TABLE teams (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL,
    slug        TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE team_user (
    team_id     UUID NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role        TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'admin', 'member')),
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

CREATE INDEX idx_team_user_user_id ON team_user(user_id);
```

### Roles and Permissions (RBAC)
```sql
CREATE TABLE roles (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    guard_name  TEXT NOT NULL DEFAULT 'web'
);

CREATE TABLE permissions (
    id          BIGSERIAL PRIMARY KEY,
    name        TEXT NOT NULL UNIQUE,
    guard_name  TEXT NOT NULL DEFAULT 'web'
);

CREATE TABLE role_user (
    role_id     BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    user_id     UUID   NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, user_id)
);

CREATE TABLE permission_role (
    permission_id BIGINT NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    role_id       BIGINT NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    PRIMARY KEY (permission_id, role_id)
);
```

### Polymorphic Relations
```sql
-- Prefer explicit tables over polymorphic in PostgreSQL
-- But if polymorphic is needed:
CREATE TABLE comments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    body            TEXT NOT NULL,
    commentable_id  UUID NOT NULL,
    commentable_type TEXT NOT NULL CHECK (commentable_type IN ('posts', 'videos', 'products')),
    user_id         UUID NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comments_commentable ON comments(commentable_type, commentable_id);
```

### Audit Log
```sql
CREATE TABLE audit_logs (
    id          BIGSERIAL PRIMARY KEY,
    user_id     UUID REFERENCES users(id) ON DELETE SET NULL,
    action      TEXT NOT NULL,          -- 'created', 'updated', 'deleted'
    table_name  TEXT NOT NULL,
    record_id   TEXT NOT NULL,          -- TEXT to accommodate UUID and INT PKs
    old_values  JSONB,
    new_values  JSONB,
    ip_address  INET,
    user_agent  TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user_id   ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_table_record ON audit_logs(table_name, record_id);
CREATE INDEX idx_audit_logs_created_at ON audit_logs(created_at DESC);
```

### Tagging System
```sql
CREATE TABLE tags (
    id    BIGSERIAL PRIMARY KEY,
    name  TEXT NOT NULL UNIQUE,
    slug  TEXT NOT NULL UNIQUE
);

CREATE TABLE post_tag (
    post_id UUID   NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    tag_id  BIGINT NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (post_id, tag_id)
);

CREATE INDEX idx_post_tag_tag_id ON post_tag(tag_id);
```

### Orders + Line Items
```sql
CREATE TABLE orders (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id),
    status      TEXT NOT NULL DEFAULT 'pending'
                  CHECK (status IN ('pending', 'paid', 'shipped', 'cancelled')),
    currency    CHAR(3) NOT NULL DEFAULT 'EUR',
    total_cents BIGINT NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE order_items (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id    UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  UUID NOT NULL REFERENCES products(id),
    quantity    INT  NOT NULL CHECK (quantity > 0),
    unit_price_cents BIGINT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_orders_user_id      ON orders(user_id);
CREATE INDEX idx_orders_status       ON orders(status);
CREATE INDEX idx_order_items_order   ON order_items(order_id);
```

---

## PostgreSQL Column Types

| Use case | Type | Notes |
|----------|------|-------|
| Primary key (distributed) | `UUID` | `gen_random_uuid()` |
| Primary key (simple) | `BIGSERIAL` | Auto-increment |
| Short text | `TEXT` | No need for VARCHAR(n) in Postgres |
| Timestamps | `TIMESTAMPTZ` | Always store in UTC |
| Money | `BIGINT` (cents) | Never FLOAT for money |
| JSON (queryable) | `JSONB` | Not JSON — JSONB is indexed |
| Boolean | `BOOLEAN` | Not `TINYINT(1)` |
| IP addresses | `INET` | Supports IPv4 and IPv6 |
| Enum values | `TEXT` + `CHECK` or `ENUM` type | CHECK is more flexible |
| Arrays | `TEXT[]`, `INT[]` | Use sparingly — prefer join table |
| Full-text search | `TSVECTOR` | With GIN index |

---

## MySQL-specific Considerations

- Use `BIGINT UNSIGNED AUTO_INCREMENT` for simple PKs (or `CHAR(36)` for UUID)
- Use `DATETIME` or `TIMESTAMP` — store UTC, set `@@global.time_zone = '+00:00'`
- Use `VARCHAR(n)` — MySQL doesn't have an unbounded TEXT equivalent efficiently
- Use `InnoDB` engine always — never MyISAM
- Money: `DECIMAL(10, 2)` or store as cents in `BIGINT`
- Indexes: InnoDB has clustered index on PK — keep PK narrow (BIGINT > UUID for perf)
