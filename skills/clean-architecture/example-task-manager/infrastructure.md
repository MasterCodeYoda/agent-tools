# Infrastructure Layer - Task Manager Example

## Overview

The Infrastructure layer provides concrete implementations for the interfaces defined in inner layers. It handles all I/O operations: databases, file systems, external services, and more.

## Core Concepts

### Repository Implementations

Implements the repository interfaces defined in Domain layer:
- Handles persistence (database, file, memory)
- Maps between domain entities and storage models
- Manages transactions

## Implementation Across Languages

### Python Implementation

```python
# infrastructure/repositories/in_memory_task_repository.py

from typing import Optional, List, Dict
from domain.entities import Task
from domain.repositories import TaskRepository

class InMemoryTaskRepository(TaskRepository):
    """In-memory implementation of TaskRepository."""

    def __init__(self):
        self._tasks: Dict[str, Task] = {}

    async def save(self, task: Task) -> None:
        """Save a task to memory."""
        # In real implementation, you'd clone to prevent external modification
        self._tasks[task.id] = task

    async def find_by_id(self, task_id: str) -> Optional[Task]:
        """Find a task by ID."""
        return self._tasks.get(task_id)

    async def find_all(self) -> List[Task]:
        """Get all tasks."""
        return list(self._tasks.values())

    async def delete(self, task_id: str) -> None:
        """Delete a task."""
        if task_id in self._tasks:
            del self._tasks[task_id]
```

```python
# infrastructure/repositories/sqlalchemy_task_repository.py

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from typing import Optional, List

from domain.entities import Task
from domain.repositories import TaskRepository
from .models import TaskModel

class SqlAlchemyTaskRepository(TaskRepository):
    """SQLAlchemy implementation of TaskRepository."""

    def __init__(self, session: AsyncSession):
        self._session = session

    async def save(self, task: Task) -> None:
        """Save a task to database."""
        # Check if exists
        stmt = select(TaskModel).where(TaskModel.id == task.id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if model:
            # Update existing
            self._update_model(model, task)
        else:
            # Create new
            model = self._to_model(task)
            self._session.add(model)

        await self._session.commit()

    async def find_by_id(self, task_id: str) -> Optional[Task]:
        """Find a task by ID."""
        stmt = select(TaskModel).where(TaskModel.id == task_id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if not model:
            return None

        return self._to_domain(model)

    async def find_all(self) -> List[Task]:
        """Get all tasks."""
        stmt = select(TaskModel).order_by(TaskModel.created_at.desc())
        result = await self._session.execute(stmt)
        models = result.scalars().all()

        return [self._to_domain(model) for model in models]

    async def delete(self, task_id: str) -> None:
        """Delete a task."""
        stmt = delete(TaskModel).where(TaskModel.id == task_id)
        await self._session.execute(stmt)
        await self._session.commit()

    def _to_domain(self, model: TaskModel) -> Task:
        """Convert database model to domain entity."""
        # Reconstruct domain entity from database
        task = Task.__new__(Task)  # Skip __init__
        task._id = model.id
        task.description = model.description
        task._completed = model.completed
        task._created_at = model.created_at
        task._completed_at = model.completed_at
        return task

    def _to_model(self, task: Task) -> TaskModel:
        """Convert domain entity to database model."""
        return TaskModel(
            id=task.id,
            description=task.description,
            completed=task.is_completed,
            created_at=task.created_at,
            completed_at=task.completed_at
        )

    def _update_model(self, model: TaskModel, task: Task) -> None:
        """Update database model from domain entity."""
        model.description = task.description
        model.completed = task.is_completed
        model.completed_at = task.completed_at
```

```python
# infrastructure/repositories/models.py

from sqlalchemy import Column, String, Boolean, DateTime
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class TaskModel(Base):
    """SQLAlchemy model for tasks."""
    __tablename__ = "tasks"

    id = Column(String, primary_key=True)
    description = Column(String(500), nullable=False)
    completed = Column(Boolean, default=False, nullable=False)
    created_at = Column(DateTime, nullable=False)
    completed_at = Column(DateTime, nullable=True)
```

### TypeScript Implementation

```typescript
// infrastructure/repositories/InMemoryTaskRepository.ts

import { Task } from "../../domain/entities/Task";
import { TaskRepository } from "../../domain/repositories/TaskRepository";

export class InMemoryTaskRepository implements TaskRepository {
  private tasks: Map<string, Task> = new Map();

  async save(task: Task): Promise<void> {
    this.tasks.set(task.id, task);
  }

  async findById(id: string): Promise<Task | null> {
    return this.tasks.get(id) || null;
  }

  async findAll(): Promise<Task[]> {
    return Array.from(this.tasks.values());
  }

  async delete(id: string): Promise<void> {
    this.tasks.delete(id);
  }
}
```

