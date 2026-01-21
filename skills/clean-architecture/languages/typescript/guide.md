<!-- Last reviewed: 2026-01-21 -->

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

### Branded Types for Type-Safe Identifiers

Branded types prevent accidentally passing the wrong ID type at compile time:

```typescript
// Brand symbol for nominal typing
declare const BrandSymbol: unique symbol;
type Brand<T, B> = T & { readonly [BrandSymbol]: B };

// Domain-specific ID types
export type UserId = Brand<string, 'UserId'>;
export type OrderId = Brand<string, 'OrderId'>;
export type ProductId = Brand<string, 'ProductId'>;

// Smart constructors with validation
export const UserId = {
  create(value: string): UserId {
    if (!value || value.trim().length === 0) {
      throw new Error('UserId cannot be empty');
    }
    return value as UserId;
  },

  generate(): UserId {
    return crypto.randomUUID() as UserId;
  }
};

// Compile-time safety - these errors are caught at build time
function getUser(id: UserId): Promise<User> { /* ... */ }
function getOrder(id: OrderId): Promise<Order> { /* ... */ }

const userId = UserId.create('user-123');
const orderId = OrderId.create('order-456');

getUser(userId);   // ✅ Correct
getUser(orderId);  // ❌ Compile error: OrderId not assignable to UserId
```

### Result Pattern for Error Handling

The Result pattern makes error handling explicit without exceptions for expected failures:

```typescript
// Core Result type
export type Result<T, E = Error> =
  | { success: true; value: T }
  | { success: false; error: E };

// Result factory functions
export const Result = {
  ok<T>(value: T): Result<T, never> {
    return { success: true, value };
  },

  fail<E>(error: E): Result<never, E> {
    return { success: false, error };
  },

  // Combine multiple results - fails fast on first error
  combine<T, E>(results: Result<T, E>[]): Result<T[], E> {
    const values: T[] = [];
    for (const result of results) {
      if (!result.success) return result;
      values.push(result.value);
    }
    return Result.ok(values);
  }
};

// Domain error types
export type DomainError =
  | { type: 'VALIDATION_ERROR'; field: string; message: string }
  | { type: 'NOT_FOUND'; entity: string; id: string }
  | { type: 'BUSINESS_RULE_VIOLATION'; rule: string; message: string };

// Usage in domain objects
export class Email {
  private constructor(private readonly value: string) {}

  static create(value: string): Result<Email, DomainError> {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'email',
        message: 'Invalid email format'
      });
    }
    return Result.ok(new Email(value));
  }

  toString(): string {
    return this.value;
  }
}

// Caller must handle both cases
const emailResult = Email.create(userInput);
if (!emailResult.success) {
  // Handle error - TypeScript knows emailResult.error exists
  console.error(emailResult.error.message);
  return;
}
// TypeScript knows emailResult.value is Email
const email = emailResult.value;
```

### Entity Base Class with Domain Events

Abstract base class for entities that supports domain event collection:

```typescript
export interface DomainEvent {
  readonly occurredOn: Date;
  readonly eventType: string;
}

export abstract class Entity<TId> {
  private _domainEvents: DomainEvent[] = [];

  protected constructor(protected readonly _id: TId) {}

  get id(): TId {
    return this._id;
  }

  get domainEvents(): ReadonlyArray<DomainEvent> {
    return [...this._domainEvents];
  }

  protected addDomainEvent(event: DomainEvent): void {
    this._domainEvents.push(event);
  }

  clearDomainEvents(): void {
    this._domainEvents = [];
  }

  equals(other: Entity<TId>): boolean {
    if (other === null || other === undefined) return false;
    if (!(other instanceof Entity)) return false;
    return this._id === other._id;
  }
}
```

### Aggregate Root Pattern

Aggregates are clusters of entities with one root that enforces consistency:

