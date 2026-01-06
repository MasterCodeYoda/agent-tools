# Frameworks Layer - Task Manager Example

## Overview

The Frameworks layer is the outermost layer, containing all the delivery mechanisms: web frameworks, CLI tools, GUI applications, and other entry points. This layer is where users interact with the system.

## Core Concepts

### Entry Points

Different ways users can interact with the Task Manager:
- **REST API**: HTTP endpoints for web/mobile clients
- **CLI**: Command-line interface for terminal users
- **GraphQL**: Alternative API style
- **WebSocket**: Real-time updates

### Dependency Injection

The Frameworks layer is responsible for wiring all the layers together.

## Implementation Across Languages

### Python Implementation (FastAPI)

```python
# frameworks/fastapi/main.py

from fastapi import FastAPI
from .routers import task_router
from .dependencies import setup_dependencies
from .middleware import setup_middleware
from .exception_handlers import setup_exception_handlers

def create_app() -> FastAPI:
    """Create and configure FastAPI application."""
    app = FastAPI(
        title="Task Manager API",
        description="Clean Architecture Task Manager",
        version="1.0.0"
    )

    # Setup
    setup_dependencies(app)
    setup_middleware(app)
    setup_exception_handlers(app)

    # Routes
    app.include_router(task_router, prefix="/api/v1")

    return app

app = create_app()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
```

```python
# frameworks/fastapi/routers/task_router.py

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List

from application.use_cases import (
    CreateTaskUseCase,
    CreateTaskRequest,
    ListTasksUseCase,
    ListTasksRequest,
    CompleteTaskUseCase,
    CompleteTaskRequest
)
from application.exceptions import TaskNotFoundError
from ..dependencies import (
    get_create_task_use_case,
    get_list_tasks_use_case,
    get_complete_task_use_case
)

router = APIRouter(prefix="/tasks", tags=["tasks"])

# HTTP DTOs
class CreateTaskDTO(BaseModel):
    description: str

class TaskDTO(BaseModel):
    id: str
    description: str
    completed: bool
    created_at: str
    completed_at: str | None = None

# Endpoints
@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    response_model=TaskDTO
)
async def create_task(
    dto: CreateTaskDTO,
    use_case: CreateTaskUseCase = Depends(get_create_task_use_case)
):
    """Create a new task."""
    request = CreateTaskRequest(description=dto.description)
    response = await use_case.execute(request)

    return TaskDTO(
        id=response.task_id,
        description=response.description,
        completed=False,
        created_at=response.created_at.isoformat(),
        completed_at=None
    )

@router.get(
    "/",
    response_model=List[TaskDTO]
)
async def list_tasks(
    use_case: ListTasksUseCase = Depends(get_list_tasks_use_case)
):
    """List all tasks."""
    request = ListTasksRequest()
    response = await use_case.execute(request)

    return [
        TaskDTO(
            id=task.id,
            description=task.description,
            completed=task.completed,
            created_at=task.created_at.isoformat(),
            completed_at=task.completed_at.isoformat() if task.completed_at else None
        )
        for task in response.tasks
    ]

@router.put(
    "/{task_id}/complete",
    response_model=dict
)
async def complete_task(
    task_id: str,
    use_case: CompleteTaskUseCase = Depends(get_complete_task_use_case)
):
    """Mark a task as complete."""
    try:
        request = CompleteTaskRequest(task_id=task_id)
        response = await use_case.execute(request)

        if not response.success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=response.message
            )

        return {
            "success": response.success,
            "completed_at": response.completed_at.isoformat() if response.completed_at else None
        }

    except TaskNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
```

