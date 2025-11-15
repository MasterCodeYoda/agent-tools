# Vertical Slicing with Layer Sanctity

## Overview

Vertical slicing is an implementation strategy that delivers working features incrementally while maintaining Clean Architecture principles.

## The Two Orthogonal Principles

### 1. Vertical Slicing (WHEN to build)
- Implement ONE user story at a time
- Complete all layers for that story
- Deliver working software after each story
- Priority-driven: P1 → P2 → P3

### 2. Layer Sanctity (HOW to build)
- Maintain architectural boundaries always
- Dependencies flow inward only
- Each layer has distinct responsibilities
- No shortcuts, even for "simple" features

## Why Vertical Slicing?

### Traditional Horizontal Approach Problems
```
Week 1-2: Build entire Domain layer
Week 3-4: Build entire Application layer
Week 5-6: Build entire Infrastructure layer
Week 7-8: Build entire Framework layer
Week 9: Try to integrate... nothing works!
```

**Problems:**
- No working software for weeks
- Integration issues discovered late
- Can't get user feedback early
- High risk of building wrong things

### Vertical Slicing Benefits
```
Day 1-2: Story 1 - Create Task (all layers)
  ✓ Working feature, can demo
Day 3-4: Story 2 - Complete Task (all layers)
  ✓ Another working feature
Day 5-6: Story 3 - List Tasks (all layers)
  ✓ Fully functional task manager
```

**Benefits:**
- Working software from day one
- Continuous integration
- Early user feedback
- Reduced risk
- Clear progress visibility

## Implementation Workflow

### Step 1: Prioritize User Stories

```
P1 - MVP (Must have for launch):
□ Create Task
□ List Tasks
□ Complete Task

P2 - Enhanced (Important but not critical):
□ Edit Task
□ Delete Task
□ Filter Tasks

P3 - Nice to Have (Can wait):
□ Task Categories
□ Task Assignments
□ Task Comments
```

### Step 2: Implement One Story Vertically

For each story, implement through ALL layers:

```
Story: "As a user, I want to create a task"

1. Domain Layer
   └─ Create Task entity with validation

2. Application Layer
   └─ Create CreateTaskUseCase

3. Infrastructure Layer
   └─ Implement TaskRepository

4. Framework Layer
   └─ Add POST /tasks endpoint

5. Tests
   └─ Test each layer

✓ CHECKPOINT: Can create tasks end-to-end
```

### Step 3: Validate Before Moving On

Before starting the next story:
- Feature works completely
- All tests pass
- Code follows architecture rules
- Could ship if needed

## Detailed Example: Task Management System

### Story 1: Create Task (P1)

**Domain Layer:**
```python
# domain/entities/task.py
class Task:
    def __init__(self, description: str):
        if not description:
            raise ValueError("Task description required")
        self._id = generate_id()
        self._description = description
        self._completed = False
        self._created_at = datetime.now()

    @property
    def id(self) -> str:
        return self._id

    def to_dict(self) -> dict:
        return {
            "id": self._id,
            "description": self._description,
            "completed": self._completed
        }
```

**Application Layer:**
```python
# application/use_cases/create_task.py
class CreateTaskRequest:
    description: str

class CreateTaskResponse:
    task_id: str
    created: bool

class CreateTaskUseCase:
    def __init__(self, task_repository: TaskRepository):
        self._repo = task_repository

    def execute(self, request: CreateTaskRequest) -> CreateTaskResponse:
        task = Task(request.description)
        self._repo.save(task)
        return CreateTaskResponse(
            task_id=task.id,
            created=True
        )
```

**Infrastructure Layer:**
```python
# infrastructure/repositories/memory_task_repository.py
class MemoryTaskRepository(TaskRepository):
    def __init__(self):
        self._tasks = {}

    def save(self, task: Task) -> None:
        self._tasks[task.id] = task

    def find_by_id(self, task_id: str) -> Optional[Task]:
        return self._tasks.get(task_id)
```

**Framework Layer:**
```python
# frameworks/web/controllers/task_controller.py
@app.post("/tasks")
def create_task(request: dict) -> dict:
    use_case = get_create_task_use_case()
    app_request = CreateTaskRequest(
        description=request["description"]
    )
    response = use_case.execute(app_request)
    return {
        "taskId": response.task_id,
        "created": response.created
    }
```

**✓ CHECKPOINT:** Can now create tasks via API!

### Story 2: List Tasks (P1)

Build on existing code, adding list functionality:

**Domain Layer:**
```python
# No changes needed - entities stay same
```

**Application Layer:**
```python
# application/use_cases/list_tasks.py
class ListTasksRequest:
    pass  # No parameters for simple list

class ListTasksResponse:
    tasks: List[TaskView]

class ListTasksUseCase:
    def __init__(self, task_repository: TaskRepository):
        self._repo = task_repository

    def execute(self, request: ListTasksRequest) -> ListTasksResponse:
        tasks = self._repo.find_all()
        views = [TaskView.from_entity(t) for t in tasks]
        return ListTasksResponse(tasks=views)
```

**Infrastructure Layer:**
```python
# Add to memory_task_repository.py
def find_all(self) -> List[Task]:
    return list(self._tasks.values())
```

**Framework Layer:**
```python
@app.get("/tasks")
def list_tasks() -> dict:
    use_case = get_list_tasks_use_case()
    response = use_case.execute(ListTasksRequest())
    return {
        "tasks": [t.to_dict() for t in response.tasks]
    }
```

**✓ CHECKPOINT:** Can create AND list tasks!

### Story 3: Complete Task (P1)

Add ability to mark tasks as complete:

