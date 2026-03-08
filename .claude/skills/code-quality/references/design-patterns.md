# Design Patterns Reference

Source: https://refactoring.guru/design-patterns/catalog

Apply patterns to solve recurring design problems — not for their own sake. Prefer the simplest solution; reach for a pattern only when it removes real complexity.

---

## Creational Patterns

Object creation mechanisms that increase flexibility and reuse.

### Factory Method
Defines an interface for creating objects but lets subclasses decide which class to instantiate.
- **Use when:** the exact type to create isn't known until runtime, or subclasses should control creation
- **Laravel:** `Notification::route()`, custom `Transport` factories, seeder factories
- **Anti-pattern:** `new ConcreteClass()` scattered across business logic

### Abstract Factory
Creates families of related objects without specifying their concrete classes.
- **Use when:** the system must be independent of how its products are created and must work with multiple product families
- **Laravel:** swappable driver families (mail, cache, queue) via service container bindings
- **Anti-pattern:** `if ($driver === 'redis') { ... } elseif ($driver === 'memcached') { ... }`

### Builder
Constructs complex objects step by step, separating construction from representation.
- **Use when:** constructing an object requires many steps or configurations
- **Laravel:** `QueryBuilder`, `MailMessage`, `NotificationBuilder`, test `Factory::state()`
- **TypeScript:** fluent request builders, form schema builders
- **Anti-pattern:** constructor with 8+ parameters

### Prototype
Creates new objects by cloning an existing object.
- **Use when:** object creation is expensive and a similar object already exists
- **Laravel:** `$model->replicate()` for duplicating Eloquent records
- **Anti-pattern:** manually re-setting every property to copy an object

### Singleton
Ensures a class has only one instance and provides a global access point.
- **Use when:** exactly one instance is needed to coordinate across the system (e.g. config, logger)
- **Laravel:** avoid — use service container bindings (`app()->singleton(...)`) instead of hand-rolled singletons
- **Anti-pattern:** static state that makes testing impossible

---

## Structural Patterns

Assemble objects and classes into larger, flexible structures.

### Adapter
Converts the interface of a class into another interface clients expect.
- **Use when:** integrating incompatible third-party or legacy interfaces
- **Laravel:** wrapping a third-party SDK behind a local interface/contract; `FilesystemAdapter`
- **TypeScript:** wrapping browser APIs or legacy modules behind a consistent interface
- **Anti-pattern:** spreading third-party SDK calls throughout the codebase

### Bridge
Separates abstraction from its implementation so both can vary independently.
- **Use when:** you want to avoid a permanent binding between abstraction and implementation; useful for multiple dimensions of variation
- **Laravel:** separating notification channels from notification content
- **Anti-pattern:** explosion of subclasses (`EmailUserNotification`, `SmsAdminNotification`, etc.)

### Composite
Composes objects into tree structures to represent part-whole hierarchies.
- **Use when:** clients should treat individual objects and compositions uniformly
- **Laravel:** nested menu structures, permission trees, nested form fields
- **TypeScript/Vue:** recursive tree components (file explorer, nested comments)

### Decorator
Attaches additional behaviour to objects dynamically by wrapping them.
- **Use when:** you need to add responsibilities to objects without subclassing
- **Laravel:** Laravel middleware pipeline, `Cache` decorator wrapping a repository, `LoggingRepository`
- **TypeScript:** class decorators, HOCs in Vue/React
- **Anti-pattern:** inheritance chains that add one small behaviour per level

### Facade
Provides a simplified interface to a complex subsystem.
- **Use when:** you want to provide a simple interface to a complex body of code
- **Laravel:** `Auth`, `Cache`, `Storage` facades; custom `PaymentService` hiding Stripe SDK complexity
- **Anti-pattern:** business logic that directly chains multiple subsystems without abstraction

### Flyweight
Shares common state between many fine-grained objects to save memory.
- **Use when:** a large number of similar objects consume too much memory
- **Use rarely** — mostly relevant in game engines or rendering. In web apps: shared config/locale objects
- **Anti-pattern:** premature optimisation for memory without measurement