```typescript
// infrastructure/repositories/TypeOrmTaskRepository.ts

import { Repository } from "typeorm";
import { Task } from "../../domain/entities/Task";
import { TaskRepository } from "../../domain/repositories/TaskRepository";
import { TaskEntity } from "./entities/TaskEntity";

export class TypeOrmTaskRepository implements TaskRepository {
  constructor(private readonly ormRepository: Repository<TaskEntity>) {}

  async save(task: Task): Promise<void> {
    const entity = this.toEntity(task);
    await this.ormRepository.save(entity);
  }

  async findById(id: string): Promise<Task | null> {
    const entity = await this.ormRepository.findOne({ where: { id } });
    return entity ? this.toDomain(entity) : null;
  }

  async findAll(): Promise<Task[]> {
    const entities = await this.ormRepository.find({
      order: { createdAt: "DESC" }
    });
    return entities.map(entity => this.toDomain(entity));
  }

  async delete(id: string): Promise<void> {
    await this.ormRepository.delete(id);
  }

  private toDomain(entity: TaskEntity): Task {
    // Reconstruct domain object from persistence
    const task = new Task(entity.description, entity.id);
    // Use reflection or other means to set private fields
    // This is a limitation of TypeScript - consider factory pattern
    return task;
  }

  private toEntity(task: Task): TaskEntity {
    const entity = new TaskEntity();
    entity.id = task.id;
    entity.description = task.description;
    entity.completed = task.isCompleted;
    entity.createdAt = task.createdAt;
    entity.completedAt = task.completedAt;
    return entity;
  }
}
```

### C# Implementation

```csharp
// Infrastructure/Repositories/InMemoryTaskRepository.cs

using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using TaskManager.Domain.Entities;
using TaskManager.Domain.Repositories;

namespace TaskManager.Infrastructure.Repositories
{
    public class InMemoryTaskRepository : ITaskRepository
    {
        private readonly Dictionary<string, Domain.Entities.Task> _tasks = new();

        public Task SaveAsync(Domain.Entities.Task task)
        {
            _tasks[task.Id] = task;
            return Task.CompletedTask;
        }

        public Task<Domain.Entities.Task?> FindByIdAsync(string id)
        {
            _tasks.TryGetValue(id, out var task);
            return Task.FromResult(task);
        }

        public Task<List<Domain.Entities.Task>> FindAllAsync()
        {
            var tasks = _tasks.Values.ToList();
            return Task.FromResult(tasks);
        }

        public Task DeleteAsync(string id)
        {
            _tasks.Remove(id);
            return Task.CompletedTask;
        }
    }
}
```

### Rust Implementation

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

    async fn delete(&self, id: &TaskId) -> Result<(), RepositoryError> {
        sqlx::query("DELETE FROM tasks WHERE id = ?")
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;

        Ok(())
    }
}
```

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

    async fn delete(&self, id: &TaskId) -> Result<(), RepositoryError> {
        let mut tasks = self.tasks.write().unwrap();
        tasks.remove(&id.to_string());
        Ok(())
    }
}
```

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

    sqlx::query("CREATE INDEX IF NOT EXISTS idx_tasks_completed ON tasks(completed)")
        .execute(pool)
        .await?;

    Ok(())
}
```

## Key Infrastructure Patterns

### 1. Mapping Between Layers

```python
def _to_domain(self, model: TaskModel) -> Task:
    """Database → Domain"""
    # Reconstruct domain entity preserving encapsulation
    task = Task.__new__(Task)
    task._id = model.id
    # ... map other fields
    return task

def _to_model(self, task: Task) -> TaskModel:
    """Domain → Database"""
    return TaskModel(
        id=task.id,
        description=task.description,
        # ... map other fields
    )
```

### 2. Transaction Management

```python
class SqlAlchemyTaskRepository:
    async def save_batch(self, tasks: List[Task]) -> None:
        """Save multiple tasks in a transaction."""
        async with self._session.begin():
            for task in tasks:
                model = self._to_model(task)
                self._session.add(model)
            # Commits automatically if no exception
```

### 3. Query Optimization

```python
async def find_with_pagination(
    self,
    limit: int,
    offset: int
) -> Tuple[List[Task], int]:
    """Find tasks with pagination."""
    # Count query
    count_stmt = select(func.count()).select_from(TaskModel)
    total = await self._session.scalar(count_stmt)

    # Data query
    stmt = (
        select(TaskModel)
        .order_by(TaskModel.created_at.desc())
        .limit(limit)
        .offset(offset)
    )
    result = await self._session.execute(stmt)
    models = result.scalars().all()

    tasks = [self._to_domain(model) for model in models]
    return tasks, total
