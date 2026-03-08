# Query Optimization Reference

## Reading EXPLAIN ANALYZE

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 'abc' ORDER BY created_at DESC LIMIT 20;
```

**Key terms:**

| Term | Meaning |
|------|---------|
| `Seq Scan` | Full table scan — usually bad on large tables |
| `Index Scan` | Uses index to find rows — good |
| `Index Only Scan` | Reads from index without touching table — best |
| `Bitmap Heap Scan` | Scans multiple index entries, then fetches rows |
| `Hash Join` | Joins by building hash table — good for large sets |
| `Nested Loop` | Row-by-row join — good for small inner sets |
| `cost=X..Y` | Estimated cost: startup..total (lower = better) |
| `rows=X` | Estimated rows (compare with actual) |
| `actual time=X..Y` | Measured time in ms |
| `Buffers: hit=X` | Pages read from cache (good) vs `read=X` (disk) |

**Red flags:**
- `Seq Scan` on table with >10k rows → missing index
- `rows=1000 actual rows=1` → stale statistics, run `ANALYZE`
- `Nested Loop` with large `loops=10000` → consider a different join strategy
- High `read=` in buffers → data not cached, index might help

```sql
-- Update statistics (run after large data loads)
ANALYZE orders;

-- More detailed stats
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT) SELECT ...;
```

---

## Common Query Rewrites

### Correlated subquery → JOIN
```sql
-- Bad: runs once per row (N+1 in SQL)
SELECT *
FROM orders
WHERE user_id IN (
    SELECT id FROM users WHERE is_active = true
);

-- Good: single join
SELECT o.*
FROM orders o
JOIN users u ON o.user_id = u.id
WHERE u.is_active = true;
```

### EXISTS vs IN (for large sets)
```sql
-- IN loads all matching IDs into memory
SELECT * FROM orders WHERE user_id IN (SELECT id FROM users WHERE country = 'PT');

-- EXISTS stops at first match — better for large subqueries
SELECT * FROM orders o WHERE EXISTS (
    SELECT 1 FROM users u WHERE u.id = o.user_id AND u.country = 'PT'
);
```

### OFFSET pagination → cursor-based
```sql
-- Bad: OFFSET 10000 scans and discards 10000 rows
SELECT * FROM posts ORDER BY created_at DESC LIMIT 20 OFFSET 10000;

-- Good: cursor-based using indexed column
SELECT * FROM posts
WHERE created_at < '2024-01-15 10:00:00'  -- last value from previous page
ORDER BY created_at DESC
LIMIT 20;
```

### COUNT(*) optimisation
```sql
-- Bad: counts all columns
SELECT COUNT(id) FROM orders WHERE status = 'pending';

-- Good: COUNT(*) is optimised by the planner
SELECT COUNT(*) FROM orders WHERE status = 'pending';

-- For approximate counts on huge tables (fast)
SELECT reltuples::BIGINT AS estimate FROM pg_class WHERE relname = 'orders';
```

### Avoid functions on indexed columns
```sql
-- Bad: index on created_at can't be used
SELECT * FROM orders WHERE DATE(created_at) = '2024-01-15';

-- Good: range query uses the index
SELECT * FROM orders
WHERE created_at >= '2024-01-15'
  AND created_at < '2024-01-16';
```

---

## Index Strategy

### Composite index column order
```sql
-- Query: WHERE status = 'active' AND created_at > '2024-01-01'
-- Rule: equality conditions first, then range
CREATE INDEX idx_orders_status_created ON orders(status, created_at);
-- NOT: (created_at, status) — range on first col prevents using second
```

### Covering index (Index Only Scan)
```sql
-- Query only needs these columns — covering index avoids table lookup
SELECT id, email, created_at FROM users WHERE is_active = true ORDER BY created_at DESC;

CREATE INDEX idx_users_active_covering ON users(is_active, created_at DESC)
    INCLUDE (id, email);
```

### Partial index (index subset of rows)
```sql
-- Only index rows where status = 'pending' (small subset)
CREATE INDEX idx_orders_pending ON orders(created_at)
    WHERE status = 'pending';

-- Query must include the WHERE clause to use partial index
SELECT * FROM orders WHERE status = 'pending' ORDER BY created_at;
```

### Index for LIKE queries
```sql
-- Regular B-tree index works for prefix LIKE
CREATE INDEX idx_users_email ON users(email text_pattern_ops);

-- Query using prefix LIKE (uses index)
SELECT * FROM users WHERE email LIKE 'john%';

