# Application Layer - Task Manager Example

## Overview

The Application layer orchestrates the flow of data between the Domain layer and outer layers. It contains use cases that represent the actions users can perform.

## Core Concepts

### Use Cases

Each use case represents a single user action:
- **CreateTaskUseCase**: Creates a new task
- **ListTasksUseCase**: Retrieves all tasks
- **CompleteTaskUseCase**: Marks a task as complete

### Request/Response Models

Each use case has:
- **Request DTO**: Input data from the user
- **Response DTO**: Output data to the user
- **Colocated**: All three in the same file

## Implementation Across Languages

### Python Implementation

```python
# application/use_cases/create_task.py

from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

from domain.entities import Task
from domain.repositories import TaskRepository

# Request DTO
class CreateTaskRequest(BaseModel):
    description: str = Field(..., min_length=1, max_length=500)

    class Config:
        str_strip_whitespace = True

# Response DTO
class CreateTaskResponse(BaseModel):
    task_id: str
    description: str
    created: bool
    created_at: datetime

# Use Case
class CreateTaskUseCase:
    """Create a new task use case."""

    def __init__(self, task_repository: TaskRepository):
        self._repository = task_repository

    async def execute(self, request: CreateTaskRequest) -> CreateTaskResponse:
        """Execute the use case."""
        # Create domain entity
        task = Task(description=request.description)

        # Persist via repository
        await self._repository.save(task)

        # Return response
        return CreateTaskResponse(
            task_id=task.id,
            description=task.description,
            created=True,
            created_at=task.created_at
        )
```

```python
# application/use_cases/list_tasks.py

from pydantic import BaseModel
from typing import List
from datetime import datetime

from domain.repositories import TaskRepository

# View Model (shared across read operations)
class TaskView(BaseModel):
    id: str
    description: str
    completed: bool
    created_at: datetime
    completed_at: Optional[datetime] = None

    @classmethod
    def from_entity(cls, task) -> 'TaskView':
        """Create view from domain entity."""
        return cls(
            id=task.id,
            description=task.description,
            completed=task.is_completed,
            created_at=task.created_at,
            completed_at=task.completed_at
        )

# Request DTO
class ListTasksRequest(BaseModel):
    # Empty for now, will add filters later
    pass

# Response DTO
class ListTasksResponse(BaseModel):
    tasks: List[TaskView]
    total: int

# Use Case
class ListTasksUseCase:
    """List all tasks use case."""

    def __init__(self, task_repository: TaskRepository):
        self._repository = task_repository

    async def execute(self, request: ListTasksRequest) -> ListTasksResponse:
        """Execute the use case."""
        # Get tasks from repository
        tasks = await self._repository.find_all()

        # Convert to views
        task_views = [TaskView.from_entity(task) for task in tasks]

        # Return response
        return ListTasksResponse(
            tasks=task_views,
            total=len(task_views)
        )
```

```python
# application/use_cases/complete_task.py

from pydantic import BaseModel
from datetime import datetime

from domain.repositories import TaskRepository
from application.exceptions import TaskNotFoundError

# Request DTO
class CompleteTaskRequest(BaseModel):
    task_id: str

# Response DTO
class CompleteTaskResponse(BaseModel):
    success: bool
    completed_at: Optional[datetime] = None
    message: str

# Use Case
class CompleteTaskUseCase:
    """Complete a task use case."""

    def __init__(self, task_repository: TaskRepository):
        self._repository = task_repository

    async def execute(self, request: CompleteTaskRequest) -> CompleteTaskResponse:
        """Execute the use case."""
        # Find the task
        task = await self._repository.find_by_id(request.task_id)
        if not task:
            raise TaskNotFoundError(request.task_id)

        # Execute domain logic
        try:
            task.complete()
        except ValueError as e:
            return CompleteTaskResponse(
                success=False,
                message=str(e)
            )

        # Persist changes
        await self._repository.save(task)

        # Return response
        return CompleteTaskResponse(
            success=True,
            completed_at=task.completed_at,
            message="Task completed successfully"
        )
```

### TypeScript Implementation