**Domain Layer:**
```python
# Add to Task entity
def complete(self) -> None:
    if self._completed:
        raise ValueError("Task already completed")
    self._completed = True
    self._completed_at = datetime.now()
```

**Application Layer:**
```python
# application/use_cases/complete_task.py
class CompleteTaskRequest:
    task_id: str

class CompleteTaskResponse:
    success: bool

class CompleteTaskUseCase:
    def __init__(self, task_repository: TaskRepository):
        self._repo = task_repository

    def execute(self, request: CompleteTaskRequest) -> CompleteTaskResponse:
        task = self._repo.find_by_id(request.task_id)
        if not task:
            raise TaskNotFoundError(request.task_id)

        task.complete()
        self._repo.save(task)

        return CompleteTaskResponse(success=True)
```

**Framework Layer:**
```python
@app.put("/tasks/{task_id}/complete")
def complete_task(task_id: str) -> dict:
    use_case = get_complete_task_use_case()
    request = CompleteTaskRequest(task_id=task_id)
    response = use_case.execute(request)
    return {"success": response.success}
```

**✓ CHECKPOINT:** Full MVP - create, list, and complete tasks!

## Maintaining Layer Boundaries

### While Building Vertically, Never Compromise Horizontally

**❌ DON'T: Break layers for speed**
```python
# BAD - Controller directly accessing repository
@app.post("/tasks")
def create_task(request):
    task = Task(request["description"])
    repository.save(task)  # Skipping use case!
    return {"id": task.id}
```

**✅ DO: Maintain layers even for simple features**
```python
# GOOD - Proper layer separation
@app.post("/tasks")
def create_task(request):
    use_case = get_create_task_use_case()
    response = use_case.execute(CreateTaskRequest(...))
    return {"id": response.task_id}
```

### The Dependency Rule Still Applies

Even when implementing vertically:
```
Domain knows nothing about outer layers
Application only knows Domain
Infrastructure knows Application + Domain
Framework knows all inner layers
```

## Handling Cross-Cutting Concerns

Some features span multiple stories. Handle incrementally:

### Authentication Example

**Story 1: Create Task (No auth)**
```python
def execute(self, request: CreateTaskRequest):
    task = Task(request.description)
    # No user association yet
```

**Story 4: Add User Authentication (P2)**
```python
def execute(self, request: CreateTaskRequest):
    user = self._get_current_user()  # New
    task = Task(request.description, user.id)  # Modified
```

**Approach:**
1. Start without cross-cutting concern
2. Add it when story requires it
3. Refactor existing features if needed
4. Keep each story independently shippable

## Benefits of This Approach

### 1. Early Value Delivery
- P1 stories deliver MVP quickly
- Can ship and get feedback early
- Validate assumptions before building more

### 2. Reduced Risk
- Find integration issues immediately
- Each story is small and manageable
- Can pivot based on feedback

### 3. Better Prioritization
- Build what's needed now
- Defer complex features
- YAGNI principle in action

### 4. Clear Progress
- Stakeholders see working features
- Easy to track completion
- Natural milestones (story checkpoints)

### 5. Maintained Quality
- Architecture stays clean
- Tests for each layer
- Refactoring is easier with small changes

## Common Pitfalls and Solutions

### Pitfall 1: "This story is too simple for all layers"

**Problem:** Temptation to skip layers for "simple" features

**Solution:** Every feature goes through all layers. Simple features are practice for complex ones. The architecture is the constant.

### Pitfall 2: "We'll refactor to layers later"

**Problem:** Starting without layers, planning to add them later

**Solution:** Start with layers from story 1. It's harder to add layers later than to maintain them from the start.

### Pitfall 3: "The domain model keeps changing"

**Problem:** Each story requires domain model changes

**Solution:** This is expected and good! The domain model evolves based on real requirements, not speculation.

### Pitfall 4: "Too much boilerplate for simple operations"

**Problem:** Lots of code for simple CRUD

**Solution:**
1. Use code generation for true boilerplate
2. Accept that consistency has a cost
3. The pattern pays off as complexity grows

## Workflow Checklist

For each user story:

### Planning
- [ ] Story is clearly defined
- [ ] Acceptance criteria are clear
- [ ] Story is truly independent

### Implementation
- [ ] Domain: Entity/value object created or modified
- [ ] Application: Use case implemented
- [ ] Infrastructure: Repository/gateway implemented
- [ ] Framework: Endpoint/command created
- [ ] Tests: Each layer has tests

### Validation
- [ ] Feature works end-to-end
- [ ] All tests pass
- [ ] Dependency rule maintained
- [ ] Could ship if needed

### Checkpoint
- [ ] Document what was built
- [ ] Update API documentation
- [ ] Commit with clear message
- [ ] Ready for next story

## Evolution Path

As the system grows, maintain the pattern:

### Phase 1: MVP (P1 Stories)
- Basic CRUD operations
- Core business rules
- Minimal viable features

### Phase 2: Enhancement (P2 Stories)
- Additional operations
- Business rule refinements
- Performance optimization

### Phase 3: Advanced (P3 Stories)
- Complex workflows
- Advanced features
- Integration with external systems

### Continuous
- Refactor when patterns emerge
- Extract shared concepts
- Maintain architectural fitness

## Summary

Vertical slicing with layer sanctity enables:
1. **Fast delivery** - Working software from day one
2. **Risk reduction** - Find issues early
3. **Flexibility** - Adapt based on feedback
4. **Quality** - Maintain architecture throughout
5. **Visibility** - Clear progress and value delivery

Remember:
- One story at a time
- All layers for each story
- Validate before moving on
- Never compromise the architecture
- Ship early, ship often