```python
# frameworks/fastapi/dependencies.py

from functools import lru_cache
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from fastapi import Depends

from application.use_cases import (
    CreateTaskUseCase,
    ListTasksUseCase,
    CompleteTaskUseCase
)
from infrastructure.repositories import SqlAlchemyTaskRepository
from .config import Settings

# Configuration
@lru_cache()
def get_settings() -> Settings:
    return Settings()

# Database
@lru_cache()
def get_session_factory():
    settings = get_settings()
    engine = create_async_engine(settings.database_url)
    return async_sessionmaker(engine, expire_on_commit=False)

async def get_db_session():
    factory = get_session_factory()
    async with factory() as session:
        yield session

# Repositories
def get_task_repository(
    session: AsyncSession = Depends(get_db_session)
) -> TaskRepository:
    return SqlAlchemyTaskRepository(session)

# Use Cases
def get_create_task_use_case(
    repository: TaskRepository = Depends(get_task_repository)
) -> CreateTaskUseCase:
    return CreateTaskUseCase(repository)

def get_list_tasks_use_case(
    repository: TaskRepository = Depends(get_task_repository)
) -> ListTasksUseCase:
    return ListTasksUseCase(repository)

def get_complete_task_use_case(
    repository: TaskRepository = Depends(get_task_repository)
) -> CompleteTaskUseCase:
    return CompleteTaskUseCase(repository)
```

### TypeScript Implementation (NestJS)

```typescript
// tasks/tasks.module.ts

import { Module } from '@nestjs/common';
import { TasksController } from './presentation/tasks.controller';
import { CreateTaskUseCase } from './application/use-cases/create-task.use-case';
import { ListTasksUseCase } from './application/use-cases/list-tasks.use-case';
import { CompleteTaskUseCase } from './application/use-cases/complete-task.use-case';
import { TASK_REPOSITORY } from './tokens';
import { PrismaTaskRepository } from './infrastructure/prisma-task.repository';
import { PrismaModule } from '../shared/prisma/prisma.module';

@Module({
  imports: [PrismaModule],
  controllers: [TasksController],
  providers: [
    CreateTaskUseCase,
    ListTasksUseCase,
    CompleteTaskUseCase,
    {
      provide: TASK_REPOSITORY,
      useClass: PrismaTaskRepository,
    },
  ],
})
export class TasksModule {}
```

```typescript
// tasks/presentation/tasks.controller.ts

import {
  Controller,
  Post,
  Get,
  Put,
  Body,
  Param,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { CreateTaskUseCase } from '../application/use-cases/create-task.use-case';
import { ListTasksUseCase } from '../application/use-cases/list-tasks.use-case';
import { CompleteTaskUseCase } from '../application/use-cases/complete-task.use-case';
import { CreateTaskDto } from './dto/create-task.dto';
import { DomainException } from '../../shared/domain/exceptions';

@Controller('api/v1/tasks')
export class TasksController {
  constructor(
    private readonly createTaskUseCase: CreateTaskUseCase,
    private readonly listTasksUseCase: ListTasksUseCase,
    private readonly completeTaskUseCase: CompleteTaskUseCase,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async createTask(@Body() dto: CreateTaskDto) {
    const result = await this.createTaskUseCase.execute({
      description: dto.description,
    });

    if (!result.success) {
      throw new DomainException(result.error);
    }

    return {
      id: result.value.taskId,
      description: dto.description,
      completed: false,
      createdAt: result.value.createdAt,
    };
  }

  @Get()
  async listTasks() {
    const result = await this.listTasksUseCase.execute({});

    if (!result.success) {
      throw new DomainException(result.error);
    }

    return {
      tasks: result.value.tasks.map((task) => ({
        id: task.id,
        description: task.description,
        completed: task.completed,
        createdAt: task.createdAt,
        completedAt: task.completedAt,
      })),
    };
  }

  @Put(':id/complete')
  async completeTask(@Param('id') id: string) {
    const result = await this.completeTaskUseCase.execute({ taskId: id });

    if (!result.success) {
      throw new DomainException(result.error);
    }

    return {
      success: true,
      completedAt: result.value.completedAt,
    };
  }
}
```

```typescript
// main.ts

import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { DomainExceptionFilter } from './shared/filters/domain-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalFilters(new DomainExceptionFilter());

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`Server running on port ${port}`);
}

bootstrap();
```

