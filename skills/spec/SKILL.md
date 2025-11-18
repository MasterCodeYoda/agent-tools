---
name: spec
description: Plan and implement features using vertical slicing - a story-first strategy that delivers complete functionality through all architectural layers. Successor to spec.plan and spec.implement commands with enhanced project management integration for Linear, Jira, or manual workflows.
---

# Spec: Vertical Slicing Implementation Strategy

This skill (formerly `vertical-slicing`, successor to `/spec.plan` and `/spec.implement` commands) provides comprehensive guidance on planning and implementing features using vertical slicing - a story-first approach that delivers complete, working features incrementally. It combines philosophy with practical workflows for planning and implementation.

## When to Use This Skill

Activate this skill when:
- Planning new features with vertical slicing approach
- Implementing user stories end-to-end
- Working with project management tools (Linear, Jira, or manual)
- Converting from horizontal to vertical architecture
- Breaking down complex features into deployable slices
- Following Clean Architecture with story-first development
- Need the functionality of former `/spec.plan` or `/spec.implement` commands

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

## Planning Workflow

When planning a feature implementation using vertical slicing, follow this structured approach:

### 1. Identify the Work Item

Start with your project management work item (Linear issue, Jira ticket, or manual specification):
- Review title and description
- Understand acceptance criteria
- Note priority and constraints
- Identify dependencies or blockers

### 2. Analyze Current State

Understand the existing codebase:
```bash
# Review code structure
tree src/ -L 3

# Search for related existing code
grep -r "relevant_term" src/

# Check for existing tests
# Language-specific test discovery
```

### 3. Create Vertical Slice Plan

For each user story, identify the minimal slice through all layers:

#### Vertical Slice Template

```markdown
## Story: [ID] User story description

### Vertical Slice:
1. **Domain Layer**
   - [ ] Entities/models needed (minimal properties)
   - [ ] Validation rules
   - [ ] Business logic

2. **Application Layer**
   - [ ] Use case implementation
   - [ ] Request/Response models
   - [ ] Business orchestration

3. **Infrastructure Layer**
   - [ ] Repository methods needed
   - [ ] External service integrations
   - [ ] Database changes (if needed)

4. **Framework Layer**
   - [ ] API endpoints or UI components
   - [ ] Input validation
   - [ ] Response formatting

5. **Tests**
   - [ ] Unit tests for domain logic
   - [ ] Unit tests for use cases
   - [ ] Integration tests for infrastructure
   - [ ] E2E tests for complete flow

### Dependencies:
- List any prerequisites or blockers

### Risk Assessment:
- Complexity level
- Technical unknowns
- External dependencies
```

### 4. Break Down into Tasks

Prioritize work using P1/P2/P3 classification:

```markdown
## Tasks for [Story ID]:

### P1 - Must Have (for story completion)
- [ ] Core domain entity with required fields
- [ ] Primary use case implementation
- [ ] Essential repository methods
- [ ] Main API endpoint
- [ ] Critical path tests

### P2 - Should Have (improvements)
- [ ] Additional validation
- [ ] Enhanced error handling
- [ ] Comprehensive test coverage
- [ ] Performance optimizations

### P3 - Nice to Have (polish)
- [ ] Additional logging
- [ ] Extended documentation
- [ ] UI enhancements
- [ ] Analytics integration
```

### 5. Document Technical Decisions

Record important choices for future reference:

```markdown
## Technical Decisions:

### Approach:
- Why vertical slicing for this feature
- Key architectural patterns used
- Trade-offs considered

### Patterns:
- Repository pattern for data access
- Use case pattern for business logic
- Result pattern for error handling

### Simplifications:
- What we're explicitly NOT building yet
- YAGNI decisions made
- Future extension points
```

### 6. Create Planning Document

Save your plan for team visibility and future reference:

```markdown
# [ID]: [Feature Title]

## Story
As a [user type], I want [capability] so that [benefit].

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Implementation Plan
[Vertical slice details from template above]

## Tasks
[P1/P2/P3 breakdown]

## Technical Decisions
[Key decisions and rationale]

## Testing Strategy
- Unit tests: [approach]
- Integration tests: [approach]
- E2E tests: [approach]

## Definition of Done
- [ ] Code complete
- [ ] All tests passing
- [ ] Code review approved
- [ ] Documentation updated
- [ ] Quality checks passed
```

## Implementation Workflow

After planning, follow this structured implementation approach:

### 1. Review the Plan

Before coding:
- Review planning document if created
- Understand the vertical slice scope
- Check for any updates to requirements
- Confirm technical decisions

### 2. Implement Bottom-Up

While we plan top-down (user story → layers), we implement bottom-up (domain → framework):

#### Why Bottom-Up?
- Domain logic is independent and testable
- Each layer depends only on layers below
- Errors caught early in foundational layers
- Natural test-driven development flow

#### Implementation Order:

1. **Domain Layer First**
   - Create minimal entities
   - Add validation rules
   - Implement business logic
   - Write unit tests

2. **Infrastructure Layer Second**
   - Create repository interfaces
   - Implement data access
   - Add external integrations
   - Write integration tests

3. **Application Layer Third**
   - Create use cases
   - Define request/response models
   - Orchestrate domain and infrastructure
   - Write unit tests