```typescript
// Domain events for order aggregate
export interface OrderCreatedEvent extends DomainEvent {
  eventType: 'ORDER_CREATED';
  orderId: OrderId;
  customerId: CustomerId;
}

export interface OrderItemAddedEvent extends DomainEvent {
  eventType: 'ORDER_ITEM_ADDED';
  orderId: OrderId;
  productId: ProductId;
  quantity: number;
}

// Order aggregate root
export class Order extends Entity<OrderId> {
  private _items: OrderItem[] = [];
  private _status: OrderStatus;
  private readonly _customerId: CustomerId;
  private readonly _createdAt: Date;

  // Private constructor - use factory methods
  private constructor(
    id: OrderId,
    customerId: CustomerId,
    status: OrderStatus
  ) {
    super(id);
    this._customerId = customerId;
    this._status = status;
    this._createdAt = new Date();
  }

  // Factory method with Result pattern
  static create(customerId: CustomerId): Result<Order, DomainError> {
    if (!customerId) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'customerId',
        message: 'Customer ID is required'
      });
    }

    const order = new Order(
      OrderId.generate(),
      customerId,
      OrderStatus.DRAFT
    );

    order.addDomainEvent({
      eventType: 'ORDER_CREATED',
      occurredOn: new Date(),
      orderId: order.id,
      customerId
    } as OrderCreatedEvent);

    return Result.ok(order);
  }

  // Reconstitute from persistence (no validation, no events)
  static reconstitute(
    id: OrderId,
    customerId: CustomerId,
    status: OrderStatus,
    items: OrderItem[]
  ): Order {
    const order = new Order(id, customerId, status);
    order._items = items;
    return order;
  }

  // Business method with Result pattern
  addItem(
    productId: ProductId,
    quantity: number,
    unitPrice: Money
  ): Result<void, DomainError> {
    if (this._status !== OrderStatus.DRAFT) {
      return Result.fail({
        type: 'BUSINESS_RULE_VIOLATION',
        rule: 'ORDER_MUST_BE_DRAFT',
        message: 'Cannot modify a submitted order'
      });
    }

    if (quantity <= 0) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'quantity',
        message: 'Quantity must be positive'
      });
    }

    const existingItem = this._items.find(
      item => item.productId === productId
    );

    if (existingItem) {
      existingItem.increaseQuantity(quantity);
    } else {
      this._items.push(new OrderItem(productId, quantity, unitPrice));
    }

    this.addDomainEvent({
      eventType: 'ORDER_ITEM_ADDED',
      occurredOn: new Date(),
      orderId: this.id,
      productId,
      quantity
    } as OrderItemAddedEvent);

    return Result.ok(undefined);
  }

  submit(): Result<void, DomainError> {
    if (this._items.length === 0) {
      return Result.fail({
        type: 'BUSINESS_RULE_VIOLATION',
        rule: 'ORDER_MUST_HAVE_ITEMS',
        message: 'Cannot submit an empty order'
      });
    }

    this._status = OrderStatus.SUBMITTED;
    return Result.ok(undefined);
  }

  get total(): Money {
    return this._items.reduce(
      (sum, item) => sum.add(item.subtotal),
      Money.zero('USD')
    );
  }

  get items(): ReadonlyArray<OrderItem> {
    return [...this._items];
  }

  get status(): OrderStatus {
    return this._status;
  }
}

export enum OrderStatus {
  DRAFT = 'DRAFT',
  SUBMITTED = 'SUBMITTED',
  CONFIRMED = 'CONFIRMED',
  SHIPPED = 'SHIPPED',
  DELIVERED = 'DELIVERED',
  CANCELLED = 'CANCELLED'
}
```

### Enhanced Value Objects with Result Pattern

Value objects use factory methods returning Result for validation:

```typescript
export class Money {
  private constructor(
    private readonly _amount: number,
    private readonly _currency: string
  ) {}

  static create(amount: number, currency: string): Result<Money, DomainError> {
    if (amount < 0) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'amount',
        message: 'Amount cannot be negative'
      });
    }
    if (currency.length !== 3) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'currency',
        message: 'Currency must be 3-letter ISO code'
      });
    }
    return Result.ok(new Money(amount, currency.toUpperCase()));
  }

  static zero(currency: string): Money {
    // Internal use - we trust the currency is valid
    return new Money(0, currency.toUpperCase());
  }

  get amount(): number {
    return this._amount;
  }

  get currency(): string {
    return this._currency;
  }

  add(other: Money): Money {
    if (this._currency !== other._currency) {
      throw new Error('Cannot add different currencies');
    }
    return new Money(this._amount + other._amount, this._currency);
  }

  multiply(factor: number): Money {
    return new Money(this._amount * factor, this._currency);
  }

  equals(other: Money): boolean {
    return (
      this._amount === other._amount &&
      this._currency === other._currency
    );
  }
}

// Additional value object example
export class Address {
  private constructor(
    readonly street: string,
    readonly city: string,
    readonly postalCode: string,
    readonly country: string
  ) {}

  static create(props: {
    street: string;
    city: string;
    postalCode: string;
    country: string;
  }): Result<Address, DomainError> {
    if (!props.street?.trim()) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'street',
        message: 'Street is required'
      });
    }
    if (!props.city?.trim()) {
      return Result.fail({
        type: 'VALIDATION_ERROR',
        field: 'city',
        message: 'City is required'
      });
    }
    // Additional validation...

    return Result.ok(new Address(
      props.street.trim(),
      props.city.trim(),
      props.postalCode.trim(),
      props.country.toUpperCase()
    ));
  }

  equals(other: Address): boolean {
    return (
      this.street === other.street &&
      this.city === other.city &&
      this.postalCode === other.postalCode &&
      this.country === other.country
    );
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

### Specification Pattern

Encapsulate business rules as composable, reusable specifications:

```typescript
// domain/specifications/specification.ts
export interface Specification<T> {
  isSatisfiedBy(candidate: T): boolean;
}

export abstract class CompositeSpecification<T> implements Specification<T> {
  abstract isSatisfiedBy(candidate: T): boolean;

  and(other: Specification<T>): Specification<T> {
    return new AndSpecification(this, other);
  }

  or(other: Specification<T>): Specification<T> {
    return new OrSpecification(this, other);
  }

  not(): Specification<T> {
    return new NotSpecification(this);
  }
}

class AndSpecification<T> extends CompositeSpecification<T> {
  constructor(
    private left: Specification<T>,
    private right: Specification<T>,
  ) {
    super();
  }

  isSatisfiedBy(candidate: T): boolean {
    return (
      this.left.isSatisfiedBy(candidate) &&
      this.right.isSatisfiedBy(candidate)
    );
  }
}

class OrSpecification<T> extends CompositeSpecification<T> {
  constructor(
    private left: Specification<T>,
    private right: Specification<T>,
  ) {
    super();
  }

  isSatisfiedBy(candidate: T): boolean {
    return (
      this.left.isSatisfiedBy(candidate) ||
      this.right.isSatisfiedBy(candidate)
    );
  }
}

class NotSpecification<T> extends CompositeSpecification<T> {
  constructor(private spec: Specification<T>) {
    super();
  }

  isSatisfiedBy(candidate: T): boolean {
    return !this.spec.isSatisfiedBy(candidate);
  }
}