### TypeScript Implementation (Next.js)

```typescript
// app/(features)/tasks/page.tsx

import { getContainer } from '@/lib/container';
import { TaskList } from './components/task-list';
import { CreateTaskForm } from './components/create-task-form';

export default async function TasksPage() {
  const container = getContainer();
  const result = await container.getListTasksUseCase().execute({});

  if (!result.success) {
    return <div>Error loading tasks</div>;
  }

  return (
    <div>
      <h1>Task Manager</h1>
      <CreateTaskForm />
      <TaskList tasks={result.value.tasks} />
    </div>
  );
}
```

```typescript
// app/(features)/tasks/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { getContainer } from '@/lib/container';
import { z } from 'zod';

const CreateTaskSchema = z.object({
  description: z.string().min(1).max(500),
});

export async function createTask(formData: FormData) {
  const parsed = CreateTaskSchema.safeParse({
    description: formData.get('description'),
  });

  if (!parsed.success) {
    return { success: false, error: parsed.error.flatten() };
  }

  const container = getContainer();
  const result = await container.getCreateTaskUseCase().execute({
    description: parsed.data.description,
  });

  if (!result.success) {
    return { success: false, error: result.error };
  }

  revalidatePath('/tasks');
  return { success: true, data: result.value };
}

export async function completeTask(taskId: string) {
  const container = getContainer();
  const result = await container.getCompleteTaskUseCase().execute({ taskId });

  if (!result.success) {
    return { success: false, error: result.error };
  }

  revalidatePath('/tasks');
  return { success: true, data: result.value };
}
```

```typescript
// app/(features)/tasks/components/create-task-form.tsx
'use client';

import { useActionState } from 'react';
import { createTask } from '../actions';

export function CreateTaskForm() {
  const [state, formAction, isPending] = useActionState(
    async (_: unknown, formData: FormData) => createTask(formData),
    null,
  );

  return (
    <form action={formAction}>
      <input
        name="description"
        placeholder="Enter task description"
        disabled={isPending}
      />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Task'}
      </button>
      {state && !state.success && (
        <p className="error">{JSON.stringify(state.error)}</p>
      )}
    </form>
  );
}
```

### C# Implementation (ASP.NET Core)

```csharp
// Frameworks/Web/Controllers/TasksController.cs

using Microsoft.AspNetCore.Mvc;
using TaskManager.Application.UseCases.CreateTask;
using TaskManager.Application.UseCases.ListTasks;
using TaskManager.Application.UseCases.CompleteTask;

namespace TaskManager.Frameworks.Web.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class TasksController : ControllerBase
    {
        private readonly CreateTaskUseCase _createTaskUseCase;
        private readonly ListTasksUseCase _listTasksUseCase;
        private readonly CompleteTaskUseCase _completeTaskUseCase;

        public TasksController(
            CreateTaskUseCase createTaskUseCase,
            ListTasksUseCase listTasksUseCase,
            CompleteTaskUseCase completeTaskUseCase)
        {
            _createTaskUseCase = createTaskUseCase;
            _listTasksUseCase = listTasksUseCase;
            _completeTaskUseCase = completeTaskUseCase;
        }

        [HttpPost]
        public async Task<IActionResult> CreateTask([FromBody] CreateTaskDto dto)
        {
            var request = new CreateTaskRequest
            {
                Description = dto.Description
            };

            var response = await _createTaskUseCase.ExecuteAsync(request);

            return Created($"/api/v1/tasks/{response.TaskId}", new
            {
                id = response.TaskId,
                description = response.Description,
                completed = false,
                createdAt = response.CreatedAt
            });
        }

        [HttpGet]
        public async Task<IActionResult> ListTasks()
        {
            var request = new ListTasksRequest();
            var response = await _listTasksUseCase.ExecuteAsync(request);

            var tasks = response.Tasks.Select(t => new
            {
                id = t.Id,
                description = t.Description,
                completed = t.Completed,
                createdAt = t.CreatedAt,
                completedAt = t.CompletedAt
            });

            return Ok(new { tasks });
        }

        [HttpPut("{id}/complete")]
        public async Task<IActionResult> CompleteTask(string id)
        {
            var request = new CompleteTaskRequest { TaskId = id };

            try
            {
                var response = await _completeTaskUseCase.ExecuteAsync(request);

                return Ok(new
                {
                    success = response.Success,
                    completedAt = response.CompletedAt
                });
            }
            catch (TaskNotFoundException)
            {
                return NotFound(new { error = "Task not found" });
            }
        }
    }

    // HTTP DTOs
    public class CreateTaskDto
    {
        public string Description { get; set; }
    }
}
```

