# Implementation Strategy: Combining Vertical and Horizontal Approaches

## The Fundamental Challenge

Building software with Clean Architecture requires balancing two seemingly opposing forces:

1. **Vertical Delivery**: Ship working features quickly
2. **Horizontal Integrity**: Maintain architectural boundaries

This document explains how to achieve both simultaneously.

## The Two-Dimensional Approach

Think of your codebase as a grid:

```
        Domain | Application | Infrastructure | Framework
        -------+-------------+---------------+----------
Story 1    ✓   |      ✓      |       ✓       |     ✓     → Working Feature
Story 2    ✓   |      ✓      |       ✓       |     ✓     → Working Feature
Story 3    ✓   |      ✓      |       ✓       |     ✓     → Working Feature
        -------+-------------+---------------+----------
           ↓          ↓              ↓             ↓
        Pure     Orchestration   Concrete     Entry Points
```

- **Horizontal axis**: Architectural layers (maintain always)
- **Vertical axis**: User stories (implement sequentially)

## Core Strategy Principles

### Principle 1: Architecture is Non-Negotiable

The layer boundaries and dependency rule are constants:
- Never skip layers to "save time"
- Never allow reverse dependencies
- Never mix responsibilities between layers

### Principle 2: Features are Negotiable

What to build and when is flexible:
- Prioritize based on value
- Defer complex features
- Simplify scope when possible

### Principle 3: Evolution Over Speculation

Let the architecture evolve based on real needs:
- Start simple, refactor when patterns emerge
- Don't create abstractions prematurely
- Extract common code when you have 3+ examples

## Implementation Phases

### Phase 0: Setup (One Time)

Before implementing any features:

1. **Create directory structure**
```
src/
├── domain/
├── application/
├── infrastructure/
└── frameworks/
```

2. **Establish boundaries**
   - Configure linters/tools to enforce dependencies
   - Set up import rules
   - Create initial interfaces

3. **Choose initial infrastructure**
   - Start with in-memory repositories
   - Use simple implementations
   - Can swap later without changing domain

### Phase 1: First Feature (Establish Patterns)

Your first feature sets the patterns:

```python
# Story: Create a simple entity

# 1. Domain (What it is)
class Task:
    def __init__(self, description):
        self._id = generate_id()
        self._description = description

# 2. Application (What it does)
class CreateTaskUseCase:
    def execute(self, request):
        task = Task(request.description)
        self._repository.save(task)
        return response

# 3. Infrastructure (How it's stored)
class InMemoryTaskRepository:
    def save(self, task):
        self._storage[task.id] = task

# 4. Framework (How users interact)
@app.post("/tasks")
def create_task(data):
    return use_case.execute(data)
```

**Key Decisions Made:**
- File organization pattern
- Naming conventions
- Dependency injection approach
- Testing strategy

### Phase 2: Second Feature (Validate Patterns)

The second feature validates your patterns:

- Does the structure still work?
- Are the abstractions right?
- What duplication is emerging?

**Don't refactor yet!** Wait for the third example.

### Phase 3: Third Feature (Extract Patterns)

With three examples, patterns become clear:

```python
# After 3 features, you might extract:

# Base use case
class UseCase(ABC):
    @abstractmethod
    def execute(self, request): pass

# Base repository
class Repository(ABC):
    @abstractmethod
    def save(self, entity): pass
    @abstractmethod
    def find_by_id(self, id): pass

# Common validation
def validate_required(value, field_name):
    if not value:
        raise ValidationError(f"{field_name} is required")
```

## Practical Implementation Workflow

### Step-by-Step for Each Story

#### 1. Start with Domain Understanding
```
Questions to ask:
- What business concept does this represent?
- What are the invariants (rules that must always be true)?
- What operations make business sense?

Output: Domain entity or value object
```

#### 2. Design the Use Case
```
Questions to ask:
- What's the user trying to accomplish?
- What data do they provide?
- What response do they expect?
- What side effects occur?

Output: Use case with request/response
```

#### 3. Define Infrastructure Needs
```
Questions to ask:
- What needs to be persisted?
- What external services are called?
- What can be mocked for now?

Output: Repository/gateway interfaces and implementations
```

#### 4. Create the Entry Point
```
Questions to ask:
- How do users invoke this feature?
- What validation is needed at the boundary?
- How to handle errors gracefully?

Output: Controller, CLI command, or handler
```

#### 5. Write Tests for Each Layer
```
Domain: Unit tests, no mocks needed
Application: Mock repositories/gateways
Infrastructure: Integration tests with real resources
Framework: End-to-end happy path tests
```

## Handling Common Scenarios

### Scenario 1: "This feature needs authentication"

**Incremental Approach:**

```python
# Version 1: No auth (Story 1-3)
class CreateTaskUseCase:
    def execute(self, request):
        task = Task(request.description)

# Version 2: Add auth (Story 4+)
class CreateTaskUseCase:
    def execute(self, request, user):  # Added user parameter
        task = Task(request.description, user.id)

# Version 3: Extract auth to middleware (Story 10+)
class AuthenticatedUseCase:
    def execute(self, request, context):  # Context includes user
        # Subclasses implement
```

### Scenario 2: "We need better performance"

**Incremental Optimization:**

