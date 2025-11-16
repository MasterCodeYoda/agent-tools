---
name: vertical-slicing
description: Story-first implementation strategy for Clean Architecture that delivers complete, working features incrementally through all architectural layers, avoiding horizontal layer building
---

# Vertical Slicing Implementation Strategy

This skill provides guidance on implementing features using vertical slicing - a story-first approach that delivers complete, working features incrementally.

## Core Concept

Vertical slicing means implementing features end-to-end through all architectural layers, rather than building layers horizontally. Each slice represents a complete, deployable feature that delivers user value.

## Philosophy

> "Build by story, not by layer"

Traditional (Horizontal) Approach ❌:
1. Build all domain entities
2. Build all repositories
3. Build all use cases
4. Build all API endpoints
5. Build UI
6. Integrate and test

Vertical Slicing Approach ✅:
1. Pick highest priority user story
2. Build ONLY what's needed for that story through ALL layers
3. Deploy it
4. Pick next story, repeat

## Benefits

1. **Faster Time to Value** - Deploy features as soon as they're ready
2. **Reduced Risk** - Each slice is small and testable
3. **Better Feedback Loop** - Users see progress immediately
4. **Easier Integration** - Continuous integration, not big-bang
5. **Clear Progress** - Stakeholders see working features, not "90% complete" layers

## Implementation Process

### Step 1: Story Selection

Start with a user story that provides clear value:

```markdown
Story: "As a user, I want to create a task so that I can track my work"

Acceptance Criteria:
- User can enter task title and description
- Task is saved to the database
- User sees confirmation of creation
- Created task appears in task list
```

### Step 2: Vertical Planning

Map out ONLY what's needed for this story:

```
UI Layer:
  └─ POST /tasks endpoint

Application Layer:
  └─ CreateTaskUseCase

Domain Layer:
  └─ Task entity (only properties needed for creation)

Infrastructure Layer:
  └─ TaskRepository.create() method (only)
```

### Step 3: Bottom-Up Implementation

While we plan top-down, we implement bottom-up:

#### 3.1 Domain Layer (Minimal)

```python
# domain/models/task.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional

@dataclass
class Task:
    """Task entity - only what's needed for creation story."""
    id: str
    title: str
    description: Optional[str]
    created_at: datetime
    # DON'T add status, assignee, etc. until needed by a story
```

#### 3.2 Infrastructure Layer (Minimal)

```python
# infrastructure/repositories/task_repository.py
from typing import Protocol
from domain.models.task import Task

class TaskRepository(Protocol):
    """Repository for task persistence."""

    def create(self, task: Task) -> Task:
        """Create a new task."""
        ...

    # DON'T add update(), delete(), find_by_status() yet


class SQLTaskRepository:
    """SQL implementation of TaskRepository."""

    def create(self, task: Task) -> Task:
        # Implementation for create ONLY
        pass
```

#### 3.3 Application Layer

```python
# application/tasks/create.py
from dataclasses import dataclass
from datetime import datetime
from typing import Optional
import uuid

from domain.models.task import Task
from infrastructure.repositories.task_repository import TaskRepository

@dataclass
class CreateTaskRequest:
    """Request for creating a task."""
    title: str
    description: Optional[str] = None


@dataclass
class CreateTaskResponse:
    """Response after creating a task."""
    id: str
    title: str
    created_at: datetime


class CreateTaskUseCase:
    """Use case for creating tasks."""

    def __init__(self, repository: TaskRepository):
        self._repository = repository

    def execute(self, request: CreateTaskRequest) -> CreateTaskResponse:
        """Create a new task."""
        task = Task(
            id=str(uuid.uuid4()),
            title=request.title,
            description=request.description,
            created_at=datetime.utcnow()
        )

        created_task = self._repository.create(task)

        return CreateTaskResponse(
            id=created_task.id,
            title=created_task.title,
            created_at=created_task.created_at
        )
```