```csharp
// Frameworks/Web/Program.cs

using TaskManager.Application.UseCases.CreateTask;
using TaskManager.Infrastructure.Repositories;
using TaskManager.Infrastructure.Persistence;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Configure database
builder.Services.AddDbContext<TaskDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register dependencies
builder.Services.AddScoped<ITaskRepository, EfTaskRepository>();
builder.Services.AddScoped<CreateTaskUseCase>();
builder.Services.AddScoped<ListTasksUseCase>();
builder.Services.AddScoped<CompleteTaskUseCase>();

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

## CLI Implementation Example

```python
# frameworks/cli/commands.py

import click
import asyncio
from application.use_cases import (
    CreateTaskUseCase,
    ListTasksUseCase,
    CompleteTaskUseCase
)
from infrastructure.repositories import InMemoryTaskRepository

# Simple DI for CLI
repository = InMemoryTaskRepository()
create_use_case = CreateTaskUseCase(repository)
list_use_case = ListTasksUseCase(repository)
complete_use_case = CompleteTaskUseCase(repository)

@click.group()
def cli():
    """Task Manager CLI"""
    pass

@cli.command()
@click.argument('description')
def create(description: str):
    """Create a new task"""
    async def run():
        request = CreateTaskRequest(description=description)
        response = await create_use_case.execute(request)
        click.echo(f"Created task: {response.task_id}")

    asyncio.run(run())

@cli.command()
def list():
    """List all tasks"""
    async def run():
        request = ListTasksRequest()
        response = await list_use_case.execute(request)

        for task in response.tasks:
            status = "✓" if task.completed else "○"
            click.echo(f"{status} [{task.id[:8]}] {task.description}")

    asyncio.run(run())

@cli.command()
@click.argument('task_id')
def complete(task_id: str):
    """Complete a task"""
    async def run():
        request = CompleteTaskRequest(task_id=task_id)
        response = await complete_use_case.execute(request)

        if response.success:
            click.echo(f"Task {task_id} completed!")
        else:
            click.echo(f"Failed: {response.message}")

    asyncio.run(run())

if __name__ == '__main__':
    cli()
```

## Key Framework Patterns

### 1. Thin Controllers

Controllers should only:
- Parse input
- Call use cases
- Format output

```python
# ✅ GOOD - Thin controller
async def create_task(dto: CreateTaskDTO, use_case: CreateTaskUseCase):
    request = CreateTaskRequest(description=dto.description)
    response = await use_case.execute(request)
    return format_response(response)

# ❌ BAD - Fat controller
async def create_task(dto: CreateTaskDTO):
    # Validation logic
    # Business logic
    # Database calls
    # 100+ lines of code
```

### 2. Error Handling

```python
# frameworks/fastapi/exception_handlers.py

from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse
from application.exceptions import TaskNotFoundError, DomainError

async def domain_error_handler(request: Request, exc: DomainError):
    return JSONResponse(
        status_code=400,
        content={"error": str(exc)}
    )

async def not_found_handler(request: Request, exc: TaskNotFoundError):
    return JSONResponse(
        status_code=404,
        content={"error": str(exc)}
    )

def setup_exception_handlers(app: FastAPI):
    app.add_exception_handler(DomainError, domain_error_handler)
    app.add_exception_handler(TaskNotFoundError, not_found_handler)
