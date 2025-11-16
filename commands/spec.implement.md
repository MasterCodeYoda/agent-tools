# /spec.implement - Implement with Vertical Slicing

Implement a feature using vertical slicing strategy, tracked in Linear.

## Instructions

### 1. Review the Plan

If you used `/spec.plan`, review the planning document:
```bash
cat planning/LIN-123-implementation-plan.md
```

Otherwise, quickly identify the vertical slice needed.

### 2. Set Up Linear Tracking

Update Linear issue status:
- Move to "In Progress"
- Add a comment: "Starting implementation"

### 3. Implement Bottom-Up

While we plan top-down (user story → layers), we implement bottom-up (domain → framework).

#### Step 1: Domain Layer

Create the minimal entity needed:

```python
# src/PROJECT_NAME/domain/tasks/models.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class Task:
    """Task entity - minimal for LIN-123 create story."""
    id: str
    title: str
    description: Optional[str]
    created_at: datetime

    def __post_init__(self) -> None:
        """Validate task on creation."""
        if not self.title:
            raise ValueError("Task title is required")
        if len(self.title) > 200:
            raise ValueError("Task title too long")
```

Run tests after each layer:
```bash
pytest tests/unit/domain/tasks/test_models.py -v
```

#### Step 2: Application Layer

Create the use case:

```python
# src/PROJECT_NAME/application/tasks/create.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional
import uuid

from PROJECT_NAME.domain.tasks.models import Task

@dataclass
class CreateTaskRequest:
    title: str
    description: Optional[str] = None

@dataclass
class CreateTaskResponse:
    id: str
    title: str
    created_at: datetime

class CreateTaskUseCase:
    def __init__(self, repository):
        self._repository = repository

    def execute(self, request: CreateTaskRequest) -> CreateTaskResponse:
        task = Task(
            id=str(uuid.uuid4()),
            title=request.title,
            description=request.description,
            created_at=datetime.utcnow()
        )

        self._repository.create(task)

        return CreateTaskResponse(
            id=task.id,
            title=task.title,
            created_at=task.created_at
        )
```

Test the use case:
```bash
pytest tests/unit/application/tasks/test_create.py -v
```

#### Step 3: Infrastructure Layer

Implement only what's needed:

```python
# src/PROJECT_NAME/infrastructure/tasks/repository.py
from typing import Protocol
from PROJECT_NAME.domain.tasks.models import Task

class TaskRepository(Protocol):
    """Repository interface for tasks."""

    def create(self, task: Task) -> Task:
        """Create a new task."""
        ...

class InMemoryTaskRepository:
    """In-memory implementation for testing."""

    def __init__(self):
        self._tasks = {}

    def create(self, task: Task) -> Task:
        self._tasks[task.id] = task
        return task
```

Test the repository:
```bash
pytest tests/integration/infrastructure/tasks/test_repository.py -v
```

#### Step 4: Framework Layer

Add the API endpoint:

```python
# src/PROJECT_NAME/frameworks/api/tasks.py
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional

from PROJECT_NAME.application.tasks.create import (
    CreateTaskUseCase,
    CreateTaskRequest,
    CreateTaskResponse
)

router = APIRouter(prefix="/tasks", tags=["tasks"])

class CreateTaskRequest(BaseModel):
    title: str
    description: Optional[str] = None

@router.post("/", response_model=CreateTaskResponse)
async def create_task(
    data: CreateTaskRequest,
    use_case: CreateTaskUseCase = Depends(get_create_task_use_case)
) -> CreateTaskResponse:
    """Create a new task."""
    request = CreateTaskRequest(
        title=data.title,
        description=data.description
    )
    return use_case.execute(request)
```

Test the endpoint:
```bash
pytest tests/e2e/test_tasks_api.py::test_create_task -v
```

### 4. Quality Check

After implementing each layer:

```bash
# Run quality checks
./scripts/check_all.py

# Fix any issues
./scripts/check_all.py --fix
```

### 5. Test the Complete Slice

Run all tests for the feature:
```bash
pytest tests/ -k "task" -v
```

Manual testing (if API):
```bash
# Start the server
uvicorn src.PROJECT_NAME.frameworks.api.main:app --reload

# Test with curl
curl -X POST http://localhost:8000/tasks \
  -H "Content-Type: application/json" \
  -d '{"title": "Test task", "description": "Testing LIN-123"}'
```

### 6. Commit the Slice

Commit the complete vertical slice:
```bash
git add .
git commit -m "feat(tasks): implement create task endpoint [LIN-123]

- Add Task domain entity with validation
- Implement CreateTaskUseCase in application layer
- Add TaskRepository interface and in-memory implementation
- Create POST /tasks API endpoint
- Add comprehensive test coverage

Implements vertical slice for task creation story"
```

### 7. Update Linear

Update the Linear issue:
- Add comment with what was implemented
- Link to commit/PR
- Move to "In Review" or "Done"
- Log time spent

### 8. Next Slice

If more stories in the feature:
1. Identify the next vertical slice
2. Extend existing code (don't rebuild)
3. Repeat the process

## Implementation Checklist

For each vertical slice:
- [ ] Domain entity created (minimal)
- [ ] Use case implemented
- [ ] Repository method added (only needed)
- [ ] API endpoint created
- [ ] Unit tests written
- [ ] Integration tests written
- [ ] E2E tests written
- [ ] Quality checks pass
- [ ] Manually tested
- [ ] Committed with Linear reference
- [ ] Linear issue updated

## Common Patterns

### File-per-use-case Structure
```
application/tasks/
├── create.py    # CreateTaskUseCase + models
├── update.py    # UpdateTaskUseCase + models
├── delete.py    # DeleteTaskUseCase + models
└── views.py     # Shared view models
```

### Test Structure Mirrors Source
```
tests/
├── unit/
│   ├── domain/tasks/
│   └── application/tasks/
├── integration/
│   └── infrastructure/tasks/
└── e2e/
    └── test_tasks_api.py
```

## Remember

- Implement only what the current story needs
- Test each layer as you build
- Commit complete, working slices
- Keep Linear updated
- Don't build horizontal infrastructure
- Refactor as patterns emerge
- YAGNI is your friend