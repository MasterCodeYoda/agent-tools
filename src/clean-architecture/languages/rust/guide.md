# Rust Clean Architecture Guide

## Overview

Rust's ownership model and strong type system make it exceptionally well-suited for Clean Architecture. The language's guarantees around memory safety, zero-cost abstractions, and explicit error handling naturally enforce architectural boundaries that other languages achieve through discipline alone.

**Key Rust advantages for Clean Architecture:**
- **Traits as interfaces**: Define clean abstractions without runtime overhead
- **Ownership enforces encapsulation**: Private fields are truly private, mutations are explicit
- **Result pattern for errors**: No hidden exceptions, explicit error handling at boundaries
- **Cargo workspaces**: Physical layer separation with dependency constraints
- **No inheritance**: Composition over inheritance is the default

---

## Three-Crate Architecture Pattern

For projects requiring strict architectural compliance, separate Cargo crates enforce layer boundaries at compile time. The compiler itself prevents architecture violations.

### Why Separate Crates?

| Aspect | Single Crate | Three Crates |
|--------|--------------|--------------|
| **Dependency enforcement** | Requires discipline and tooling | Compile-time errors |
| **Build speed** | Faster (one compilation unit) | Parallel builds offset multi-crate overhead |
| **Refactoring** | Easier to move code | More ceremony, clearer boundaries |
| **Team scaling** | Harder to maintain boundaries | Clear ownership per crate |

**Recommendation:** Use three-crate architecture when:
- Team has 3+ developers
- Project will live >6 months
- Strict architectural compliance required
- Multiple applications share domain logic

### Crate Structure

```
crates/
├── project-domain/           # Pure business entities - NO internal dependencies
│   └── src/
│       ├── lib.rs
│       ├── workspace.rs      # Workspace entity
│       ├── page.rs           # Page entity
│       └── block.rs          # Block entity
│
├── project-application/      # Use cases + service abstractions
│   └── src/                  # Depends on: domain
│       ├── lib.rs
│       └── workspace/
│           ├── mod.rs
│           ├── services.rs   # WorkspaceRepository trait + errors
│           ├── initialize.rs # InitializeWorkspaceUseCase
│           └── create.rs     # CreateWorkspaceUseCase
│
└── project-infrastructure/   # Concrete implementations
    └── src/                  # Depends on: application, domain
        └── filesystem/
            └── workspace_repository.rs
```

### Cargo.toml Dependency Structure

```toml
# crates/project-domain/Cargo.toml
[package]
name = "project-domain"
version.workspace = true
edition.workspace = true

[dependencies]
# External crates only - NO project dependencies
chrono = { workspace = true }
uuid = { workspace = true }
thiserror = { workspace = true }
serde = { workspace = true }
```

```toml
# crates/project-application/Cargo.toml
[package]
name = "project-application"
version.workspace = true
edition.workspace = true

[dependencies]
project-domain = { path = "../project-domain" }  # Domain only
async-trait = { workspace = true }
thiserror = { workspace = true }
```

```toml
# crates/project-infrastructure/Cargo.toml
[package]
name = "project-infrastructure"
version.workspace = true
edition.workspace = true

[dependencies]
project-domain = { path = "../project-domain" }
project-application = { path = "../project-application" }
tokio = { workspace = true }
# Database/storage dependencies here
```

### Compile-Time Enforcement

With separate crates, this code **won't compile**:

```rust
// In project-domain/src/workspace.rs
use project_infrastructure::FileSystemWorkspaceRepository;  // ❌ ERROR: unknown crate

// The compiler prevents domain from knowing about infrastructure
```

This is enforced by Cargo's dependency resolution - domain crate has no dependency on infrastructure, so it literally cannot import from it.

### Workspace Root Configuration

```toml
# Cargo.toml (workspace root)
[workspace]
resolver = "2"
members = [
    "crates/project-domain",
    "crates/project-application",
    "crates/project-infrastructure",
    "apps/desktop/src-tauri",
]

[workspace.package]
version = "0.1.0"
edition = "2021"

[workspace.dependencies]
# Centralized versions for all crates
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1", features = ["v4", "serde"] }
thiserror = "1"
async-trait = "0.1"
```

### When to Use Single-Crate Instead

For smaller projects or prototypes, a single crate with module-based separation is simpler:

```
src/
├── domain/
├── application/
├── infrastructure/
└── lib.rs
```

The tradeoff: you rely on code review discipline rather than the compiler to prevent cross-layer imports.

---

## Rust Type System for Clean Architecture

### Traits for Abstractions

Traits define contracts that infrastructure implements:

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

**Why `Send + Sync`?** Required for trait objects to be used across async contexts and threads, which is essential for web frameworks like Axum and Tauri.

### Ownership and Borrowing Across Layers

Rust's ownership model naturally enforces Clean Architecture boundaries:

```rust
// Domain entity with controlled access
pub struct Task {
    id: TaskId,           // Private - immutable after creation
    description: String,  // Private - controlled mutation
    completed: bool,
    created_at: DateTime<Utc>,
    completed_at: Option<DateTime<Utc>>,
}

impl Task {
    // Constructor enforces invariants
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

    // Read-only access via references
    pub fn id(&self) -> &TaskId {
        &self.id
    }

    pub fn description(&self) -> &str {
        &self.description
    }

    pub fn is_completed(&self) -> bool {
        self.completed
    }

    // Behavior methods modify state
    pub fn complete(&mut self) -> Result<(), DomainError> {
        if self.completed {
            return Err(DomainError::AlreadyCompleted);
        }
        self.completed = true;
        self.completed_at = Some(Utc::now());
        Ok(())
    }
}
```

### Result Pattern with thiserror

Use `thiserror` for library/domain errors and `anyhow` for application-level errors:

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

    #[error("Invalid task ID format")]
    InvalidTaskId,
}

#[derive(Error, Debug)]
pub enum RepositoryError {
    #[error("Database connection failed: {0}")]
    ConnectionFailed(String),

    #[error("Record not found")]
    NotFound,

    #[error("Duplicate key: {0}")]
    DuplicateKey(String),

    #[error("Query failed: {0}")]
    QueryFailed(#[from] sqlx::Error),
}
```

### Newtype Pattern for Type-Safe IDs

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

    pub fn as_uuid(&self) -> &Uuid {
        &self.0
    }
}

impl Default for TaskId {
    fn default() -> Self {
        Self::new()
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

**Why newtypes?** They prevent accidentally passing a `UserId` where a `TaskId` is expected - the compiler catches these errors.

---

## Domain Layer Patterns

The domain layer contains pure business logic with zero external dependencies.

### Entities

Entities have identity and lifecycle:

```rust
// domain/src/entities/task.rs
use chrono::{DateTime, Utc};
use crate::{
    errors::DomainError,
    value_objects::TaskId,
};

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

    /// Reconstitute from persistence - bypasses validation.
    ///
    /// Use this when rebuilding entities from trusted storage (database, cache).
    /// Unlike `new()`, this doesn't validate because:
    /// 1. Data was already validated when first created via `new()`
    /// 2. Storage is trusted - if your DB is corrupted, you have bigger problems
    /// 3. Allows loading historical data that might not pass current validation rules
    ///
    /// **Never use reconstitute with untrusted input** - always go through `new()`.
    pub fn reconstitute(
        id: TaskId,
        description: String,
        completed: bool,
        created_at: DateTime<Utc>,
        completed_at: Option<DateTime<Utc>>,
    ) -> Self {
        Self {
            id,
            description,
            completed,
            created_at,
            completed_at,
        }
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

    pub fn update_description(&mut self, description: String) -> Result<(), DomainError> {
        Self::validate_description(&description)?;
        self.description = description;
        Ok(())
    }

    // Validation
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

impl Eq for Task {}
```

### Value Objects

Value objects are immutable and compared by all their attributes:

```rust
// domain/src/value_objects/priority.rs
use serde::{Deserialize, Serialize};
use crate::errors::DomainError;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Serialize, Deserialize)]
pub struct Priority(u8);

impl Priority {
    pub const MIN: u8 = 1;
    pub const MAX: u8 = 5;

    pub fn new(value: u8) -> Result<Self, DomainError> {
        if value < Self::MIN || value > Self::MAX {
            return Err(DomainError::InvalidPriority {
                value,
                min: Self::MIN,
                max: Self::MAX
            });
        }
        Ok(Self(value))
    }

    pub fn value(&self) -> u8 {
        self.0
    }

    pub fn is_high(&self) -> bool {
        self.0 >= 4
    }

    pub fn is_low(&self) -> bool {
        self.0 <= 2
    }
}

impl Default for Priority {
    fn default() -> Self {
        Self(3)  // Medium priority
    }
}

impl TryFrom<u8> for Priority {
    type Error = DomainError;

    fn try_from(value: u8) -> Result<Self, Self::Error> {
        Self::new(value)
    }
}
```

### Domain Services

Pure functions with no state, operating on domain concepts:

```rust
// domain/src/services/task_scheduler.rs
use crate::entities::Task;
use chrono::{DateTime, Utc};

/// Domain service for task scheduling logic
pub struct TaskScheduler;

impl TaskScheduler {
    /// Get tasks that are overdue
    pub fn get_overdue_tasks(tasks: &[Task], now: DateTime<Utc>) -> Vec<&Task> {
        tasks
            .iter()
            .filter(|task| {
                if task.is_completed() {
                    return false;
                }
                task.due_date()
                    .map(|due| due < now)
                    .unwrap_or(false)
            })
            .collect()
    }

