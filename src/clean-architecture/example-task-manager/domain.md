# Domain Layer - Task Manager Example

## Overview

The Domain layer contains the core business logic of our Task Manager. It knows nothing about databases, web frameworks, or external services - just pure business rules.

## Core Concepts

### Task Entity

The Task is our primary entity with:
- **Identity**: Unique ID that persists
- **State**: Can transition from incomplete to complete
- **Invariants**: Business rules that must always be true

## Implementation Across Languages

### Conceptual Model (Language Agnostic)

```
Entity: Task
├─ Identity: id (UUID)
├─ Attributes:
│  ├─ description (required, non-empty)
│  ├─ completed (boolean, default false)
│  ├─ createdAt (timestamp)
│  └─ completedAt (optional timestamp)
└─ Operations:
   ├─ create(description) → Task
   ├─ complete() → void
   └─ validateDescription(desc) → void
```

### Business Rules (Invariants)

1. **Task description cannot be empty**
2. **Task cannot be completed twice**
3. **Completed tasks have a completion timestamp**
4. **Task IDs are immutable once created**

### Python Implementation

```python
# domain/entities/task.py
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
import uuid

@dataclass
class Task:
    """Task entity with business rules."""

    description: str
    _id: str = field(default_factory=lambda: str(uuid.uuid4()))
    _completed: bool = field(default=False)
    _created_at: datetime = field(default_factory=datetime.now)
    _completed_at: Optional[datetime] = field(default=None)

    def __post_init__(self):
        """Validate on creation."""
        self._validate_description(self.description)

    @property
    def id(self) -> str:
        return self._id

    @property
    def is_completed(self) -> bool:
        return self._completed

    @property
    def created_at(self) -> datetime:
        return self._created_at

    @property
    def completed_at(self) -> Optional[datetime]:
        return self._completed_at

    def complete(self) -> None:
        """Mark task as complete."""
        if self._completed:
            raise ValueError("Task is already completed")

        self._completed = True
        self._completed_at = datetime.now()

    @staticmethod
    def _validate_description(description: str) -> None:
        """Validate task description."""
        if not description or not description.strip():
            raise ValueError("Task description cannot be empty")

        if len(description) > 500:
            raise ValueError("Task description too long (max 500 chars)")
```

### TypeScript Implementation

```typescript
// domain/entities/Task.ts

export class Task {
  private readonly _id: string;
  private _description: string;
  private _completed: boolean;
  private readonly _createdAt: Date;
  private _completedAt: Date | null;

  constructor(description: string, id?: string) {
    this._validateDescription(description);

    this._id = id || this._generateId();
    this._description = description;
    this._completed = false;
    this._createdAt = new Date();
    this._completedAt = null;
  }

  // Getters for controlled access
  get id(): string {
    return this._id;
  }

  get description(): string {
    return this._description;
  }

  get isCompleted(): boolean {
    return this._completed;
  }

  get createdAt(): Date {
    return this._createdAt;
  }

  get completedAt(): Date | null {
    return this._completedAt;
  }

  complete(): void {
    if (this._completed) {
      throw new Error("Task is already completed");
    }

    this._completed = true;
    this._completedAt = new Date();
  }

  private _validateDescription(description: string): void {
    if (!description || description.trim().length === 0) {
      throw new Error("Task description cannot be empty");
    }

    if (description.length > 500) {
      throw new Error("Task description too long (max 500 chars)");
    }
  }

  private _generateId(): string {
    return crypto.randomUUID();
  }
}
```

### C# Implementation

```csharp
// Domain/Entities/Task.cs

using System;

namespace TaskManager.Domain.Entities
{
    public class Task
    {
        private string _description;
        private bool _completed;
        private DateTime? _completedAt;

        public string Id { get; }
        public string Description => _description;
        public bool IsCompleted => _completed;
        public DateTime CreatedAt { get; }
        public DateTime? CompletedAt => _completedAt;

        public Task(string description) : this(description, Guid.NewGuid().ToString())
        {
        }

        public Task(string description, string id)
        {
            ValidateDescription(description);

            Id = id;
            _description = description;
            _completed = false;
            CreatedAt = DateTime.UtcNow;
            _completedAt = null;
        }

        public void Complete()
        {
            if (_completed)
            {
                throw new InvalidOperationException("Task is already completed");
            }

            _completed = true;
            _completedAt = DateTime.UtcNow;
        }

        private static void ValidateDescription(string description)
        {
            if (string.IsNullOrWhiteSpace(description))
            {
                throw new ArgumentException("Task description cannot be empty");
            }

            if (description.Length > 500)
            {
                throw new ArgumentException("Task description too long (max 500 chars)");
            }
        }
    }
}
```

