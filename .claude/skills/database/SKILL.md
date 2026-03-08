---
name: database
metadata:
  compatible_agents: [claude-code]
  tags: [database, postgresql, mysql, sqlite, valkey, redis, schema, migration, optimization, indexing, backup]
description: >
  Database assistant for schema design, migration strategies, query optimization,
  indexing, and backup/restore planning. Covers PostgreSQL, MySQL, SQLite, and Valkey.
  Trigger with: "design schema", "optimize query", "create migration",
  "add index", "database backup", "query performance", "normalize tables".
---

## Commands

| Command | Description |
|---------|-------------|
| `/db schema` | Design or review a database schema |
| `/db migrate` | Generate migration with rollback strategy |
| `/db optimize` | Analyze and optimize slow queries |
| `/db index` | Recommend indexes for a table or query pattern |
| `/db backup` | Design backup and restore strategy |

---

## `/db schema`

Design or review a database schema from a feature or domain description.

**Interview:**
1. What entities does this domain contain?
2. What are the relationships between them?
3. What are the primary access patterns (what queries will run most)?
4. PostgreSQL, MySQL, or SQLite?
5. Expected row counts per table?

**Output:**
- ERD description with relationship types (1:1, 1:N, M:N)
- `CREATE TABLE` statements with full column definitions
- Relationship mapping and foreign key definitions
- Index recommendations based on access patterns

**Naming conventions:**
- Table names: `snake_case`, plural (`users`, `team_members`)
- Column names: `snake_case`, singular (`first_name`, `created_at`)
- Foreign keys: `{table_singular}_id` (`user_id`, `team_id`)
- Junction tables: `{table_a}_{table_b}` alphabetical (`role_user`, `post_tag`)
- Timestamps: always include `created_at`, `updated_at`; add `deleted_at` if soft-deleting

