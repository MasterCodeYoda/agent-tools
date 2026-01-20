# Rust Code Patterns

This guide covers Rust-specific coding standards, patterns, and best practices for building maintainable applications.

## Environment and Tooling

### Rust Version

- **Minimum**: Rust 1.75+ (stable)
- **Edition**: 2021
- **Toolchain**: Use `rustup` for version management

### Essential Tools

| Tool | Purpose | Installation |
|------|---------|--------------|
| `cargo` | Build system and package manager | Included with Rust |
| `rustfmt` | Code formatting | `rustup component add rustfmt` |
| `clippy` | Linting | `rustup component add clippy` |
| `cargo-nextest` | Faster test runner | `cargo install cargo-nextest` |
| `cargo-watch` | Auto-rebuild on changes | `cargo install cargo-watch` |
| `cargo-audit` | Security vulnerability scanner | `cargo install cargo-audit` |

### Cargo.toml Best Practices

```toml
[package]
name = "my-app"
version = "0.1.0"
edition = "2021"
rust-version = "1.75"  # Minimum supported Rust version

[dependencies]
# Pin major versions for stability
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }

# Use workspace dependencies for consistency in workspaces
# chrono = { workspace = true }

[dev-dependencies]
# Test dependencies
mockall = "0.12"
proptest = "1"
tokio = { version = "1", features = ["test-util", "macros"] }

[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
all = "warn"
pedantic = "warn"
nursery = "warn"

# Allow specific pedantic lints
module_name_repetitions = "allow"
must_use_candidate = "allow"

[profile.release]
lto = true
codegen-units = 1
strip = true
```

---

## Code Style and Formatting

### Naming Conventions

| Item | Convention | Example |
|------|------------|---------|
| Crates | snake_case | `my_crate` |
| Modules | snake_case | `task_repository` |
| Types (structs, enums, traits) | PascalCase | `TaskRepository`, `DomainError` |
| Functions, methods | snake_case | `find_by_id`, `create_task` |
| Local variables | snake_case | `task_id`, `user_name` |
| Constants | SCREAMING_SNAKE_CASE | `MAX_RETRIES`, `DEFAULT_PORT` |
| Type parameters | PascalCase (usually single letter) | `T`, `E`, `R` |
| Lifetimes | lowercase with apostrophe | `'a`, `'static` |
| Feature flags | kebab-case | `full-featured`, `async-runtime` |

### Module Organization

```rust
// lib.rs - Organize with explicit module structure
pub mod entities;
pub mod repositories;
pub mod services;
pub mod errors;

// Re-export commonly used items
pub use entities::Task;
pub use errors::{DomainError, RepositoryError};
pub use repositories::TaskRepository;
```

### Import Grouping

Group imports in this order, separated by blank lines:

```rust
// 1. Standard library
use std::collections::HashMap;
use std::sync::Arc;

// 2. External crates
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

// 3. Current crate
use crate::entities::Task;
use crate::errors::DomainError;

// 4. Parent/sibling modules
use super::TaskRepository;
```

### Rustfmt Configuration

```toml
# rustfmt.toml
edition = "2021"
max_width = 100
tab_spaces = 4
newline_style = "Unix"
use_field_init_shorthand = true
use_try_shorthand = true
imports_granularity = "Crate"
group_imports = "StdExternalCrate"
reorder_imports = true
reorder_modules = true
format_code_in_doc_comments = true
format_macro_matchers = true
format_strings = true
```

---

## Type Safety Patterns

### Newtype Pattern

Wrap primitive types for type safety:

```rust
// WRONG - Primitives can be confused
fn transfer(from: String, to: String, amount: i64) {
    // Easy to swap from/to accidentally
}

// RIGHT - Newtypes prevent confusion
#[derive(Debug, Clone, PartialEq, Eq, Hash)]
pub struct AccountId(String);

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Money(i64);

impl AccountId {
    pub fn new(id: impl Into<String>) -> Self {
        Self(id.into())
    }

    pub fn as_str(&self) -> &str {
        &self.0
    }
}

impl Money {
    pub fn new(cents: i64) -> Self {
        Self(cents)
    }

    pub fn cents(&self) -> i64 {
        self.0
    }

    pub fn dollars(&self) -> f64 {
        self.0 as f64 / 100.0
    }
}

// Now type-safe
fn transfer(from: AccountId, to: AccountId, amount: Money) {
    // Can't accidentally swap types
}
```

### Builder Pattern

For complex object construction:

```rust
#[derive(Debug, Clone)]
pub struct Request {
    url: String,
    method: Method,
    headers: HashMap<String, String>,
    timeout: Duration,
    retries: u32,
}

#[derive(Debug, Default)]
pub struct RequestBuilder {
    url: Option<String>,
    method: Method,
    headers: HashMap<String, String>,
    timeout: Duration,
    retries: u32,
}

impl RequestBuilder {
    pub fn new() -> Self {
        Self {
            method: Method::Get,
            timeout: Duration::from_secs(30),
            retries: 3,
            ..Default::default()
        }
    }

    pub fn url(mut self, url: impl Into<String>) -> Self {
        self.url = Some(url.into());
        self
    }

    pub fn method(mut self, method: Method) -> Self {
        self.method = method;
        self
    }

    pub fn header(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.headers.insert(key.into(), value.into());
        self
    }

    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    pub fn retries(mut self, retries: u32) -> Self {
        self.retries = retries;
        self
    }

    pub fn build(self) -> Result<Request, BuildError> {
        let url = self.url.ok_or(BuildError::MissingUrl)?;

        Ok(Request {
            url,
            method: self.method,
            headers: self.headers,
            timeout: self.timeout,
            retries: self.retries,
        })
    }
}

// Usage
let request = RequestBuilder::new()
    .url("https://api.example.com")
    .method(Method::Post)
    .header("Content-Type", "application/json")
    .timeout(Duration::from_secs(10))
    .build()?;
```