// Example: Order specifications
export class OrderIsReadyToShip extends CompositeSpecification<Order> {
  isSatisfiedBy(order: Order): boolean {
    return order.status === OrderStatus.CONFIRMED && order.isPaid;
  }
}

export class OrderHasMinimumValue extends CompositeSpecification<Order> {
  constructor(private minValue: Money) {
    super();
  }

  isSatisfiedBy(order: Order): boolean {
    return order.total.amount >= this.minValue.amount;
  }
}

// Usage
const readyToShip = new OrderIsReadyToShip();
// Note: For known-valid hardcoded values, we can assert non-null
// In production code, always check result.success first
const moneyResult = Money.create(100, 'USD');
if (!moneyResult.success) throw new Error('Invalid money value');
const highValue = new OrderHasMinimumValue(moneyResult.value);
const priorityShipping = readyToShip.and(highValue);

const orders = await orderRepository.findAll();
const priorityOrders = orders.filter((o) => priorityShipping.isSatisfiedBy(o));
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

### Prisma Repository Implementation

Prisma provides type-safe database access with auto-generated types from your schema:

```prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Task {
  id          String    @id @default(uuid())
  description String
  completed   Boolean   @default(false)
  createdAt   DateTime  @default(now()) @map("created_at")
  completedAt DateTime? @map("completed_at")
  customerId  String    @map("customer_id")
  customer    Customer  @relation(fields: [customerId], references: [id])

  @@map("tasks")
}

model Customer {
  id    String @id @default(uuid())
  email String @unique
  name  String
  tasks Task[]

  @@map("customers")
}
```

```typescript
// infrastructure/repositories/prisma-task.repository.ts
import { PrismaClient, Task as PrismaTask } from '@prisma/client';
import { Task, TaskId } from '../../domain/entities/task';
import { TaskRepository } from '../../domain/repositories/task.repository';

export class PrismaTaskRepository implements TaskRepository {
  constructor(private readonly prisma: PrismaClient) {}

  async save(task: Task): Promise<void> {
    await this.prisma.task.upsert({
      where: { id: task.id },
      update: this.toData(task),
      create: this.toData(task),
    });
  }

  async findById(id: TaskId): Promise<Task | null> {
    const data = await this.prisma.task.findUnique({
      where: { id },
    });
    return data ? this.toDomain(data) : null;
  }

  async findByCustomerId(customerId: string): Promise<Task[]> {
    const data = await this.prisma.task.findMany({
      where: { customerId },
      orderBy: { createdAt: 'desc' },
    });
    return data.map((d) => this.toDomain(d));
  }

  async findAll(): Promise<Task[]> {
    const data = await this.prisma.task.findMany({
      orderBy: { createdAt: 'desc' },
    });
    return data.map((d) => this.toDomain(d));
  }

  // Map from persistence to domain
  private toDomain(data: PrismaTask): Task {
    return Task.reconstitute(
      TaskId.create(data.id),
      data.description,
      data.completed,
      data.createdAt,
      data.completedAt,
    );
  }

  // Map from domain to persistence
  private toData(task: Task): Omit<PrismaTask, 'customer'> {
    return {
      id: task.id,
      description: task.description,
      completed: task.isCompleted,
      createdAt: task.createdAt,
      completedAt: task.completedAt,
      customerId: task.customerId,
    };
  }
}
```

### Domain Event Publishing with Prisma

Publish domain events after successful persistence:

```typescript
// infrastructure/repositories/prisma-task.repository.ts
export class PrismaTaskRepository implements TaskRepository {
  constructor(
    private readonly prisma: PrismaClient,
    private readonly eventPublisher: DomainEventPublisher,
  ) {}

  async save(task: Task): Promise<void> {
    // Capture events before clearing
    const events = task.domainEvents;

    await this.prisma.task.upsert({
      where: { id: task.id },
      update: this.toData(task),
      create: this.toData(task),
    });

    // Publish events after successful persistence
    task.clearDomainEvents();
    for (const event of events) {
      await this.eventPublisher.publish(event);
    }
  }
}
```

### Domain Event Dispatcher

A complete domain event dispatcher with typed handlers:

```typescript
// shared/domain/events/domain-event.ts
export interface DomainEvent {
  readonly occurredOn: Date;
  readonly eventType: string;
}

// shared/domain/events/event-dispatcher.ts
export interface DomainEventHandler<T extends DomainEvent> {
  handle(event: T): Promise<void>;
}

export class DomainEventDispatcher {
  private handlers = new Map<string, DomainEventHandler<DomainEvent>[]>();

  register<T extends DomainEvent>(
    eventType: string,
    handler: DomainEventHandler<T>,
  ): void {
    const existing = this.handlers.get(eventType) ?? [];
    existing.push(handler as DomainEventHandler<DomainEvent>);
    this.handlers.set(eventType, existing);
  }

  async dispatch(event: DomainEvent): Promise<void> {
    const handlers = this.handlers.get(event.eventType) ?? [];
    await Promise.all(handlers.map((h) => h.handle(event)));
  }

  async dispatchAll(events: DomainEvent[]): Promise<void> {
    for (const event of events) {
      await this.dispatch(event);
    }
  }
}

// Example handler
export class SendWelcomeEmailHandler
  implements DomainEventHandler<UserCreatedEvent>
{
  constructor(private readonly emailService: EmailService) {}

  async handle(event: UserCreatedEvent): Promise<void> {
    await this.emailService.sendWelcome(event.userId, event.email);
  }
}

// Registration in module
const dispatcher = new DomainEventDispatcher();
dispatcher.register('USER_CREATED', new SendWelcomeEmailHandler(emailService));
dispatcher.register('USER_CREATED', new CreateAuditLogHandler(auditService));
```