    /// Calculate task completion rate
    pub fn completion_rate(tasks: &[Task]) -> f64 {
        if tasks.is_empty() {
            return 0.0;
        }
        let completed = tasks.iter().filter(|t| t.is_completed()).count();
        completed as f64 / tasks.len() as f64
    }
}
```

### Domain Events

Domain events capture something meaningful that happened in the domain. Return events from entity methods rather than publishing them directly:

```rust
// domain/src/events.rs
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use crate::value_objects::TaskId;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DomainEvent {
    TaskCreated(TaskCreatedEvent),
    TaskCompleted(TaskCompletedEvent),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskCreatedEvent {
    pub task_id: TaskId,
    pub description: String,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TaskCompletedEvent {
    pub task_id: TaskId,
    pub completed_at: DateTime<Utc>,
}
```

Entity methods return events alongside state changes:

```rust
impl Task {
    pub fn complete(&mut self) -> Result<TaskCompletedEvent, DomainError> {
        if self.completed {
            return Err(DomainError::AlreadyCompleted);
        }

        let completed_at = Utc::now();
        self.completed = true;
        self.completed_at = Some(completed_at);

        Ok(TaskCompletedEvent {
            task_id: self.id.clone(),
            completed_at,
        })
    }
}
```

Use cases collect and handle events:

```rust
impl<R: TaskRepository> CompleteTaskUseCase<R> {
    pub async fn execute(&self, request: CompleteTaskRequest) -> Result<CompleteTaskResponse, Error> {
        let mut task = self.repository.find_by_id(&request.task_id).await?
            .ok_or(Error::NotFound)?;

        // Domain method returns the event
        let event = task.complete()?;

        // Save task and event atomically
        self.repository.save_with_events(&task, &[DomainEvent::TaskCompleted(event.clone())]).await?;

        Ok(CompleteTaskResponse {
            completed_at: event.completed_at,
        })
    }
}
```

### Repository Traits

Defined in domain, implemented in infrastructure:

```rust
// domain/src/repositories/task_repository.rs
use async_trait::async_trait;
use crate::{
    entities::Task,
    value_objects::TaskId,
    errors::RepositoryError,
};

#[async_trait]
pub trait TaskRepository: Send + Sync {
    async fn save(&self, task: &Task) -> Result<(), RepositoryError>;
    async fn find_by_id(&self, id: &TaskId) -> Result<Option<Task>, RepositoryError>;
    async fn find_all(&self) -> Result<Vec<Task>, RepositoryError>;
    async fn find_pending(&self) -> Result<Vec<Task>, RepositoryError>;
    async fn find_completed(&self) -> Result<Vec<Task>, RepositoryError>;
    async fn delete(&self, id: &TaskId) -> Result<(), RepositoryError>;
    async fn exists(&self, id: &TaskId) -> Result<bool, RepositoryError>;
}
```

### Aggregate Roots

An aggregate is a cluster of domain objects treated as a single unit for data changes. The **aggregate root** is the only entry point for modifications, ensuring invariants are maintained.

```rust
// Order is the aggregate root - it owns OrderItems
pub struct Order {
    id: OrderId,
    customer_id: CustomerId,
    items: Vec<OrderItem>,  // Owned by Order
    status: OrderStatus,
    created_at: DateTime<Utc>,
}

// OrderItem can only be accessed through Order
pub struct OrderItem {
    product_id: ProductId,
    quantity: u32,
    unit_price: Money,
}

impl Order {
    const MAX_ITEMS: usize = 100;

    pub fn new(customer_id: CustomerId) -> Self {
        Self {
            id: OrderId::new(),
            customer_id,
            items: Vec::new(),
            status: OrderStatus::Draft,
            created_at: Utc::now(),
        }
    }

    /// Add item - aggregate root enforces invariants
    pub fn add_item(
        &mut self,
        product_id: ProductId,
        quantity: u32,
        unit_price: Money,
    ) -> Result<(), DomainError> {
        if self.status != OrderStatus::Draft {
            return Err(DomainError::OrderNotModifiable);
        }
        if self.items.len() >= Self::MAX_ITEMS {
            return Err(DomainError::TooManyItems);
        }
        if quantity == 0 {
            return Err(DomainError::InvalidQuantity);
        }

        self.items.push(OrderItem { product_id, quantity, unit_price });
        Ok(())
    }

    /// Read-only access to items - Rust enforces this naturally
    pub fn items(&self) -> &[OrderItem] {
        &self.items
    }

    pub fn total(&self) -> Money {
        self.items.iter()
            .map(|item| item.unit_price * item.quantity)
            .sum()
    }
}
```

**Rust advantages for aggregates**:
- **Ownership**: `Vec<OrderItem>` inside `Order` naturally prevents external modification
- **Encapsulation**: Private fields with public methods enforce the aggregate boundary
- **No leaking**: Returning `&[OrderItem]` (immutable slice) prevents mutation

**Repository pattern with aggregates**: Load and save entire aggregates, not individual items:

```rust
#[async_trait]
pub trait OrderRepository: Send + Sync {
    async fn save(&self, order: &Order) -> Result<(), RepositoryError>;
    async fn find_by_id(&self, id: &OrderId) -> Result<Option<Order>, RepositoryError>;
    // No find_order_item() - items come with their order
}
```

### Domain Module Structure

```rust
// domain/src/lib.rs
pub mod entities;
pub mod value_objects;
pub mod errors;
pub mod repositories;
pub mod services;

// Re-exports for convenience
pub use entities::Task;
pub use value_objects::{TaskId, Priority};
pub use errors::{DomainError, RepositoryError};
pub use repositories::TaskRepository;
```

---

## Application Layer Patterns

The application layer orchestrates use cases using domain objects.

### Service Abstractions in Application Layer

Service abstractions (repository traits, gateway interfaces) belong in the **application layer**, colocated with use cases - not in the domain layer. This is a departure from some Clean Architecture interpretations but offers practical benefits:

**Why Application Layer?**

1. **Closer to consumers**: Use cases consume these abstractions; changes to use case needs are reflected locally
2. **Clearer ownership**: Each bounded context owns its service definitions
3. **Reduces coupling**: Domain layer stays pure with zero dependencies
4. **Avoids "ports" confusion**: The term "services" is more intuitive than "ports"

```rust
// crates/project-application/src/workspace/services.rs
use async_trait::async_trait;
use project_domain::Workspace;
use std::path::Path;
use thiserror::Error;

#[derive(Error, Debug)]
pub enum WorkspaceError {
    #[error("Workspace not found at path: {0}")]
    NotFound(String),

    #[error("IO error: {0}")]
    IoError(#[from] std::io::Error),

    #[error("Workspace already exists at path: {0}")]
    AlreadyExists(String),
}

/// Repository abstraction defined in application layer, implemented in infrastructure
#[async_trait]
pub trait WorkspaceRepository: Send + Sync {
    async fn save(&self, workspace: &Workspace) -> Result<(), WorkspaceError>;
    async fn find_by_path(&self, path: &Path) -> Result<Option<Workspace>, WorkspaceError>;
    async fn exists(&self, path: &Path) -> Result<bool, WorkspaceError>;
}
```

### File-Per-Use-Case Pattern

Each bounded context gets its own directory with:
- `mod.rs` for re-exports
- `services.rs` for repository/gateway traits and errors
- One file per use case

```
crates/project-application/src/
├── lib.rs                        # Re-exports all contexts
├── workspace/                    # Bounded context
│   ├── mod.rs                    # Re-exports
│   ├── services.rs               # WorkspaceRepository trait + errors
│   ├── initialize.rs             # InitializeWorkspaceUseCase
│   ├── create.rs                 # CreateWorkspaceUseCase
│   └── get.rs                    # GetWorkspaceUseCase
├── page/
│   ├── mod.rs
│   ├── services.rs               # PageRepository trait + errors
│   ├── create.rs
│   ├── update.rs
│   └── delete.rs
└── block/
    └── ...
```

**Module re-exports:**

```rust
// crates/project-application/src/workspace/mod.rs
mod services;
mod initialize;
mod create;
mod get;

pub use services::{WorkspaceRepository, WorkspaceError};
pub use initialize::{InitializeWorkspaceUseCase, InitializeWorkspaceRequest, InitializeWorkspaceResponse};
pub use create::{CreateWorkspaceUseCase, CreateWorkspaceRequest, CreateWorkspaceResponse};
pub use get::{GetWorkspaceUseCase, GetWorkspaceRequest, GetWorkspaceResponse};
```

```rust
// crates/project-application/src/lib.rs
pub mod workspace;
pub mod page;
pub mod block;

// Convenience re-exports
pub use workspace::*;
pub use page::*;
pub use block::*;
```

### Use Case Structure

Each use case file contains:
- Request struct (input DTO)
- Response struct (output DTO)
- Use case struct with repository dependency
- Execute method

```rust
// crates/project-application/src/workspace/initialize.rs
use super::services::{WorkspaceRepository, WorkspaceError};
use project_domain::Workspace;
use std::path::PathBuf;

pub struct InitializeWorkspaceRequest {
    pub path: PathBuf,
    pub name: String,
}

pub struct InitializeWorkspaceResponse {
    pub workspace_id: String,
    pub path: PathBuf,
}

pub struct InitializeWorkspaceUseCase<R: WorkspaceRepository> {
    repository: R,
}

impl<R: WorkspaceRepository> InitializeWorkspaceUseCase<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub async fn execute(
        &self,
        request: InitializeWorkspaceRequest,
    ) -> Result<InitializeWorkspaceResponse, WorkspaceError> {
        // Check if workspace already exists
        if self.repository.exists(&request.path).await? {
            return Err(WorkspaceError::AlreadyExists(
                request.path.display().to_string(),
            ));
        }

        // Create domain entity
        let workspace = Workspace::new(request.name, request.path.clone());

        // Persist via repository
        self.repository.save(&workspace).await?;

        Ok(InitializeWorkspaceResponse {
            workspace_id: workspace.id().to_string(),
            path: request.path,
        })
    }
}
```

### Use Cases with Generics

```rust
// application/src/use_cases/create_task.rs
use async_trait::async_trait;
use domain::{Task, TaskRepository, DomainError, RepositoryError};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

// Request DTO
#[derive(Debug, Deserialize)]
pub struct CreateTaskRequest {
    pub description: String,
}

// Response DTO
#[derive(Debug, Serialize)]
pub struct CreateTaskResponse {
    pub task_id: String,
    pub description: String,
    pub created_at: DateTime<Utc>,
}

// Use Case Error
#[derive(Debug, thiserror::Error)]
pub enum CreateTaskError {
    #[error("Validation failed: {0}")]
    ValidationFailed(#[from] DomainError),

    #[error("Failed to save task: {0}")]
    PersistenceFailed(#[from] RepositoryError),
}

// Use Case
pub struct CreateTaskUseCase<R: TaskRepository> {
    repository: R,
}

impl<R: TaskRepository> CreateTaskUseCase<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub async fn execute(
        &self,
        request: CreateTaskRequest,
    ) -> Result<CreateTaskResponse, CreateTaskError> {
        // Create domain entity (validates business rules)
        let task = Task::new(request.description)?;

        // Persist via repository
        self.repository.save(&task).await?;

        // Return response DTO
        Ok(CreateTaskResponse {
            task_id: task.id().to_string(),
            description: task.description().to_string(),
            created_at: task.created_at(),
        })
    }
}
```

### Alternative: Trait-based Use Cases

For more flexibility with dependency injection:

```rust
// application/src/use_cases/traits.rs
use async_trait::async_trait;

#[async_trait]
pub trait UseCase<Request, Response, Error> {
    async fn execute(&self, request: Request) -> Result<Response, Error>;
}

// Implementation
#[async_trait]
impl<R: TaskRepository> UseCase<CreateTaskRequest, CreateTaskResponse, CreateTaskError>
    for CreateTaskUseCase<R>
{
    async fn execute(&self, request: CreateTaskRequest) -> Result<CreateTaskResponse, CreateTaskError> {
        // Implementation here
    }
}
```

> ⚠️ **Warning: Avoid Over-Abstraction**
>
> The generic `UseCase<Request, Response, Error>` trait above is shown for completeness but can lead to unnecessary complexity. **Prefer the concrete generic approach** shown in the examples below:
>
> ```rust
> // Preferred: Concrete struct with repository generic
> pub struct CreateTaskUseCase<R: TaskRepository> {
>     repository: R,
> }
>
> impl<R: TaskRepository> CreateTaskUseCase<R> {
>     pub async fn execute(&self, request: CreateTaskRequest) -> Result<CreateTaskResponse, CreateTaskError> {
>         // Direct implementation - no trait ceremony
>     }
> }
> ```
>
> The abstract trait is only valuable when you need to:
> - Execute use cases through a uniform interface (rare)
> - Build middleware that wraps arbitrary use cases (uncommon)

### Complete Task Use Case

```rust
// application/src/use_cases/complete_task.rs
use domain::{Task, TaskId, TaskRepository, DomainError, RepositoryError};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Deserialize)]
pub struct CompleteTaskRequest {
    pub task_id: String,
}

#[derive(Debug, Serialize)]
pub struct CompleteTaskResponse {
    pub success: bool,
    pub completed_at: Option<DateTime<Utc>>,
}

#[derive(Debug, thiserror::Error)]
pub enum CompleteTaskError {
    #[error("Invalid task ID: {0}")]
    InvalidTaskId(String),

    #[error("Task not found: {0}")]
    TaskNotFound(String),

    #[error("Domain error: {0}")]
    DomainError(#[from] DomainError),

    #[error("Repository error: {0}")]
    RepositoryError(#[from] RepositoryError),
}

pub struct CompleteTaskUseCase<R: TaskRepository> {
    repository: R,
}

impl<R: TaskRepository> CompleteTaskUseCase<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub async fn execute(
        &self,
        request: CompleteTaskRequest,
    ) -> Result<CompleteTaskResponse, CompleteTaskError> {
        // Parse task ID
        let task_id: TaskId = request.task_id
            .parse()
            .map_err(|_| CompleteTaskError::InvalidTaskId(request.task_id.clone()))?;

        // Find task
        let mut task = self.repository
            .find_by_id(&task_id)
            .await?
            .ok_or_else(|| CompleteTaskError::TaskNotFound(request.task_id))?;

        // Execute domain logic
        task.complete()?;

        // Persist changes
        self.repository.save(&task).await?;

        Ok(CompleteTaskResponse {
            success: true,
            completed_at: task.completed_at(),
        })
    }
}
```

### List Tasks Use Case

```rust
// application/src/use_cases/list_tasks.rs
use domain::{Task, TaskRepository, RepositoryError};
use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};

#[derive(Debug, Default, Deserialize)]
pub struct ListTasksRequest {
    pub status: Option<TaskStatus>,
}

#[derive(Debug, Deserialize, Clone, Copy)]
#[serde(rename_all = "lowercase")]
pub enum TaskStatus {
    All,
    Pending,
    Completed,
}

#[derive(Debug, Serialize)]
pub struct TaskView {
    pub id: String,
    pub description: String,
    pub completed: bool,
    pub created_at: DateTime<Utc>,
    pub completed_at: Option<DateTime<Utc>>,
}

impl From<&Task> for TaskView {
    fn from(task: &Task) -> Self {
        Self {
            id: task.id().to_string(),
            description: task.description().to_string(),
            completed: task.is_completed(),
            created_at: task.created_at(),
            completed_at: task.completed_at(),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct ListTasksResponse {
    pub tasks: Vec<TaskView>,
    pub total: usize,
}

pub struct ListTasksUseCase<R: TaskRepository> {
    repository: R,
}

impl<R: TaskRepository> ListTasksUseCase<R> {
    pub fn new(repository: R) -> Self {
        Self { repository }
    }

    pub async fn execute(
        &self,
        request: ListTasksRequest,
    ) -> Result<ListTasksResponse, RepositoryError> {
        let tasks = match request.status.unwrap_or(TaskStatus::All) {
            TaskStatus::All => self.repository.find_all().await?,
            TaskStatus::Pending => self.repository.find_pending().await?,
            TaskStatus::Completed => self.repository.find_completed().await?,
        };

        let views: Vec<TaskView> = tasks.iter().map(TaskView::from).collect();
        let total = views.len();

        Ok(ListTasksResponse { tasks: views, total })
    }
}
```

### Transactions and Unit of Work

For operations requiring atomicity across multiple entities, encapsulate the transaction in the repository:

**Simple approach** - Transaction within repository method:

```rust
impl SqlxTaskRepository {
    /// Save task and its events atomically
    pub async fn save_with_events(
        &self,
        task: &Task,
        events: &[DomainEvent],
    ) -> Result<(), RepositoryError> {
        let mut tx = self.pool.begin().await?;

        // Save task
        sqlx::query("INSERT INTO tasks ... ON CONFLICT DO UPDATE ...")
            .bind(task.id().to_string())
            .bind(task.description())
            .execute(&mut *tx)
            .await?;

        // Save events
        for event in events {
            sqlx::query("INSERT INTO domain_events ...")
                .bind(serde_json::to_string(event)?)
                .execute(&mut *tx)
                .await?;
        }

        tx.commit().await?;
        Ok(())
    }
}
```

**Cross-aggregate transactions** - Use a Unit of Work when spanning multiple repositories:

```rust
// Define a Unit of Work trait
#[async_trait]
pub trait UnitOfWork: Send + Sync {
    type TaskRepo: TaskRepository;
    type OrderRepo: OrderRepository;

    fn task_repository(&self) -> &Self::TaskRepo;
    fn order_repository(&self) -> &Self::OrderRepo;

    async fn commit(self) -> Result<(), RepositoryError>;
    async fn rollback(self) -> Result<(), RepositoryError>;
}

// Use case with multiple repositories
pub struct TransferTaskUseCase<U: UnitOfWork> {
    unit_of_work_factory: Box<dyn Fn() -> U + Send + Sync>,
}

impl<U: UnitOfWork> TransferTaskUseCase<U> {
    pub async fn execute(&self, request: TransferRequest) -> Result<(), UseCaseError> {
        let uow = (self.unit_of_work_factory)();

        // Perform operations on both repositories
        let task = uow.task_repository().find_by_id(&request.task_id).await?;
        // ... modify task ...
        uow.task_repository().save(&task).await?;

        // ... update order ...
        uow.order_repository().save(&order).await?;

        // Commit atomically
        uow.commit().await?;
        Ok(())
    }
}
```

**Guidance**: Start with simple repository-level transactions. Only introduce Unit of Work when you genuinely need cross-aggregate atomicity - it adds significant complexity.

### Application Module Structure

```rust
// application/src/lib.rs
pub mod use_cases;

pub use use_cases::{
    create_task::{CreateTaskUseCase, CreateTaskRequest, CreateTaskResponse, CreateTaskError},
    complete_task::{CompleteTaskUseCase, CompleteTaskRequest, CompleteTaskResponse, CompleteTaskError},
    list_tasks::{ListTasksUseCase, ListTasksRequest, ListTasksResponse, TaskView, TaskStatus},
};
```

---

## Infrastructure Layer Patterns

The infrastructure layer provides concrete implementations for domain abstractions.

### SQLx Repository Implementation

```rust
// infrastructure/src/repositories/sqlx_task_repository.rs
use async_trait::async_trait;
use sqlx::{Pool, Sqlite, FromRow};
use chrono::{DateTime, Utc};
use domain::{Task, TaskId, TaskRepository, RepositoryError};
use uuid::Uuid;

// Database model (separate from domain entity)
#[derive(Debug, FromRow)]
struct TaskRow {
    id: String,
    description: String,
    completed: bool,
    created_at: DateTime<Utc>,
    completed_at: Option<DateTime<Utc>>,
}

impl TaskRow {
    fn to_domain(&self) -> Task {
        let id = TaskId::from_uuid(
            Uuid::parse_str(&self.id).expect("Invalid UUID in database")
        );

        Task::reconstitute(
            id,
            self.description.clone(),
            self.completed,
            self.created_at,
            self.completed_at,
        )
    }
}

pub struct SqlxTaskRepository {
    pool: Pool<Sqlite>,
}

impl SqlxTaskRepository {
    pub fn new(pool: Pool<Sqlite>) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl TaskRepository for SqlxTaskRepository {
    async fn save(&self, task: &Task) -> Result<(), RepositoryError> {
        sqlx::query(
            r#"
            INSERT INTO tasks (id, description, completed, created_at, completed_at)
            VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(id) DO UPDATE SET
                description = excluded.description,
                completed = excluded.completed,
                completed_at = excluded.completed_at
            "#
        )
        .bind(task.id().to_string())
        .bind(task.description())
        .bind(task.is_completed())
        .bind(task.created_at())
        .bind(task.completed_at())
        .execute(&self.pool)
        .await?;

        Ok(())
    }

    async fn find_by_id(&self, id: &TaskId) -> Result<Option<Task>, RepositoryError> {
        let row: Option<TaskRow> = sqlx::query_as(
            "SELECT id, description, completed, created_at, completed_at FROM tasks WHERE id = ?"
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;

        Ok(row.map(|r| r.to_domain()))
    }

    async fn find_all(&self) -> Result<Vec<Task>, RepositoryError> {
        let rows: Vec<TaskRow> = sqlx::query_as(
            "SELECT id, description, completed, created_at, completed_at FROM tasks ORDER BY created_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.iter().map(|r| r.to_domain()).collect())
    }

    async fn find_pending(&self) -> Result<Vec<Task>, RepositoryError> {
        let rows: Vec<TaskRow> = sqlx::query_as(
            "SELECT id, description, completed, created_at, completed_at FROM tasks WHERE completed = false ORDER BY created_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.iter().map(|r| r.to_domain()).collect())
    }

    async fn find_completed(&self) -> Result<Vec<Task>, RepositoryError> {
        let rows: Vec<TaskRow> = sqlx::query_as(
            "SELECT id, description, completed, created_at, completed_at FROM tasks WHERE completed = true ORDER BY completed_at DESC"
        )
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.iter().map(|r| r.to_domain()).collect())
    }

    async fn delete(&self, id: &TaskId) -> Result<(), RepositoryError> {
        sqlx::query("DELETE FROM tasks WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }

    async fn exists(&self, id: &TaskId) -> Result<bool, RepositoryError> {
        let count: (i64,) = sqlx::query_as(
            "SELECT COUNT(*) FROM tasks WHERE id = ?"
        )
        .bind(id.to_string())
        .fetch_one(&self.pool)
        .await?;

        Ok(count.0 > 0)
    }
}
```

### In-Memory Repository (for testing)

```rust
// infrastructure/src/repositories/in_memory_task_repository.rs
use async_trait::async_trait;
use std::collections::HashMap;
use std::sync::RwLock;
use domain::{Task, TaskId, TaskRepository, RepositoryError};

pub struct InMemoryTaskRepository {
    tasks: RwLock<HashMap<String, Task>>,
}

impl InMemoryTaskRepository {
    pub fn new() -> Self {
        Self {
            tasks: RwLock::new(HashMap::new()),
        }
    }
}

impl Default for InMemoryTaskRepository {
    fn default() -> Self {
        Self::new()
    }
}

#[async_trait]
impl TaskRepository for InMemoryTaskRepository {
    async fn save(&self, task: &Task) -> Result<(), RepositoryError> {
        let mut tasks = self.tasks.write().unwrap();
        tasks.insert(task.id().to_string(), task.clone());
        Ok(())
    }

    async fn find_by_id(&self, id: &TaskId) -> Result<Option<Task>, RepositoryError> {
        let tasks = self.tasks.read().unwrap();
        Ok(tasks.get(&id.to_string()).cloned())
    }

    async fn find_all(&self) -> Result<Vec<Task>, RepositoryError> {
        let tasks = self.tasks.read().unwrap();
        Ok(tasks.values().cloned().collect())
    }

    async fn find_pending(&self) -> Result<Vec<Task>, RepositoryError> {
        let tasks = self.tasks.read().unwrap();
        Ok(tasks.values().filter(|t| !t.is_completed()).cloned().collect())
    }

    async fn find_completed(&self) -> Result<Vec<Task>, RepositoryError> {
        let tasks = self.tasks.read().unwrap();
        Ok(tasks.values().filter(|t| t.is_completed()).cloned().collect())
    }

    async fn delete(&self, id: &TaskId) -> Result<(), RepositoryError> {
        let mut tasks = self.tasks.write().unwrap();
        tasks.remove(&id.to_string());
        Ok(())
    }

    async fn exists(&self, id: &TaskId) -> Result<bool, RepositoryError> {
        let tasks = self.tasks.read().unwrap();
        Ok(tasks.contains_key(&id.to_string()))
    }
}
```

### Database Migrations

```rust
// infrastructure/src/database/migrations.rs
use sqlx::{Pool, Sqlite};

pub async fn run_migrations(pool: &Pool<Sqlite>) -> Result<(), sqlx::Error> {
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            description TEXT NOT NULL,
            completed BOOLEAN NOT NULL DEFAULT FALSE,
            created_at DATETIME NOT NULL,
            completed_at DATETIME
        )
        "#
    )
    .execute(pool)
    .await?;

    // Add indexes
    sqlx::query("CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed)")
        .execute(pool)
        .await?;

    sqlx::query("CREATE INDEX IF NOT EXISTS idx_tasks_created_at ON tasks(created_at)")
        .execute(pool)
        .await?;

    Ok(())
}
```

---

## Frameworks Layer Patterns

### Axum Integration (Web APIs)

```rust
// frameworks/axum-app/src/main.rs
use axum::{
    Router,
    routing::{get, post, put},
    extract::{State, Path},
    Json,
    http::StatusCode,
};
use std::sync::Arc;
use sqlx::sqlite::SqlitePoolOptions;
use tower_http::cors::CorsLayer;

mod handlers;
mod state;
mod error;

use state::AppState;
use handlers::tasks;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    // Initialize tracing
    tracing_subscriber::init();

    // Create database pool
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect("sqlite:tasks.db")
        .await?;

    // Run migrations
    infrastructure::database::run_migrations(&pool).await?;

    // Create application state
    let state = Arc::new(AppState::new(pool));

    // Build router
    let app = Router::new()
        .route("/api/v1/tasks", post(tasks::create_task))
        .route("/api/v1/tasks", get(tasks::list_tasks))
        .route("/api/v1/tasks/:id/complete", put(tasks::complete_task))
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Run server
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    tracing::info!("Server running on http://localhost:3000");
    axum::serve(listener, app).await?;

    Ok(())
}
```

```rust
// frameworks/axum-app/src/state.rs
use std::sync::Arc;
use sqlx::{Pool, Sqlite};
use infrastructure::SqlxTaskRepository;
use application::{CreateTaskUseCase, ListTasksUseCase, CompleteTaskUseCase};

pub struct AppState {
    pub create_task: CreateTaskUseCase<Arc<SqlxTaskRepository>>,
    pub list_tasks: ListTasksUseCase<Arc<SqlxTaskRepository>>,
    pub complete_task: CompleteTaskUseCase<Arc<SqlxTaskRepository>>,
}

impl AppState {
    pub fn new(pool: Pool<Sqlite>) -> Self {
        let repository = Arc::new(SqlxTaskRepository::new(pool));

        Self {
            create_task: CreateTaskUseCase::new(Arc::clone(&repository)),
            list_tasks: ListTasksUseCase::new(Arc::clone(&repository)),
            complete_task: CompleteTaskUseCase::new(Arc::clone(&repository)),
        }
    }
}
```

```rust
// frameworks/axum-app/src/handlers/tasks.rs
use axum::{
    extract::{State, Path},
    Json,
    http::StatusCode,
};
use std::sync::Arc;
use serde::Deserialize;
use crate::{state::AppState, error::ApiError};
use application::{
    CreateTaskRequest, CreateTaskResponse,
    ListTasksRequest, ListTasksResponse,
    CompleteTaskRequest, CompleteTaskResponse,
};

#[derive(Debug, Deserialize)]
pub struct CreateTaskDto {
    description: String,
}

pub async fn create_task(
    State(state): State<Arc<AppState>>,
    Json(dto): Json<CreateTaskDto>,
) -> Result<(StatusCode, Json<CreateTaskResponse>), ApiError> {
    let request = CreateTaskRequest {
        description: dto.description,
    };

    let response = state.create_task.execute(request).await?;

    Ok((StatusCode::CREATED, Json(response)))
}

pub async fn list_tasks(
    State(state): State<Arc<AppState>>,
) -> Result<Json<ListTasksResponse>, ApiError> {
    let request = ListTasksRequest::default();
    let response = state.list_tasks.execute(request).await?;

    Ok(Json(response))
}

pub async fn complete_task(
    State(state): State<Arc<AppState>>,
    Path(task_id): Path<String>,
) -> Result<Json<CompleteTaskResponse>, ApiError> {
    let request = CompleteTaskRequest { task_id };
    let response = state.complete_task.execute(request).await?;

    Ok(Json(response))
}
```

```rust
// frameworks/axum-app/src/error.rs
use axum::{
    response::{IntoResponse, Response},
    http::StatusCode,
    Json,
};
use serde_json::json;
use application::{CreateTaskError, CompleteTaskError};
use domain::RepositoryError;

pub struct ApiError {
    status: StatusCode,
    message: String,
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = Json(json!({
            "error": self.message
        }));
        (self.status, body).into_response()
    }
}

impl From<CreateTaskError> for ApiError {
    fn from(err: CreateTaskError) -> Self {
        match err {
            CreateTaskError::ValidationFailed(e) => Self {
                status: StatusCode::BAD_REQUEST,
                message: e.to_string(),
            },
            CreateTaskError::PersistenceFailed(e) => Self {
                status: StatusCode::INTERNAL_SERVER_ERROR,
                message: e.to_string(),
            },
        }
    }
}

impl From<CompleteTaskError> for ApiError {
    fn from(err: CompleteTaskError) -> Self {
        match err {
            CompleteTaskError::InvalidTaskId(_) => Self {
                status: StatusCode::BAD_REQUEST,
                message: err.to_string(),
            },
            CompleteTaskError::TaskNotFound(_) => Self {
                status: StatusCode::NOT_FOUND,
                message: err.to_string(),
            },
            CompleteTaskError::DomainError(e) => Self {
                status: StatusCode::CONFLICT,
                message: e.to_string(),
            },
            CompleteTaskError::RepositoryError(_) => Self {
                status: StatusCode::INTERNAL_SERVER_ERROR,
                message: "Internal server error".to_string(),
            },
        }
    }
}

impl From<RepositoryError> for ApiError {
    fn from(err: RepositoryError) -> Self {
        Self {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: err.to_string(),
        }
    }
}
```

---

## Tauri Integration (Desktop Apps)

Tauri is a framework for building desktop applications with a Rust backend and web frontend. It fits perfectly with Clean Architecture.

### Cargo Workspace Structure for Tauri

```
task-manager/
├── Cargo.toml                    # Workspace manifest
├── crates/
│   ├── domain/                   # Pure domain logic
│   │   ├── Cargo.toml
│   │   └── src/lib.rs
│   ├── application/              # Use cases
│   │   ├── Cargo.toml           # depends on: domain
│   │   └── src/lib.rs
│   ├── infrastructure/           # Repository implementations
│   │   ├── Cargo.toml           # depends on: domain, sqlx
│   │   └── src/lib.rs
│   └── tauri-app/               # Tauri desktop app
│       ├── Cargo.toml           # depends on: application, infrastructure, tauri
│       ├── tauri.conf.json
│       ├── src/
│       │   ├── main.rs
│       │   ├── commands.rs      # Thin invoke handlers
│       │   └── state.rs
│       └── icons/
└── frontend/                     # TypeScript/React UI
    ├── package.json
    ├── src/
    │   ├── App.tsx
    │   └── api/tasks.ts         # invoke() wrappers
    └── index.html
```

### Workspace Cargo.toml

```toml
# Cargo.toml (workspace root)
[workspace]
resolver = "2"
members = [
    "crates/domain",
    "crates/application",
    "crates/infrastructure",
    "crates/tauri-app",
]

[workspace.package]
version = "0.1.0"
edition = "2021"
authors = ["Your Name"]

[workspace.dependencies]
# Shared dependencies with consistent versions
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
chrono = { version = "0.4", features = ["serde"] }
uuid = { version = "1", features = ["v4", "serde"] }
thiserror = "1"
async-trait = "0.1"
sqlx = { version = "0.7", features = ["runtime-tokio", "sqlite"] }
tauri = { version = "2", features = ["test"] }
```

**Using workspace dependencies in crates:**

```toml
# crates/domain/Cargo.toml
[package]
name = "domain"
version.workspace = true       # Inherit from [workspace.package]
edition.workspace = true

[dependencies]
chrono = { workspace = true }  # Uses version from [workspace.dependencies]
uuid = { workspace = true }
thiserror = { workspace = true }
```

This pattern ensures all crates use the same dependency versions, avoiding conflicts and simplifying updates.

### Tauri Commands as Thin Controllers

```rust
// crates/tauri-app/src/commands.rs
use tauri::State;
use serde::{Deserialize, Serialize};
use crate::state::AppState;
use application::{
    CreateTaskRequest, CreateTaskResponse, CreateTaskError,
    CompleteTaskRequest, CompleteTaskResponse, CompleteTaskError,
    ListTasksRequest, ListTasksResponse,
};

// Command response wrapper for frontend
#[derive(Debug, Serialize)]
#[serde(tag = "status", rename_all = "lowercase")]
pub enum CommandResult<T> {
    Success { data: T },
    Error { message: String, code: String },
}

impl<T: Serialize> CommandResult<T> {
    fn success(data: T) -> Self {
        Self::Success { data }
    }

    fn error(message: impl ToString, code: impl ToString) -> Self {
        Self::Error {
            message: message.to_string(),
            code: code.to_string(),
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct CreateTaskInput {
    description: String,
}

#[tauri::command]
pub async fn create_task(
    input: CreateTaskInput,
    state: State<'_, AppState>,
) -> CommandResult<CreateTaskResponse> {
    let request = CreateTaskRequest {
        description: input.description,
    };

    match state.create_task.execute(request).await {
        Ok(response) => CommandResult::success(response),
        Err(CreateTaskError::ValidationFailed(e)) => {
            CommandResult::error(e, "VALIDATION_ERROR")
        }
        Err(CreateTaskError::PersistenceFailed(e)) => {
            CommandResult::error(e, "PERSISTENCE_ERROR")
        }
    }
}

#[tauri::command]
pub async fn list_tasks(
    state: State<'_, AppState>,
) -> CommandResult<ListTasksResponse> {
    let request = ListTasksRequest::default();

    match state.list_tasks.execute(request).await {
        Ok(response) => CommandResult::success(response),
        Err(e) => CommandResult::error(e, "REPOSITORY_ERROR"),
    }
}

#[tauri::command]
pub async fn complete_task(
    task_id: String,
    state: State<'_, AppState>,
) -> CommandResult<CompleteTaskResponse> {
    let request = CompleteTaskRequest { task_id: task_id.clone() };

    match state.complete_task.execute(request).await {
        Ok(response) => CommandResult::success(response),
        Err(CompleteTaskError::TaskNotFound(_)) => {
            CommandResult::error(format!("Task {} not found", task_id), "NOT_FOUND")
        }
        Err(CompleteTaskError::DomainError(e)) => {
            CommandResult::error(e, "DOMAIN_ERROR")
        }
        Err(e) => CommandResult::error(e, "INTERNAL_ERROR"),
    }
}
```

### Tauri State Management

```rust
// crates/tauri-app/src/state.rs
use std::sync::Arc;
use sqlx::{Pool, Sqlite};
use infrastructure::SqlxTaskRepository;
use application::{CreateTaskUseCase, ListTasksUseCase, CompleteTaskUseCase};

pub struct AppState {
    pub create_task: CreateTaskUseCase<Arc<SqlxTaskRepository>>,
    pub list_tasks: ListTasksUseCase<Arc<SqlxTaskRepository>>,
    pub complete_task: CompleteTaskUseCase<Arc<SqlxTaskRepository>>,
}

impl AppState {
    pub async fn new(app: &tauri::AppHandle) -> anyhow::Result<Self> {
        // Get app data directory for database (Tauri v2 API)
        let app_dir = app.path().app_data_dir()
            .expect("Failed to get app data dir");

        std::fs::create_dir_all(&app_dir)?;
        let db_path = app_dir.join("tasks.db");
        let db_url = format!("sqlite:{}?mode=rwc", db_path.display());

        // Create connection pool
        let pool = sqlx::sqlite::SqlitePoolOptions::new()
            .max_connections(5)
            .connect(&db_url)
            .await?;

        // Run migrations
        infrastructure::database::run_migrations(&pool).await?;

        // Create repository
        let repository = Arc::new(SqlxTaskRepository::new(pool));

        Ok(Self {
            create_task: CreateTaskUseCase::new(Arc::clone(&repository)),
            list_tasks: ListTasksUseCase::new(Arc::clone(&repository)),
            complete_task: CompleteTaskUseCase::new(Arc::clone(&repository)),
        })
    }
}
```

### Tauri Main Entry Point

```rust
// crates/tauri-app/src/main.rs
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod state;

use state::AppState;
use tokio::sync::OnceCell;

// Global state with guaranteed initialization
static APP_STATE: OnceCell<AppState> = OnceCell::const_new();

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            // Block on async initialization - guarantees state is ready before commands
            let handle = app.handle().clone();
            tauri::async_runtime::block_on(async move {
                let state = AppState::new(&handle).await
                    .expect("Failed to initialize app state");
                APP_STATE.set(state).expect("State already initialized");
            });
            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::create_task,
            commands::list_tasks,
            commands::complete_task,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}

// In commands, access state via the OnceCell:
// let state = APP_STATE.get().expect("State not initialized");
```

### Environment-Aware Path Configuration

Development and production environments need different paths to isolate data. Create a dedicated paths module:

```rust
// apps/desktop/src-tauri/src/paths.rs
use std::path::PathBuf;

pub struct AppPaths {
    pub workspaces: PathBuf,
    pub settings: PathBuf,
}

impl AppPaths {
    pub fn resolve() -> Self {
        if Self::is_dev_mode() {
            Self::dev_paths()
        } else {
            Self::prod_paths()
        }
    }

    fn is_dev_mode() -> bool {
        // Environment variable takes precedence
        if let Ok(val) = std::env::var("APP_DEV") {
            return !matches!(val.as_str(), "0" | "false" | "no");
        }
        // Fall back to debug assertions
        cfg!(debug_assertions)
    }

    fn dev_paths() -> Self {
        let project_root = std::env::current_dir().expect("No current dir");
        Self {
            workspaces: project_root.join(".data/workspaces"),
            settings: project_root.join(".data/settings"),
        }
    }

    fn prod_paths() -> Self {
        let home = dirs::home_dir().expect("No home directory");
        Self {
            workspaces: home.join("AppName/Workspaces"),
            settings: dirs::config_dir()
                .expect("No config dir")
                .join("AppName"),
        }
    }
}
```

**Path isolation strategy:**

| Environment | Workspaces | Settings |
|-------------|------------|----------|
| Development | `{project}/.data/workspaces/` | `{project}/.data/settings/` |
| Production | `~/AppName/Workspaces/` | `~/Library/Application Support/AppName/` |

**Usage in state initialization:**

```rust
// In AppState::new()
let paths = AppPaths::resolve();
std::fs::create_dir_all(&paths.workspaces)?;
std::fs::create_dir_all(&paths.settings)?;

let repository = Arc::new(FileSystemWorkspaceRepository::new(paths.workspaces));
```

**Benefits:**
- Development data is git-ignored in `.data/`
- Production data uses platform-standard locations
- `APP_DEV=0 cargo tauri dev` forces production paths for testing
- Clear separation prevents accidental data corruption

### TypeScript Frontend Integration

```typescript
// frontend/src/api/tasks.ts
import { invoke } from '@tauri-apps/api/core';

// Type definitions matching Rust structs
interface TaskView {
  id: string;
  description: string;
  completed: boolean;
  created_at: string;
  completed_at: string | null;
}

interface CreateTaskResponse {
  task_id: string;
  description: string;
  created_at: string;
}

interface ListTasksResponse {
  tasks: TaskView[];
  total: number;
}

interface CompleteTaskResponse {
  success: boolean;
  completed_at: string | null;
}

// Command result wrapper (matches Rust CommandResult)
type CommandResult<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; message: string; code: string };

// API functions with type-safe invoke
export async function createTask(description: string): Promise<CreateTaskResponse> {
  const result = await invoke<CommandResult<CreateTaskResponse>>('create_task', {
    input: { description },
  });

  if (result.status === 'error') {
    throw new Error(`${result.code}: ${result.message}`);
  }

  return result.data;
}

export async function listTasks(): Promise<ListTasksResponse> {
  const result = await invoke<CommandResult<ListTasksResponse>>('list_tasks');

  if (result.status === 'error') {
    throw new Error(`${result.code}: ${result.message}`);
  }

  return result.data;
}

export async function completeTask(taskId: string): Promise<CompleteTaskResponse> {
  const result = await invoke<CommandResult<CompleteTaskResponse>>('complete_task', {
    taskId,
  });

  if (result.status === 'error') {
    throw new Error(`${result.code}: ${result.message}`);
  }

  return result.data;
}
```

```tsx
// frontend/src/App.tsx
import { useState, useEffect } from 'react';
import { listTasks, createTask, completeTask, TaskView } from './api/tasks';

function App() {
  const [tasks, setTasks] = useState<TaskView[]>([]);
  const [description, setDescription] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadTasks();
  }, []);

  async function loadTasks() {
    try {
      const response = await listTasks();
      setTasks(response.tasks);
      setError(null);
    } catch (e) {
      setError(`Failed to load tasks: ${e}`);
    }
  }

  async function handleCreateTask(e: React.FormEvent) {
    e.preventDefault();
    if (!description.trim()) return;

    try {
      await createTask(description);
      setDescription('');
      await loadTasks();
    } catch (e) {
      setError(`Failed to create task: ${e}`);
    }
  }

  async function handleCompleteTask(taskId: string) {
    try {
      await completeTask(taskId);
      await loadTasks();
    } catch (e) {
      setError(`Failed to complete task: ${e}`);
    }
  }

  return (
    <div className="container">
      <h1>Task Manager</h1>

      {error && <div className="error">{error}</div>}

      <form onSubmit={handleCreateTask}>
        <input
          type="text"
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Enter task description"
        />
        <button type="submit">Add Task</button>
      </form>

      <ul className="task-list">
        {tasks.map((task) => (
          <li key={task.id} className={task.completed ? 'completed' : ''}>
            <span>{task.description}</span>
            {!task.completed && (
              <button onClick={() => handleCompleteTask(task.id)}>
                Complete
              </button>
            )}
          </li>
        ))}
      </ul>
    </div>
  );
}

export default App;
```

---

## Testing Patterns

### Unit Testing Domain Logic

```rust
// domain/src/entities/task_tests.rs
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_valid_task() {
        let task = Task::new("Learn Rust".to_string()).unwrap();

        assert_eq!(task.description(), "Learn Rust");
        assert!(!task.is_completed());
        assert!(task.completed_at().is_none());
    }

    #[test]
    fn reject_empty_description() {
        let result = Task::new("".to_string());

        assert!(matches!(result, Err(DomainError::EmptyDescription)));
    }

    #[test]
    fn reject_whitespace_only_description() {
        let result = Task::new("   ".to_string());

        assert!(matches!(result, Err(DomainError::EmptyDescription)));
    }

    #[test]
    fn reject_too_long_description() {
        let long_desc = "a".repeat(501);
        let result = Task::new(long_desc);

        assert!(matches!(result, Err(DomainError::DescriptionTooLong { max: 500 })));
    }

    #[test]
    fn complete_task() {
        let mut task = Task::new("Test task".to_string()).unwrap();

        task.complete().unwrap();

        assert!(task.is_completed());
        assert!(task.completed_at().is_some());
    }

    #[test]
    fn cannot_complete_twice() {
        let mut task = Task::new("Test task".to_string()).unwrap();
        task.complete().unwrap();

        let result = task.complete();

        assert!(matches!(result, Err(DomainError::AlreadyCompleted)));
    }

    #[test]
    fn entity_equality_by_id() {
        let task1 = Task::new("Task A".to_string()).unwrap();
        let task2 = Task::new("Task B".to_string()).unwrap();

        // Different tasks are not equal
        assert_ne!(task1, task2);

        // Reconstituted task with same ID is equal
        let task1_clone = Task::reconstitute(
            task1.id().clone(),
            "Different description".to_string(),
            false,
            task1.created_at(),
            None,
        );

        assert_eq!(task1, task1_clone);
    }
}
```

### Mocking with mockall

```rust
// application/src/use_cases/create_task_tests.rs
#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;
    use domain::MockTaskRepository;

    #[tokio::test]
    async fn create_task_successfully() {
        let mut mock_repo = MockTaskRepository::new();
        mock_repo
            .expect_save()
            .times(1)
            .returning(|_| Ok(()));

        let use_case = CreateTaskUseCase::new(mock_repo);
        let request = CreateTaskRequest {
            description: "Test task".to_string(),
        };

        let result = use_case.execute(request).await;

        assert!(result.is_ok());
        let response = result.unwrap();
        assert_eq!(response.description, "Test task");
    }

    #[tokio::test]
    async fn reject_invalid_description() {
        let mock_repo = MockTaskRepository::new();
        // No expectations - save should not be called

        let use_case = CreateTaskUseCase::new(mock_repo);
        let request = CreateTaskRequest {
            description: "".to_string(),
        };

        let result = use_case.execute(request).await;

        assert!(matches!(result, Err(CreateTaskError::ValidationFailed(_))));
    }

    #[tokio::test]
    async fn handle_repository_error() {
        let mut mock_repo = MockTaskRepository::new();
        mock_repo
            .expect_save()
            .times(1)
            .returning(|_| Err(RepositoryError::ConnectionFailed("DB down".to_string())));

        let use_case = CreateTaskUseCase::new(mock_repo);
        let request = CreateTaskRequest {
            description: "Test task".to_string(),
        };

        let result = use_case.execute(request).await;

        assert!(matches!(result, Err(CreateTaskError::PersistenceFailed(_))));
    }
}
```

### Property-Based Testing with proptest

```rust
// domain/src/value_objects/priority_tests.rs
#[cfg(test)]
mod tests {
    use super::*;
    use proptest::prelude::*;

    proptest! {
        #[test]
        fn valid_priorities_in_range(value in 1u8..=5) {
            let priority = Priority::new(value);
            prop_assert!(priority.is_ok());
            prop_assert_eq!(priority.unwrap().value(), value);
        }

        #[test]
        fn invalid_priorities_rejected(value in 6u8..=255) {
            let priority = Priority::new(value);
            prop_assert!(priority.is_err());
        }

        #[test]
        fn zero_priority_rejected(value in 0u8..1) {
            let priority = Priority::new(value);
            prop_assert!(priority.is_err());
        }
    }

    proptest! {
        #[test]
        fn priority_ordering_consistent(a in 1u8..=5, b in 1u8..=5) {
            let pa = Priority::new(a).unwrap();
            let pb = Priority::new(b).unwrap();

            prop_assert_eq!(pa < pb, a < b);
            prop_assert_eq!(pa > pb, a > b);
            prop_assert_eq!(pa == pb, a == b);
        }
    }
}
```

### Integration Testing with Test Containers

```rust
// infrastructure/tests/repository_integration_tests.rs
use sqlx::sqlite::SqlitePoolOptions;
use infrastructure::SqlxTaskRepository;
use domain::{Task, TaskRepository};

async fn create_test_pool() -> sqlx::Pool<sqlx::Sqlite> {
    let pool = SqlitePoolOptions::new()
        .max_connections(1)
        .connect(":memory:")
        .await
        .expect("Failed to create test database");

    infrastructure::database::run_migrations(&pool)
        .await
        .expect("Failed to run migrations");

    pool
}

#[tokio::test]
async fn save_and_retrieve_task() {
    let pool = create_test_pool().await;
    let repo = SqlxTaskRepository::new(pool);

    let task = Task::new("Integration test task".to_string()).unwrap();
    let task_id = task.id().clone();

    repo.save(&task).await.unwrap();

    let found = repo.find_by_id(&task_id).await.unwrap();
    assert!(found.is_some());
    assert_eq!(found.unwrap().description(), "Integration test task");
}

#[tokio::test]
async fn update_task() {
    let pool = create_test_pool().await;
    let repo = SqlxTaskRepository::new(pool);

    let mut task = Task::new("Update test".to_string()).unwrap();
    let task_id = task.id().clone();
    repo.save(&task).await.unwrap();

    task.complete().unwrap();
    repo.save(&task).await.unwrap();

    let found = repo.find_by_id(&task_id).await.unwrap().unwrap();
    assert!(found.is_completed());
}

#[tokio::test]
async fn find_pending_and_completed() {
    let pool = create_test_pool().await;
    let repo = SqlxTaskRepository::new(pool);

    let task1 = Task::new("Pending task".to_string()).unwrap();
    let mut task2 = Task::new("Completed task".to_string()).unwrap();
    task2.complete().unwrap();

    repo.save(&task1).await.unwrap();
    repo.save(&task2).await.unwrap();

    let pending = repo.find_pending().await.unwrap();
    let completed = repo.find_completed().await.unwrap();

    assert_eq!(pending.len(), 1);
    assert_eq!(completed.len(), 1);
    assert_eq!(pending[0].description(), "Pending task");
    assert_eq!(completed[0].description(), "Completed task");
}
```

### Contract Testing for Repositories

Contract tests ensure your mock and real implementations behave identically. Define shared test functions that run against any implementation:

```rust
// tests/repository_contract.rs
use domain::{Task, TaskId, TaskRepository};

/// Contract tests that any TaskRepository implementation must pass
pub mod task_repository_contract {
    use super::*;

    pub async fn test_save_and_find_by_id<R: TaskRepository>(repo: &R) {
        let task = Task::new("Contract test".to_string()).unwrap();
        let id = task.id().clone();

        repo.save(&task).await.unwrap();

        let found = repo.find_by_id(&id).await.unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().description(), "Contract test");
    }

    pub async fn test_find_missing_returns_none<R: TaskRepository>(repo: &R) {
        let missing_id = TaskId::new();
        let found = repo.find_by_id(&missing_id).await.unwrap();
        assert!(found.is_none());
    }

    pub async fn test_save_updates_existing<R: TaskRepository>(repo: &R) {
        let mut task = Task::new("Original".to_string()).unwrap();
        let id = task.id().clone();

        repo.save(&task).await.unwrap();

        task.complete().unwrap();
        repo.save(&task).await.unwrap();

        let found = repo.find_by_id(&id).await.unwrap().unwrap();
        assert!(found.is_completed());
    }

    pub async fn test_delete_removes_task<R: TaskRepository>(repo: &R) {
        let task = Task::new("To delete".to_string()).unwrap();
        let id = task.id().clone();

        repo.save(&task).await.unwrap();
        repo.delete(&id).await.unwrap();

        let found = repo.find_by_id(&id).await.unwrap();
        assert!(found.is_none());
    }
}
```

Run contract tests against both implementations:

```rust
// infrastructure/tests/sqlx_contract_tests.rs
use crate::tests::repository_contract::task_repository_contract;
use infrastructure::SqlxTaskRepository;

#[tokio::test]
async fn sqlx_save_and_find() {
    let repo = create_sqlx_repo().await;
    task_repository_contract::test_save_and_find_by_id(&repo).await;
}

#[tokio::test]
async fn sqlx_find_missing() {
    let repo = create_sqlx_repo().await;
    task_repository_contract::test_find_missing_returns_none(&repo).await;
}

// infrastructure/tests/in_memory_contract_tests.rs
use infrastructure::InMemoryTaskRepository;

#[tokio::test]
async fn in_memory_save_and_find() {
    let repo = InMemoryTaskRepository::new();
    task_repository_contract::test_save_and_find_by_id(&repo).await;
}

#[tokio::test]
async fn in_memory_find_missing() {
    let repo = InMemoryTaskRepository::new();
    task_repository_contract::test_find_missing_returns_none(&repo).await;
}
```

**Why contract tests matter**: If your mocks behave differently from your real implementations, tests pass but production fails. Contract tests catch these mismatches.

---

## Project Structure

### Recommended Cargo Workspace Layout

```
project-name/
├── Cargo.toml                    # Workspace manifest
├── README.md
├── .github/
│   └── workflows/
│       └── ci.yml
├── crates/
│   ├── domain/                   # Pure domain logic
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs           # Module exports
│   │       ├── entities/
│   │       │   ├── mod.rs
│   │       │   └── task.rs
│   │       ├── value_objects/
│   │       │   ├── mod.rs
│   │       │   ├── task_id.rs
│   │       │   └── priority.rs
│   │       ├── repositories/    # Trait definitions only
│   │       │   ├── mod.rs
│   │       │   └── task_repository.rs
│   │       ├── services/
│   │       │   ├── mod.rs
│   │       │   └── task_scheduler.rs
│   │       └── errors.rs
│   │
│   ├── application/              # Use cases
│   │   ├── Cargo.toml           # depends on: domain
│   │   └── src/
│   │       ├── lib.rs
│   │       └── use_cases/
│   │           ├── mod.rs
│   │           ├── create_task.rs
│   │           ├── list_tasks.rs
│   │           └── complete_task.rs
│   │
│   ├── infrastructure/           # Concrete implementations
│   │   ├── Cargo.toml           # depends on: domain, sqlx/diesel
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── repositories/
│   │       │   ├── mod.rs
│   │       │   ├── sqlx_task_repository.rs
│   │       │   └── in_memory_task_repository.rs
│   │       └── database/
│   │           ├── mod.rs
│   │           └── migrations.rs
│   │
│   └── [framework-crate]/        # Choose one or more:
│       ├── axum-app/             # Web API
│       ├── tauri-app/            # Desktop application
│       └── cli-app/              # Command-line interface
│
└── frontend/                     # For Tauri apps
    ├── package.json
    ├── tsconfig.json
    └── src/
```

### Crate Cargo.toml Examples

```toml
# crates/domain/Cargo.toml
[package]
name = "domain"
version.workspace = true
edition.workspace = true

[dependencies]
chrono = { workspace = true }
uuid = { workspace = true }
thiserror = { workspace = true }
serde = { workspace = true }

# No database, no framework dependencies!
```

```toml
# crates/application/Cargo.toml
[package]
name = "application"
version.workspace = true
edition.workspace = true

[dependencies]
domain = { path = "../domain" }
chrono = { workspace = true }
serde = { workspace = true }
thiserror = { workspace = true }
async-trait = { workspace = true }

# Still no database or framework dependencies
```

```toml
# crates/infrastructure/Cargo.toml
[package]
name = "infrastructure"
version.workspace = true
edition.workspace = true

[dependencies]
domain = { path = "../domain" }
sqlx = { workspace = true }
async-trait = { workspace = true }
tokio = { workspace = true }

[dev-dependencies]
tokio = { workspace = true, features = ["test-util"] }
```

```toml
# crates/tauri-app/Cargo.toml
[package]
name = "tauri-app"
version.workspace = true
edition.workspace = true

[dependencies]
domain = { path = "../domain" }
application = { path = "../application" }
infrastructure = { path = "../infrastructure" }
tauri = { workspace = true }
serde = { workspace = true }
serde_json = { workspace = true }
tokio = { workspace = true }
anyhow = "1"

[build-dependencies]
tauri-build = { version = "2", features = [] }
```

---

## Tool Integration

### Clippy Configuration

```toml
# .cargo/config.toml or clippy.toml
[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"

# Allow some pedantic lints that are too strict
module_name_repetitions = "allow"
must_use_candidate = "allow"
missing_errors_doc = "allow"
```

### Rustfmt Configuration

```toml
# rustfmt.toml
edition = "2021"
max_width = 100
tab_spaces = 4
use_field_init_shorthand = true
use_try_shorthand = true
imports_granularity = "Crate"
group_imports = "StdExternalCrate"
```

### cargo-nextest for Faster Tests

```toml
# .config/nextest.toml
[profile.default]
retries = 0
test-threads = "num-cpus"

[profile.ci]
retries = 2
fail-fast = false
```

### CI Pipeline Example

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  CARGO_TERM_COLOR: always

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: rustfmt, clippy

      - name: Check formatting
        run: cargo fmt --all -- --check

      - name: Clippy
        run: cargo clippy --all-targets --all-features -- -D warnings

      - name: Build
        run: cargo build --all-targets

      - name: Test
        run: cargo nextest run --all-targets
```

---

## Common Pitfalls

### 1. Async Trait Without Send + Sync

```rust
// WRONG - Won't work with Axum/Tauri
#[async_trait]
pub trait TaskRepository {
    async fn save(&self, task: &Task) -> Result<(), Error>;
}

// RIGHT - Works across async boundaries
#[async_trait]
pub trait TaskRepository: Send + Sync {
    async fn save(&self, task: &Task) -> Result<(), Error>;
}
```

### 2. Exposing ORM Types in Domain

```rust
// WRONG - Domain depends on infrastructure
use sqlx::FromRow;

#[derive(FromRow)]  // SQLx type in domain!
pub struct Task {
    id: String,
}

// RIGHT - Keep domain pure
pub struct Task {
    id: TaskId,
}

// Infrastructure maps to/from database types
struct TaskRow { /* SQLx-specific */ }
impl TaskRow {
    fn to_domain(&self) -> Task { /* ... */ }
}
```

### 3. Not Cloning Domain Objects for Repository

```rust
// WRONG - Repository takes ownership
#[async_trait]
impl TaskRepository for SqlxRepo {
    async fn save(&self, task: Task) -> Result<(), Error> {
        // task is consumed, caller can't use it
    }
}

// RIGHT - Repository borrows
#[async_trait]
impl TaskRepository for SqlxRepo {
    async fn save(&self, task: &Task) -> Result<(), Error> {
        // task is borrowed, caller keeps ownership
    }
}
```

### 4. Missing Error Conversion

```rust
// WRONG - Panics or unwraps
pub async fn execute(&self, request: Request) -> Response {
    let task = self.repo.find_by_id(&id).await.unwrap(); // Panic!
}

// RIGHT - Proper error handling
pub async fn execute(&self, request: Request) -> Result<Response, Error> {
    let task = self.repo.find_by_id(&id).await?;
    Ok(response)
}
```

### 5. Blocking in Async Context

```rust
// WRONG - Blocks the async runtime
async fn save(&self, task: &Task) -> Result<(), Error> {
    let data = serde_json::to_string(task)?;
    std::fs::write("tasks.json", data)?; // Blocking I/O!
    Ok(())
}

// RIGHT - Use async I/O
async fn save(&self, task: &Task) -> Result<(), Error> {
    let data = serde_json::to_string(task)?;
    tokio::fs::write("tasks.json", data).await?;
    Ok(())
}
```

---

## Tauri v2 Security: Capabilities and ACL

Tauri v2 introduces a capability-based security model. Instead of a global allowlist, you define granular permissions per window.

### Content Security Policy (CSP)

Always configure CSP to prevent XSS attacks:

```json
// tauri.conf.json
{
  "app": {
    "security": {
      "csp": "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'"
    }
  }
}
```

### Input Validation in Commands

**Critical**: Always validate inputs in Tauri commands - frontend validation can be bypassed:

```rust
#[tauri::command]
pub async fn create_task(
    input: CreateTaskInput,
    state: State<'_, AppState>,
) -> CommandResult<CreateTaskResponse> {
    // Validate at the command layer before reaching use cases
    let description = input.description.trim();

    if description.is_empty() {
        return CommandResult::error("Description is required", "VALIDATION_ERROR");
    }
    if description.len() > 1000 {
        return CommandResult::error("Description too long (max 1000)", "VALIDATION_ERROR");
    }

    // Now delegate to use case (which also validates domain rules)
    let request = CreateTaskRequest {
        description: description.to_string(),
    };

    match state.create_task.execute(request).await {
        Ok(response) => CommandResult::success(response),
        Err(e) => CommandResult::error(e, "CREATE_FAILED"),
    }
}
```

**Note**: Commands should perform basic validation (length, format) while domain entities enforce business rules (e.g., description content rules).

### Capability Files

Create capability files in `src-tauri/capabilities/`:

```json
// src-tauri/capabilities/main.json
{
  "$schema": "https://schemas.tauri.app/v2/capabilities",
  "identifier": "main-window",
  "description": "Capabilities for the main window",
  "windows": ["main"],
  "permissions": [
    "core:default",
    "core:event:allow-emit",
    "core:event:allow-listen",
    "sql:allow-execute",
    "sql:allow-select"
  ]
}
```

### Permission Scoping

Permissions can be scoped for fine-grained control:

```json
{
  "identifier": "file-access",
  "windows": ["main"],
  "permissions": [
    {
      "identifier": "fs:allow-read",
      "allow": [
        { "path": "$APPDATA/**" },
        { "path": "$RESOURCE/**" }
      ]
    },
    {
      "identifier": "fs:allow-write",
      "allow": [
        { "path": "$APPDATA/**" }
      ]
    }
  ]
}
```

### Custom Command Permissions

Define permissions for your own commands:

```toml
# src-tauri/capabilities/permissions/task-commands.toml
[[permission]]
identifier = "allow-create-task"
description = "Allow creating tasks"
commands.allow = ["create_task"]

[[permission]]
identifier = "allow-list-tasks"
description = "Allow listing tasks"
commands.allow = ["list_tasks"]

[[permission]]
identifier = "allow-complete-task"
description = "Allow completing tasks"
commands.allow = ["complete_task"]

[[set]]
identifier = "task-management"
description = "All task management commands"
permissions = [
    "allow-create-task",
    "allow-list-tasks",
    "allow-complete-task"
]
```

### Tauri Config Reference

Reference capabilities in `tauri.conf.json`:

```json
{
  "app": {
    "security": {
      "capabilities": ["main-window", "file-access"]
    }
  }
}
```

### Mapping Capabilities to Use Cases

Structure capabilities to match your Clean Architecture use cases:

```toml
# Organize permissions by use case category
[[set]]
identifier = "task-queries"
description = "Read-only task operations (Query use cases)"
permissions = ["allow-list-tasks", "allow-get-task"]

[[set]]
identifier = "task-commands"
description = "Task modification operations (Command use cases)"
permissions = ["allow-create-task", "allow-complete-task", "allow-update-task"]

[[set]]
identifier = "task-admin"
description = "Administrative task operations (requires elevated trust)"
permissions = ["allow-delete-task", "allow-bulk-delete"]
```

This creates a clear mapping:
- **Query use cases** → Read-only permission sets
- **Command use cases** → Write permission sets
- **Administrative use cases** → Privileged permission sets

Each window can then be granted appropriate access based on its role.

---

## Type-Safe Frontend Bindings with tauri-specta

Manually maintaining TypeScript types for Tauri commands is error-prone. Use `tauri-specta` to auto-generate type-safe bindings.

### Setup

```toml
# Cargo.toml
[dependencies]
specta = { version = "2", features = ["export"] }
tauri-specta = { version = "2", features = ["typescript"] }
```

### Derive Specta Types

```rust
use specta::Type;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
pub struct TaskView {
    pub id: String,
    pub description: String,
    pub completed: bool,
    pub created_at: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
pub struct CreateTaskInput {
    pub description: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
pub struct CreateTaskResponse {
    pub task_id: String,
    pub description: String,
    pub created_at: String,
}
```

### Register Commands with Specta

```rust
use tauri_specta::{collect_commands, Builder};

#[tauri::command]
#[specta::specta]
pub async fn create_task(
    input: CreateTaskInput,
    state: State<'_, AppState>,
) -> Result<CreateTaskResponse, String> {
    // Implementation
}

#[tauri::command]
#[specta::specta]
pub async fn list_tasks(
    state: State<'_, AppState>,
) -> Result<Vec<TaskView>, String> {
    // Implementation
}

fn main() {
    let builder = Builder::<tauri::Wry>::new()
        .commands(collect_commands![create_task, list_tasks]);

    #[cfg(debug_assertions)]
    builder
        .export(
            specta_typescript::Typescript::default(),
            "../src/bindings.ts",
        )
        .expect("Failed to export typescript bindings");

    tauri::Builder::default()
        .invoke_handler(builder.invoke_handler())
        .setup(move |app| {
            builder.mount_events(app);
            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
```

### Generated TypeScript

Running the app in dev mode generates `bindings.ts`:

```typescript
// Auto-generated by tauri-specta - do not edit manually

export const commands = {
  async createTask(input: CreateTaskInput): Promise<CreateTaskResponse> {
    return await TAURI_INVOKE("create_task", { input });
  },
  async listTasks(): Promise<TaskView[]> {
    return await TAURI_INVOKE("list_tasks");
  },
};

export type CreateTaskInput = { description: string };
export type CreateTaskResponse = { task_id: string; description: string; created_at: string };
export type TaskView = { id: string; description: string; completed: boolean; created_at: string };
```

### Usage in Frontend

```typescript
import { commands } from './bindings';

// Fully type-safe - TypeScript knows the exact shapes
const response = await commands.createTask({ description: 'Learn Rust' });
console.log(response.task_id); // Type: string

const tasks = await commands.listTasks();
tasks.forEach(task => {
  console.log(task.description); // Type: string
});
```

---

## Tauri Events (Rust → Frontend Communication)

Commands handle frontend→Rust calls. For Rust→frontend communication, use events.

### Emitting Events from Rust

```rust
use tauri::Emitter;
use serde::Serialize;
use specta::Type;

#[derive(Clone, Serialize, Type)]
pub struct TaskCompletedEvent {
    pub task_id: String,
    pub completed_at: String,
}

#[derive(Clone, Serialize, Type)]
pub struct TaskProgressEvent {
    pub task_id: String,
    pub progress: u8,
}

// Emit to all windows
fn emit_task_completed(app: &tauri::AppHandle, task_id: String) {
    app.emit("task-completed", TaskCompletedEvent {
        task_id,
        completed_at: chrono::Utc::now().to_rfc3339(),
    }).expect("Failed to emit event");
}

// Emit to specific window
fn emit_task_progress(window: &tauri::WebviewWindow, task_id: String, progress: u8) {
    window.emit("task-progress", TaskProgressEvent {
        task_id,
        progress,
    }).expect("Failed to emit event");
}
```

### Type-Safe Events with tauri-specta

```rust
use tauri_specta::{collect_events, Event};

#[derive(Clone, Serialize, Type, Event)]
pub struct TaskCompletedEvent {
    pub task_id: String,
}

fn main() {
    let builder = Builder::<tauri::Wry>::new()
        .commands(collect_commands![create_task, list_tasks])
        .events(collect_events![TaskCompletedEvent]);

    // Export includes event types
    #[cfg(debug_assertions)]
    builder.export(specta_typescript::Typescript::default(), "../src/bindings.ts")
        .expect("Failed to export");

    // ...
}
```

### Listening in TypeScript

```typescript
import { listen } from '@tauri-apps/api/event';

// Basic listener
const unlisten = await listen('task-completed', (event) => {
  const payload = event.payload as { task_id: string; completed_at: string };
  console.log('Task completed:', payload.task_id);
});

// With tauri-specta generated bindings
import { events } from './bindings';

const unlisten = await events.taskCompleted.listen((data) => {
  // data is fully typed
  console.log('Task completed:', data.task_id);
});

// Clean up when component unmounts
unlisten();
```

### Bidirectional Communication Pattern

```rust
use tauri::{Emitter, Listener};

// Listen for events from frontend
fn setup_listeners(app: &tauri::AppHandle) {
    let handle = app.clone();
    app.listen("request-sync", move |event| {
        // Handle sync request
        handle.emit("sync-started", ()).unwrap();

        // Do sync work...

        handle.emit("sync-completed", SyncResult { items_synced: 42 }).unwrap();
    });
}
```

```typescript
import { emit, listen } from '@tauri-apps/api/event';

// Request sync from frontend
await emit('request-sync');

// Listen for response
await listen('sync-completed', (event) => {
  console.log('Synced items:', event.payload.items_synced);
});
```

---

## Summary

Rust's type system and ownership model naturally enforce Clean Architecture boundaries:

- **Traits** define clean interfaces between layers
- **Ownership** ensures data flows explicitly through the system
- **Result types** make error handling visible and testable
- **Cargo workspaces** physically enforce layer dependencies
- **No inheritance** encourages composition and explicit dependency injection

The combination of Rust's safety guarantees with Clean Architecture's separation of concerns creates robust, maintainable applications where both compile-time and architectural invariants are enforced.