#### 3.4 Framework Layer

```python
# frameworks/api/tasks.py
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import Optional

from application.tasks.create import (
    CreateTaskUseCase,
    CreateTaskRequest,
    CreateTaskResponse
)

router = APIRouter(prefix="/tasks", tags=["tasks"])

class CreateTaskApiRequest(BaseModel):
    """API model for task creation."""
    title: str
    description: Optional[str] = None


@router.post("/", response_model=CreateTaskResponse)
async def create_task(
    data: CreateTaskApiRequest,
    use_case: CreateTaskUseCase = Depends(get_create_task_use_case)
) -> CreateTaskResponse:
    """Create a new task."""
    request = CreateTaskRequest(
        title=data.title,
        description=data.description
    )
    return use_case.execute(request)
```

### Step 4: Test Each Layer

Test only what you've built:

```python
# tests/unit/test_create_task.py
def test_create_task_use_case():
    # Mock repository
    mock_repo = Mock(spec=TaskRepository)
    mock_repo.create.return_value = Task(
        id="123",
        title="Test Task",
        description="Test Description",
        created_at=datetime.utcnow()
    )

    # Execute use case
    use_case = CreateTaskUseCase(mock_repo)
    request = CreateTaskRequest(title="Test Task", description="Test Description")
    response = use_case.execute(request)

    # Assert
    assert response.id == "123"
    assert response.title == "Test Task"
    mock_repo.create.assert_called_once()
```

### Step 5: Deploy

This slice is complete and deployable! Users can now create tasks.

## Next Story Pattern

When implementing the next story (e.g., "View task details"):

### Extend Existing Code

```python
# domain/models/task.py
@dataclass
class Task:
    id: str
    title: str
    description: Optional[str]
    created_at: datetime
    updated_at: datetime  # Added for view story
    status: str = "pending"  # Added for view story
```

### Add New Operations

```python
# infrastructure/repositories/task_repository.py
class TaskRepository(Protocol):
    def create(self, task: Task) -> Task: ...
    def get(self, task_id: str) -> Optional[Task]: ...  # Added for view story
```

### Create New Use Case

```python
# application/tasks/get.py
@dataclass
class GetTaskRequest:
    task_id: str

@dataclass
class GetTaskResponse:
    id: str
    title: str
    description: Optional[str]
    status: str
    created_at: datetime
    updated_at: datetime

class GetTaskUseCase:
    # Implementation
```

## Common Pitfalls

### 1. Over-Engineering the First Slice

❌ **Wrong**:
```python
class Task:
    def __init__(self, title, description, status, priority,
                 assignee, labels, attachments, comments, ...):
        # Too much for "create task" story!
```

✅ **Right**:
```python
class Task:
    def __init__(self, title, description):
        # Just what's needed for creation
```

### 2. Building Horizontal Infrastructure

❌ **Wrong**:
```python
class TaskRepository:
    def create(self, task): ...
    def update(self, task): ...
    def delete(self, task_id): ...
    def find_by_status(self, status): ...
    def find_by_assignee(self, assignee): ...
    # Building everything upfront!
```

✅ **Right**:
```python
class TaskRepository:
    def create(self, task): ...
    # Just what the current story needs
```

### 3. Premature Abstraction

❌ **Wrong**:
```python
class BaseEntity:
    # Complex base class for all entities

class AuditableEntity(BaseEntity):
    # Another layer of abstraction

class Task(AuditableEntity):
    # Overly complex for simple task creation
```

✅ **Right**:
```python
@dataclass
class Task:
    # Simple, direct implementation
```

## Story Prioritization

Order stories by:

1. **Business Value** - What provides most value to users?
2. **Risk Reduction** - What validates key assumptions?
3. **Learning** - What teaches us about the domain?
4. **Dependencies** - What unblocks other stories?

