# Go Patterns Reference

## golangci-lint Configuration

```yaml
# .golangci.yml
run:
  timeout: 5m
  go: "1.22"

linters:
  enable:
    - errcheck        # check all errors are handled
    - gosimple        # simplification suggestions
    - govet           # go vet checks
    - ineffassign     # detect ineffectual assignments
    - staticcheck     # comprehensive static analysis
    - unused          # unused code
    - gofmt           # formatting
    - goimports       # import organisation
    - revive          # fast, configurable linter
    - gocritic        # opinionated style checks
    - exhaustive      # enum switch exhaustiveness
    - noctx           # detect http requests without context
    - bodyclose       # ensure http response bodies are closed
    - sqlcloserows    # ensure sql rows are closed
    - nilerr          # detect returning nil when err != nil

linters-settings:
  revive:
    rules:
      - name: exported
      - name: var-naming
      - name: error-return
      - name: error-strings
  gocritic:
    enabled-tags:
      - diagnostic
      - style
      - performance
```

---

## Project Structure

```
myapp/
├── cmd/
│   └── server/
│       └── main.go          # entrypoint, wires dependencies
├── internal/
│   ├── domain/              # business logic, no external deps
│   │   ├── user/
│   │   │   ├── user.go      # domain model
│   │   │   ├── service.go   # business rules
│   │   │   └── repository.go # interface definition
│   │   └── order/
│   ├── handler/             # HTTP handlers (thin layer)
│   ├── repository/          # DB implementations
│   ├── middleware/
│   └── config/
├── pkg/                     # exported, reusable packages
├── migrations/
├── go.mod
└── go.sum
```

**Rules:**
- `internal/` is not importable by external modules
- `cmd/` only wires dependencies — no business logic
- Interfaces defined in the package that uses them, not the one that implements them
- No circular imports — use dependency inversion

---

## Error Handling Patterns

```go
// Bad: ignoring error
result, _ := doSomething()

// Bad: returning wrong type
func findUser(id int) (*User, error) {
    user, err := db.Query(...)
    if err != nil {
        return nil, err  // loses context
    }
    return user, nil
}

// Good: wrap with context
func findUser(id int) (*User, error) {
    user, err := db.Query(...)
    if err != nil {
        return nil, fmt.Errorf("findUser %d: %w", id, err)
    }
    return user, nil
}

// Good: sentinel errors for expected conditions
var ErrNotFound = errors.New("not found")

// Good: check error type
if errors.Is(err, ErrNotFound) {
    // handle not found
}

// Good: unwrap to custom type
var validationErr *ValidationError
if errors.As(err, &validationErr) {
    // handle validation error
}
```

---

## Context Propagation

```go
// Bad: no context
func fetchUser(id int) (*User, error) {
    return db.QueryRow("SELECT * FROM users WHERE id = $1", id)
}

// Good: context first parameter
func fetchUser(ctx context.Context, id int) (*User, error) {
    return db.QueryRowContext(ctx, "SELECT * FROM users WHERE id = $1", id)
}

// Pass context through HTTP handlers
func (h *Handler) GetUser(w http.ResponseWriter, r *http.Request) {
    ctx := r.Context()
    user, err := h.service.FindUser(ctx, id)
    // ...
}
```

---

## Goroutine Safety

```go
// Bad: goroutine leak
func startWorker() {
    go func() {
        for {
            process()  // no exit condition
        }
    }()
}

// Good: goroutine with context cancellation
func startWorker(ctx context.Context) {
    go func() {
        for {
            select {
            case <-ctx.Done():
                return
            default:
                process()
            }
        }
    }()
}

// Good: errgroup for concurrent work
func fetchAll(ctx context.Context, ids []int) ([]*User, error) {
    g, ctx := errgroup.WithContext(ctx)
    results := make([]*User, len(ids))

    for i, id := range ids {
        i, id := i, id  // capture loop vars
        g.Go(func() error {
            user, err := fetchUser(ctx, id)
            if err != nil {
                return err
            }
            results[i] = user
            return nil
        })
    }

    if err := g.Wait(); err != nil {
        return nil, err
    }
    return results, nil
}
```

---

## Testing Patterns

```go
// Table-driven tests
func TestAdd(t *testing.T) {
    tests := []struct {
        name string
        a, b int
        want int
    }{
        {"positive", 1, 2, 3},
        {"negative", -1, -2, -3},
        {"zero", 0, 0, 0},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got := Add(tt.a, tt.b)
            if got != tt.want {
                t.Errorf("Add(%d, %d) = %d, want %d", tt.a, tt.b, got, tt.want)
            }
        })
    }
}

// HTTP handler testing
func TestGetUser(t *testing.T) {
    repo := &mockUserRepo{user: &User{ID: 1, Name: "Alice"}}
    h := NewHandler(repo)

    req := httptest.NewRequest(http.MethodGet, "/users/1", nil)
    w := httptest.NewRecorder()

    h.GetUser(w, req)

    assert.Equal(t, http.StatusOK, w.Code)
}

// Interface mocking (without external lib)
type mockUserRepo struct {
    user *User
    err  error
}

func (m *mockUserRepo) FindByID(ctx context.Context, id int) (*User, error) {
    return m.user, m.err
}
```

---

## Common Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `if err != nil { return err }` without context | Wrap: `fmt.Errorf("op: %w", err)` |
| Interface with many methods | Small, focused interfaces (1-3 methods) |
| `init()` functions with side effects | Explicit initialisation in `main()` |
| Package-level vars for dependencies | Constructor injection via struct fields |
| `defer` inside a loop | Move loop body to a function with defer |
| Returning concrete types from constructors | Return interface types |
| `panic` for expected errors | Return errors — panic only for true invariant violations |