**Design rules:**
- 3NF by default — denormalise only with a measured justification
- Every table has a surrogate primary key (UUID or auto-increment)
- Prefer UUID for distributed systems or public-facing IDs
- `NOT NULL` by default — nullable only when absence is meaningful
- Use appropriate column types (don't `VARCHAR(255)` everything)
- ENUM columns for small, stable value sets; lookup table for anything that might change

**PostgreSQL-specific:**
- Use `UUID` with `gen_random_uuid()` (pgcrypto)
- Use `JSONB` for semi-structured data (not `JSON`)
- Use `TIMESTAMPTZ` not `TIMESTAMP` — always store in UTC
- Consider `GENERATED ALWAYS AS` for computed columns

---

## `/db migrate`

Generate a database migration with a matching rollback.

**Input:** Description of schema change needed, target framework (Laravel, raw SQL, Flyway, etc.).

**Output:**
- Up migration (forward change)
- Down migration (rollback)
- Safety assessment (is this zero-downtime safe?)

**Laravel migration example:**
```php
public function up(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->string('display_name')->nullable()->after('email');
    });
}

public function down(): void
{
    Schema::table('users', function (Blueprint $table) {
        $table->dropColumn('display_name');
    });
}
```

**Expand/contract pattern (zero-downtime):**

For renaming a column or changing a type safely:
1. **Expand:** Add new column alongside old one
2. **Migrate:** Backfill data; write to both columns in application
3. **Contract:** Remove old column once all reads use the new one

**Dangerous operations checklist:**

| Operation | Risk | Safe Alternative |
|-----------|------|-----------------|
| `DROP COLUMN` | Irreversible data loss | Expand/contract; archive first |
| `RENAME COLUMN` | Breaks queries using old name | Add new column, backfill, remove old |
| `ALTER COLUMN` type change | May fail on existing data | Add new column, cast and backfill |
| `DROP TABLE` | Irreversible | Rename to `_archived_`, schedule drop |
| Add `NOT NULL` without default | Fails if table has rows | Add nullable → backfill → add constraint |
| Add index on large table | Locks table (MySQL) | `CREATE INDEX CONCURRENTLY` (PostgreSQL) |

**Rules:**
- Never rename columns directly in production — use expand/contract
- New columns must be nullable or have a default value
- Backfill before adding NOT NULL constraint
- Always test down migration before merging
- Large table migrations need a maintenance window or concurrent index creation

---

## `/db optimize`

Analyze and optimize a slow query or table access pattern.

**Input:** Slow query SQL + optional `EXPLAIN ANALYZE` output.

**Analysis steps:**
1. Run `EXPLAIN ANALYZE` and identify bottlenecks
2. Check for sequential scans on large tables
3. Identify missing or unused indexes
4. Look for N+1 patterns, suboptimal joins, redundant subqueries

**Reading EXPLAIN output:**
- `Seq Scan` on large table → missing index
- `Hash Join` vs `Nested Loop` — check which is faster for your data size
- `rows=X` estimate vs actual — stale statistics, run `ANALYZE table`
- High `cost` values on inner loops → consider covering indexes

**Common rewrites:**

```sql
-- Bad: correlated subquery (runs once per row)
SELECT * FROM orders WHERE user_id IN (SELECT id FROM users WHERE active = true);

-- Good: JOIN
SELECT o.* FROM orders o JOIN users u ON o.user_id = u.id WHERE u.active = true;

-- Bad: OFFSET pagination on large tables (scans all rows to skip)
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- Good: cursor-based pagination
SELECT * FROM posts WHERE created_at < :cursor ORDER BY created_at DESC LIMIT 20;
```

**Output:**
- Optimised query
- Suggested indexes with rationale
- Before/after EXPLAIN comparison (estimated)
- Any schema changes that would help

---

## `/db index`

Recommend indexes for a table based on query patterns.

**Input:** `CREATE TABLE` statement + list of common queries run against it.

**Index selection rules:**
- Index columns used in `WHERE`, `JOIN ON`, `ORDER BY`, `GROUP BY`
- Composite index column order: equality conditions first, then range, then sort
- Covering index: include all columns needed by the query to avoid table lookup
- Partial index: add `WHERE` clause to index only relevant rows
- Don't over-index — each index adds write overhead and storage cost
- Always index foreign key columns (prevents full scan on join)

**Index types (PostgreSQL):**

| Type | Use case |
|------|----------|
| `B-tree` | Default — equality and range queries, sorting |
| `GIN` | JSONB fields, arrays, full-text search |
| `GiST` | Geometric data, full-text, range types |
| `Hash` | Equality-only — rarely needed over B-tree |
| `BRIN` | Very large tables with sequential data (time-series, logs) |

**Creating indexes safely:**
```sql
-- PostgreSQL: non-blocking (preferred for production)
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- MySQL: online DDL (check InnoDB version)
ALTER TABLE orders ADD INDEX idx_user_id (user_id) ALGORITHM=INPLACE, LOCK=NONE;
```

**Output:**
- Recommended index definitions with type and rationale
- Estimated impact (which queries benefit)
- Any existing indexes that are redundant or unused

---

## `/db backup`

Design a backup and restore strategy for the database.

**Interview:**
1. What database engine? (PostgreSQL, MySQL, SQLite)
2. What is the RTO (max acceptable downtime)?
3. What is the RPO (max acceptable data loss window)?
4. Where is the database hosted? (RDS, Cloud SQL, Hetzner, self-hosted)
5. Compliance requirements? (GDPR retention, PCI-DSS)

**Backup strategies:**

| Strategy | RPO | Complexity | Use case |
|----------|-----|------------|----------|
| Daily `pg_dump` | ~24h | Low | Dev/staging, non-critical |
| Hourly `pg_dump` | ~1h | Low | Small production DBs |
| WAL archiving + base backup | Minutes | Medium | Production PostgreSQL |
| Continuous backup (RDS/Cloud SQL) | Seconds | Low (managed) | Managed production DBs |

**PostgreSQL backup commands:**
```bash
# Logical backup
pg_dump -Fc -h host -U user dbname > backup.dump

# Restore
pg_restore -d dbname backup.dump

# Point-in-time recovery requires WAL archiving enabled
# archive_mode = on, archive_command = 'cp %p /backup/%f'
```

**MySQL backup:**
```bash
mysqldump --single-transaction --routines --triggers -u user -p dbname > backup.sql
```

**RDS / managed DB:**
- Automated backups: enable, set retention 7–35 days
- Snapshot before every migration
- Cross-region snapshot copy for disaster recovery
- Test restore quarterly

**Restore testing requirements:**
- Document restore procedure step-by-step
- Test restore to staging monthly
- Measure actual RTO from test — compare to target
- Alert if backup job fails

**Rules:**
- Encrypt backups at rest (AES-256)
- Store backups in a separate account/region from the database
- Snapshot before every production migration — no exceptions
- Never test restore on production

---

## Trigger Phrases

`design schema`, `database schema`, `create tables`, `ERD`, `normalize`,
`optimize query`, `slow query`, `EXPLAIN ANALYZE`, `query performance`,
`create migration`, `database migration`, `expand contract`,
`add index`, `missing index`, `composite index`,
`database backup`, `backup strategy`, `restore plan`, `point-in-time recovery`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `VARCHAR(255)` for everything | Use appropriate types: `TEXT`, `CHAR(n)`, `INTEGER` |
| No foreign key constraints | Always define FK relationships — enforce referential integrity |
| `SELECT *` in production queries | Select only needed columns — avoid pulling unused data |
| No indexes on foreign key columns | Always index FK columns to prevent full scans on joins |
| Storing JSON for relational data | Normalise properly; use JSONB only for truly variable structure |
| Missing `created_at` / `updated_at` | Always include timestamps on every table |
| Raw queries without parameterisation | Always use prepared statements or ORM query builder |
| Renaming columns directly | Expand/contract — never rename in place on production |
| No backup testing | Test restore monthly — untested backups are not backups |
| OFFSET pagination on large tables | Cursor-based pagination using indexed columns |
| Shared DB user with superuser rights | Least-privilege DB user per application |

---

## References

| File | Purpose |
|------|---------|
| `references/schema-patterns.md` | Common schema patterns, PostgreSQL types, naming conventions |
| `references/migration-patterns.md` | Expand/contract, Laravel migrations, zero-downtime checklist |
| `references/query-optimization.md` | EXPLAIN ANALYZE guide, index strategies, PostgreSQL/MySQL tuning |
