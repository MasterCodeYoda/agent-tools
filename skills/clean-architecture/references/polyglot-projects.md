# Polyglot Projects Reference

This guide covers Clean Architecture patterns for projects spanning multiple languages, typically combining a backend language (Rust, Python, C#) with a frontend (TypeScript/React).

## Project Structure Patterns

### Monorepo Organization

Polyglot projects benefit from monorepo structure with clear language separation:

```
project/
├── apps/                    # Runnable applications
│   ├── desktop/             # Tauri app (Rust + TypeScript)
│   ├── api/                 # Backend API (Rust/Python/C#)
│   └── web/                 # Web frontend (TypeScript)
│
├── packages/                # Shared TypeScript packages
│   ├── contracts/           # Generated types from backend
│   ├── domain/              # TypeScript domain logic
│   ├── ui/                  # Shared UI components
│   └── editor/              # Feature-specific packages
│
├── crates/                  # Rust workspace (if using Rust)
│   ├── project-domain/      # Domain layer
│   ├── project-application/ # Application layer
│   └── project-infrastructure/ # Infrastructure layer
│
├── libs/                    # Shared non-TypeScript libraries
│   └── python/              # Python packages (if using Python)
│
├── tools/                   # Build and development scripts
└── docs/                    # Documentation
```

### When to Use Each Directory

| Directory | Purpose | Contains |
|-----------|---------|----------|
| `apps/` | Runnable applications | Entry points, framework configuration |
| `packages/` | Shared TypeScript code | Reusable across apps |
| `crates/` | Rust workspace members | Domain, Application, Infrastructure |
| `libs/` | Shared non-TS libraries | Python packages, C# projects |
| `tools/` | Development utilities | Scripts, generators, validators |

### Naming Conventions

**Tauri Applications:**
```
apps/desktop/
├── src-tauri/               # Rust backend (matches Tauri convention)
│   ├── src/
│   │   ├── commands/        # Tauri command handlers
│   │   ├── state.rs         # DI wiring
│   │   └── paths.rs         # Environment-aware paths
│   └── Cargo.toml
└── src-react/               # React frontend (or src-vue/, src-svelte/)
    ├── src/
    └── package.json
```

The `src-{framework}` pattern creates naming parity between frontend and backend source directories.

## Type Generation Pipeline

### Why Type Generation?

In polyglot projects, data structures cross language boundaries. Type generation ensures:
- **Type safety** across the boundary
- **Single source of truth** (backend defines, frontend consumes)
- **Automatic updates** when types change

### Specta (Rust → TypeScript)

For Rust backends with TypeScript frontends, [Specta](https://github.com/oscartbeaumont/specta) generates TypeScript types from Rust structs.

**Setup:**

```toml
# Cargo.toml
[dependencies]
specta = { version = "2", features = ["export"] }
tauri-specta = { version = "2", features = ["typescript"] }  # For Tauri
```

**Derive types:**

```rust
use specta::Type;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, Type)]
pub struct WorkspaceInfo {
    pub id: String,
    pub name: String,
    pub path: String,
    pub created_at: String,
}
```

**Export during build:**

```rust
// build.rs or during app startup
#[cfg(debug_assertions)]
fn export_types() {
    specta_typescript::Typescript::default()
        .export_to("../packages/contracts/generated/types.ts")
        .expect("Failed to export types");
}
```

**Generated output:**

```typescript
// packages/contracts/generated/types.ts
// Auto-generated - do not edit

export interface WorkspaceInfo {
    id: string;
    name: string;
    path: string;
    created_at: string;
}
```

### JSON Schema (Language-Agnostic)

For projects with more than two languages, JSON Schema serves as a universal intermediate format.

**Workflow:**
1. Define schemas in JSON Schema format
2. Generate types for each language using language-specific tools
3. Validate data at runtime using schema validators

**Tools by language:**
- TypeScript: `json-schema-to-typescript`, `zod` (with `zod-to-json-schema`)
- Python: `datamodel-code-generator`, `pydantic`
- Rust: `schemars`, `typify`
- C#: `NJsonSchema`

### Type Generation Strategy Decision Tree

```
Do you have a primary backend language?
├── YES: Use that language as source of truth
│   ├── Rust → TypeScript: Use Specta
│   ├── Python → TypeScript: Use pydantic + datamodel-codegen
│   └── C# → TypeScript: Use NSwag or TypeScript generator
│
└── NO: Multiple backends or language-agnostic requirement
    └── Use JSON Schema as intermediate format
        ├── Define schemas in /schemas/*.json
        ├── Generate types for each language in CI
        └── Validate at runtime boundaries
```

### Build Integration

Add type generation to your build process:

```json
// package.json
{
  "scripts": {
    "generate:types": "cargo build && cp target/generated/*.ts packages/contracts/generated/",
    "prebuild": "pnpm generate:types",
    "predev": "pnpm generate:types"
  }
}
```

## Three-Package/Crate Architecture

### Compile-Time Layer Enforcement

Separate packages/crates enforce Clean Architecture dependencies at compile time:

**Rust (Cargo workspace):**
```
crates/
├── project-domain/           # No internal dependencies
├── project-application/      # Depends on: domain
└── project-infrastructure/   # Depends on: application, domain
```

**TypeScript (npm/pnpm workspace):**
```
packages/
├── domain/                   # No internal dependencies
├── application/              # Depends on: @project/domain
└── infrastructure/           # Depends on: @project/application
```

### Dependency Configuration

**Rust Cargo.toml:**

```toml
# crates/project-domain/Cargo.toml
[package]
name = "project-domain"
# No project dependencies - only external crates

[dependencies]
chrono = { workspace = true }
uuid = { workspace = true }
thiserror = { workspace = true }
```

```toml
# crates/project-application/Cargo.toml
[package]
name = "project-application"

[dependencies]
project-domain = { path = "../project-domain" }
async-trait = { workspace = true }
```

```toml
# crates/project-infrastructure/Cargo.toml
[package]
name = "project-infrastructure"

[dependencies]
project-domain = { path = "../project-domain" }
project-application = { path = "../project-application" }
sqlx = { workspace = true }
tokio = { workspace = true }
```

**TypeScript package.json:**

```json
// packages/application/package.json
{
  "name": "@project/application",
  "dependencies": {
    "@project/domain": "workspace:*"
  }
}
```

### Single vs Multi-Package Tradeoffs

| Aspect | Single Package | Multi-Package |
|--------|---------------|---------------|
| **Dependency enforcement** | Requires discipline | Compile-time errors |
| **Build speed** | Faster (one compilation unit) | Slower (multiple units) |
| **Parallelization** | N/A | Crates build in parallel |
| **Refactoring** | Easier (one project) | More ceremony |
| **Team scaling** | Harder to maintain boundaries | Clear ownership |

**Recommendation:** Use multi-package when:
- Team has 3+ developers
- Project will live >6 months
- Strict architectural compliance required
- Multiple applications share domain logic

## Service Abstractions in Application Layer

### The Pattern

Service abstractions (repository traits, gateway interfaces) belong in the **application layer**, colocated with use cases:

```
crates/project-application/src/
├── workspace/
│   ├── mod.rs                    # Re-exports
│   ├── services.rs               # WorkspaceRepository trait + errors
│   ├── initialize.rs             # InitializeWorkspaceUseCase
│   ├── create.rs                 # CreateWorkspaceUseCase
│   └── get.rs                    # GetWorkspaceUseCase
└── lib.rs
```

### Why Application Layer, Not Domain?

**Closer to consumers:**
- Use cases consume these abstractions
- Changes to use case needs are reflected locally
- Reduces coupling between domain and infrastructure

**Clearer ownership:**
- Each bounded context owns its service definitions
- No "shared ports" package to maintain
- Dependencies are explicit in the module

**Avoids "ports" terminology:**
- The term "ports" from hexagonal architecture can confuse
- "Services" is more intuitive for most developers
- Focus on what it does (repository for workspaces) not architectural role

### Implementation Example

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

#[async_trait]
pub trait WorkspaceRepository: Send + Sync {
    async fn save(&self, workspace: &Workspace) -> Result<(), WorkspaceError>;
    async fn find_by_path(&self, path: &Path) -> Result<Option<Workspace>, WorkspaceError>;
    async fn exists(&self, path: &Path) -> Result<bool, WorkspaceError>;
}
```

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

        // Persist
        self.repository.save(&workspace).await?;

        Ok(InitializeWorkspaceResponse {
            workspace_id: workspace.id().to_string(),
            path: request.path,
        })
    }
}
```

## Framework Layer Patterns

### Thin Adapter Pattern

Framework layers (Tauri commands, NestJS controllers, Axum handlers) should be thin adapters:

1. **Parse/validate input** (framework-specific DTOs)
2. **Call use case** (framework-agnostic)
3. **Map response** (to framework format)
4. **Handle errors** (map to framework error responses)

### Tauri Commands (Desktop)

```rust
// apps/desktop/src-tauri/src/commands/workspace.rs
use tauri::State;
use project_application::workspace::{
    InitializeWorkspaceUseCase,
    InitializeWorkspaceRequest,
};
use crate::state::AppState;

#[tauri::command]
pub async fn initialize_workspace(
    path: String,
    name: String,
    state: State<'_, AppState>,
) -> Result<WorkspaceResponse, CommandError> {
    // 1. Create request
    let request = InitializeWorkspaceRequest {
        path: path.into(),
        name,
    };

    // 2. Call use case
    let response = state
        .initialize_workspace
        .execute(request)
        .await
        .map_err(CommandError::from)?;

    // 3. Map to response DTO
    Ok(WorkspaceResponse {
        id: response.workspace_id,
        path: response.path.display().to_string(),
    })
}
```

### NestJS Controllers (Backend API)

```typescript
// apps/api/src/workspace/workspace.controller.ts
@Controller('workspaces')
export class WorkspaceController {
  constructor(
    private readonly initializeWorkspace: InitializeWorkspaceUseCase,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateWorkspaceDto): Promise<WorkspaceResponse> {
    // 1. Create request
    const request = {
      path: dto.path,
      name: dto.name,
    };

    // 2. Call use case
    const result = await this.initializeWorkspace.execute(request);

    // 3. Handle result
    if (!result.success) {
      throw new DomainException(result.error);
    }

    // 4. Map to response
    return {
      id: result.value.workspaceId,
      path: result.value.path,
    };
  }
}
```

### Dependency Injection Wiring

**Tauri (state.rs):**

```rust
// apps/desktop/src-tauri/src/state.rs
use std::sync::Arc;
use project_application::workspace::InitializeWorkspaceUseCase;
use project_infrastructure::filesystem::FileSystemWorkspaceRepository;

pub struct AppState {
    pub initialize_workspace: InitializeWorkspaceUseCase<Arc<FileSystemWorkspaceRepository>>,
}

impl AppState {
    pub fn new(base_path: PathBuf) -> Self {
        let workspace_repo = Arc::new(FileSystemWorkspaceRepository::new(base_path));

        Self {
            initialize_workspace: InitializeWorkspaceUseCase::new(workspace_repo.clone()),
        }
    }
}
```

**NestJS (module):**

```typescript
// apps/api/src/workspace/workspace.module.ts
@Module({
  providers: [
    InitializeWorkspaceUseCase,
    {
      provide: WORKSPACE_REPOSITORY,
      useClass: PrismaWorkspaceRepository,
    },
  ],
  controllers: [WorkspaceController],
})
export class WorkspaceModule {}
```

## Infrastructure Organization

### By Provider vs By Context

Two valid approaches for organizing infrastructure:

**Provider-based (recommended for many external systems):**
```
infrastructure/
├── postgres/
│   ├── workspace_repository.rs
│   ├── user_repository.rs
│   └── connection.rs
├── redis/
│   ├── cache_repository.rs
│   └── connection.rs
├── s3/
│   └── file_storage.rs
└── email/
    └── smtp_gateway.rs
```

**Context-based (recommended for domain-heavy projects):**
```
infrastructure/
├── workspace/
│   ├── filesystem_repository.rs
│   └── postgres_repository.rs
├── user/
│   ├── postgres_repository.rs
│   └── redis_cache.rs
└── shared/
    └── connections.rs
```

### Decision Tree

```
How many external systems do you integrate with?
├── Few (1-2 databases, maybe cache)
│   └── Use context-based organization
│       - Keeps related implementations together
│       - Easier navigation by feature
│
└── Many (multiple databases, caches, APIs, queues)
    └── Use provider-based organization
        - Groups similar connection/configuration code
        - Easier to swap providers
        - Clear technology boundaries
```

## Environment-Aware Paths

### The Pattern

Development and production environments need different paths to isolate data:

| Environment | Workspaces | Settings |
|-------------|------------|----------|
| Development | `{project}/.data/workspaces/` | `{project}/.data/settings/` |
| Production | `~/Inklings/Workspaces/` | `~/Library/Application Support/Inklings/` |

### Implementation

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
            workspaces: home.join("Inklings/Workspaces"),
            settings: dirs::config_dir()
                .expect("No config dir")
                .join("Inklings"),
        }
    }
}
```

### Gitignore

```gitignore
# Development data (environment-isolated)
.data/
```

## Shared Contracts Package

### Purpose

The contracts package provides a single source of truth for:
- Generated types from backend
- Shared type definitions
- API contracts

### Structure

```
packages/contracts/
├── generated/               # Auto-generated from backend
│   ├── types.ts            # Specta output
│   └── index.ts            # Re-exports
├── src/
│   ├── api/                # API contract definitions
│   │   └── workspace.ts
│   └── index.ts
├── package.json
└── tsconfig.json
```

### Usage

```typescript
// In frontend application
import { WorkspaceInfo } from '@project/contracts';
import type { InitializeWorkspaceRequest } from '@project/contracts/api';
```

### Build Order

Ensure contracts are built before dependent packages:

```json
// turbo.json
{
  "pipeline": {
    "generate:types": {
      "outputs": ["packages/contracts/generated/**"]
    },
    "build": {
      "dependsOn": ["generate:types", "^build"]
    }
  }
}
```

## Monorepo Tooling

### Turborepo (TypeScript)

```json
// turbo.json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "typecheck": {
      "dependsOn": ["^build"]
    },
    "lint": {}
  }
}
```

### Cargo Workspace (Rust)

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
# Centralized dependency versions
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }
thiserror = "1"
async-trait = "0.1"
```

### Combined Workflow

```json
// package.json (root)
{
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "typecheck": "turbo run typecheck",
    "lint": "turbo run lint && cargo clippy --workspace",
    "test": "turbo run test && cargo test --workspace",
    "generate:types": "cargo build -p project-domain && pnpm --filter @project/contracts generate"
  }
}
```

## Summary

Polyglot Clean Architecture projects succeed by:

1. **Clear directory structure** - Separate apps/, packages/, crates/ by language
2. **Type generation pipeline** - Single source of truth, auto-generated consumers
3. **Compile-time enforcement** - Separate packages/crates per layer
4. **Service abstractions in application** - Colocated with use cases
5. **Thin framework adapters** - Commands/controllers just wire things together
6. **Environment isolation** - Dev and prod paths don't collide
7. **Shared contracts** - One package for cross-language type definitions
