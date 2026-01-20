# Task Manager - Rust/Tauri Implementation

A complete Clean Architecture implementation using Rust with a Tauri desktop frontend.

## Overview

This implementation demonstrates Clean Architecture principles using Rust's unique features:

- **Traits** for dependency inversion (repository interfaces)
- **Ownership model** for natural encapsulation
- **Result pattern** for explicit error handling
- **Cargo workspaces** for physical layer separation

## Project Structure

```
rust/
├── Cargo.toml                    # Workspace manifest
├── README.md                     # This file
├── crates/
│   ├── domain/                   # Pure domain logic (no external deps)
│   │   ├── Cargo.toml
│   │   └── src/
│   │       ├── lib.rs
│   │       ├── entities/
│   │       │   ├── mod.rs
│   │       │   └── task.rs
│   │       ├── value_objects/
│   │       │   ├── mod.rs
│   │       │   └── task_id.rs
│   │       ├── repositories/
│   │       │   ├── mod.rs
│   │       │   └── task_repository.rs  # Trait only
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
│   ├── infrastructure/           # Repository implementations
│   │   ├── Cargo.toml           # depends on: domain, sqlx
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
│   └── tauri-app/               # Tauri desktop app
│       ├── Cargo.toml           # depends on: application, infrastructure, tauri
│       ├── tauri.conf.json
│       ├── build.rs
│       └── src/
│           ├── main.rs
│           ├── commands.rs       # Thin invoke handlers
│           └── state.rs
│
└── frontend/                     # TypeScript/React UI
    ├── package.json
    ├── tsconfig.json
    ├── vite.config.ts
    ├── index.html
    └── src/
        ├── main.tsx
        ├── App.tsx
        └── api/
            └── tasks.ts          # invoke() wrappers
```

## Layer Dependencies

```
┌─────────────────────────────────────────┐
│              tauri-app                   │  depends on: application, infrastructure, tauri
├─────────────────────────────────────────┤
│            infrastructure                │  depends on: domain, sqlx
├─────────────────────────────────────────┤
│             application                  │  depends on: domain
├─────────────────────────────────────────┤
│               domain                     │  no external dependencies
└─────────────────────────────────────────┘
```

## Prerequisites

