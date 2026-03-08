# Migration Patterns Reference

## Expand/Contract Pattern (Zero-Downtime)

The safest way to rename columns or change types on a live system.

**Problem:** You can't rename a column directly in production — old code still reads the old name during deployment.

**Solution:** Three phases across three separate deployments:

```
Phase 1 — EXPAND:   Add new column (nullable), write to BOTH
Phase 2 — MIGRATE:  Backfill data, switch reads to new column
Phase 3 — CONTRACT: Remove old column
```

### Example: Rename `user_name` → `display_name`

**Phase 1 — Add new column, write to both:**
```php
// Migration
Schema::table('users', function (Blueprint $table) {
    $table->string('display_name')->nullable()->after('user_name');
});

// Application code: write to both
$user->user_name = $name;
$user->display_name = $name;
$user->save();

// Application code: read from old column still
echo $user->user_name;
```

**Phase 2 — Backfill and switch reads:**
```php
// Migration: backfill
DB::statement("UPDATE users SET display_name = user_name WHERE display_name IS NULL");

// Then add NOT NULL constraint
Schema::table('users', function (Blueprint $table) {
    $table->string('display_name')->nullable(false)->change();
});

// Application code: read from NEW column
echo $user->display_name;
// Still writing to both (safe)
```

**Phase 3 — Remove old column:**
```php
// Migration: drop old column
Schema::table('users', function (Blueprint $table) {
    $table->dropColumn('user_name');
});

// Application code: remove all references to user_name
```

---

## Dangerous Operations and Safe Alternatives

| Operation | Risk | Safe Approach |
|-----------|------|---------------|
| `dropColumn` | Irreversible data loss | Archive to `_archived_` table first |
| `renameColumn` | Breaks running code | Expand/contract (3 phases) |
| `changeColumn` type | May fail on existing data | Add new column, cast and backfill |
| `dropTable` | Irreversible | Rename to `_archived_YYYY`, schedule drop |
| Add `NOT NULL` without default | Fails if rows exist | Add nullable → backfill → add constraint |
| Add index on large table (MySQL) | Locks table for minutes/hours | `CREATE INDEX CONCURRENTLY` (PostgreSQL) |
| Add FK constraint on large table | Validates all rows | Add FK without validation, validate later |

### Add NOT NULL safely
```php
// Step 1: Add as nullable
Schema::table('orders', function (Blueprint $table) {
    $table->string('currency', 3)->nullable()->after('total');
});

// Step 2: Backfill
DB::statement("UPDATE orders SET currency = 'EUR' WHERE currency IS NULL");

// Step 3: Add constraint (separate migration)
Schema::table('orders', function (Blueprint $table) {
    $table->string('currency', 3)->nullable(false)->change();
});
```

### Add index without downtime (PostgreSQL)
```sql
-- Regular CREATE INDEX locks the table for writes
-- CONCURRENTLY builds without blocking
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id);

-- In Laravel raw migration
DB::statement('CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders(user_id)');
```

### Add FK without full validation
```sql
-- Add FK constraint, skip validation of existing rows
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_user_id
  FOREIGN KEY (user_id) REFERENCES users(id)
  NOT VALID;

-- Validate separately (doesn't lock — runs as background check)
ALTER TABLE orders VALIDATE CONSTRAINT fk_orders_user_id;
```

---

## Laravel Migration Examples

### Full migration template
```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('currency', 3)
                  ->nullable()
                  ->after('total_cents')
                  ->comment('ISO 4217 currency code');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn('currency');
        });
    }
};
```

### Create table
```php
Schema::create('products', function (Blueprint $table) {
    $table->uuid('id')->primary();
    $table->foreignUuid('team_id')->constrained()->cascadeOnDelete();
    $table->string('name');
    $table->text('description')->nullable();
    $table->unsignedBigInteger('price_cents')->default(0);
    $table->string('currency', 3)->default('EUR');
    $table->boolean('is_active')->default(true);
    $table->timestamps();
    $table->softDeletes();

    $table->index('team_id');
    $table->index(['is_active', 'created_at']);
});
```

### Backfill with chunking (large tables)
```php
public function up(): void
{
    // Add column first
    Schema::table('users', function (Blueprint $table) {
        $table->string('full_name')->nullable();
    });

    // Backfill in chunks to avoid memory issues and long locks
    DB::table('users')
        ->whereNull('full_name')
        ->orderBy('id')
        ->chunkById(1000, function ($users) {
            foreach ($users as $user) {
                DB::table('users')
                    ->where('id', $user->id)
                    ->update(['full_name' => trim($user->first_name . ' ' . $user->last_name)]);
            }
        });
}
```

---

## Zero-Downtime Migration Checklist

Before every production migration:

- [ ] Take a database snapshot/backup
- [ ] Test `down()` migration on staging
- [ ] Check if migration acquires locks (ALTER TABLE, DROP COLUMN)
- [ ] For large tables (>100k rows): use CONCURRENTLY or chunking
- [ ] Verify application code is compatible with both before and after state
- [ ] Plan rollback procedure if migration fails mid-run
- [ ] Schedule for low-traffic window if any risk of locking

---

## Raw SQL Migrations (non-Laravel)

```sql
-- migrations/V1__create_users.sql (Flyway style)
CREATE TABLE users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email       TEXT NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- migrations/V2__add_name_to_users.sql
ALTER TABLE users ADD COLUMN name TEXT;
UPDATE users SET name = email WHERE name IS NULL;
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
```

```bash
# Apply with Flyway
flyway -url=jdbc:postgresql://localhost/mydb -user=myapp migrate

# Apply with golang-migrate
migrate -path migrations/ -database "postgres://..." up
```

---

## Pre-migration Checklist

```bash
# 1. Check table size
SELECT pg_size_pretty(pg_total_relation_size('orders'));

# 2. Check active connections
SELECT count(*) FROM pg_stat_activity WHERE datname = 'myapp';

# 3. Check for long-running queries
SELECT pid, now() - query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active' AND now() - query_start > interval '1 minute';

# 4. Check locks before migration
SELECT * FROM pg_locks WHERE NOT granted;

# 5. Snapshot before migration
pg_dump -Fc myapp > backup_before_migration_$(date +%Y%m%d).dump
```