```python
# Version 1: Simple (Stories 1-5)
class InMemoryRepository:
    def find_all(self):
        return list(self._items.values())

# Version 2: Add pagination (Story 6)
class InMemoryRepository:
    def find_all(self, offset=0, limit=10):
        items = list(self._items.values())
        return items[offset:offset + limit]

# Version 3: Add caching (Story 15)
class CachedRepository:
    def find_all(self, offset=0, limit=10):
        cache_key = f"all_{offset}_{limit}"
        if cache_key in self._cache:
            return self._cache[cache_key]
        # ... fetch and cache
```

### Scenario 3: "Requirements changed significantly"

**Adaptation Strategy:**

1. **Identify impact scope**
   - Which layer is affected?
   - Which stories are impacted?

2. **Modify incrementally**
   - Change domain if business rules changed
   - Change application if workflow changed
   - Change infrastructure if storage changed
   - Change framework if interface changed

3. **Maintain backwards compatibility (if needed)**
   - Add new use cases alongside old
   - Deprecate gradually
   - Remove when safe

## Managing Technical Debt

### Acceptable Temporary Debt

Early in development, these are OK:

```python
# In-memory repositories (replace with DB later)
class InMemoryUserRepository:
    # Fine for MVP

# Simple validation (enhance later)
if not email or "@" not in email:
    raise ValueError("Invalid email")
    # Good enough for now

# Basic error handling (improve later)
try:
    result = operation()
except Exception as e:
    return {"error": str(e)}
    # Refine error types later
```

### Unacceptable Debt

Never compromise on these:

```python
# ❌ NEVER: Domain depending on framework
class User:
    def save(self):
        db.execute("INSERT...")  # Domain knows about DB!

# ❌ NEVER: Skipping layers
@app.post("/users")
def create_user(data):
    user = User(data["name"])
    db.save(user)  # Controller talking to DB directly!

# ❌ NEVER: Circular dependencies
# application/use_case.py
from infrastructure.repository import SqlRepository  # Wrong direction!
```

## Refactoring Strategy

### When to Refactor

Apply the "Rule of Three":
1. **First time**: Just implement it
2. **Second time**: Note the duplication
3. **Third time**: Extract the pattern

### What to Refactor

**Extract when you see:**
- Same validation in 3+ places → Domain value object
- Same workflow in 3+ use cases → Application service
- Same data access in 3+ repositories → Base repository
- Same error handling in 3+ controllers → Error middleware

**Don't extract:**
- Similar but not identical code
- "Might be useful later" abstractions
- Patterns with only 1-2 instances

### How to Refactor Safely

1. **Ensure test coverage**
   ```bash
   pytest --cov=src --cov-report=term-missing
   # Aim for >80% coverage before major refactoring
   ```

2. **Refactor in small steps**
   ```
   Step 1: Extract method (tests still pass)
   Step 2: Move to new class (tests still pass)
   Step 3: Create abstraction (tests still pass)
   Step 4: Update callers one by one (tests still pass)
   ```

3. **Use parallel implementations**
   ```python
   # Keep old version working
   class OldImplementation:
       # Existing code

   # Build new version alongside
   class NewImplementation:
       # Refactored code

   # Switch gradually
   if feature_flag("use_new_impl"):
       impl = NewImplementation()
   else:
       impl = OldImplementation()
   ```

## Pragmatic Decisions

### When to Bend Rules (Slightly)

**Scenario**: Rapid prototype for user testing
```python
# Acceptable for prototype:
class SimpleTaskRepository:
    # Combines interface and implementation temporarily
    def save(self, task):
        self._tasks[task.id] = task

# Refactor after validation:
class TaskRepository(Protocol):  # Interface
    def save(self, task): ...

class SqlTaskRepository(TaskRepository):  # Implementation
    def save(self, task): ...
```

**Scenario**: Performance-critical operation
```python
# Acceptable for performance:
class OptimizedReadModel:
    # Bypass layers for read-only queries
    def get_dashboard_data(self):
        return db.execute_raw_sql("""
            SELECT ... complex optimized query
        """)

# But maintain write path through layers:
class CreateOrderUseCase:
    # All writes go through proper layers
```

### When to Stay Strict

**Always strict about:**
- Dependency direction (inward only)
- Domain purity (no I/O)
- Separation of concerns
- Test coverage for business logic

## Measuring Success

### Metrics That Matter

1. **Time to implement new feature**
   - Should decrease as patterns establish
   - New features should fit existing structure

2. **Defect rate in production**
   - Lower than before architecture
   - Defects isolated to single layer

3. **Time to fix bugs**
   - Quick to locate issue (clear layers)
   - Fix doesn't break other features

4. **Onboarding time**
   - New developers productive in days
   - Clear where code belongs

### Warning Signs

You might be over-engineering if:
- More abstraction code than business logic
- Simple features take days to implement
- Team constantly confused about structure
- More time refactoring than adding features

You might be under-engineering if:
- Can't change framework without rewriting
- Can't test without full system running
- Business logic scattered everywhere
- Every change breaks something else

## Summary

Successful implementation requires:

1. **Discipline**: Maintain layers always
2. **Pragmatism**: Build what's needed now
3. **Evolution**: Refactor based on real patterns
4. **Balance**: Neither over nor under-engineer

Remember:
- Vertical slicing for delivery speed
- Horizontal layers for long-term maintainability
- Start simple, evolve based on needs
- The architecture serves the business, not vice versa

The goal is working software that's maintainable, not architectural purity for its own sake.