- Rust 1.75+ (install via [rustup](https://rustup.rs/))
- Node.js 18+ (for frontend)
- Tauri CLI: `cargo install tauri-cli`

## Getting Started

### 1. Clone and navigate

```bash
cd example-task-manager/rust
```

### 2. Install dependencies

```bash
# Install Rust dependencies (via Cargo workspace)
cargo build

# Install frontend dependencies
cd frontend
npm install
cd ..
```

### 3. Run in development mode

```bash
# Start the Tauri app with hot reload
cargo tauri dev
```

### 4. Build for production

```bash
cargo tauri build
```

## Workspace Configuration

### Root Cargo.toml

```toml
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
anyhow = "1"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
all = "warn"
pedantic = "warn"
```

### Domain Cargo.toml

```toml
[package]
name = "domain"
version.workspace = true
edition.workspace = true

[dependencies]
chrono = { workspace = true }
uuid = { workspace = true }
thiserror = { workspace = true }
serde = { workspace = true }
async-trait = { workspace = true }

# Note: No database, framework, or external service dependencies!
```

### Application Cargo.toml

```toml
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

# Note: Still no database or framework dependencies
```

### Infrastructure Cargo.toml

```toml
[package]
name = "infrastructure"
version.workspace = true
edition.workspace = true

[dependencies]
domain = { path = "../domain" }
sqlx = { workspace = true }
async-trait = { workspace = true }
tokio = { workspace = true }
uuid = { workspace = true }
chrono = { workspace = true }

[dev-dependencies]
tokio = { workspace = true, features = ["test-util"] }
```

### Tauri App Cargo.toml

```toml
[package]
name = "tauri-app"
version.workspace = true
edition.workspace = true

[build-dependencies]
tauri-build = { version = "2", features = [] }

[dependencies]
domain = { path = "../domain" }
application = { path = "../application" }
infrastructure = { path = "../infrastructure" }
tauri = { workspace = true }
serde = { workspace = true }
serde_json = { workspace = true }
tokio = { workspace = true }
anyhow = { workspace = true }

[features]
default = ["custom-protocol"]
custom-protocol = ["tauri/custom-protocol"]
```

## Running Tests

```bash
# Run all tests
cargo test --workspace

# Run domain tests only
cargo test -p domain

# Run with coverage (requires cargo-llvm-cov)
cargo llvm-cov --workspace
```

## API Reference

### Tauri Commands

| Command | Input | Output |
|---------|-------|--------|
| `create_task` | `{ input: { description: string } }` | `{ task_id, description, created_at }` |
| `list_tasks` | none | `{ tasks: Task[], total: number }` |
| `complete_task` | `{ taskId: string }` | `{ success: boolean, completed_at }` |

### TypeScript Usage

```typescript
import { createTask, listTasks, completeTask } from './api/tasks';

// Create a task
const task = await createTask('Learn Clean Architecture');

// List all tasks
const { tasks, total } = await listTasks();

// Complete a task
const completed = await completeTask(task.task_id);
```

## Key Patterns Demonstrated

### 1. Trait-based Dependency Inversion

```rust
// Domain defines the contract
#[async_trait]
pub trait TaskRepository: Send + Sync {
    async fn save(&self, task: &Task) -> Result<(), RepositoryError>;
    async fn find_by_id(&self, id: &TaskId) -> Result<Option<Task>, RepositoryError>;
}

// Infrastructure provides implementation
pub struct SqlxTaskRepository { pool: Pool<Sqlite> }

#[async_trait]
impl TaskRepository for SqlxTaskRepository {
    // Implementation...
}
```

### 2. Use Case with Generic Repository

```rust
pub struct CreateTaskUseCase<R: TaskRepository> {
    repository: R,
}

impl<R: TaskRepository> CreateTaskUseCase<R> {
    pub async fn execute(&self, request: CreateTaskRequest) -> Result<CreateTaskResponse, Error> {
        let task = Task::new(request.description)?;
        self.repository.save(&task).await?;
        Ok(CreateTaskResponse::from(&task))
    }
}
```

### 3. Type-Safe IDs with Newtype Pattern

```rust
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct TaskId(Uuid);

impl TaskId {
    pub fn new() -> Self { Self(Uuid::new_v4()) }
}
```

### 4. Tauri Commands as Thin Controllers

```rust
#[tauri::command]
pub async fn create_task(
    input: CreateTaskInput,
    state: State<'_, AppState>,
) -> CommandResult<CreateTaskResponse> {
    // Parse input -> call use case -> format response
    let request = CreateTaskRequest { description: input.description };
    match state.create_task.execute(request).await {
        Ok(response) => CommandResult::success(response),
        Err(e) => CommandResult::error(e, "CREATE_FAILED"),
    }
}
```

## Troubleshooting

### "Cannot find crate" errors

Ensure all workspace members are listed in the root `Cargo.toml`.

### Database errors

The SQLite database is created in the app data directory. To reset:
- macOS: `~/Library/Application Support/com.taskmanager.app/tasks.db`
- Windows: `%APPDATA%/com.taskmanager.app/tasks.db`
- Linux: `~/.local/share/com.taskmanager.app/tasks.db`

### Frontend not connecting

Make sure the Tauri app is running (`cargo tauri dev`) before testing frontend functionality.

## Tauri v2 Features

This example uses Tauri v2 patterns:

### Security with Capabilities

Permissions are defined in `src-tauri/capabilities/`:

```json
{
  "identifier": "main-window",
  "windows": ["main"],
  "permissions": ["core:default", "sql:allow-execute"]
}
```

See: [Tauri v2 Security Guide](../../languages/rust/guide.md#tauri-v2-security-capabilities-and-acl)

### Type-Safe Bindings (Optional)

For larger projects, use `tauri-specta` to auto-generate TypeScript types:

```toml
[dependencies]
specta = { version = "2", features = ["export"] }
tauri-specta = { version = "2", features = ["typescript"] }
```

See: [Type-Safe Frontend Bindings](../../languages/rust/guide.md#type-safe-frontend-bindings-with-tauri-specta)

### Rust→Frontend Events

For real-time updates, use Tauri events:

```rust
use tauri::Emitter;
app.emit("task-completed", TaskCompletedEvent { task_id })?;
```

See: [Tauri Events Guide](../../languages/rust/guide.md#tauri-events-rust--frontend-communication)

## Learning More

- [Rust Clean Architecture Guide](../../languages/rust/guide.md)
- [Tauri v2 Documentation](https://v2.tauri.app/)
- [Tauri v2 Security](https://v2.tauri.app/security/capabilities/)
- [tauri-specta](https://github.com/specta-rs/tauri-specta)
- [SQLx Documentation](https://docs.rs/sqlx/)
- [async-trait Crate](https://docs.rs/async-trait/)

## License

MIT
