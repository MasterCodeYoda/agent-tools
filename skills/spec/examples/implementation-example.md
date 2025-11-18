# Example: Implementing a Task Management Feature

This example demonstrates the complete implementation of a vertical slice for task creation functionality, following the bottom-up approach.

## Overview

**Feature**: Create and manage tasks
**Work Item**: PROJ-123
**Estimate**: 6 hours
**Status**: In Progress

## Layer 1: Domain Implementation

### Step 1.1: Create Task Entity

```typescript
// domain/entities/Task.ts

export class Task {
  private constructor(
    public readonly id: string,
    public readonly title: string,
    public readonly description: string | null,
    public readonly status: TaskStatus,
    public readonly createdAt: Date,
    public readonly updatedAt: Date
  ) {}

  static create(params: {
    id: string;
    title: string;
    description?: string;
  }): Task {
    // Business validation
    if (!params.title || params.title.trim().length === 0) {
      throw new Error('Task title is required');
    }

    if (params.title.length > 200) {
      throw new Error('Task title must be 200 characters or less');
    }

    const now = new Date();
    return new Task(
      params.id,
      params.title.trim(),
      params.description?.trim() || null,
      TaskStatus.PENDING,
      now,
      now
    );
  }

  markAsComplete(): Task {
    if (this.status === TaskStatus.COMPLETED) {
      throw new Error('Task is already completed');
    }

    return new Task(
      this.id,
      this.title,
      this.description,
      TaskStatus.COMPLETED,
      this.createdAt,
      new Date()
    );
  }
}

export enum TaskStatus {
  PENDING = 'PENDING',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED'
}
```

### Step 1.2: Domain Tests

```typescript
// domain/entities/Task.test.ts

describe('Task Entity', () => {
  describe('create', () => {
    it('should create a valid task', () => {
      const task = Task.create({
        id: '123',
        title: 'Test Task',
        description: 'Test Description'
      });

      expect(task.title).toBe('Test Task');
      expect(task.status).toBe(TaskStatus.PENDING);
      expect(task.createdAt).toBeInstanceOf(Date);
    });

    it('should throw error for empty title', () => {
      expect(() => {
        Task.create({ id: '123', title: '' });
      }).toThrow('Task title is required');
    });

    it('should throw error for title too long', () => {
      const longTitle = 'a'.repeat(201);
      expect(() => {
        Task.create({ id: '123', title: longTitle });
      }).toThrow('Task title must be 200 characters or less');
    });
  });

  describe('markAsComplete', () => {
    it('should mark pending task as complete', () => {
      const task = Task.create({
        id: '123',
        title: 'Test Task'
      });

      const completed = task.markAsComplete();

      expect(completed.status).toBe(TaskStatus.COMPLETED);
      expect(completed.updatedAt).not.toBe(task.updatedAt);
    });
  });
});
```

**✅ Domain Layer Complete** - Tests passing, no dependencies

## Layer 2: Infrastructure Implementation

### Step 2.1: Repository Interface

```typescript
// application/repositories/TaskRepository.ts

import { Task } from '../../domain/entities/Task';

export interface TaskRepository {
  save(task: Task): Promise<Task>;
  findById(id: string): Promise<Task | null>;
  findAll(): Promise<Task[]>;
}
```

### Step 2.2: Repository Implementation

```typescript
// infrastructure/repositories/InMemoryTaskRepository.ts

import { TaskRepository } from '../../application/repositories/TaskRepository';
import { Task } from '../../domain/entities/Task';

export class InMemoryTaskRepository implements TaskRepository {
  private tasks: Map<string, Task> = new Map();

  async save(task: Task): Promise<Task> {
    this.tasks.set(task.id, task);
    return task;
  }

  async findById(id: string): Promise<Task | null> {
    return this.tasks.get(id) || null;
  }

  async findAll(): Promise<Task[]> {
    return Array.from(this.tasks.values());
  }
}
```

### Step 2.3: Infrastructure Tests

```typescript
// infrastructure/repositories/InMemoryTaskRepository.test.ts

describe('InMemoryTaskRepository', () => {
  let repository: InMemoryTaskRepository;

  beforeEach(() => {
    repository = new InMemoryTaskRepository();
  });

  it('should save and retrieve a task', async () => {
    const task = Task.create({
      id: '123',
      title: 'Test Task'
    });

    await repository.save(task);
    const retrieved = await repository.findById('123');

    expect(retrieved).toEqual(task);
  });

  it('should return null for non-existent task', async () => {
    const result = await repository.findById('nonexistent');
    expect(result).toBeNull();
  });

  it('should return all tasks', async () => {
    const task1 = Task.create({ id: '1', title: 'Task 1' });
    const task2 = Task.create({ id: '2', title: 'Task 2' });

    await repository.save(task1);
    await repository.save(task2);

    const all = await repository.findAll();
    expect(all).toHaveLength(2);
  });
});
```