### Drizzle ORM (Alternative)

For projects preferring SQL-like syntax with type safety:

```typescript
// infrastructure/repositories/drizzle-task.repository.ts
import { eq } from 'drizzle-orm';
import { db } from '../database/drizzle';
import { tasks } from '../database/schema';
import { Task, TaskId } from '../../domain/entities/task';
import { TaskRepository } from '../../domain/repositories/task.repository';

export class DrizzleTaskRepository implements TaskRepository {
  async save(task: Task): Promise<void> {
    await db
      .insert(tasks)
      .values(this.toData(task))
      .onConflictDoUpdate({
        target: tasks.id,
        set: this.toData(task),
      });
  }

  async findById(id: TaskId): Promise<Task | null> {
    const [data] = await db
      .select()
      .from(tasks)
      .where(eq(tasks.id, id));
    return data ? this.toDomain(data) : null;
  }

  // ... mapping methods similar to Prisma
}
```

### Unit of Work Pattern

Coordinate multiple repository operations within a single transaction:

```typescript
// application/interfaces/unit-of-work.ts
export interface UnitOfWork {
  taskRepository: TaskRepository;
  orderRepository: OrderRepository;
  begin(): Promise<void>;
  commit(): Promise<void>;
  rollback(): Promise<void>;
}

// infrastructure/unit-of-work/prisma-unit-of-work.ts
import { PrismaClient, Prisma } from '@prisma/client';

export class PrismaUnitOfWork implements UnitOfWork {
  private tx: Prisma.TransactionClient | null = null;
  private _taskRepository: TaskRepository | null = null;
  private _orderRepository: OrderRepository | null = null;

  constructor(private readonly prisma: PrismaClient) {}

  get taskRepository(): TaskRepository {
    if (!this.tx) throw new Error('Transaction not started');
    if (!this._taskRepository) {
      this._taskRepository = new PrismaTaskRepository(this.tx);
    }
    return this._taskRepository;
  }

  get orderRepository(): OrderRepository {
    if (!this.tx) throw new Error('Transaction not started');
    if (!this._orderRepository) {
      this._orderRepository = new PrismaOrderRepository(this.tx);
    }
    return this._orderRepository;
  }

  async begin(): Promise<void> {
    // Using Prisma's interactive transaction
    return new Promise((resolve) => {
      this.prisma.$transaction(async (tx) => {
        this.tx = tx;
        resolve();
        // Transaction held open until commit/rollback
        await new Promise((r) => (this.commitResolve = r));
      });
    });
  }

  private commitResolve: (() => void) | null = null;

  async commit(): Promise<void> {
    if (this.commitResolve) {
      this.commitResolve();
      this.tx = null;
    }
  }

  async rollback(): Promise<void> {
    if (this.tx) {
      throw new Error('Rollback requested');
    }
  }
}

// Usage in use case
export class PlaceOrderUseCase {
  constructor(private readonly uow: UnitOfWork) {}

  async execute(request: PlaceOrderRequest): Promise<Result<OrderId, DomainError>> {
    await this.uow.begin();

    try {
      // Multiple operations in single transaction
      const order = Order.create(request.customerId);
      if (!order.success) {
        await this.uow.rollback();
        return order;
      }

      for (const item of request.items) {
        order.value.addItem(item.productId, item.quantity, item.price);
      }

      await this.uow.orderRepository.save(order.value);
      await this.uow.taskRepository.save(
        Task.create(`Fulfill order ${order.value.id}`).value,
      );

      await this.uow.commit();
      return Result.ok(order.value.id);
    } catch (error) {
      await this.uow.rollback();
      throw error;
    }
  }
}
```

## Frameworks Layer Patterns

### Recommended Frameworks

| Use Case | Recommended Framework |
|----------|----------------------|
| Backend API | NestJS |
| Full-stack React | Next.js App Router |
| Both (API + UI) | NestJS + Next.js |

### NestJS Layer Mapping

NestJS concepts map directly to Clean Architecture layers:

| Clean Architecture | NestJS Concept |
|-------------------|----------------|
| Frameworks | Controllers, Modules, main.ts |
| Infrastructure | Injectable Services, Repository implementations |
| Application | Use Cases as @Injectable services |
| Domain | Pure TypeScript classes (no decorators) |

### NestJS Module Organization

Organize modules by feature (bounded context), not by technical layer:

```typescript
// ✅ GOOD - Feature-based modules
// tasks/tasks.module.ts
@Module({
  imports: [PrismaModule],
  controllers: [TasksController],
  providers: [
    CreateTaskUseCase,
    CompleteTaskUseCase,
    {
      provide: TASK_REPOSITORY,
      useClass: PrismaTaskRepository,
    },
  ],
  exports: [CreateTaskUseCase],
})
export class TasksModule {}

// ❌ BAD - Technical-layer modules
// controllers.module.ts, services.module.ts, repositories.module.ts
```

### NestJS Controllers

Controllers are the entry point - convert HTTP to use case requests:

```typescript
import {
  Controller,
  Post,
  Get,
  Body,
  Param,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { CreateTaskUseCase } from '../application/create-task.use-case';
import { CreateTaskDto } from './dto/create-task.dto';

@Controller('tasks')
export class TasksController {
  constructor(
    private readonly createTaskUseCase: CreateTaskUseCase,
  ) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() dto: CreateTaskDto) {
    const result = await this.createTaskUseCase.execute({
      description: dto.description,
    });

    if (!result.success) {
      // Exception filter handles this
      throw new DomainExceptionFilter(result.error);
    }

    return {
      id: result.value.taskId,
      created: true,
    };
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    // ... similar pattern
  }
}
```