### Type State Pattern

Enforce state transitions at compile time:

```rust
// States as zero-sized types
pub struct Draft;
pub struct Published;
pub struct Archived;

pub struct Article<State> {
    title: String,
    content: String,
    _state: std::marker::PhantomData<State>,
}

impl Article<Draft> {
    pub fn new(title: String) -> Self {
        Self {
            title,
            content: String::new(),
            _state: std::marker::PhantomData,
        }
    }

    pub fn edit_content(&mut self, content: String) {
        self.content = content;
    }

    pub fn publish(self) -> Article<Published> {
        Article {
            title: self.title,
            content: self.content,
            _state: std::marker::PhantomData,
        }
    }
}

impl Article<Published> {
    pub fn archive(self) -> Article<Archived> {
        Article {
            title: self.title,
            content: self.content,
            _state: std::marker::PhantomData,
        }
    }
}

// Usage - compiler enforces valid transitions
let draft = Article::<Draft>::new("My Article".into());
// draft.archive(); // ERROR: no method `archive` for Article<Draft>

let published = draft.publish();
// published.edit_content("new".into()); // ERROR: no method `edit_content`

let archived = published.archive();
```

---

## Error Handling Patterns

### thiserror for Library Errors

Define structured error types with `thiserror`:

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum DomainError {
    #[error("Task description cannot be empty")]
    EmptyDescription,

    #[error("Task description exceeds maximum length of {max} characters (got {actual})")]
    DescriptionTooLong { max: usize, actual: usize },

    #[error("Task is already completed")]
    AlreadyCompleted,

    #[error("Invalid task ID: {0}")]
    InvalidTaskId(String),
}

