# TypeScript Clean Architecture Guide

## Overview

This guide provides TypeScript-specific patterns and idioms for implementing Clean Architecture. TypeScript's strong typing and interface system make it well-suited for Clean Architecture.

## TypeScript Type System for Clean Architecture

### Interfaces for Contracts

TypeScript interfaces define clear contracts between layers:

```typescript
// Domain layer - Repository interface
export interface TaskRepository {
  save(task: Task): Promise<void>;
  findById(id: string): Promise<Task | null>;
  findAll(): Promise<Task[]>;
}

// Application layer - Use case interface
export interface UseCase<TRequest, TResponse> {
  execute(request: TRequest): Promise<TResponse>;
}
```

### Strict Type Checking

Enable strict mode in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitAny": true,
    "noImplicitThis": true
  }
}
```

## Domain Layer Patterns

### Entities

```typescript
export class Task {
  private readonly _id: string;
  private _description: string;
  private _completed: boolean;
  private _createdAt: Date;
  private _completedAt: Date | null;

  constructor(description: string, id?: string) {
    this.validateDescription(description);
    this._id = id || crypto.randomUUID();
    this._description = description;
    this._completed = false;
    this._createdAt = new Date();
    this._completedAt = null;
  }

  get id(): string {
    return this._id;
  }

  get description(): string {
    return this._description;
  }

  get isCompleted(): boolean {
    return this._completed;
  }

  complete(): void {
    if (this._completed) {
      throw new Error("Task already completed");
    }
    this._completed = true;
    this._completedAt = new Date();
  }

  private validateDescription(description: string): void {
    if (!description || description.trim().length === 0) {
      throw new Error("Description cannot be empty");
    }
  }
}
```

### Value Objects

```typescript
export class Money {
  constructor(
    private readonly _amount: number,
    private readonly _currency: string
  ) {
    if (_amount < 0) {
      throw new Error("Amount cannot be negative");
    }
    if (_currency.length !== 3) {
      throw new Error("Currency must be 3-letter code");
    }
  }

  get amount(): number {
    return this._amount;
  }

  get currency(): string {
    return this._currency;
  }

  add(other: Money): Money {
    if (this._currency !== other.currency) {
      throw new Error("Cannot add different currencies");
    }
    return new Money(this._amount + other.amount, this._currency);
  }

  equals(other: Money): boolean {
    return this._amount === other.amount &&
           this._currency === other.currency;
  }
}
```

## Application Layer Patterns

### Use Cases with DTOs

```typescript
// DTOs
export class CreateTaskRequest {
  constructor(public readonly description: string) {}
}

export class CreateTaskResponse {
  constructor(
    public readonly taskId: string,
    public readonly created: boolean
  ) {}
}

// Use Case
export class CreateTaskUseCase
  implements UseCase<CreateTaskRequest, CreateTaskResponse> {

  constructor(
    private readonly taskRepository: TaskRepository
  ) {}

  async execute(request: CreateTaskRequest): Promise<CreateTaskResponse> {
    const task = new Task(request.description);
    await this.taskRepository.save(task);

    return new CreateTaskResponse(task.id, true);
  }
}
```

## Infrastructure Layer Patterns

### Repository Implementation

```typescript
import { Repository } from "typeorm";
import { Task } from "../../domain/entities/Task";
import { TaskRepository } from "../../domain/repositories/TaskRepository";
import { TaskEntity } from "./entities/TaskEntity";

export class TypeOrmTaskRepository implements TaskRepository {
  constructor(
    private readonly ormRepository: Repository<TaskEntity>
  ) {}

  async save(task: Task): Promise<void> {
    const entity = this.toEntity(task);
    await this.ormRepository.save(entity);
  }

  async findById(id: string): Promise<Task | null> {
    const entity = await this.ormRepository.findOne({ where: { id } });
    return entity ? this.toDomain(entity) : null;
  }

  async findAll(): Promise<Task[]> {
    const entities = await this.ormRepository.find();
    return entities.map(e => this.toDomain(e));
  }

  private toDomain(entity: TaskEntity): Task {
    // Map from persistence to domain
    return new Task(entity.description, entity.id);
  }

  private toEntity(task: Task): TaskEntity {
    // Map from domain to persistence
    const entity = new TaskEntity();
    entity.id = task.id;
    entity.description = task.description;
    // ... map other fields
    return entity;
  }
}
```

## Frameworks Layer Patterns

### Express Controllers

```typescript
import { Router, Request, Response } from "express";
import { CreateTaskUseCase } from "../../application/use-cases/CreateTaskUseCase";

export class TaskController {
  constructor(
    private readonly createTaskUseCase: CreateTaskUseCase
  ) {}