```typescript
// application/use-cases/CreateTaskUseCase.ts

import { Task } from "../../domain/entities/Task";
import { TaskRepository } from "../../domain/repositories/TaskRepository";

// Request DTO
export class CreateTaskRequest {
  constructor(public readonly description: string) {
    this.validate();
  }

  private validate(): void {
    if (!this.description || this.description.trim().length === 0) {
      throw new Error("Description is required");
    }
  }
}

// Response DTO
export class CreateTaskResponse {
  constructor(
    public readonly taskId: string,
    public readonly description: string,
    public readonly created: boolean,
    public readonly createdAt: Date
  ) {}
}

// Use Case
export class CreateTaskUseCase {
  constructor(private readonly taskRepository: TaskRepository) {}

  async execute(request: CreateTaskRequest): Promise<CreateTaskResponse> {
    // Create domain entity
    const task = new Task(request.description);

    // Persist via repository
    await this.taskRepository.save(task);

    // Return response
    return new CreateTaskResponse(
      task.id,
      task.description,
      true,
      task.createdAt
    );
  }
}
```

### C# Implementation

```csharp
// Application/UseCases/CreateTask/CreateTaskUseCase.cs

using System.Threading.Tasks;
using TaskManager.Domain.Entities;
using TaskManager.Domain.Repositories;

namespace TaskManager.Application.UseCases.CreateTask
{
    // Request DTO
    public class CreateTaskRequest
    {
        public string Description { get; set; }

        public void Validate()
        {
            if (string.IsNullOrWhiteSpace(Description))
            {
                throw new ArgumentException("Description is required");
            }
        }
    }

    // Response DTO
    public class CreateTaskResponse
    {
        public string TaskId { get; set; }
        public string Description { get; set; }
        public bool Created { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // Use Case
    public class CreateTaskUseCase
    {
        private readonly ITaskRepository _taskRepository;

        public CreateTaskUseCase(ITaskRepository taskRepository)
        {
            _taskRepository = taskRepository;
        }

        public async Task<CreateTaskResponse> ExecuteAsync(CreateTaskRequest request)
        {
            request.Validate();

            // Create domain entity
            var task = new Task(request.Description);

            // Persist via repository
            await _taskRepository.SaveAsync(task);

            // Return response
            return new CreateTaskResponse
            {
                TaskId = task.Id,
                Description = task.Description,
                Created = true,
                CreatedAt = task.CreatedAt
            };
        }
    }
}
```

## Repository Interface

The repository interface is defined in the Domain layer but referenced by Application:

```python
# domain/repositories/task_repository.py

from typing import Protocol, Optional, List
from domain.entities import Task

class TaskRepository(Protocol):
    """Task repository interface."""

    async def save(self, task: Task) -> None:
        """Save a task."""
        ...

    async def find_by_id(self, task_id: str) -> Optional[Task]:
        """Find a task by ID."""
        ...

    async def find_all(self) -> List[Task]:
        """Find all tasks."""
        ...

    async def delete(self, task_id: str) -> None:
        """Delete a task."""
        ...
```

## Key Application Patterns

### 1. Use Case Pattern

Each use case:
- Has single responsibility
- Orchestrates domain logic
- Handles transaction boundaries
- Converts between domain and DTOs

### 2. Request/Response Separation

```python
# Separate models for input and output
CreateTaskRequest   # What user provides
CreateTaskResponse  # What user receives
```

### 3. View Models for Reads

```python
class TaskView:
    """Read model for displaying tasks."""
    # Optimized for presentation
    # May combine data from multiple entities
    # No business logic
```

### 4. Exception Handling

```python
class TaskNotFoundError(Exception):
    """Raised when task doesn't exist."""
    def __init__(self, task_id: str):
        self.task_id = task_id
        super().__init__(f"Task not found: {task_id}")
```

## Evolution Examples

### Adding Filtering

