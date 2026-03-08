# PHP Quality Patterns

## PHPStan / Larastan Config (phpstan.neon)

```neon
includes:
    - vendor/larastan/larastan/extension.neon

parameters:
    level: 8
    paths:
        - app
    excludePaths:
        - app/Http/Middleware/TrustProxies.php
    checkMissingIterableValueType: false
```

---

## Rector Config (rector.php)

```php
<?php

use Rector\Config\RectorConfig;
use Rector\Set\ValueObject\LevelSetList;
use Rector\Set\ValueObject\SetList;
use RectorLaravel\Set\LaravelSetList;

return RectorConfig::configure()
    ->withPaths([__DIR__ . '/app', __DIR__ . '/tests'])
    ->withSets([
        LevelSetList::UP_TO_PHP_83,
        SetList::CODE_QUALITY,
        SetList::DEAD_CODE,
        SetList::TYPE_DECLARATION,
        LaravelSetList::LARAVEL_110,
    ])
    ->withSkip([
        // add exceptions here
    ]);
```

---

## Pint Config (pint.json)

```json
{
    "preset": "laravel",
    "rules": {
        "ordered_imports": true,
        "no_unused_imports": true,
        "single_quote": true,
        "trailing_comma_in_multiline": true
    }
}
```

---

## PHP 8.x Modernisation Targets

### PHP 8.0+
```php
// Before
switch ($status) {
    case 'active': return true;
    case 'inactive': return false;
    default: throw new \Exception();
}

// After
return match ($status) {
    'active' => true,
    'inactive' => false,
    default => throw new \Exception(),
};
```

### PHP 8.1+
```php
// Enums instead of class constants
enum Status: string {
    case Active = 'active';
    case Inactive = 'inactive';
}

// Readonly properties
class User {
    public function __construct(
        public readonly string $name,
        public readonly string $email,
    ) {}
}

// First-class callables
$fn = strlen(...);
$users = array_map($this->transform(...), $users);
```

### PHP 8.2+
```php
// Readonly classes
readonly class UserDto {
    public function __construct(
        public string $name,
        public string $email,
    ) {}
}
```

---

## Laravel Anti-Patterns → Fixes

| Anti-Pattern | Fix |
|---|---|
| Business logic in controllers | Move to Action classes (`app/Actions/`) |
| Raw DB queries in controllers | Use Eloquent + Repository if complex |
| `$request->all()` in store/update | Use `$request->validated()` always |
| Mass assignment without `$fillable` | Define `$fillable` or use `$guarded = []` with caution |
| Missing DB indexes for foreign keys | Always add index to foreign key columns |
| N+1 queries | Eager load with `with()`, use Laravel Debugbar to detect |
