# Pest Patterns

## File Structure

```
tests/
├── Pest.php                    # Global uses, helpers, expects
├── TestCase.php
├── Unit/
│   └── Actions/
│       └── CreateUserTest.php
├── Feature/
│   └── Api/
│       └── UserControllerTest.php
└── Architecture/
    └── ArchTest.php
```

---

## Pest.php Setup

```php
<?php

uses(Tests\TestCase::class)->in('Feature');
uses(Tests\TestCase::class)->in('Unit');
```

---

## Feature Test Pattern (HTTP)

```php
<?php

use App\Models\User;
use function Pest\Laravel\{actingAs, getJson, postJson, deleteJson};

describe('UserController', function () {

    describe('index', function () {
        it('returns paginated users for admin', function () {
            $admin = User::factory()->admin()->create();
            User::factory()->count(5)->create();

            actingAs($admin)
                ->getJson('/api/v1/users')
                ->assertOk()
                ->assertJsonStructure([
                    'data' => [['id', 'name', 'email']],
                    'meta' => ['total', 'per_page'],
                ]);
        });

        it('denies access to guests', function () {
            getJson('/api/v1/users')->assertUnauthorized();
        });
    });

    describe('store', function () {
        it('creates a user with valid data', function () {
            $admin = User::factory()->admin()->create();

            actingAs($admin)
                ->postJson('/api/v1/users', [
                    'name' => 'Jane Doe',
                    'email' => 'jane@example.com',
                ])
                ->assertCreated()
                ->assertJsonPath('data.email', 'jane@example.com');

            expect(User::where('email', 'jane@example.com')->exists())->toBeTrue();
        });

        it('validates required fields', function () {
            $admin = User::factory()->admin()->create();

            actingAs($admin)
                ->postJson('/api/v1/users', [])
                ->assertUnprocessable()
                ->assertJsonValidationErrors(['name', 'email']);
        });
    });
});
```

---

## Unit Test Pattern (Action)

```php
<?php

use App\Actions\CreateUser;
use App\Models\User;

describe('CreateUser', function () {

    it('creates and returns a user', function () {
        $action = new CreateUser();

        $user = $action->handle([
            'name' => 'John',
            'email' => 'john@example.com',
            'password' => 'secret',
        ]);

        expect($user)
            ->toBeInstanceOf(User::class)
            ->name->toBe('John')
            ->email->toBe('john@example.com');
    });

});
```

---

## Datasets

```php
it('validates email format', function (string $email) {
    postJson('/api/v1/users', ['email' => $email])
        ->assertUnprocessable();
})->with([
    'missing @' => ['not-an-email'],
    'missing domain' => ['user@'],
    'empty string' => [''],
]);
```

---

## Architecture Tests (ArchTest.php)

```php
<?php

arch('controllers do not contain business logic')
    ->expect('App\Http\Controllers')
    ->not->toUse('App\Models');

arch('actions are invokable')
    ->expect('App\Actions')
    ->toHaveMethod('handle');

arch('models extend Eloquent')
    ->expect('App\Models')
    ->toExtend('Illuminate\Database\Eloquent\Model');

arch('no debugging functions in production code')
    ->expect('App')
    ->not->toUse(['dd', 'dump', 'var_dump', 'ray']);

arch()->preset()->laravel();
arch()->preset()->security();
```

---

## Useful Expectations

```php
expect($value)->toBe('exact');
expect($value)->toEqual(['loose', 'comparison']);
expect($value)->toBeTrue();
expect($value)->toBeNull();
expect($value)->toBeInstanceOf(User::class);
expect($array)->toHaveCount(3);
expect($array)->toContain('item');
expect($string)->toStartWith('prefix');
expect($string)->toContain('substring');
expect(fn() => $action->handle())->toThrow(ValidationException::class);
```