  async createTask(req: Request, res: Response): Promise<void> {
    try {
      const request = new CreateTaskRequest(req.body.description);
      const response = await this.createTaskUseCase.execute(request);

      res.status(201).json({
        id: response.taskId,
        created: response.created
      });
    } catch (error) {
      res.status(400).json({ error: error.message });
    }
  }
}
```

### Dependency Injection

```typescript
// Simple DI Container
export class Container {
  private taskRepository: TaskRepository;
  private createTaskUseCase: CreateTaskUseCase;

  constructor() {
    // Infrastructure
    this.taskRepository = new InMemoryTaskRepository();

    // Application
    this.createTaskUseCase = new CreateTaskUseCase(this.taskRepository);
  }

  getCreateTaskUseCase(): CreateTaskUseCase {
    return this.createTaskUseCase;
  }
}

// Or use a DI library like InversifyJS
import { Container } from "inversify";
import { TYPES } from "./types";

const container = new Container();
container.bind<TaskRepository>(TYPES.TaskRepository)
  .to(InMemoryTaskRepository);
container.bind<CreateTaskUseCase>(TYPES.CreateTaskUseCase)
  .to(CreateTaskUseCase);
```

## Testing Patterns

### Domain Layer Tests

```typescript
import { Task } from "../domain/entities/Task";

describe("Task Entity", () => {
  it("should create a valid task", () => {
    const task = new Task("Learn TypeScript");

    expect(task.description).toBe("Learn TypeScript");
    expect(task.isCompleted).toBe(false);
    expect(task.id).toBeDefined();
  });

  it("should not create task with empty description", () => {
    expect(() => new Task("")).toThrow("Description cannot be empty");
  });

  it("should complete a task", () => {
    const task = new Task("Test task");
    task.complete();

    expect(task.isCompleted).toBe(true);
  });

  it("should not complete task twice", () => {
    const task = new Task("Test task");
    task.complete();

    expect(() => task.complete()).toThrow("Task already completed");
  });
});
```

### Application Layer Tests

```typescript
import { CreateTaskUseCase } from "../application/use-cases/CreateTaskUseCase";

describe("CreateTaskUseCase", () => {
  it("should create a task", async () => {
    const mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn()
    };

    const useCase = new CreateTaskUseCase(mockRepository);
    const request = new CreateTaskRequest("New task");

    const response = await useCase.execute(request);

    expect(response.created).toBe(true);
    expect(mockRepository.save).toHaveBeenCalledTimes(1);
  });
});
```

## Project Structure

```
src/
├── domain/
│   ├── entities/
│   │   └── Task.ts
│   ├── value-objects/
│   │   └── Money.ts
│   ├── repositories/
│   │   └── TaskRepository.ts
│   └── exceptions/
│       └── DomainException.ts
│
├── application/
│   ├── use-cases/
│   │   ├── CreateTaskUseCase.ts
│   │   └── ListTasksUseCase.ts
│   └── dto/
│       └── TaskDto.ts
│
├── infrastructure/
│   ├── repositories/
│   │   └── TypeOrmTaskRepository.ts
│   ├── database/
│   │   └── entities/
│   │       └── TaskEntity.ts
│   └── services/
│       └── EmailService.ts
│
└── presentation/  // or frameworks
    ├── express/
    │   ├── controllers/
    │   │   └── TaskController.ts
    │   ├── routes/
    │   │   └── taskRoutes.ts
    │   └── app.ts
    └── graphql/
        └── resolvers/
            └── taskResolver.ts
```

## TypeScript-Specific Tools

### Development Dependencies

```json
{
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/express": "^4.17.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.0.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "ts-node": "^10.0.0",
    "typescript": "^5.0.0"
  }
}
```

### ESLint Configuration

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended"
  ],
  "parser": "@typescript-eslint/parser",
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/explicit-function-return-type": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "error"
  }
}
```

## Common TypeScript Pitfalls

### 1. Using `any` Type

```typescript
// ❌ BAD - Using any
function processTask(task: any): any {
  return task.complete();
}

// ✅ GOOD - Proper typing
function processTask(task: Task): void {
  task.complete();
}
```

### 2. Not Handling null/undefined

```typescript
// ❌ BAD - Not checking for null
const task = await repository.findById(id);
task.complete(); // Runtime error if null!

// ✅ GOOD - Null checking
const task = await repository.findById(id);
if (!task) {
  throw new TaskNotFoundError(id);
}
task.complete();
```

### 3. Mutating Readonly Properties

```typescript
// ❌ BAD - Public mutable fields
class Task {
  public id: string;
  public completed: boolean; // Can be changed externally!
}

// ✅ GOOD - Private with readonly
class Task {
  private readonly _id: string;
  private _completed: boolean;

  get id(): string {
    return this._id;
  }
}
```

## Summary

TypeScript's features for Clean Architecture:
- **Strong typing** prevents runtime errors
- **Interfaces** define clear contracts
- **Access modifiers** enforce encapsulation
- **Generics** enable reusable patterns
- **Async/await** simplifies asynchronous code

The type system helps enforce architectural boundaries at compile time, making violations immediately visible.