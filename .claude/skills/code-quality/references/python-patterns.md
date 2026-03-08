# Python Patterns Reference

## ruff Configuration

```toml
# pyproject.toml
[tool.ruff]
target-version = "py312"
line-length = 88

[tool.ruff.lint]
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "UP",  # pyupgrade
    "ANN", # flake8-annotations (type hints)
    "S",   # flake8-bandit (security)
    "RUF", # ruff-specific rules
]
ignore = [
    "ANN101",  # missing type for self
    "ANN102",  # missing type for cls
]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]  # allow assert in tests

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
```

---

## mypy Configuration

```toml
# pyproject.toml
[tool.mypy]
python_version = "3.12"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_any_generics = true
no_implicit_optional = true

[[tool.mypy.overrides]]
module = "tests.*"
disallow_untyped_defs = false
```

---

## Project Structure

```
myapp/
├── src/
│   └── myapp/
│       ├── __init__.py
│       ├── domain/          # business logic
│       │   ├── models.py    # Pydantic models / dataclasses
│       │   └── services.py
│       ├── infrastructure/  # DB, external APIs
│       │   ├── database.py
│       │   └── repositories.py
│       ├── api/             # HTTP layer (FastAPI/Flask)
│       │   ├── routes.py
│       │   └── schemas.py
│       └── config.py
├── tests/
│   ├── unit/
│   ├── integration/
│   └── conftest.py
├── pyproject.toml
└── uv.lock  # or poetry.lock
```

---

## Dependency Management

**uv (recommended — fastest):**
```bash
uv init myapp
uv add fastapi pydantic
uv add --dev pytest mypy ruff
uv run pytest
```

**Poetry:**
```bash
poetry init
poetry add fastapi pydantic
poetry add --group dev pytest mypy ruff
poetry run pytest
```

---

## Type Hint Patterns

```python
# Bad: no type hints
def process_users(users, limit):
    return users[:limit]

# Good: full type hints
def process_users(users: list[User], limit: int) -> list[User]:
    return users[:limit]

# Union types (Python 3.10+)
def find_user(id: int) -> User | None:
    ...

# TypedDict for structured dicts
from typing import TypedDict

class UserDict(TypedDict):
    id: int
    name: str
    email: str

# Protocol for duck typing (prefer over ABC)
from typing import Protocol

class Repository(Protocol):
    def find_by_id(self, id: int) -> User | None: ...
    def save(self, user: User) -> None: ...
```

---

## Pydantic Models

```python
from pydantic import BaseModel, EmailStr, field_validator

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    age: int

    @field_validator("age")
    @classmethod
    def age_must_be_positive(cls, v: int) -> int:
        if v < 0:
            raise ValueError("age must be positive")
        return v

class UserResponse(BaseModel):
    id: int
    name: str
    email: str

    model_config = {"from_attributes": True}  # for ORM models
```

---

## pytest Patterns

```python
# conftest.py — shared fixtures
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session

@pytest.fixture
def db_session() -> Session:
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    with Session(engine) as session:
        yield session
        session.rollback()

# Unit test
def test_user_full_name() -> None:
    user = User(first_name="Alice", last_name="Smith")
    assert user.full_name == "Alice Smith"

# Parametrize
@pytest.mark.parametrize("email,valid", [
    ("user@example.com", True),
    ("not-an-email", False),
    ("", False),
])
def test_email_validation(email: str, valid: bool) -> None:
    if valid:
        UserCreate(name="Test", email=email, age=25)
    else:
        with pytest.raises(ValueError):
            UserCreate(name="Test", email=email, age=25)

# Async test
import pytest_asyncio

@pytest.mark.asyncio
async def test_async_fetch() -> None:
    result = await fetch_users()
    assert len(result) > 0
```

---

## Common Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| `True == value` (Yoda condition) | `value == True` — or better, just `if value:` for booleans |
| `def f(items=[])` mutable default | `def f(items: list \| None = None)` then `items = items or []` |
| Bare `except:` | `except ValueError:` or `except (TypeError, ValueError):` |
| `import *` | Explicit imports only |
| `os.path.join(...)` | `pathlib.Path(...) / "subdir"` |
| `"Hello " + name` | `f"Hello {name}"` |
| `type: ignore` without comment | Add explanation: `# type: ignore[assignment] — third-party stub missing` |
| Synchronous I/O in async functions | Offload to thread pool: `asyncio.to_thread(blocking_fn)` |
| God class with 20+ methods | Split by responsibility into smaller classes or functions |