```

### 4. Caching Strategy

```python
class CachedTaskRepository(TaskRepository):
    """Repository with caching."""

    def __init__(self, repository: TaskRepository, cache: Cache):
        self._repository = repository
        self._cache = cache

    async def find_by_id(self, task_id: str) -> Optional[Task]:
        # Try cache first
        cache_key = f"task:{task_id}"
        cached = await self._cache.get(cache_key)
        if cached:
            return self._deserialize(cached)

        # Fetch from repository
        task = await self._repository.find_by_id(task_id)
        if task:
            await self._cache.set(cache_key, self._serialize(task))

        return task

    async def save(self, task: Task) -> None:
        # Save to repository
        await self._repository.save(task)

        # Invalidate cache
        cache_key = f"task:{task.id}"
        await self._cache.delete(cache_key)
```

## Evolution Examples

### Adding Database Migrations

```python
# infrastructure/migrations/001_create_tasks.py

from alembic import op
import sqlalchemy as sa

def upgrade():
    op.create_table(
        'tasks',
        sa.Column('id', sa.String(36), primary_key=True),
        sa.Column('description', sa.String(500), nullable=False),
        sa.Column('completed', sa.Boolean, default=False),
        sa.Column('created_at', sa.DateTime, nullable=False),
        sa.Column('completed_at', sa.DateTime, nullable=True),
    )
    op.create_index('idx_tasks_completed', 'tasks', ['completed'])
    op.create_index('idx_tasks_created_at', 'tasks', ['created_at'])

def downgrade():
    op.drop_table('tasks')
```

### Adding External Service Gateway

```python
# infrastructure/gateways/notification_gateway.py

import httpx
from application.services import NotificationService

class EmailNotificationGateway(NotificationService):
    """Email notification gateway implementation."""

    def __init__(self, api_key: str, api_url: str):
        self._api_key = api_key
        self._api_url = api_url
        self._client = httpx.AsyncClient()

    async def send_task_completed(
        self,
        user_email: str,
        task_description: str
    ) -> None:
        """Send task completion notification."""
        payload = {
            "to": user_email,
            "subject": "Task Completed!",
            "body": f"Your task '{task_description}' has been completed."
        }

        headers = {"Authorization": f"Bearer {self._api_key}"}

        response = await self._client.post(
            f"{self._api_url}/send",
            json=payload,
            headers=headers
        )
        response.raise_for_status()

    async def close(self):
        await self._client.aclose()
```

## Testing the Infrastructure Layer

```python
import pytest
from infrastructure.repositories import SqlAlchemyTaskRepository
from domain.entities import Task

@pytest.fixture
async def test_repository(test_db_session):
    """Create repository with test database."""
    return SqlAlchemyTaskRepository(test_db_session)

@pytest.mark.asyncio
async def test_save_and_find(test_repository):
    # Create domain entity
    task = Task("Test task")

    # Save
    await test_repository.save(task)

    # Find
    found = await test_repository.find_by_id(task.id)

    # Assert
    assert found is not None
    assert found.id == task.id
    assert found.description == "Test task"

@pytest.mark.asyncio
async def test_find_all(test_repository):
    # Create multiple tasks
    tasks = [
        Task(f"Task {i}")
        for i in range(3)
    ]

    # Save all
    for task in tasks:
        await test_repository.save(task)

    # Find all
    all_tasks = await test_repository.find_all()

    # Assert
    assert len(all_tasks) == 3
```

## Common Mistakes to Avoid

### 1. Leaking ORM Entities

```python
# ❌ BAD - Exposing ORM entity
class SqlTaskRepository:
    async def find_by_id(self, task_id: str) -> TaskModel:  # ORM model!
        return await self._session.get(TaskModel, task_id)

# ✅ GOOD - Return domain entity
class SqlTaskRepository:
    async def find_by_id(self, task_id: str) -> Task:  # Domain entity
        model = await self._session.get(TaskModel, task_id)
        return self._to_domain(model)
```

### 2. Business Logic in Repository

```python
# ❌ BAD - Business logic in repository
class TaskRepository:
    async def complete_task(self, task_id: str):
        # Repository shouldn't know business rules!
        task = await self.find_by_id(task_id)
        if task.completed:
            raise ValueError("Already completed")
        task.completed = True

# ✅ GOOD - Repository just persists
class TaskRepository:
    async def save(self, task: Task):
        # Just save, no business logic
        model = self._to_model(task)
        await self._session.save(model)
```

### 3. Tight Coupling to Database

```python
# ❌ BAD - SQL in domain/application
class GetTasksUseCase:
    async def execute(self):
        return db.execute("SELECT * FROM tasks")  # SQL leak!

# ✅ GOOD - Abstract through repository
class GetTasksUseCase:
    async def execute(self):
        return await self.repository.find_all()  # No SQL
```

## Summary

The Infrastructure layer in our Task Manager:
- Implements abstractions from inner layers
- Handles all I/O operations
- Maps between domain and persistence
- Manages transactions and performance
- Can be swapped without affecting business logic

This layer changes when we switch technologies (database, external services) but the inner layers remain stable.