4. **Framework Layer Last**
   - Create API endpoints or UI
   - Add input validation
   - Handle responses
   - Write E2E tests

### 3. Quality Checkpoints

After implementing each layer:

```markdown
## Layer Completion Checklist:
- [ ] Code implements planned functionality
- [ ] Tests written and passing
- [ ] No quality tool warnings
- [ ] Code follows project patterns
- [ ] Changes are atomic and focused
```

Run quality checks:
- Linting and formatting
- Type checking
- Security scanning
- Test coverage

### 4. Test the Complete Slice

Verify end-to-end functionality:
- Run all layer tests
- Perform manual testing
- Check edge cases
- Validate acceptance criteria

### 5. Commit the Vertical Slice

Create atomic commits that represent complete features:

```
feat(feature-area): implement story description

- Add domain entity with validation
- Implement use case for business logic
- Add repository methods for persistence
- Create API endpoint for user interaction
- Include comprehensive test coverage

Implements vertical slice for [Story ID]
```

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

## Project Management Integration (Optional)

This skill supports integration with project management tools to track and update work items throughout the vertical slicing process. Configure once per project for seamless workflow integration.

### Configuration

When first using this skill in a project, you'll be prompted to configure your project management tool preference if not already set.

#### Settings Storage

Configuration is stored in `.claude/settings.json`:

```json
{
  "preferences": {
    "project_management": {
      "tool": "manual",  // Options: "linear", "jira", or "manual"
      "update_on_commit": true,
      "include_time_tracking": false
    }
  }
}
```

#### First-Time Setup

If no configuration exists, you'll see:
```
No project management tool configured for this project.
Which tool are you using?
1. Linear (for Linear issues like LIN-123)
2. Jira (for Jira tickets like PROJ-456)
3. Manual/Other (default - provides generic instructions)

Your choice will be saved to .claude/settings.json
```

### Tool-Specific Workflows

#### Linear Workflow

For teams using Linear:

**Issue Format**: `LIN-123`

**Status Values**:
- `Backlog` → `In Progress` → `In Review` → `Done`

**Planning Phase**:
1. Reference Linear issue: `LIN-123`
2. Review issue description and acceptance criteria
3. Update status to "In Progress"
4. Add planning document link to issue

**Implementation Phase**:
1. Reference issue in commits: `feat: implement feature [LIN-123]`
2. Update Linear with progress comments
3. Move to "In Review" when code complete
4. Move to "Done" after deployment

**MCP Integration** (if available):
- Use `mcp__linear__getIssue` to fetch details
- Use `mcp__linear__updateIssue` for status updates
- Use `mcp__linear__createComment` for progress notes

#### Jira Workflow

For teams using Jira:

**Issue Format**: `PROJ-456` (project key varies)

**Status Values**:
- `To Do` → `In Progress` → `Code Review` → `Testing` → `Done`

**Planning Phase**:
1. Reference Jira ticket: `PROJ-456`
2. Review description and acceptance criteria
3. Transition to "In Progress"
4. Add planning document as attachment or link

**Implementation Phase**:
1. Reference ticket in commits: `feat: implement feature [PROJ-456]`
2. Log work and add comments
3. Transition through workflow states
4. Add testing evidence

**MCP Integration** (if available):
- Use `mcp__jira__getIssue` for ticket details
- Use `mcp__jira__transitionIssue` for status changes
- Use `mcp__jira__addComment` for updates
- Use `mcp__jira__logWork` for time tracking

#### Manual Workflow

For teams using other tools or manual tracking:

**Planning Phase**:
1. Document work item ID and description
2. Create planning document in project
3. Share with team as appropriate
4. Update tracking system manually

**Implementation Phase**:
1. Reference work item in commits
2. Update status in your system
3. Document completion
4. Follow team's deployment process

### Integration Points

#### During Planning

```markdown
## Planning Document Header
Work Item: [LIN-123 / PROJ-456 / CUSTOM-789]
Status: Planning → In Progress
Link: [URL to work item]
```

#### During Implementation

```bash
# Commit message format
git commit -m "feat(area): description [WORK-ITEM-ID]

- Implementation details
- Testing approach
- Related to: WORK-ITEM-ID"
```

#### After Deployment

Update work item with:
- Deployment confirmation
- Link to merged PR/commit
- Any relevant metrics
- Time spent (if tracking)

### Changing Configuration

To switch project management tools:

1. Edit `.claude/settings.json`
2. Change `tool` value to "linear", "jira", or "manual"
3. Save the file
4. Next execution will use new settings

### Best Practices

1. **Configure Once**: Set up PM tool preference at project start
2. **Consistent References**: Always include work item IDs
3. **Regular Updates**: Update status at key milestones
4. **Link Artifacts**: Connect planning docs, PRs, and deployments
5. **Time Tracking**: Log effort if your team tracks time

## Remember

- **YAGNI** - Build only what the current story needs
- **Ship Early** - Deploy as soon as the slice works
- **Refactor Continuously** - Clean up as patterns emerge
- **Stay Vertical** - Resist the urge to build horizontal layers
- **Track Progress** - Keep stakeholders informed through PM tool updates

Vertical slicing is not just a technique, it's a mindset shift from "building systems" to "delivering value."