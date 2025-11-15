# Task Manager Example

## Overview

This is a complete, evolving example of Clean Architecture implementation across multiple languages. The Task Manager starts with basic CRUD operations and documents how to evolve it to handle more complex scenarios.

## Current Implementation (v1.0 - MVP)

### User Stories Implemented

**P1 - Must Have (Current)**
- ✅ Create Task
- ✅ List Tasks
- ✅ Complete Task

**P2 - Should Have (Planned)**
- ⏳ Edit Task
- ⏳ Delete Task
- ⏳ Filter Tasks by Status

**P3 - Could Have (Future)**
- ⏳ Task Categories
- ⏳ Due Dates
- ⏳ Task Assignment

## Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                    Frameworks Layer                       │
│  (REST API, CLI, Web UI - Entry Points)                  │
├─────────────────────────────────────────────────────────┤
│                 Infrastructure Layer                      │
│  (Database, File Storage, External Services)             │
├─────────────────────────────────────────────────────────┤
│                  Application Layer                        │
│  (Use Cases, Orchestration, DTOs)                       │
├─────────────────────────────────────────────────────────┤
│                     Domain Layer                         │
│  (Task Entity, Business Rules, Value Objects)           │
└─────────────────────────────────────────────────────────┘
```

## Implementation by Layer

- **Domain Layer**: See [domain.md](domain.md)
- **Application Layer**: See [application.md](application.md)
- **Infrastructure Layer**: See [infrastructure.md](infrastructure.md)
- **Frameworks Layer**: See [frameworks.md](frameworks.md)

## Language Implementations

Each language implements the same functionality with language-specific patterns:

### Python
- Location: `python/`
- Framework: FastAPI
- Database: SQLAlchemy with SQLite
- Testing: pytest
- [View Python Implementation](python/README.md)

### TypeScript
- Location: `typescript/`
- Framework: Express.js
- Database: TypeORM with SQLite
- Testing: Jest
- [View TypeScript Implementation](typescript/README.md)

### C#
- Location: `csharp/`
- Framework: ASP.NET Core
- Database: Entity Framework Core with SQLite
- Testing: xUnit
- [View C# Implementation](csharp/README.md)

## Running the Examples

### Quick Start (Any Language)

1. Choose your language directory
2. Install dependencies (see language-specific README)
3. Run migrations/setup
4. Start the application
5. Test the API endpoints

### API Endpoints (Common Across Languages)

```
POST   /tasks          Create a new task
GET    /tasks          List all tasks
PUT    /tasks/{id}/complete  Complete a task
```

### Request/Response Examples

**Create Task**
```json
POST /tasks
{
  "description": "Learn Clean Architecture"
}

Response: 201 Created
{
  "taskId": "123e4567-e89b-12d3-a456-426614174000",
  "description": "Learn Clean Architecture",
  "completed": false,
  "createdAt": "2024-01-15T10:30:00Z"
}
```

**List Tasks**
```json
GET /tasks

Response: 200 OK
{
  "tasks": [
    {
      "id": "123e4567-e89b-12d3-a456-426614174000",
      "description": "Learn Clean Architecture",
      "completed": false,
      "createdAt": "2024-01-15T10:30:00Z"
    }
  ]
}
```

**Complete Task**
```json
PUT /tasks/123e4567-e89b-12d3-a456-426614174000/complete

Response: 200 OK
{
  "success": true,
  "completedAt": "2024-01-15T11:00:00Z"
}
```

## Evolution Roadmap

### Phase 1: MVP (Current) ✅
Basic CRUD with Clean Architecture:
- Simple Task entity
- Three use cases
- In-memory or simple database
- REST API

### Phase 2: Enhanced Features
Add business complexity:
- Task priorities
- Due dates with validation
- Task categories/tags
- Filtering and searching

**Architectural Learning**:
- Value objects (DueDate, Priority)
- Domain services (TaskScheduler)
- Query patterns in repositories

### Phase 3: Multi-User System
Add authentication and authorization:
- User entity
- Task assignment
- Permissions (view own, view all)
- User preferences

**Architectural Learning**:
- Aggregates (User-Task relationship)
- Cross-cutting concerns (auth)
- Application services

### Phase 4: Advanced Features
Complex business logic:
- Recurring tasks
- Task dependencies
- Notifications
- Task templates

**Architectural Learning**:
- Domain events
- Event-driven patterns
- Complex aggregates
- Saga/Process managers

### Phase 5: Performance & Scale
Optimization and scaling:
- Caching strategies
- Read/Write separation (CQRS)
- Event sourcing
- Async processing

**Architectural Learning**:
- CQRS pattern
- Event sourcing
- Cache-aside pattern
- Message queues

## Learning Objectives

By studying this example, you'll understand:

1. **Layer Separation**: How each layer has distinct responsibilities
2. **Dependency Rule**: Dependencies always point inward
3. **Domain Purity**: Business logic free from technical concerns
4. **Use Case Orchestration**: Coordinating domain objects
5. **Repository Pattern**: Abstracting data access
6. **Dependency Injection**: Wiring layers together
7. **Testing Strategy**: Testing each layer appropriately
8. **Evolution**: How to grow the system while maintaining architecture

## Common Patterns Demonstrated

### Domain Patterns
- ✅ Entity with identity
- ✅ Business rule validation
- ✅ Encapsulation
- ⏳ Value objects
- ⏳ Domain services
- ⏳ Domain events

### Application Patterns
- ✅ Use case per operation
- ✅ Request/Response DTOs
- ✅ Repository interfaces
- ⏳ Application services
- ⏳ Query objects
- ⏳ Result patterns

### Infrastructure Patterns
- ✅ Repository implementation
- ✅ Database mapping
- ⏳ Gateway pattern
- ⏳ Cache implementation
- ⏳ Message queue adapter

### Framework Patterns
- ✅ Thin controllers
- ✅ Dependency injection
- ✅ Error handling
- ⏳ Middleware
- ⏳ Authentication
- ⏳ API versioning

## Testing Strategy

Each implementation includes tests demonstrating:

### Unit Tests
- Domain entity logic
- Business rule validation
- Value object equality

### Integration Tests
- Use cases with mocked repositories
- Repository implementations with test database
- Gateway implementations

### E2E Tests
- Complete API workflows
- Error scenarios
- Edge cases

## Contributing

To improve this example:

1. **Add features**: Implement next phase items
2. **Add languages**: Create implementation in new language
3. **Improve tests**: Add more test scenarios
4. **Document learnings**: Share insights from implementation

## Key Takeaways

1. **Start Simple**: MVP demonstrates all layers working together
2. **Evolve Gradually**: Each phase adds complexity purposefully
3. **Maintain Boundaries**: Never compromise layer separation
4. **Test Everything**: Each layer needs appropriate testing
5. **Language Agnostic**: Patterns work across languages

## Resources

- [Clean Architecture Book](https://www.amazon.com/Clean-Architecture-Craftsmans-Software-Structure/dp/0134494164)
- [Domain-Driven Design](https://www.amazon.com/Domain-Driven-Design-Tackling-Complexity-Software/dp/0321125215)
- [This Skill's Documentation](../README.md)

## Questions to Consider

As you study this example, consider:

1. **Why is the Task entity in Domain, not Infrastructure?**
2. **Why do we need both Request and Response DTOs?**
3. **How would you add a new feature without breaking existing code?**
4. **What changes if we switch from REST to GraphQL?**
5. **What changes if we switch from SQL to NoSQL?**

The answers reveal the power of Clean Architecture's separation of concerns.