### Rust Implementation

```rust
// domain/src/entities/task.rs
use chrono::{DateTime, Utc};
use crate::{errors::DomainError, value_objects::TaskId};

const MAX_DESCRIPTION_LENGTH: usize = 500;

#[derive(Debug, Clone)]
pub struct Task {
    id: TaskId,
    description: String,
    completed: bool,
    created_at: DateTime<Utc>,
    completed_at: Option<DateTime<Utc>>,
}

impl Task {
    /// Create a new task with validation
    pub fn new(description: String) -> Result<Self, DomainError> {
        Self::validate_description(&description)?;

        Ok(Self {
            id: TaskId::new(),
            description,
            completed: false,
            created_at: Utc::now(),
            completed_at: None,
        })
    }

    /// Reconstitute from persistence (bypasses validation)
    pub fn reconstitute(
        id: TaskId,
        description: String,
        completed: bool,
        created_at: DateTime<Utc>,
        completed_at: Option<DateTime<Utc>>,
    ) -> Self {
        Self { id, description, completed, created_at, completed_at }
    }

    // Getters
    pub fn id(&self) -> &TaskId { &self.id }
    pub fn description(&self) -> &str { &self.description }
    pub fn is_completed(&self) -> bool { self.completed }
    pub fn created_at(&self) -> DateTime<Utc> { self.created_at }
    pub fn completed_at(&self) -> Option<DateTime<Utc>> { self.completed_at }

    // Behavior
    pub fn complete(&mut self) -> Result<(), DomainError> {
        if self.completed {
            return Err(DomainError::AlreadyCompleted);
        }
        self.completed = true;
        self.completed_at = Some(Utc::now());
        Ok(())
    }

    fn validate_description(description: &str) -> Result<(), DomainError> {
        let trimmed = description.trim();
        if trimmed.is_empty() {
            return Err(DomainError::EmptyDescription);
        }
        if trimmed.len() > MAX_DESCRIPTION_LENGTH {
            return Err(DomainError::DescriptionTooLong {
                max: MAX_DESCRIPTION_LENGTH
            });
        }
        Ok(())
    }
}

impl PartialEq for Task {
    fn eq(&self, other: &Self) -> bool {
        self.id == other.id  // Entity equality by ID
    }
}
```

```rust
// domain/src/value_objects/task_id.rs
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct TaskId(Uuid);

impl TaskId {
    pub fn new() -> Self {
        Self(Uuid::new_v4())
    }

    pub fn from_uuid(uuid: Uuid) -> Self {
        Self(uuid)
    }
}

impl std::fmt::Display for TaskId {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}", self.0)
    }
}

impl std::str::FromStr for TaskId {
    type Err = uuid::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        Ok(Self(Uuid::parse_str(s)?))
    }
}
```

```rust
// domain/src/errors.rs
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DomainError {
    #[error("Task description cannot be empty")]
    EmptyDescription,

    #[error("Task description exceeds maximum length of {max} characters")]
    DescriptionTooLong { max: usize },

    #[error("Task is already completed")]
    AlreadyCompleted,
}
```

```rust
// domain/src/repositories/task_repository.rs
use async_trait::async_trait;
use crate::{entities::Task, value_objects::TaskId, errors::RepositoryError};

#[async_trait]
pub trait TaskRepository: Send + Sync {
    async fn save(&self, task: &Task) -> Result<(), RepositoryError>;
    async fn find_by_id(&self, id: &TaskId) -> Result<Option<Task>, RepositoryError>;
    async fn find_all(&self) -> Result<Vec<Task>, RepositoryError>;
    async fn delete(&self, id: &TaskId) -> Result<(), RepositoryError>;
}
```

## Key Domain Patterns

### 1. Encapsulation

All implementations demonstrate proper encapsulation:
- Private fields with controlled access
- Public methods for behavior
- Properties/getters for read-only access
- No direct state manipulation

### 2. Invariant Protection

Business rules are enforced at all times:
```
// Can't create invalid task
new Task("")  // Throws error

// Can't complete twice
task.complete()
task.complete()  // Throws error
```

### 3. Rich Domain Model vs Anemic

**Rich (Good):**
```python
task.complete()  # Business logic in entity
```