```

### 3. Middleware

```python
# frameworks/fastapi/middleware.py

from fastapi import Request
import time
import logging

logger = logging.getLogger(__name__)

async def logging_middleware(request: Request, call_next):
    start_time = time.time()

    response = await call_next(request)

    process_time = time.time() - start_time
    logger.info(
        f"{request.method} {request.url.path} "
        f"completed in {process_time:.3f}s"
    )

    response.headers["X-Process-Time"] = str(process_time)
    return response
```

### 4. Configuration

```python
# frameworks/fastapi/config.py

from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    # Application
    app_name: str = "Task Manager"
    debug: bool = False

    # Database
    database_url: str = "sqlite+aiosqlite:///./tasks.db"

    # API
    api_prefix: str = "/api/v1"
    cors_origins: List[str] = ["http://localhost:3000"]

    # Security
    secret_key: str = "change-me-in-production"

    class Config:
        env_file = ".env"
```

## Testing the Framework Layer

```python
# tests/frameworks/test_api.py

import pytest
from fastapi.testclient import TestClient
from frameworks.fastapi.main import app

client = TestClient(app)

def test_create_task():
    response = client.post(
        "/api/v1/tasks",
        json={"description": "Test task"}
    )

    assert response.status_code == 201
    data = response.json()
    assert data["description"] == "Test task"
    assert "id" in data

def test_list_tasks():
    # Create a task first
    client.post("/api/v1/tasks", json={"description": "Task 1"})

    # List tasks
    response = client.get("/api/v1/tasks")

    assert response.status_code == 200
    data = response.json()
    assert len(data["tasks"]) > 0

def test_complete_task():
    # Create a task
    create_response = client.post(
        "/api/v1/tasks",
        json={"description": "Task to complete"}
    )
    task_id = create_response.json()["id"]

    # Complete it
    response = client.put(f"/api/v1/tasks/{task_id}/complete")

    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True

def test_complete_nonexistent_task():
    response = client.put("/api/v1/tasks/nonexistent/complete")
    assert response.status_code == 404
```

## Common Mistakes to Avoid

### 1. Business Logic in Framework

```python
# ❌ BAD - Business logic in controller
@router.post("/tasks")
async def create_task(dto: CreateTaskDTO):
    # Business validation in controller!
    if len(dto.description) < 3:
        raise HTTPException(400, "Too short")

    if "bad" in dto.description:
        raise HTTPException(400, "Invalid word")

# ✅ GOOD - Business logic in domain
@router.post("/tasks")
async def create_task(dto: CreateTaskDTO, use_case: CreateTaskUseCase):
    # Controller just coordinates
    request = CreateTaskRequest(description=dto.description)
    response = await use_case.execute(request)  # Business logic in use case/domain
```

### 2. Tight Coupling to Framework

```python
# ❌ BAD - Use case depends on framework
class CreateTaskUseCase:
    def execute(self, request: FastAPIRequest):  # Framework type!
        # ...

# ✅ GOOD - Framework-agnostic use case
class CreateTaskUseCase:
    def execute(self, request: CreateTaskRequest):  # Domain type
        # ...
```

### 3. Missing Error Translation

```python
# ❌ BAD - Exposing internal errors
@router.post("/tasks")
async def create_task(dto: CreateTaskDTO):
    task = Task(dto.description)  # May raise domain exception
    # Domain exception leaks to user!

# ✅ GOOD - Translate errors
@router.post("/tasks")
async def create_task(dto: CreateTaskDTO):
    try:
        task = Task(dto.description)
    except DomainError as e:
        # Translate to HTTP error
        raise HTTPException(400, "Invalid task data")
```

## Summary

The Frameworks layer in our Task Manager:
- Provides entry points (API, CLI, GUI)
- Handles HTTP/framework concerns
- Wires dependencies together
- Translates between external and internal formats
- Remains thin with no business logic

This layer changes frequently (new endpoints, different frameworks) but inner layers remain stable because they don't depend on it.