**✅ Infrastructure Layer Complete** - Repository working, tests passing

## Layer 3: Application Implementation

### Step 3.1: Use Case Implementation

```typescript
// application/use-cases/CreateTaskUseCase.ts

import { Task } from '../../domain/entities/Task';
import { TaskRepository } from '../repositories/TaskRepository';
import { IdGenerator } from '../services/IdGenerator';

export interface CreateTaskRequest {
  title: string;
  description?: string;
}

export interface CreateTaskResponse {
  id: string;
  title: string;
  description: string | null;
  status: string;
  createdAt: Date;
}

export class CreateTaskUseCase {
  constructor(
    private taskRepository: TaskRepository,
    private idGenerator: IdGenerator
  ) {}

  async execute(request: CreateTaskRequest): Promise<CreateTaskResponse> {
    // Generate unique ID
    const id = this.idGenerator.generate();

    // Create domain entity
    const task = Task.create({
      id,
      title: request.title,
      description: request.description
    });

    // Persist
    const savedTask = await this.taskRepository.save(task);

    // Map to response
    return {
      id: savedTask.id,
      title: savedTask.title,
      description: savedTask.description,
      status: savedTask.status,
      createdAt: savedTask.createdAt
    };
  }
}
```

### Step 3.2: Application Tests

```typescript
// application/use-cases/CreateTaskUseCase.test.ts

describe('CreateTaskUseCase', () => {
  let useCase: CreateTaskUseCase;
  let mockRepository: jest.Mocked<TaskRepository>;
  let mockIdGenerator: jest.Mocked<IdGenerator>;

  beforeEach(() => {
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn()
    };

    mockIdGenerator = {
      generate: jest.fn().mockReturnValue('generated-id')
    };

    useCase = new CreateTaskUseCase(mockRepository, mockIdGenerator);
  });

  it('should create a task successfully', async () => {
    mockRepository.save.mockImplementation(async (task) => task);

    const request: CreateTaskRequest = {
      title: 'New Task',
      description: 'Task description'
    };

    const response = await useCase.execute(request);

    expect(response.id).toBe('generated-id');
    expect(response.title).toBe('New Task');
    expect(response.status).toBe('PENDING');
    expect(mockRepository.save).toHaveBeenCalledTimes(1);
  });

  it('should handle validation errors', async () => {
    const request: CreateTaskRequest = {
      title: '' // Invalid
    };

    await expect(useCase.execute(request))
      .rejects.toThrow('Task title is required');

    expect(mockRepository.save).not.toHaveBeenCalled();
  });
});
```

**✅ Application Layer Complete** - Use case implemented, tests passing

## Layer 4: Framework Implementation

### Step 4.1: API Controller

```typescript
// framework/api/controllers/TaskController.ts

import { Request, Response } from 'express';
import { CreateTaskUseCase } from '../../../application/use-cases/CreateTaskUseCase';
import { validateCreateTaskRequest } from '../validators/taskValidators';

export class TaskController {
  constructor(
    private createTaskUseCase: CreateTaskUseCase
  ) {}

  async createTask(req: Request, res: Response): Promise<void> {
    try {
      // Validate input
      const validation = validateCreateTaskRequest(req.body);
      if (!validation.isValid) {
        res.status(400).json({
          error: 'Validation failed',
          details: validation.errors
        });
        return;
      }

      // Execute use case
      const result = await this.createTaskUseCase.execute(req.body);

      // Return success response
      res.status(201).json({
        success: true,
        data: result
      });
    } catch (error) {
      // Handle domain errors
      if (error instanceof Error) {
        res.status(400).json({
          error: error.message
        });
      } else {
        res.status(500).json({
          error: 'Internal server error'
        });
      }
    }
  }
}
```

### Step 4.2: Route Configuration

```typescript
// framework/api/routes/taskRoutes.ts

import { Router } from 'express';
import { TaskController } from '../controllers/TaskController';
import { createTaskUseCase } from '../../../container';

const router = Router();
const taskController = new TaskController(createTaskUseCase);

router.post('/tasks', (req, res) =>
  taskController.createTask(req, res)
);

export default router;
```

### Step 4.3: E2E Tests