#[derive(Error, Debug)]
pub enum RepositoryError {
    #[error("Database connection failed")]
    ConnectionFailed(#[source] sqlx::Error),

    #[error("Record not found: {entity} with ID {id}")]
    NotFound { entity: &'static str, id: String },

    #[error("Duplicate key: {0}")]
    DuplicateKey(String),

    #[error("Query execution failed")]
    QueryFailed(#[from] sqlx::Error),
}

// Compose errors with #[from]
#[derive(Error, Debug)]
pub enum UseCaseError {
    #[error("Validation error: {0}")]
    Validation(#[from] DomainError),

    #[error("Persistence error: {0}")]
    Persistence(#[from] RepositoryError),

    #[error("Resource not found: {0}")]
    NotFound(String),
}
```

### Error Propagation with ?

```rust
// The ? operator propagates errors
pub async fn complete_task(&self, task_id: &str) -> Result<(), UseCaseError> {
    let id: TaskId = task_id
        .parse()
        .map_err(|_| DomainError::InvalidTaskId(task_id.to_string()))?;

    let mut task = self.repository
        .find_by_id(&id)
        .await?  // Converts RepositoryError -> UseCaseError
        .ok_or_else(|| UseCaseError::NotFound(task_id.to_string()))?;

    task.complete()?;  // Converts DomainError -> UseCaseError

    self.repository.save(&task).await?;

    Ok(())
}
```

### Result Extensions and Combinators

```rust
use std::result::Result;

// Map success value
let doubled = result.map(|x| x * 2);

// Map error
let converted = result.map_err(|e| CustomError::from(e));

// Chain operations
let final_result = get_user(id)
    .and_then(|user| get_permissions(&user))
    .and_then(|perms| validate_access(&perms));

// Provide default on error
let value = risky_operation().unwrap_or_default();
let value = risky_operation().unwrap_or(fallback_value);
let value = risky_operation().unwrap_or_else(|| compute_fallback());

// Convert Option to Result
let task = maybe_task.ok_or(UseCaseError::NotFound("task".into()))?;

// Transpose Option<Result<T, E>> to Result<Option<T>, E>
let result: Result<Option<Task>, Error> = maybe_result.transpose();
```

### anyhow for Application Errors

Use `anyhow` at application boundaries:

```rust
use anyhow::{anyhow, bail, Context, Result};

// In main.rs or application entry points
fn main() -> Result<()> {
    let config = load_config()
        .context("Failed to load configuration")?;

    let db = connect_database(&config.database_url)
        .context("Failed to connect to database")?;

    run_server(db).await
}

// Adding context to errors
async fn process_order(order_id: &str) -> Result<()> {
    let order = fetch_order(order_id)
        .await
        .with_context(|| format!("Failed to fetch order {}", order_id))?;

    if order.items.is_empty() {
        bail!("Order {} has no items", order_id);
    }

    validate_order(&order)
        .with_context(|| format!("Order {} validation failed", order_id))?;

    Ok(())
}
```

### snafu for Rich Context in Large Systems

For systems requiring detailed error context with backtraces:

```rust
use snafu::{Backtrace, ResultExt, Snafu};

#[derive(Debug, Snafu)]
pub enum DataStoreError {
    #[snafu(display("Failed to read config from {path}"))]
    ReadConfig {
        path: String,
        source: std::io::Error,
        backtrace: Backtrace,
    },

    #[snafu(display("Failed to parse config"))]
    ParseConfig {
        source: toml::de::Error,
        backtrace: Backtrace,
    },

    #[snafu(display("Database connection failed for {url}"))]
    DbConnection {
        url: String,
        source: sqlx::Error,
        backtrace: Backtrace,
    },
}

// Usage with context extension
fn load_config(path: &str) -> Result<Config, DataStoreError> {
    let contents = std::fs::read_to_string(path)
        .context(ReadConfigSnafu { path })?;

    toml::from_str(&contents)
        .context(ParseConfigSnafu)
}
```

### Error Handling Decision Guide

| Library | Best For | Key Feature |
|---------|----------|-------------|
| **thiserror** | Libraries, public APIs | Minimal boilerplate, `#[from]` for conversion |
| **anyhow** | Applications, binaries | Flexible context, ergonomic `?` usage |
| **snafu** | Large systems, debugging | Rich context fields, automatic backtraces |

### Context Patterns (Best Practice)

Always add context - bare `?` loses information:

```rust
// WRONG - Where did this error happen?
let config = load_config()?;
let user = fetch_user(id)?;

// RIGHT - Context tells the story
let config = load_config()
    .context("Failed to load configuration")?;

let user = fetch_user(id)
    .with_context(|| format!("Failed to fetch user {}", id))?;

// For Option -> Result conversion
let user = users.get(&id)
    .context("User not found")?;

// Lazy context for expensive formatting
let data = parse_complex_data(&input)
    .with_context(|| format!("Failed to parse: {:?}", &input[..50.min(input.len())]))?;
```

### Error Chaining and Display

```rust
use thiserror::Error;

#[derive(Error, Debug)]
pub enum ServiceError {
    #[error("Authentication failed")]
    AuthFailed(#[source] AuthError),

    #[error("Database operation failed")]
    Database(#[source] sqlx::Error),

    #[error("External API error: {message}")]
    ExternalApi {
        message: String,
        #[source]
        source: reqwest::Error,
    },
}

// Displaying error chain
fn log_error_chain(err: &dyn std::error::Error) {
    eprintln!("Error: {}", err);
    let mut source = err.source();
    while let Some(cause) = source {
        eprintln!("Caused by: {}", cause);
        source = cause.source();
    }
}
```

---

## Async Patterns

### Runtime Selection: Tokio

```rust
// Cargo.toml
[dependencies]
tokio = { version = "1", features = ["full"] }

// main.rs - Use tokio::main macro
#[tokio::main]
async fn main() {
    // Async code here
}

// For library code, be runtime-agnostic where possible
// Use async-trait for async trait methods
```

### async_trait Usage

```rust
use async_trait::async_trait;

#[async_trait]
pub trait Repository: Send + Sync {
    async fn find(&self, id: &str) -> Result<Option<Entity>, Error>;
    async fn save(&self, entity: &Entity) -> Result<(), Error>;
}

#[async_trait]
impl Repository for SqlRepository {
    async fn find(&self, id: &str) -> Result<Option<Entity>, Error> {
        // Implementation
    }

    async fn save(&self, entity: &Entity) -> Result<(), Error> {
        // Implementation
    }
}
```

### Concurrent Operations with join!

```rust
use tokio::join;

// Run multiple futures concurrently
async fn fetch_dashboard_data(user_id: &str) -> Result<Dashboard> {
    let (user, tasks, notifications) = join!(
        fetch_user(user_id),
        fetch_tasks(user_id),
        fetch_notifications(user_id)
    );

    Ok(Dashboard {
        user: user?,
        tasks: tasks?,
        notifications: notifications?,
    })
}

// With futures::future::join_all for dynamic collections
use futures::future::join_all;

async fn process_all(items: Vec<Item>) -> Vec<Result<Output, Error>> {
    let futures: Vec<_> = items
        .into_iter()
        .map(|item| process_item(item))
        .collect();

    join_all(futures).await
}
```

### Cancellation with select!

```rust
use tokio::select;
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout(url: &str) -> Result<Response, Error> {
    select! {
        result = fetch(url) => {
            result
        }
        _ = tokio::time::sleep(Duration::from_secs(30)) => {
            Err(Error::Timeout)
        }
    }
}

// Or use the timeout helper
async fn fetch_with_timeout_helper(url: &str) -> Result<Response, Error> {
    timeout(Duration::from_secs(30), fetch(url))
        .await
        .map_err(|_| Error::Timeout)?
}
```

### Spawning Tasks

```rust
use tokio::task;

// Spawn a background task
let handle = task::spawn(async move {
    process_in_background().await
});

// Wait for the result
let result = handle.await?;

// Spawn blocking work on a thread pool
let result = task::spawn_blocking(move || {
    expensive_cpu_computation()
}).await?;
```

### Structured Concurrency with JoinSet

`JoinSet` manages multiple spawned tasks and collects their results:

```rust
use tokio::task::JoinSet;

async fn process_batch(items: Vec<Item>) -> Vec<Result<Output, Error>> {
    let mut set = JoinSet::new();

    for item in items {
        set.spawn(async move {
            process_item(item).await
        });
    }

    let mut results = Vec::new();
    while let Some(result) = set.join_next().await {
        match result {
            Ok(output) => results.push(output),
            Err(join_error) => {
                // Task panicked or was cancelled
                eprintln!("Task failed: {}", join_error);
            }
        }
    }
    results
}

// JoinSet with abort on drop - all tasks cancelled when set is dropped
async fn fetch_first_success(urls: Vec<String>) -> Option<Response> {
    let mut set = JoinSet::new();

    for url in urls {
        set.spawn(async move {
            fetch_url(&url).await
        });
    }

    // Return first successful result, abort remaining tasks
    while let Some(result) = set.join_next().await {
        if let Ok(Ok(response)) = result {
            // JoinSet dropped here, remaining tasks aborted
            return Some(response);
        }
    }
    None
}
```

### TaskTracker for Graceful Shutdown

Use `TaskTracker` from tokio-util for lifecycle management:

```rust
use tokio_util::task::TaskTracker;
use tokio_util::sync::CancellationToken;

struct Server {
    tracker: TaskTracker,
    cancel: CancellationToken,
}

impl Server {
    fn new() -> Self {
        Self {
            tracker: TaskTracker::new(),
            cancel: CancellationToken::new(),
        }
    }

    fn spawn_task<F>(&self, future: F)
    where
        F: Future<Output = ()> + Send + 'static,
    {
        let cancel = self.cancel.clone();
        self.tracker.spawn(async move {
            tokio::select! {
                _ = cancel.cancelled() => {
                    // Graceful shutdown
                }
                _ = future => {}
            }
        });
    }

    async fn shutdown(&self) {
        // Signal all tasks to stop
        self.cancel.cancel();

        // Close tracker to prevent new tasks
        self.tracker.close();

        // Wait for all tasks to complete
        self.tracker.wait().await;
    }
}
```

### Cancellation Patterns

```rust
use tokio_util::sync::CancellationToken;

async fn long_running_task(cancel: CancellationToken) -> Result<(), Error> {
    loop {
        tokio::select! {
            _ = cancel.cancelled() => {
                // Clean up resources
                return Ok(());
            }
            result = do_work() => {
                // Process result
                result?;
            }
        }
    }
}

// Hierarchical cancellation with child tokens
let parent = CancellationToken::new();
let child = parent.child_token();

// Cancelling parent also cancels child
parent.cancel();
assert!(child.is_cancelled());
```

### Parallel Processing with Semaphore

```rust
use tokio::sync::Semaphore;
use std::sync::Arc;

async fn process_with_concurrency_limit(
    items: Vec<Item>,
    max_concurrent: usize,
) -> Vec<Result<Output, Error>> {
    let semaphore = Arc::new(Semaphore::new(max_concurrent));
    let mut handles = Vec::new();

    for item in items {
        let permit = semaphore.clone().acquire_owned().await.unwrap();
        handles.push(tokio::spawn(async move {
            let result = process_item(item).await;
            drop(permit); // Release when done
            result
        }));
    }

    futures::future::join_all(handles)
        .await
        .into_iter()
        .map(|r| r.expect("Task panicked"))
        .collect()
}
```

---

## Testing Patterns

### Unit Tests

```rust
// Place tests in the same file
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_valid_task() {
        let task = Task::new("Learn Rust".to_string()).unwrap();

        assert_eq!(task.description(), "Learn Rust");
        assert!(!task.is_completed());
    }

    #[test]
    fn test_reject_empty_description() {
        let result = Task::new("".to_string());

        assert!(result.is_err());
        assert!(matches!(result, Err(DomainError::EmptyDescription)));
    }

    #[test]
    #[should_panic(expected = "assertion failed")]
    fn test_that_panics() {
        panic!("assertion failed");
    }
}
```

### Async Tests

```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_async_operation() {
        let result = async_function().await;
        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_with_timeout() {
        use tokio::time::{timeout, Duration};

        let result = timeout(
            Duration::from_secs(5),
            slow_operation()
        ).await;

        assert!(result.is_ok());
    }
}
```

### Mocking with mockall

```rust
use mockall::{automock, predicate::*};

// Define trait with automock
#[automock]
#[async_trait]
pub trait TaskRepository: Send + Sync {
    async fn save(&self, task: &Task) -> Result<(), RepositoryError>;
    async fn find_by_id(&self, id: &TaskId) -> Result<Option<Task>, RepositoryError>;
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockall::predicate::*;

    #[tokio::test]
    async fn test_create_task_use_case() {
        let mut mock = MockTaskRepository::new();

        // Expect save to be called once with any task
        mock.expect_save()
            .times(1)
            .returning(|_| Ok(()));

        let use_case = CreateTaskUseCase::new(mock);
        let request = CreateTaskRequest {
            description: "Test task".to_string(),
        };

        let result = use_case.execute(request).await;

        assert!(result.is_ok());
    }

    #[tokio::test]
    async fn test_with_specific_expectations() {
        let mut mock = MockTaskRepository::new();

        // Expect find_by_id with specific ID
        mock.expect_find_by_id()
            .with(eq(TaskId::from_string("123")))
            .times(1)
            .returning(|_| Ok(Some(Task::new("Found task".to_string()).unwrap())));

        // Test code using the mock
    }
}
```

### rstest for Fixtures and Parametrization

```rust
use rstest::{fixture, rstest};

#[fixture]
fn task() -> Task {
    Task::new("Test task".to_string()).unwrap()
}

#[fixture]
fn completed_task(mut task: Task) -> Task {
    task.complete().unwrap();
    task
}

#[rstest]
fn test_task_is_not_completed(task: Task) {
    assert!(!task.is_completed());
}

#[rstest]
fn test_completed_task_is_completed(completed_task: Task) {
    assert!(completed_task.is_completed());
}

// Parametrized tests
#[rstest]
#[case("valid description", true)]
#[case("", false)]
#[case("   ", false)]
#[case("a".repeat(500).as_str(), true)]
#[case("a".repeat(501).as_str(), false)]
fn test_description_validation(#[case] description: &str, #[case] expected_valid: bool) {
    let result = Task::new(description.to_string());
    assert_eq!(result.is_ok(), expected_valid);
}
```

### proptest for Property-Based Testing

```rust
use proptest::prelude::*;

proptest! {
    // Test that valid priorities are always accepted
    #[test]
    fn valid_priorities_accepted(value in 1u8..=5) {
        let priority = Priority::new(value);
        prop_assert!(priority.is_ok());
    }

    // Test that invalid priorities are always rejected
    #[test]
    fn invalid_priorities_rejected(value in 6u8..=255) {
        let priority = Priority::new(value);
        prop_assert!(priority.is_err());
    }

    // Test string properties
    #[test]
    fn non_empty_strings_accepted(s in "[a-zA-Z0-9 ]{1,500}") {
        let result = Task::new(s);
        prop_assert!(result.is_ok());
    }

    // Test round-trip serialization
    #[test]
    fn task_serialization_roundtrip(desc in "[a-zA-Z0-9 ]{1,100}") {
        let task = Task::new(desc.clone()).unwrap();
        let json = serde_json::to_string(&task).unwrap();
        let restored: Task = serde_json::from_str(&json).unwrap();
        prop_assert_eq!(task.description(), restored.description());
    }
}

// Custom strategies
fn priority_strategy() -> impl Strategy<Value = Priority> {
    (1u8..=5).prop_map(|v| Priority::new(v).unwrap())
}

proptest! {
    #[test]
    fn priority_ordering_is_consistent(
        a in priority_strategy(),
        b in priority_strategy()
    ) {
        prop_assert_eq!(a < b, a.value() < b.value());
    }
}
```

### Snapshot Testing with insta

Capture expected output and detect unexpected changes:

```toml
# Cargo.toml
[dev-dependencies]
insta = { version = "1", features = ["json", "yaml"] }
```

```rust
use insta::{assert_json_snapshot, assert_debug_snapshot, assert_snapshot};

#[test]
fn test_task_serialization() {
    let task = Task::new("Learn Rust").unwrap();

    // Snapshot of JSON output - creates/updates snapshots/__test_task_serialization.snap
    assert_json_snapshot!(task, {
        ".id" => "[uuid]",           // Redact dynamic values
        ".created_at" => "[timestamp]"
    });
}

#[test]
fn test_error_display() {
    let err = DomainError::DescriptionTooLong { max: 500, actual: 600 };

    // Snapshot of string representation
    assert_snapshot!(err.to_string());
}

#[test]
fn test_complex_structure() {
    let response = build_api_response();

    // Snapshot of Debug output
    assert_debug_snapshot!(response);
}

// Inline snapshots (stored in source file)
#[test]
fn test_with_inline_snapshot() {
    let result = format_output("test");

    insta::assert_snapshot!(result, @r###"
    formatted: test
    "###);
}
```

**Workflow:**

```bash
# Run tests - new/changed snapshots marked as pending
cargo test

# Review and accept/reject changes interactively
cargo insta review

# Accept all pending snapshots
cargo insta accept

# Reject all pending snapshots
cargo insta reject
```

**Settings for redacting dynamic values:**

```rust
use insta::Settings;

#[test]
fn test_with_settings() {
    let mut settings = Settings::clone_current();
    settings.set_sort_maps(true);  // Deterministic map ordering
    settings.add_redaction(".timestamp", "[ts]");
    settings.add_redaction(".*.id", "[id]");  // Nested paths

    settings.bind(|| {
        let response = fetch_api_response();
        assert_json_snapshot!(response);
    });
}
```

### Test Organization

```
project/
├── src/
│   └── lib.rs
├── tests/                      # Integration tests
│   ├── common/
│   │   └── mod.rs             # Shared test utilities
│   ├── api_tests.rs
│   └── repository_tests.rs
└── src/
    └── domain/
        └── task.rs            # Unit tests inline with #[cfg(test)]
```

**Shared test utilities:**

```rust
// tests/common/mod.rs
use sqlx::sqlite::SqlitePoolOptions;

pub async fn create_test_db() -> sqlx::Pool<sqlx::Sqlite> {
    SqlitePoolOptions::new()
        .max_connections(1)
        .connect(":memory:")
        .await
        .expect("Failed to create test database")
}

pub fn create_test_task() -> Task {
    Task::new("Test task".to_string()).unwrap()
}
```

**Using in integration tests:**

```rust
// tests/api_tests.rs
mod common;

#[tokio::test]
async fn test_create_task_endpoint() {
    let pool = common::create_test_db().await;
    // Test implementation
}
```

---

## Serde Patterns

### Basic Derive

```rust
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    pub id: String,
    pub description: String,
    pub completed: bool,
    pub created_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub completed_at: Option<DateTime<Utc>>,
}
```

### Field Attributes

```rust
#[derive(Serialize, Deserialize)]
pub struct User {
    // Rename in JSON
    #[serde(rename = "userId")]
    pub id: String,

    // Use different name for serialization/deserialization
    #[serde(rename(serialize = "userName", deserialize = "user_name"))]
    pub name: String,

    // Skip serialization
    #[serde(skip_serializing)]
    pub password_hash: String,

    // Skip if None
    #[serde(skip_serializing_if = "Option::is_none")]
    pub phone: Option<String>,

    // Default value on missing field
    #[serde(default)]
    pub active: bool,

    // Custom default
    #[serde(default = "default_role")]
    pub role: String,

    // Flatten nested struct
    #[serde(flatten)]
    pub metadata: Metadata,
}

fn default_role() -> String {
    "user".to_string()
}
```

### Enum Representations

```rust
// Tagged (default) - {"type": "Admin", "level": 5}
#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum Role {
    Admin { level: u8 },
    User { department: String },
    Guest,
}

// Untagged - {"level": 5} or {"department": "Sales"} or null
#[derive(Serialize, Deserialize)]
#[serde(untagged)]
pub enum Value {
    Integer(i64),
    Float(f64),
    String(String),
    Boolean(bool),
}

// Adjacent - {"t": "Admin", "c": {"level": 5}}
#[derive(Serialize, Deserialize)]
#[serde(tag = "t", content = "c")]
pub enum Event {
    Created { id: String },
    Updated { id: String, changes: Vec<Change> },
    Deleted { id: String },
}

// Rename all variants
#[derive(Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Status {
    InProgress,  // Serializes as "in_progress"
    Completed,   // Serializes as "completed"
    OnHold,      // Serializes as "on_hold"
}
```

### Custom Serialization

```rust
use serde::{Deserialize, Deserializer, Serialize, Serializer};

// Serialize DateTime as ISO string
fn serialize_datetime<S>(date: &DateTime<Utc>, s: S) -> Result<S::Ok, S::Error>
where
    S: Serializer,
{
    s.serialize_str(&date.to_rfc3339())
}

fn deserialize_datetime<'de, D>(d: D) -> Result<DateTime<Utc>, D::Error>
where
    D: Deserializer<'de>,
{
    let s = String::deserialize(d)?;
    DateTime::parse_from_rfc3339(&s)
        .map(|dt| dt.with_timezone(&Utc))
        .map_err(serde::de::Error::custom)
}

#[derive(Serialize, Deserialize)]
pub struct Event {
    #[serde(serialize_with = "serialize_datetime", deserialize_with = "deserialize_datetime")]
    pub timestamp: DateTime<Utc>,
}
```

---

## Framework Patterns: Axum

### Handler Functions

```rust
use axum::{
    extract::{Path, Query, State, Json},
    http::StatusCode,
    response::IntoResponse,
};

// Basic handler
async fn health_check() -> &'static str {
    "OK"
}

// Handler with JSON body
async fn create_task(
    State(state): State<AppState>,
    Json(payload): Json<CreateTaskRequest>,
) -> Result<impl IntoResponse, ApiError> {
    let response = state.create_task.execute(payload).await?;
    Ok((StatusCode::CREATED, Json(response)))
}

// Handler with path parameters
async fn get_task(
    State(state): State<AppState>,
    Path(task_id): Path<String>,
) -> Result<Json<TaskResponse>, ApiError> {
    let task = state.get_task.execute(&task_id).await?;
    Ok(Json(task))
}

// Handler with query parameters
#[derive(Deserialize)]
struct ListParams {
    #[serde(default)]
    status: Option<String>,
    #[serde(default = "default_limit")]
    limit: usize,
}

fn default_limit() -> usize { 100 }

async fn list_tasks(
    State(state): State<AppState>,
    Query(params): Query<ListParams>,
) -> Result<Json<ListResponse>, ApiError> {
    let tasks = state.list_tasks.execute(params).await?;
    Ok(Json(tasks))
}
```

### Router Configuration

```rust
use axum::{
    Router,
    routing::{get, post, put, delete},
    middleware,
};
use tower_http::{
    cors::CorsLayer,
    trace::TraceLayer,
    compression::CompressionLayer,
};

pub fn create_router(state: AppState) -> Router {
    let api_routes = Router::new()
        .route("/tasks", get(list_tasks).post(create_task))
        .route("/tasks/:id", get(get_task).put(update_task).delete(delete_task))
        .route("/tasks/:id/complete", put(complete_task));

    Router::new()
        .nest("/api/v1", api_routes)
        .route("/health", get(health_check))
        .layer(TraceLayer::new_for_http())
        .layer(CompressionLayer::new())
        .layer(CorsLayer::permissive())
        .with_state(state)
}
```

### Error Handling with IntoResponse

```rust
use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;

pub struct ApiError {
    status: StatusCode,
    message: String,
    code: String,
}

impl ApiError {
    pub fn bad_request(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::BAD_REQUEST,
            message: message.into(),
            code: "BAD_REQUEST".into(),
        }
    }

    pub fn not_found(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::NOT_FOUND,
            message: message.into(),
            code: "NOT_FOUND".into(),
        }
    }

    pub fn internal(message: impl Into<String>) -> Self {
        Self {
            status: StatusCode::INTERNAL_SERVER_ERROR,
            message: message.into(),
            code: "INTERNAL_ERROR".into(),
        }
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = Json(json!({
            "error": {
                "code": self.code,
                "message": self.message,
            }
        }));
        (self.status, body).into_response()
    }
}

// Convert domain errors to API errors
impl From<DomainError> for ApiError {
    fn from(err: DomainError) -> Self {
        match err {
            DomainError::EmptyDescription => Self::bad_request("Description cannot be empty"),
            DomainError::AlreadyCompleted => Self::bad_request("Task is already completed"),
            _ => Self::bad_request(err.to_string()),
        }
    }
}

impl From<RepositoryError> for ApiError {
    fn from(err: RepositoryError) -> Self {
        match err {
            RepositoryError::NotFound { .. } => Self::not_found(err.to_string()),
            _ => Self::internal("Database error"),
        }
    }
}
```

### Extractors

```rust
use axum::{
    extract::{FromRequest, FromRequestParts},
    http::request::Parts,
    async_trait,
};

// Custom extractor for authenticated user
pub struct AuthenticatedUser {
    pub user_id: String,
    pub roles: Vec<String>,
}

#[async_trait]
impl<S> FromRequestParts<S> for AuthenticatedUser
where
    S: Send + Sync,
{
    type Rejection = ApiError;

    async fn from_request_parts(parts: &mut Parts, _state: &S) -> Result<Self, Self::Rejection> {
        // Extract from Authorization header
        let auth_header = parts
            .headers
            .get("Authorization")
            .and_then(|v| v.to_str().ok())
            .ok_or_else(|| ApiError::unauthorized("Missing authorization header"))?;

        // Validate token and extract user
        let user = validate_token(auth_header)
            .map_err(|_| ApiError::unauthorized("Invalid token"))?;

        Ok(user)
    }
}

// Use in handlers
async fn get_profile(user: AuthenticatedUser) -> Json<Profile> {
    // user is automatically extracted and validated
    Json(get_user_profile(&user.user_id).await)
}
```

---

## Framework Patterns: Tauri

### Command Handlers

```rust
use tauri::{command, State};
use serde::{Deserialize, Serialize};

// Command input
#[derive(Debug, Deserialize)]
pub struct CreateTaskInput {
    pub description: String,
}

// Command output
#[derive(Debug, Serialize)]
pub struct TaskOutput {
    pub id: String,
    pub description: String,
    pub completed: bool,
}

// Result wrapper for frontend
#[derive(Debug, Serialize)]
#[serde(tag = "status", rename_all = "lowercase")]
pub enum CommandResult<T> {
    Success { data: T },
    Error { code: String, message: String },
}

impl<T> CommandResult<T> {
    pub fn success(data: T) -> Self {
        Self::Success { data }
    }

    pub fn error(code: impl Into<String>, message: impl Into<String>) -> Self {
        Self::Error {
            code: code.into(),
            message: message.into(),
        }
    }
}

// Tauri command
#[command]
pub async fn create_task(
    input: CreateTaskInput,
    state: State<'_, AppState>,
) -> CommandResult<TaskOutput> {
    match state.create_task.execute(input.description).await {
        Ok(task) => CommandResult::success(TaskOutput {
            id: task.id().to_string(),
            description: task.description().to_string(),
            completed: task.is_completed(),
        }),
        Err(e) => CommandResult::error("CREATE_FAILED", e.to_string()),
    }
}

#[command]
pub async fn list_tasks(state: State<'_, AppState>) -> CommandResult<Vec<TaskOutput>> {
    match state.list_tasks.execute().await {
        Ok(tasks) => CommandResult::success(
            tasks.into_iter().map(|t| TaskOutput {
                id: t.id().to_string(),
                description: t.description().to_string(),
                completed: t.is_completed(),
            }).collect()
        ),
        Err(e) => CommandResult::error("LIST_FAILED", e.to_string()),
    }
}

#[command]
pub async fn complete_task(
    task_id: String,
    state: State<'_, AppState>,
) -> CommandResult<TaskOutput> {
    match state.complete_task.execute(&task_id).await {
        Ok(task) => CommandResult::success(TaskOutput {
            id: task.id().to_string(),
            description: task.description().to_string(),
            completed: task.is_completed(),
        }),
        Err(e) => CommandResult::error("COMPLETE_FAILED", e.to_string()),
    }
}
```

### State Setup

```rust
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct AppState {
    pub create_task: CreateTaskUseCase,
    pub list_tasks: ListTasksUseCase,
    pub complete_task: CompleteTaskUseCase,
}

impl AppState {
    pub async fn new(db_path: &str) -> anyhow::Result<Self> {
        let pool = sqlx::sqlite::SqlitePoolOptions::new()
            .max_connections(5)
            .connect(&format!("sqlite:{}?mode=rwc", db_path))
            .await?;

        infrastructure::run_migrations(&pool).await?;

        let repository = Arc::new(SqlxTaskRepository::new(pool));

        Ok(Self {
            create_task: CreateTaskUseCase::new(Arc::clone(&repository)),
            list_tasks: ListTasksUseCase::new(Arc::clone(&repository)),
            complete_task: CompleteTaskUseCase::new(Arc::clone(&repository)),
        })
    }
}
```

### Main Entry Point

```rust
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

mod commands;
mod state;

use state::AppState;
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .setup(|app| {
            let handle = app.handle().clone();

            // Initialize state asynchronously
            tauri::async_runtime::spawn(async move {
                let app_dir = handle
                    .path()
                    .app_data_dir()
                    .expect("Failed to get app data dir");

                std::fs::create_dir_all(&app_dir).expect("Failed to create app dir");
                let db_path = app_dir.join("tasks.db");

                match AppState::new(db_path.to_str().unwrap()).await {
                    Ok(state) => {
                        handle.manage(state);
                        tracing::info!("App state initialized");
                    }
                    Err(e) => {
                        tracing::error!("Failed to initialize: {}", e);
                        std::process::exit(1);
                    }
                }
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
```

### Frontend Integration (TypeScript)

```typescript
// src/api/tasks.ts
import { invoke } from '@tauri-apps/api/core';

interface Task {
  id: string;
  description: string;
  completed: boolean;
}

type Result<T> =
  | { status: 'success'; data: T }
  | { status: 'error'; code: string; message: string };

async function invokeCommand<T>(cmd: string, args?: object): Promise<T> {
  const result = await invoke<Result<T>>(cmd, args);

  if (result.status === 'error') {
    throw new Error(`${result.code}: ${result.message}`);
  }

  return result.data;
}

export async function createTask(description: string): Promise<Task> {
  return invokeCommand('create_task', { input: { description } });
}

export async function listTasks(): Promise<Task[]> {
  return invokeCommand('list_tasks');
}

export async function completeTask(taskId: string): Promise<Task> {
  return invokeCommand('complete_task', { taskId });
}
```

---

## Performance Patterns

### Avoiding Allocations

```rust
// WRONG - Unnecessary allocation
fn process(data: &str) {
    let owned = data.to_string();  // Allocates!
    do_something(&owned);
}

// RIGHT - Work with borrowed data
fn process(data: &str) {
    do_something(data);  // No allocation
}

// Use Cow for conditional ownership
use std::borrow::Cow;

fn process_or_transform(data: &str) -> Cow<'_, str> {
    if needs_transformation(data) {
        Cow::Owned(transform(data))  // Allocates only when needed
    } else {
        Cow::Borrowed(data)  // No allocation
    }
}
```

### Connection Pooling

```rust
use sqlx::{Pool, Sqlite, sqlite::SqlitePoolOptions};

pub async fn create_pool(database_url: &str) -> Result<Pool<Sqlite>, sqlx::Error> {
    SqlitePoolOptions::new()
        .max_connections(10)
        .min_connections(2)
        .acquire_timeout(Duration::from_secs(5))
        .idle_timeout(Duration::from_secs(600))
        .max_lifetime(Duration::from_secs(1800))
        .connect(database_url)
        .await
}
```

### Lazy Initialization

```rust
use std::sync::OnceLock;

// Global lazy initialization
static CONFIG: OnceLock<Config> = OnceLock::new();

pub fn get_config() -> &'static Config {
    CONFIG.get_or_init(|| {
        Config::from_env().expect("Failed to load config")
    })
}

// Local lazy initialization
use once_cell::sync::Lazy;

static REGEX: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap()
});

fn is_date_format(s: &str) -> bool {
    REGEX.is_match(s)
}
```

### Efficient String Building

```rust
// WRONG - O(n^2) concatenation
let mut result = String::new();
for item in items {
    result = result + &item.to_string();  // Reallocates each time!
}

// RIGHT - O(n) with push_str
let mut result = String::with_capacity(estimated_size);
for item in items {
    result.push_str(&item.to_string());
}

// BETTER - Use iterators
let result: String = items
    .iter()
    .map(|item| item.to_string())
    .collect();

// BEST for joining with separator
let result = items
    .iter()
    .map(|item| item.to_string())
    .collect::<Vec<_>>()
    .join(", ");
```

---

## Security Patterns

### Input Validation

```rust
use validator::{Validate, ValidationError};

#[derive(Debug, Validate, Deserialize)]
pub struct CreateUserRequest {
    #[validate(email)]
    pub email: String,

    #[validate(length(min = 8, max = 128))]
    pub password: String,

    #[validate(length(min = 1, max = 100))]
    pub name: String,

    #[validate(custom = "validate_username")]
    pub username: String,
}

fn validate_username(username: &str) -> Result<(), ValidationError> {
    let valid = username
        .chars()
        .all(|c| c.is_alphanumeric() || c == '_' || c == '-');

    if !valid {
        return Err(ValidationError::new("invalid_username"));
    }
    Ok(())
}

// In handler
async fn create_user(Json(payload): Json<CreateUserRequest>) -> Result<Json<User>, ApiError> {
    payload.validate()
        .map_err(|e| ApiError::bad_request(format!("Validation failed: {}", e)))?;

    // Process validated input
}
```

### Secret Management with secrecy

```rust
use secrecy::{ExposeSecret, Secret};

pub struct Config {
    pub database_url: String,
    pub api_key: Secret<String>,  // Won't be printed in logs
}

impl Config {
    pub fn from_env() -> Result<Self, ConfigError> {
        Ok(Self {
            database_url: std::env::var("DATABASE_URL")?,
            api_key: Secret::new(std::env::var("API_KEY")?),
        })
    }
}

// Using the secret
fn make_api_call(config: &Config) {
    let key = config.api_key.expose_secret();  // Explicit exposure
    // Use key...
}

// Debug output won't leak secret
println!("{:?}", config);  // api_key shows as "Secret([REDACTED])"
```

### SQL Injection Prevention

```rust
// WRONG - String interpolation
let query = format!("SELECT * FROM users WHERE id = '{}'", user_id);

// RIGHT - Parameterized queries with SQLx
let user: Option<User> = sqlx::query_as(
    "SELECT * FROM users WHERE id = $1"
)
.bind(&user_id)  // Properly escaped
.fetch_optional(&pool)
.await?;

// Also RIGHT - Using query macros for compile-time verification
let user = sqlx::query_as!(
    User,
    "SELECT id, name, email FROM users WHERE id = $1",
    user_id
)
.fetch_optional(&pool)
.await?;
```

---

## Common Crate Recommendations

### Core Dependencies

| Purpose | Crate | Notes |
|---------|-------|-------|
| Async runtime | `tokio` | Full-featured async runtime |
| Async utilities | `tokio-util` | TaskTracker, CancellationToken |
| Serialization | `serde`, `serde_json` | De-facto standard |
| Error handling | `thiserror`, `anyhow` | Library vs application errors |
| Error handling | `snafu` | Rich context for large systems |
| Date/time | `chrono` | Comprehensive datetime handling |
| UUIDs | `uuid` | UUID generation and parsing |
| HTTP client | `reqwest` | Async HTTP with good defaults |
| Logging | `tracing` | Structured logging |
| Configuration | `config` | Multi-source configuration |

### Web Development

| Purpose | Crate | Notes |
|---------|-------|-------|
| Web framework | `axum` | Modern, type-safe, tower-based |
| Database | `sqlx` | Compile-time checked SQL |
| Validation | `validator` | Derive-based validation |
| CORS | `tower-http` | Tower middleware ecosystem |

### Desktop Development

| Purpose | Crate | Notes |
|---------|-------|-------|
| Desktop framework | `tauri` | Tauri v2 - lightweight Electron alternative |
| Type-safe bindings | `tauri-specta` | Auto-generate TypeScript types |
| Type export | `specta` | Rust→TypeScript type generation |
| State | `tauri::State` | App-wide state management |

### Testing

| Purpose | Crate | Notes |
|---------|-------|-------|
| Mocking | `mockall` | Powerful trait mocking |
| Property testing | `proptest` | Property-based testing |
| Snapshot testing | `insta` | Output comparison testing |
| Fixtures | `rstest` | Test fixtures and parametrization |
| Assertions | `assert_matches` | Pattern matching assertions |

---

## Summary

Rust's type system and ownership model provide powerful tools for building safe, performant applications:

- **Newtype pattern** prevents type confusion at compile time
- **Result/thiserror** make error handling explicit and composable
- **async_trait** enables clean async abstractions
- **mockall/proptest** provide comprehensive testing capabilities
- **Axum/Tauri** integrate seamlessly with Clean Architecture

The key is leveraging Rust's strengths: zero-cost abstractions, memory safety without garbage collection, and fearless concurrency.