### Dependency Injection with Interface Tokens

Use symbols to inject interfaces (Clean Architecture's dependency inversion):

```typescript
// tokens.ts - Define injection tokens
export const TASK_REPOSITORY = Symbol('TASK_REPOSITORY');
export const NOTIFICATION_SERVICE = Symbol('NOTIFICATION_SERVICE');

// create-task.use-case.ts - Use case depends on interfaces
@Injectable()
export class CreateTaskUseCase {
  constructor(
    @Inject(TASK_REPOSITORY)
    private readonly taskRepository: TaskRepository,
    @Inject(NOTIFICATION_SERVICE)
    private readonly notificationService: NotificationService,
  ) {}

  async execute(request: CreateTaskRequest): Promise<Result<CreateTaskResponse, DomainError>> {
    const taskResult = Task.create(request.description);
    if (!taskResult.success) return taskResult;

    await this.taskRepository.save(taskResult.value);
    await this.notificationService.notifyTaskCreated(taskResult.value);

    return Result.ok({
      taskId: taskResult.value.id,
      created: true,
    });
  }
}

// tasks.module.ts - Wire implementations
@Module({
  providers: [
    CreateTaskUseCase,
    {
      provide: TASK_REPOSITORY,
      useClass: PrismaTaskRepository,
    },
    {
      provide: NOTIFICATION_SERVICE,
      useClass: EmailNotificationService,
    },
  ],
})
export class TasksModule {}
```

### Exception Filters

Map domain errors to HTTP responses:

```typescript
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpStatus,
} from '@nestjs/common';
import { Response } from 'express';
import { DomainError } from '../domain/errors';

export class DomainException extends Error {
  constructor(public readonly domainError: DomainError) {
    super(domainError.message);
  }
}

@Catch(DomainException)
export class DomainExceptionFilter implements ExceptionFilter {
  catch(exception: DomainException, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const error = exception.domainError;

    const statusMap: Record<DomainError['type'], number> = {
      VALIDATION_ERROR: HttpStatus.BAD_REQUEST,
      NOT_FOUND: HttpStatus.NOT_FOUND,
      BUSINESS_RULE_VIOLATION: HttpStatus.UNPROCESSABLE_ENTITY,
    };

    response.status(statusMap[error.type]).json({
      type: error.type,
      message: error.message,
      ...(error.type === 'VALIDATION_ERROR' && { field: error.field }),
    });
  }
}
```

### Guards for Authorization

```typescript
import { Injectable, CanActivate, ExecutionContext } from '@nestjs/common';
import { Reflector } from '@nestjs/core';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.get<string[]>(
      'roles',
      context.getHandler(),
    );
    if (!requiredRoles) return true;

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    return requiredRoles.some((role) => user.roles?.includes(role));
  }
}

// Usage with decorator
@Post()
@Roles('admin')
@UseGuards(RolesGuard)
async createTask(@Body() dto: CreateTaskDto) {
  // ...
}
```

### Validation Pipes with Zod

Use Zod for runtime validation that integrates with TypeScript types:

```typescript
import { PipeTransform, Injectable, BadRequestException } from '@nestjs/common';
import { ZodSchema, ZodError } from 'zod';

@Injectable()
export class ZodValidationPipe implements PipeTransform {
  constructor(private schema: ZodSchema) {}

  transform(value: unknown) {
    const result = this.schema.safeParse(value);
    if (!result.success) {
      throw new BadRequestException({
        message: 'Validation failed',
        errors: result.error.errors,
      });
    }
    return result.data;
  }
}

// DTO with Zod schema
import { z } from 'zod';

export const CreateTaskSchema = z.object({
  description: z.string().min(1).max(500),
  dueDate: z.string().datetime().optional(),
});

export type CreateTaskDto = z.infer<typeof CreateTaskSchema>;

// Usage in controller
@Post()
async create(
  @Body(new ZodValidationPipe(CreateTaskSchema)) dto: CreateTaskDto,
) {
  // dto is validated and typed
}
```

### CQRS Pattern (Optional)

For complex domains, separate read and write operations:

```typescript
import { CommandHandler, ICommandHandler, QueryHandler, IQueryHandler } from '@nestjs/cqrs';

// Command
export class CreateTaskCommand {
  constructor(
    public readonly description: string,
    public readonly userId: UserId,
  ) {}
}

@CommandHandler(CreateTaskCommand)
export class CreateTaskHandler implements ICommandHandler<CreateTaskCommand> {
  constructor(
    @Inject(TASK_REPOSITORY)
    private readonly taskRepository: TaskRepository,
  ) {}

  async execute(command: CreateTaskCommand): Promise<Result<TaskId, DomainError>> {
    const taskResult = Task.create(command.description, command.userId);
    if (!taskResult.success) return taskResult;

    await this.taskRepository.save(taskResult.value);
    return Result.ok(taskResult.value.id);
  }
}

// Query
export class GetTaskQuery {
  constructor(public readonly taskId: TaskId) {}
}

@QueryHandler(GetTaskQuery)
export class GetTaskHandler implements IQueryHandler<GetTaskQuery> {
  constructor(
    @Inject(TASK_REPOSITORY)
    private readonly taskRepository: TaskRepository,
  ) {}

  async execute(query: GetTaskQuery): Promise<TaskView | null> {
    return this.taskRepository.findById(query.taskId);
  }
}

// Usage in controller
@Controller('tasks')
export class TasksController {
  constructor(
    private readonly commandBus: CommandBus,
    private readonly queryBus: QueryBus,
  ) {}

  @Post()
  async create(@Body() dto: CreateTaskDto, @CurrentUser() user: User) {
    return this.commandBus.execute(
      new CreateTaskCommand(dto.description, user.id),
    );
  }

  @Get(':id')
  async findOne(@Param('id') id: string) {
    return this.queryBus.execute(new GetTaskQuery(TaskId.create(id)));
  }
}
```

> **When to use CQRS**: Complex domains with different read/write models, event sourcing, or high-scale read requirements. For simpler CRUD apps, standard use cases are sufficient.

### Next.js App Router Patterns

For full-stack React applications, Next.js App Router integrates cleanly with Clean Architecture:

#### Next.js Layer Mapping

| Clean Architecture | Next.js Implementation |
|-------------------|----------------------|
| Domain | `src/domain/` - Pure TypeScript |
| Application | `src/application/` - Use cases |
| Infrastructure | `src/infrastructure/` - Repositories |
| Frameworks | `app/` - Routes, Components, Server Actions |

#### Directory Structure

```
project/
├── src/
│   ├── domain/
│   │   ├── entities/
│   │   └── repositories/      # Interfaces only
│   ├── application/
│   │   └── use-cases/
│   └── infrastructure/
│       └── repositories/      # Prisma implementations
├── app/                       # Frameworks layer
│   ├── (features)/
│   │   └── tasks/
│   │       ├── page.tsx       # Server Component
│   │       ├── actions.ts     # Server Actions
│   │       └── components/
│   └── api/                   # Route Handlers (optional)
├── lib/
│   └── container.ts           # DI composition root
└── prisma/
    └── schema.prisma
```

#### Server Components (Read Path)

Server Components can directly invoke use cases for data fetching:

```typescript
// app/(features)/tasks/page.tsx
import { getContainer } from '@/lib/container';

export default async function TasksPage() {
  const container = getContainer();
  const listTasksUseCase = container.getListTasksUseCase();

  const result = await listTasksUseCase.execute({});

  if (!result.success) {
    // Handle error - could throw to error boundary
    return <ErrorDisplay error={result.error} />;
  }

  return (
    <div>
      <h1>Tasks</h1>
      <TaskList tasks={result.value.tasks} />
      <CreateTaskForm />
    </div>
  );
}
```

#### Server Actions (Write Path)

Server Actions are the transport layer for mutations:

```typescript
// app/(features)/tasks/actions.ts
'use server';

import { revalidatePath } from 'next/cache';
import { getContainer } from '@/lib/container';
import { CreateTaskSchema } from './schemas';

export async function createTask(formData: FormData) {
  // 1. Parse and validate input
  const parsed = CreateTaskSchema.safeParse({
    description: formData.get('description'),
  });

  if (!parsed.success) {
    return {
      success: false,
      error: { type: 'VALIDATION_ERROR', errors: parsed.error.flatten() },
    };
  }

  // 2. Call use case
  const container = getContainer();
  const useCase = container.getCreateTaskUseCase();
  const result = await useCase.execute(parsed.data);

  // 3. Handle result
  if (!result.success) {
    return { success: false, error: result.error };
  }

  // 4. Revalidate cache
  revalidatePath('/tasks');

  return { success: true, data: result.value };
}

export async function completeTask(taskId: string) {
  const container = getContainer();
  const useCase = container.getCompleteTaskUseCase();

  const result = await useCase.execute({ taskId: TaskId.create(taskId) });

  if (!result.success) {
    return { success: false, error: result.error };
  }

  revalidatePath('/tasks');
  return { success: true };
}
```

#### Client Components

Client components use `useActionState` for form handling:

```typescript
// app/(features)/tasks/components/CreateTaskForm.tsx
'use client';

import { useActionState } from 'react';
import { createTask } from '../actions';

export function CreateTaskForm() {
  const [state, formAction, isPending] = useActionState(
    async (_prevState: unknown, formData: FormData) => {
      return createTask(formData);
    },
    null,
  );

  return (
    <form action={formAction}>
      <input
        name="description"
        placeholder="Task description"
        disabled={isPending}
      />
      <button type="submit" disabled={isPending}>
        {isPending ? 'Creating...' : 'Create Task'}
      </button>

      {state && !state.success && (
        <p className="error">{state.error.message}</p>
      )}
    </form>
  );
}
```

#### DI Container for Next.js

Simple composition root pattern:

```typescript
// lib/container.ts
import { PrismaClient } from '@prisma/client';
import { PrismaTaskRepository } from '@/infrastructure/repositories/prisma-task.repository';
import { CreateTaskUseCase } from '@/application/use-cases/create-task.use-case';
import { ListTasksUseCase } from '@/application/use-cases/list-tasks.use-case';

// Singleton pattern for Prisma in Next.js
const globalForPrisma = globalThis as unknown as { prisma: PrismaClient };
const prisma = globalForPrisma.prisma ?? new PrismaClient();
if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

class Container {
  private taskRepository = new PrismaTaskRepository(prisma);

  getCreateTaskUseCase() {
    return new CreateTaskUseCase(this.taskRepository);
  }

  getListTasksUseCase() {
    return new ListTasksUseCase(this.taskRepository);
  }
}

let container: Container;

export function getContainer(): Container {
  if (!container) {
    container = new Container();
  }
  return container;
}
```

#### Route Handlers (Optional REST API)

When you need REST endpoints alongside Server Actions:

```typescript
// app/api/tasks/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { getContainer } from '@/lib/container';
import { CreateTaskSchema } from '@/app/(features)/tasks/schemas';

export async function GET() {
  const container = getContainer();
  const result = await container.getListTasksUseCase().execute({});

  if (!result.success) {
    return NextResponse.json({ error: result.error }, { status: 400 });
  }

  return NextResponse.json(result.value);
}

export async function POST(request: NextRequest) {
  const body = await request.json();
  const parsed = CreateTaskSchema.safeParse(body);

  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const container = getContainer();
  const result = await container.getCreateTaskUseCase().execute(parsed.data);

  if (!result.success) {
    return NextResponse.json({ error: result.error }, { status: 422 });
  }

  return NextResponse.json(result.value, { status: 201 });
}
```

#### Clean Architecture Rules for Next.js

1. **Server Components call use cases**, not repositories directly
2. **Server Actions are transport layer** - validate, call use case, revalidate
3. **Domain and Application layers have no Next.js imports**
4. **Client Components are pure UI** - delegate mutations to Server Actions

## Testing Patterns

### Test Helpers for Result Pattern

Create helpers to make Result assertions cleaner:

```typescript
// test/helpers/result.helpers.ts
import { Result, DomainError } from '../../src/domain/result';

export function expectSuccess<T, E>(result: Result<T, E>): T {
  expect(result.success).toBe(true);
  if (!result.success) throw new Error('Expected success');
  return result.value;
}

export function expectFailure<T>(
  result: Result<T, DomainError>,
): DomainError {
  expect(result.success).toBe(false);
  if (result.success) throw new Error('Expected failure');
  return result.error;
}

export function expectValidationError(
  result: Result<unknown, DomainError>,
  field: string,
): void {
  const error = expectFailure(result);
  expect(error.type).toBe('VALIDATION_ERROR');
  if (error.type === 'VALIDATION_ERROR') {
    expect(error.field).toBe(field);
  }
}
```

### Domain Layer Tests with Result Pattern

```typescript
import { Task } from '../domain/entities/task';
import { expectSuccess, expectFailure, expectValidationError } from './helpers/result.helpers';

describe('Task Entity', () => {
  describe('create', () => {
    it('should create a valid task', () => {
      const result = Task.create('Learn TypeScript', customerId);

      const task = expectSuccess(result);
      expect(task.description).toBe('Learn TypeScript');
      expect(task.isCompleted).toBe(false);
    });

    it('should fail with empty description', () => {
      const result = Task.create('', customerId);

      expectValidationError(result, 'description');
    });

    it('should emit TaskCreated domain event', () => {
      const result = Task.create('New task', customerId);

      const task = expectSuccess(result);
      expect(task.domainEvents).toHaveLength(1);
      expect(task.domainEvents[0].eventType).toBe('TASK_CREATED');
    });
  });

  describe('complete', () => {
    it('should complete a task', () => {
      const task = expectSuccess(Task.create('Test task', customerId));

      const result = task.complete();

      expectSuccess(result);
      expect(task.isCompleted).toBe(true);
    });

    it('should fail when completing already completed task', () => {
      const task = expectSuccess(Task.create('Test task', customerId));
      task.complete();

      const result = task.complete();

      const error = expectFailure(result);
      expect(error.type).toBe('BUSINESS_RULE_VIOLATION');
    });
  });
});
```

### Application Layer Tests

```typescript
import { CreateTaskUseCase } from '../application/use-cases/create-task.use-case';
import { expectSuccess, expectFailure } from './helpers/result.helpers';

describe('CreateTaskUseCase', () => {
  let useCase: CreateTaskUseCase;
  let mockRepository: jest.Mocked<TaskRepository>;

  beforeEach(() => {
    mockRepository = {
      save: jest.fn().mockResolvedValue(undefined),
      findById: jest.fn(),
      findAll: jest.fn(),
    };
    useCase = new CreateTaskUseCase(mockRepository);
  });

  it('should create a task successfully', async () => {
    const result = await useCase.execute({
      description: 'New task',
      customerId: 'customer-123',
    });

    const response = expectSuccess(result);
    expect(response.taskId).toBeDefined();
    expect(mockRepository.save).toHaveBeenCalledTimes(1);
  });

  it('should propagate domain validation errors', async () => {
    const result = await useCase.execute({
      description: '', // Invalid
      customerId: 'customer-123',
    });

    const error = expectFailure(result);
    expect(error.type).toBe('VALIDATION_ERROR');
  });
});
```

### NestJS Integration Tests

Use NestJS TestingModule to test with real DI:

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';
import { TASK_REPOSITORY } from '../src/tasks/tokens';
import { TaskRepository } from '../src/tasks/domain/repositories/task.repository';

describe('TasksController (e2e)', () => {
  let app: INestApplication;
  let mockRepository: jest.Mocked<TaskRepository>;

  beforeEach(async () => {
    mockRepository = {
      save: jest.fn().mockResolvedValue(undefined),
      findById: jest.fn(),
      findAll: jest.fn().mockResolvedValue([]),
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TASK_REPOSITORY)
      .useValue(mockRepository)
      .compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  describe('POST /tasks', () => {
    it('should create a task', async () => {
      const response = await request(app.getHttpServer())
        .post('/tasks')
        .send({ description: 'Test task' })
        .expect(201);

      expect(response.body.id).toBeDefined();
      expect(mockRepository.save).toHaveBeenCalled();
    });

    it('should return 400 for invalid input', async () => {
      await request(app.getHttpServer())
        .post('/tasks')
        .send({ description: '' })
        .expect(400);
    });
  });

  describe('GET /tasks', () => {
    it('should return all tasks', async () => {
      mockRepository.findAll.mockResolvedValue([
        Task.reconstitute(TaskId.create('1'), 'Task 1', false, new Date(), null),
      ]);

      const response = await request(app.getHttpServer())
        .get('/tasks')
        .expect(200);

      expect(response.body).toHaveLength(1);
    });
  });
});
```

### Unit Testing NestJS Services

```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { CreateTaskUseCase } from './create-task.use-case';
import { TASK_REPOSITORY } from '../tokens';

describe('CreateTaskUseCase', () => {
  let useCase: CreateTaskUseCase;
  let mockRepository: jest.Mocked<TaskRepository>;

  beforeEach(async () => {
    mockRepository = {
      save: jest.fn(),
      findById: jest.fn(),
      findAll: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CreateTaskUseCase,
        {
          provide: TASK_REPOSITORY,
          useValue: mockRepository,
        },
      ],
    }).compile();

    useCase = module.get<CreateTaskUseCase>(CreateTaskUseCase);
  });

  it('should be defined', () => {
    expect(useCase).toBeDefined();
  });

  // ... additional tests
});
```

## Project Structure

### NestJS Backend Structure

Feature-based modules containing all layers:

```
src/
├── main.ts                      # Bootstrap
├── app.module.ts                # Root module
│
├── tasks/                       # Feature module
│   ├── tasks.module.ts
│   ├── tokens.ts                # DI tokens
│   │
│   ├── domain/                  # Domain layer
│   │   ├── entities/
│   │   │   └── task.ts
│   │   ├── value-objects/
│   │   │   └── task-id.ts
│   │   ├── repositories/
│   │   │   └── task.repository.ts    # Interface
│   │   └── events/
│   │       └── task-created.event.ts
│   │
│   ├── application/             # Application layer
│   │   └── use-cases/
│   │       ├── create-task.use-case.ts
│   │       └── list-tasks.use-case.ts
│   │
│   ├── infrastructure/          # Infrastructure layer
│   │   └── repositories/
│   │       └── prisma-task.repository.ts
│   │
│   └── presentation/            # Frameworks layer
│       ├── controllers/
│       │   └── tasks.controller.ts
│       └── dto/
│           └── create-task.dto.ts
│
├── shared/                      # Shared kernel
│   ├── domain/
│   │   ├── entity.base.ts
│   │   ├── result.ts
│   │   └── domain-event.ts
│   └── infrastructure/
│       └── prisma/
│           └── prisma.module.ts
│
└── config/
    └── configuration.ts

prisma/
└── schema.prisma
```

### Next.js Full-Stack Structure

Clean separation with `src/` for business logic and `app/` for framework:

```
├── src/                         # Business logic (framework-agnostic)
│   ├── domain/
│   │   ├── entities/
│   │   │   └── task.ts
│   │   ├── value-objects/
│   │   │   └── task-id.ts
│   │   └── repositories/
│   │       └── task.repository.ts    # Interface
│   │
│   ├── application/
│   │   └── use-cases/
│   │       ├── create-task.use-case.ts
│   │       └── list-tasks.use-case.ts
│   │
│   └── infrastructure/
│       └── repositories/
│           └── prisma-task.repository.ts
│
├── app/                         # Frameworks layer (Next.js)
│   ├── layout.tsx
│   ├── (features)/
│   │   └── tasks/
│   │       ├── page.tsx         # Server Component
│   │       ├── actions.ts       # Server Actions
│   │       ├── schemas.ts       # Zod schemas
│   │       └── components/
│   │           ├── task-list.tsx
│   │           └── create-task-form.tsx
│   │
│   └── api/                     # Optional REST endpoints
│       └── tasks/
│           └── route.ts
│
├── lib/
│   ├── container.ts             # DI composition root
│   └── prisma.ts                # Prisma singleton
│
├── prisma/
│   └── schema.prisma
│
└── test/
    ├── helpers/
    │   └── result.helpers.ts
    └── domain/
        └── task.test.ts
```

## TypeScript-Specific Tools

### NestJS Backend Dependencies

```json
{
  "dependencies": {
    "@nestjs/common": "^11.0.0",
    "@nestjs/core": "^11.0.0",
    "@nestjs/platform-express": "^11.0.0",
    "@nestjs/cqrs": "^11.0.0",
    "@prisma/client": "^6.0.0",
    "reflect-metadata": "^0.1.13",
    "rxjs": "^7.8.0",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "@nestjs/cli": "^11.0.0",
    "@nestjs/schematics": "^11.0.0",
    "@nestjs/testing": "^11.0.0",
    "@types/node": "^22.0.0",
    "@types/supertest": "^6.0.0",
    "prisma": "^6.0.0",
    "supertest": "^6.3.0",
    "jest": "^29.0.0",
    "ts-jest": "^29.0.0",
    "typescript": "^5.5.0"
  }
}
```

### Next.js Full-Stack Dependencies

```json
{
  "dependencies": {
    "next": "^15.1.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0",
    "@prisma/client": "^6.0.0",
    "zod": "^3.24.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "prisma": "^6.0.0",
    "jest": "^29.0.0",
    "@testing-library/react": "^16.0.0",
    "typescript": "^5.5.0"
  }
}
```

### ESLint Configuration

```json
{
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/strict-type-checked"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "project": true
  },
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/explicit-function-return-type": "error",
    "@typescript-eslint/no-explicit-any": "error",
    "@typescript-eslint/no-unused-vars": "error",
    "@typescript-eslint/strict-boolean-expressions": "error"
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