### Proxy
Provides a substitute that controls access to another object.
- **Use when:** you need lazy initialisation, access control, logging, or caching around an object
- **Laravel:** `lazy()` collections, authorization policies as access proxies, HTTP client mocking in tests
- **TypeScript:** JavaScript `Proxy` for reactive systems (Vue's reactivity)

---

## Behavioral Patterns

Algorithms and assignment of responsibilities between objects.

### Chain of Responsibility
Passes a request along a chain of handlers; each handler decides to process or pass on.
- **Use when:** more than one object may handle a request, and the handler isn't known a priori
- **Laravel:** middleware pipeline, validation rule chains, pipeline pattern (`app(Pipeline::class)`)
- **Anti-pattern:** deeply nested `if/elseif` handler trees

### Command
Encapsulates a request as an object, enabling parameterisation, queuing, and undo.
- **Use when:** you need to queue, log, or reverse operations
- **Laravel:** queued Jobs (`ShouldQueue`), `artisan` commands, action classes
- **TypeScript:** command objects for undo/redo in editors
- **Anti-pattern:** controller methods directly performing multi-step operations

### Iterator
Provides a way to traverse a collection without exposing its underlying structure.
- **Use when:** you need a standard way to traverse different collection types
- **Laravel:** `Cursor`, `LazyCollection`, PHP `Generator` functions
- **TypeScript:** custom iterables with `Symbol.iterator`
- **Anti-pattern:** exposing internal array structure to allow traversal

### Mediator
Reduces chaotic dependencies between objects by centralising communication.
- **Use when:** many objects communicate in complex, tangled ways
- **Laravel:** event system (`Event::dispatch` / `Listener`) as mediator between subsystems
- **TypeScript/Vue:** Pinia store as mediator between components; event buses
- **Anti-pattern:** components/services directly referencing and calling each other

### Memento
Captures and restores an object's internal state without exposing its implementation.
- **Use when:** you need undo/redo or state snapshots
- **Laravel:** model `getOriginal()` / dirty tracking; versioning/audit packages (Spatie ActivityLog)
- **TypeScript:** undo stacks in editors, form state snapshots

### Observer
Defines a subscription mechanism to notify multiple objects about events.
- **Use when:** a change in one object requires updating others, and you don't know how many
- **Laravel:** Eloquent model observers, `Event` / `Listener`, `$dispatchesEvents`
- **TypeScript/Vue:** `watch`, `watchEffect`, event emitters
- **Anti-pattern:** polling for state changes; direct method calls to dependents

### State
Allows an object to alter its behaviour when its internal state changes.
- **Use when:** an object's behaviour depends on its state and must change at runtime
- **Laravel:** order/payment status machines; `asEnum` casts + match expressions
- **TypeScript:** state machines (XState), UI component state (loading/error/success)
- **Anti-pattern:** large `if/switch` blocks on a status field spread across methods

### Strategy
Defines a family of algorithms, encapsulates each, and makes them interchangeable.
- **Use when:** you want to swap algorithms at runtime or eliminate conditionals around algorithm selection
- **Laravel:** payment gateway strategies, shipping calculators, export formatters
- **TypeScript:** sorting/filtering strategies injected into a service
- **Anti-pattern:** `if ($method === 'paypal') { ... } elseif ($method === 'stripe') { ... }`

### Template Method
Defines the skeleton of an algorithm in a base class, deferring some steps to subclasses.
- **Use when:** multiple classes share the same algorithm structure but differ in specific steps
- **Laravel:** `Mailable`, `Notification`, `Artisan\Command` (all use template method internally)
- **Anti-pattern:** copy-pasting a multi-step process across classes and changing one step

### Visitor
Lets you add further operations to objects without modifying them.
- **Use when:** you need to perform many distinct operations on an object structure without polluting those classes
- **Laravel:** AST walkers, query compiler visitors, report exporters across multiple model types
- **TypeScript:** AST transformers (Babel plugins, TypeScript compiler API)
- **Anti-pattern:** adding unrelated methods to domain models to support new operations

---

## Pattern Selection Guide

| Symptom | Consider |
|---------|----------|
| `new ConcreteClass()` scattered in business logic | Factory Method |
| Constructor with many parameters | Builder |
| Third-party SDK calls throughout codebase | Adapter + Facade |
| Large `if/switch` on a type or status | Strategy or State |
| Adding behaviour without touching existing classes | Decorator or Visitor |
| Objects notifying each other directly | Observer or Mediator |
| Need to undo/replay actions | Command + Memento |
| Repeated multi-step algorithm with varying steps | Template Method |
| Request processing pipeline | Chain of Responsibility |

---

## Principles (SOLID + composition)

- **Single Responsibility** — one reason to change per class
- **Open/Closed** — open for extension, closed for modification (Strategy, Decorator, Observer)
- **Liskov Substitution** — subtypes must be substitutable for their base types
- **Interface Segregation** — small, focused interfaces over large general ones
- **Dependency Inversion** — depend on abstractions, not concretions (inject via constructor)
- **Favour composition over inheritance** — prefer wrapping/delegating to extending
- **Program to an interface, not an implementation**