```python
class ListTasksRequest(BaseModel):
    status: Optional[str] = None  # "completed", "pending", "all"
    search: Optional[str] = None
    limit: int = Field(default=100, ge=1, le=1000)
    offset: int = Field(default=0, ge=0)

class ListTasksUseCase:
    async def execute(self, request: ListTasksRequest) -> ListTasksResponse:
        # Apply filters
        if request.status == "completed":
            tasks = await self._repository.find_completed()
        elif request.status == "pending":
            tasks = await self._repository.find_pending()
        else:
            tasks = await self._repository.find_all()

        # Apply search
        if request.search:
            tasks = [t for t in tasks if request.search.lower() in t.description.lower()]

        # Apply pagination
        paginated = tasks[request.offset:request.offset + request.limit]

        return ListTasksResponse(
            tasks=[TaskView.from_entity(t) for t in paginated],
            total=len(tasks)
        )
```

### Adding Batch Operations

```python
class CompleteMultipleTasksRequest(BaseModel):
    task_ids: List[str]

class CompleteMultipleTasksResponse(BaseModel):
    completed: List[str]
    failed: Dict[str, str]  # task_id -> error message

class CompleteMultipleTasksUseCase:
    async def execute(self, request: CompleteMultipleTasksRequest) -> CompleteMultipleTasksResponse:
        completed = []
        failed = {}

        for task_id in request.task_ids:
            try:
                task = await self._repository.find_by_id(task_id)
                if task:
                    task.complete()
                    await self._repository.save(task)
                    completed.append(task_id)
                else:
                    failed[task_id] = "Task not found"
            except ValueError as e:
                failed[task_id] = str(e)

        return CompleteMultipleTasksResponse(
            completed=completed,
            failed=failed
        )
```

## Testing the Application Layer

```python
import pytest
from unittest.mock import AsyncMock
from application.use_cases import CreateTaskUseCase, CreateTaskRequest

@pytest.mark.asyncio
async def test_create_task_use_case():
    # Arrange
    mock_repository = AsyncMock()
    use_case = CreateTaskUseCase(mock_repository)
    request = CreateTaskRequest(description="Test task")

    # Act
    response = await use_case.execute(request)

    # Assert
    assert response.created is True
    assert response.description == "Test task"
    mock_repository.save.assert_called_once()

@pytest.mark.asyncio
async def test_complete_task_not_found():
    # Arrange
    mock_repository = AsyncMock()
    mock_repository.find_by_id.return_value = None

    use_case = CompleteTaskUseCase(mock_repository)
    request = CompleteTaskRequest(task_id="non-existent")

    # Act & Assert
    with pytest.raises(TaskNotFoundError):
        await use_case.execute(request)
```

## Common Mistakes to Avoid

### 1. Business Logic in Use Cases

```python
# ❌ BAD - Business logic in use case
class CompleteTaskUseCase:
    async def execute(self, request):
        task = await self._repository.find_by_id(request.task_id)

        # Business logic should be in domain!
        if task.completed:
            raise ValueError("Already completed")
        task.completed = True
        task.completed_at = datetime.now()

# ✅ GOOD - Use case orchestrates
class CompleteTaskUseCase:
    async def execute(self, request):
        task = await self._repository.find_by_id(request.task_id)
        task.complete()  # Domain handles business logic
        await self._repository.save(task)
```

### 2. Exposing Domain Entities

```python
# ❌ BAD - Returning domain entity
class GetTaskUseCase:
    async def execute(self, request) -> Task:  # Exposing entity!
        return await self._repository.find_by_id(request.task_id)

# ✅ GOOD - Return DTO/View
class GetTaskUseCase:
    async def execute(self, request) -> TaskView:
        task = await self._repository.find_by_id(request.task_id)
        return TaskView.from_entity(task)
```

### 3. Fat Use Cases

```python
# ❌ BAD - Use case doing too much
class ProcessOrderUseCase:
    async def execute(self, request):
        # 100+ lines of orchestration
        # Multiple responsibilities
        # Hard to test

# ✅ GOOD - Focused use cases
class CreateOrderUseCase:  # One thing
class CalculatePricingUseCase:  # Another thing
class SendOrderNotificationUseCase:  # Another thing
```

## Summary

The Application layer in our Task Manager:
- Orchestrates use cases
- Defines clear interfaces (DTOs)
- Handles application-level exceptions
- Remains framework-agnostic
- Coordinates transactions

This layer changes when business workflows change but remains stable when technical implementations change.