**Anemic (Bad):**
```python
task.completed = True  # Just data, no behavior
task.completed_at = datetime.now()  # Logic elsewhere
```

### 4. No External Dependencies

The domain entities don't know about:
- Databases (no @Entity decorators)
- HTTP (no JSON serialization)
- Frameworks (no framework-specific code)
- External services (no API calls)

## Evolution Examples

### Adding Priority (Value Object)

```python
@dataclass(frozen=True)
class Priority:
    """Priority value object."""
    value: int

    def __post_init__(self):
        if not 1 <= self.value <= 5:
            raise ValueError("Priority must be between 1 and 5")

    def is_higher_than(self, other: 'Priority') -> bool:
        return self.value > other.value

# Update Task entity
class Task:
    priority: Priority = field(default_factory=lambda: Priority(3))
```

### Adding Due Date

```python
class Task:
    _due_date: Optional[datetime] = field(default=None)

    def set_due_date(self, due_date: datetime) -> None:
        """Set task due date with validation."""
        if due_date < datetime.now():
            raise ValueError("Due date cannot be in the past")

        if self._completed:
            raise ValueError("Cannot set due date on completed task")

        self._due_date = due_date

    @property
    def is_overdue(self) -> bool:
        """Check if task is overdue."""
        if not self._due_date or self._completed:
            return False
        return datetime.now() > self._due_date
```

### Adding Domain Events

```python
@dataclass(frozen=True)
class TaskCompleted:
    """Domain event when task is completed."""
    task_id: str
    completed_at: datetime
    description: str

class Task:
    _events: List[object] = field(default_factory=list)

    def complete(self) -> None:
        """Mark task as complete and raise event."""
        if self._completed:
            raise ValueError("Task is already completed")

        self._completed = True
        self._completed_at = datetime.now()

        # Raise domain event
        self._events.append(TaskCompleted(
            task_id=self._id,
            completed_at=self._completed_at,
            description=self.description
        ))

    def collect_events(self) -> List[object]:
        """Collect and clear domain events."""
        events = self._events.copy()
        self._events.clear()
        return events
```

## Testing the Domain

### Python Test Example

```python
import pytest
from datetime import datetime
from domain.entities import Task

class TestTask:
    def test_create_valid_task(self):
        task = Task("Learn Clean Architecture")
        assert task.description == "Learn Clean Architecture"
        assert not task.is_completed
        assert task.id is not None

    def test_cannot_create_empty_task(self):
        with pytest.raises(ValueError, match="cannot be empty"):
            Task("")

    def test_complete_task(self):
        task = Task("Test task")
        task.complete()

        assert task.is_completed
        assert task.completed_at is not None

    def test_cannot_complete_twice(self):
        task = Task("Test task")
        task.complete()

        with pytest.raises(ValueError, match="already completed"):
            task.complete()
```

### Key Testing Points

1. **Test business rules, not implementation**
2. **Test both happy path and edge cases**
3. **Domain tests need no mocks or external dependencies**
4. **Fast execution (no I/O)**

## Common Mistakes to Avoid

### 1. Exposing Internal State

```python
# ❌ BAD - Direct access to mutable state
class Task:
    def __init__(self, description):
        self.items = []  # Public mutable list!

# ✅ GOOD - Controlled access
class Task:
    def __init__(self, description):
        self._items = []

    def add_item(self, item):
        # Validation here
        self._items.append(item)
```

### 2. Anemic Domain Model

```python
# ❌ BAD - No behavior
class Task:
    def __init__(self):
        self.completed = False

# Service does the logic
class TaskService:
    def complete_task(self, task):
        task.completed = True  # Anemic!

# ✅ GOOD - Rich domain
class Task:
    def complete(self):
        # Business logic here
        if self._completed:
            raise ValueError("Already completed")
        self._completed = True
```

### 3. Domain Depending on Infrastructure

```python
# ❌ BAD - Domain knows about database
from sqlalchemy import Column, String

class Task(Base):  # Coupled to SQLAlchemy!
    __tablename__ = 'tasks'
    id = Column(String, primary_key=True)

# ✅ GOOD - Pure domain
class Task:
    def __init__(self, description):
        self._id = str(uuid.uuid4())
        # Pure Python, no ORM
```

## Summary

The Domain layer in our Task Manager example:
- Contains pure business logic
- Enforces invariants
- Has no external dependencies
- Is easily testable
- Can evolve independently

This forms the stable core of our application that rarely changes when we swap databases, frameworks, or external services.