-- Trailing wildcard (does NOT use B-tree index efficiently)
SELECT * FROM users WHERE email LIKE '%@example.com';
-- Use pg_trgm extension for this:
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_users_email_trgm ON users USING GIN(email gin_trgm_ops);
```

---

## PostgreSQL Tuning

### Key configuration parameters
```ini
# postgresql.conf

# Memory
shared_buffers = 25%_of_RAM          # e.g., 4GB for 16GB server
effective_cache_size = 75%_of_RAM    # helps planner estimate
work_mem = 64MB                      # per sort/hash operation (be careful — multiplies per connection)
maintenance_work_mem = 512MB         # for VACUUM, CREATE INDEX

# Connections
max_connections = 100                # use PgBouncer for connection pooling
# With PgBouncer: max_connections = 20-50, PgBouncer pool = 100+

# WAL
wal_buffers = 64MB
checkpoint_completion_target = 0.9

# Query planner
random_page_cost = 1.1               # SSD (default 4.0 is for spinning disk)
effective_io_concurrency = 200       # SSD

# Logging slow queries
log_min_duration_statement = 1000    # log queries > 1000ms
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

### pg_stat_statements (find slow queries)
```sql
-- Enable in postgresql.conf
shared_preload_libraries = 'pg_stat_statements'

-- Enable extension
CREATE EXTENSION pg_stat_statements;

-- Find slowest queries by total time
SELECT
    round(total_exec_time::numeric, 2) AS total_ms,
    calls,
    round(mean_exec_time::numeric, 2) AS mean_ms,
    round(stddev_exec_time::numeric, 2) AS stddev_ms,
    left(query, 100) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;

-- Find queries with most rows scanned
SELECT
    calls,
    rows,
    round(total_exec_time::numeric, 2) AS total_ms,
    left(query, 100)
FROM pg_stat_statements
ORDER BY rows DESC
LIMIT 20;
```

### Find missing indexes
```sql
-- Tables with sequential scans (candidates for indexes)
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    n_live_tup
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 20;

-- Unused indexes (candidates for removal)
SELECT
    schemaname,
    tablename,
    indexname,
    idx_scan,
    pg_size_pretty(pg_relation_size(indexrelid)) AS index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND indexname NOT LIKE '%_pkey'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## MySQL Tuning

### Key configuration
```ini
# my.cnf

innodb_buffer_pool_size = 75%_of_RAM  # most important setting
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 1    # 1 = ACID safe, 2 = faster but risk
innodb_flush_method = O_DIRECT

max_connections = 150
thread_cache_size = 50

slow_query_log = 1
slow_query_log_file = /var/log/mysql/slow.log
long_query_time = 1                   # log queries > 1 second
log_queries_not_using_indexes = 1
```

```sql
-- Enable performance_schema (MySQL 5.7+)
-- Find slow queries
SELECT
    DIGEST_TEXT,
    COUNT_STAR,
    AVG_TIMER_WAIT / 1000000000 AS avg_ms,
    SUM_TIMER_WAIT / 1000000000 AS total_ms
FROM performance_schema.events_statements_summary_by_digest
ORDER BY SUM_TIMER_WAIT DESC
LIMIT 20;
```

---

## Redis Patterns

### Caching (Laravel)
```php
// Cache expensive query for 1 hour
$users = Cache::remember("team:{$teamId}:users", 3600, function () use ($teamId) {
    return User::where('team_id', $teamId)->get();
});

// Cache-aside with tags (invalidate by tag)
$users = Cache::tags(["team:{$teamId}"])->remember('users', 3600, fn() => ...);

// Invalidate on update
Cache::tags(["team:{$teamId}"])->flush();
```

### Session storage
```php
// config/session.php
'driver' => 'redis',
'connection' => 'session',  // separate Redis DB from cache

// config/database.php
'redis' => [
    'cache' => ['database' => 1],
    'session' => ['database' => 2],
    'queue' => ['database' => 3],
],
```

### Rate limiting
```php
// Using Redis atomic operations
$key = "rate:login:{$ip}";
$attempts = Redis::incr($key);
if ($attempts === 1) {
    Redis::expire($key, 60);  // 1 minute window
}
if ($attempts > 5) {
    throw new TooManyAttemptsException();
}
```

### Pub/Sub (real-time)
```php
// Publish (Laravel Broadcasting)
broadcast(new OrderShipped($order));

// Subscribe (Reverb/Pusher)
Echo.channel('orders')
    .listen('OrderShipped', (e) => {
        console.log(e.order.id);
    });
```