Example Story Order:
1. Create task (P1 - Core functionality)
2. List tasks (P1 - Users need to see what they created)
3. Complete task (P1 - Core workflow)
4. Edit task (P2 - Nice to have)
5. Delete task (P2 - Cleanup)
6. Assign task (P3 - Collaboration feature)

## Refactoring Strategy

As you add slices, refactor continuously:

### Extract Common Patterns

After 3+ similar use cases:
```python
# Before: Duplicate code in each use case
class CreateTaskUseCase:
    def execute(self, request):
        # Validation
        # Business logic
        # Persistence
        # Response mapping

# After: Extract common pattern
class BaseUseCase[TRequest, TResponse]:
    def execute(self, request: TRequest) -> TResponse:
        self.validate(request)
        result = self.process(request)
        return self.to_response(result)
```

### Consolidate Domain Logic

When patterns emerge:
```python
# After several stories reveal business rules
class Task:
    def can_be_assigned_to(self, user: User) -> bool:
        """Business rule discovered through stories."""
        return self.status == "pending" and user.is_active

    def complete(self) -> None:
        """State transition discovered through stories."""
        if self.status != "in_progress":
            raise InvalidStateError()
        self.status = "completed"
        self.completed_at = datetime.utcnow()
```

## Checkpoints

Each vertical slice should pass these checkpoints:

- [ ] **Functional** - Does it work end-to-end?
- [ ] **Tested** - Are all layers tested?
- [ ] **Documented** - Is the API documented?
- [ ] **Deployable** - Can it go to production?
- [ ] **Observable** - Can we monitor it?
- [ ] **Secure** - Is it safe from common vulnerabilities?

## Team Workflow

### For Solo Developers

1. Pick story from backlog
2. Implement vertical slice
3. Test and deploy
4. Get feedback
5. Repeat

### For Teams

1. **Story Kickoff** - Discuss acceptance criteria
2. **Slice Planning** - Identify affected layers
3. **Parallel Work** - Different people can work on different layers
4. **Integration** - Combine work, test end-to-end
5. **Deploy** - Ship the complete feature

### Avoiding Conflicts

When multiple developers work on same codebase:

```python
# application/tasks/
├── create.py     # Developer A working on create
├── update.py     # Developer B working on update
├── assign.py     # Developer C working on assign
└── views.py      # Shared view models (coordinate changes)
```

## Migration Strategy

Converting existing horizontal architecture:

### Phase 1: Stop the Bleeding
- New features use vertical slicing
- Existing code remains as-is

### Phase 2: Incremental Migration
- When touching existing code, refactor to vertical slices
- One story at a time

### Phase 3: Cleanup
- Remove unused horizontal layers
- Consolidate duplicate code

## Metrics

Track success of vertical slicing:

1. **Lead Time** - Time from story start to deployment
2. **Deployment Frequency** - How often you ship
3. **Story Completion Rate** - Stories completed per sprint
4. **Defect Rate** - Bugs per story

Good vertical slicing shows:
- ⬇️ Lead time (faster delivery)
- ⬆️ Deployment frequency (more releases)
- ⬆️ Story completion (more value delivered)
- ⬇️ Defect rate (smaller, focused changes)

## Examples by Domain

### E-Commerce
1. View product → Add to cart → Checkout → Payment
2. Each step is a complete vertical slice
3. Don't build entire product catalog first

### SaaS Platform
1. User registration → Login → Create workspace → Invite team
2. Each feature is independently valuable
3. Don't build complete user management first

### API Development
1. Single endpoint → Authentication → Rate limiting → Webhooks
2. Each API feature is a slice
3. Don't design entire API surface first

## Remember

- **YAGNI** - Build only what the current story needs
- **Ship Early** - Deploy as soon as the slice works
- **Refactor Continuously** - Clean up as patterns emerge
- **Stay Vertical** - Resist the urge to build horizontal layers

Vertical slicing is not just a technique, it's a mindset shift from "building systems" to "delivering value."