```typescript
// framework/api/controllers/TaskController.e2e.test.ts

import request from 'supertest';
import { app } from '../app';

describe('POST /tasks', () => {
  it('should create a task successfully', async () => {
    const response = await request(app)
      .post('/tasks')
      .send({
        title: 'E2E Test Task',
        description: 'Testing the complete flow'
      })
      .expect(201);

    expect(response.body.success).toBe(true);
    expect(response.body.data).toHaveProperty('id');
    expect(response.body.data.title).toBe('E2E Test Task');
  });

  it('should return 400 for invalid input', async () => {
    const response = await request(app)
      .post('/tasks')
      .send({
        title: '' // Invalid
      })
      .expect(400);

    expect(response.body.error).toBeDefined();
  });

  it('should return 400 for missing title', async () => {
    const response = await request(app)
      .post('/tasks')
      .send({
        description: 'No title provided'
      })
      .expect(400);

    expect(response.body.error).toBe('Validation failed');
  });
});
```

**✅ Framework Layer Complete** - API working, E2E tests passing

## Quality Checkpoint

### Test Coverage Report
```
Domain Layer:      100% (12/12 lines)
Infrastructure:     95% (19/20 lines)
Application:        90% (27/30 lines)
Framework:          85% (34/40 lines)
Overall:           91% (92/102 lines)
```

### Performance Metrics
```
POST /tasks response time: 45ms (p50)
Memory usage: 12MB
CPU usage: <1%
```

### Security Checklist
- ✅ Input validation implemented
- ✅ Error messages don't leak internals
- ✅ Rate limiting configured
- ✅ SQL injection not possible (no SQL yet)
- ✅ XSS prevention (input sanitization)

## Commit History

```bash
# Progressive commits showing bottom-up development
git commit -m "feat(domain): add Task entity with validation [PROJ-123]"
git commit -m "test(domain): add Task entity unit tests [PROJ-123]"
git commit -m "feat(infra): implement TaskRepository interface [PROJ-123]"
git commit -m "feat(infra): add InMemoryTaskRepository [PROJ-123]"
git commit -m "test(infra): add repository integration tests [PROJ-123]"
git commit -m "feat(app): implement CreateTaskUseCase [PROJ-123]"
git commit -m "test(app): add use case unit tests [PROJ-123]"
git commit -m "feat(api): add POST /tasks endpoint [PROJ-123]"
git commit -m "test(api): add E2E tests for task creation [PROJ-123]"
git commit -m "docs: update API documentation [PROJ-123]"

# Final commit combining everything
git commit -m "feat(tasks): implement task creation vertical slice [PROJ-123]

- Add Task domain entity with business validation
- Implement TaskRepository with in-memory storage
- Create CreateTaskUseCase for orchestration
- Add POST /tasks REST endpoint
- Include comprehensive test coverage (91%)
- Document API in OpenAPI spec

Implements complete vertical slice for task creation.
Performance: <50ms response time
Security: Input validation, error handling

Closes: PROJ-123"
```

## Project Management Updates

### Status Progression
1. **Planning Complete** → In Progress
2. **Domain Layer Done** → Comment: "Domain implementation complete, 100% test coverage"
3. **Infrastructure Done** → Comment: "Repository pattern implemented"
4. **Application Done** → Comment: "Use case working with mocked dependencies"
5. **API Complete** → In Review
6. **Tests Passing** → Comment: "91% coverage, all tests green"
7. **Deployed** → Done

### Time Log
```markdown
| Phase | Estimated | Actual | Notes |
|-------|-----------|--------|-------|
| Planning | 1h | 1.5h | More AC than expected |
| Domain | 1h | 0.75h | Simpler than planned |
| Infrastructure | 1.5h | 1.25h | In-memory faster |
| Application | 1.5h | 1.5h | As expected |
| Framework | 1h | 1.25h | Extra validation |
| Testing | 1h | 0.75h | Good coverage |
| **Total** | **7h** | **7h** | On target |
```

## Lessons Learned

### What Went Well
- Bottom-up approach caught validation issues early
- Each layer tested independently
- Clear separation of concerns
- No coupling between layers

### What Could Improve
- Could have used UUID library instead of custom IdGenerator
- Validation could be extracted to shared module
- Consider adding integration test database

### Next Slice
Ready to implement "Update Task" vertical slice, building on this foundation.

## Definition of Done ✅

- [x] Acceptance criteria met
- [x] All tests passing
- [x] Code reviewed
- [x] Documentation updated
- [x] No security vulnerabilities
- [x] Performance acceptable
- [x] Deployed to staging
- [x] Work item updated to Done