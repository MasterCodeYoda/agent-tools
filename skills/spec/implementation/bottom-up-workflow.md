# Bottom-Up Implementation Workflow

This guide explains why and how to implement vertical slices using a bottom-up approach, building from the domain layer up to the framework layer.

## Why Bottom-Up?

While we **plan** top-down (from user story to technical details), we **implement** bottom-up for several critical reasons:

### 1. Independence and Testability
- Domain layer has no dependencies
- Can be fully tested in isolation
- Errors caught before propagating up

### 2. Natural Dependency Flow
- Each layer depends only on layers below
- No circular dependencies
- Clean architecture compliance

### 3. Incremental Validation
- Test each layer as you build
- Confidence grows with each layer
- Issues identified early

### 4. Parallel Development
- Team members can work on different layers
- Clear handoff points between layers
- Reduced merge conflicts

## Layer-by-Layer Implementation Guide

### Layer 1: Domain (Foundation)

**Start Here** - This is your foundation

#### What to Build
- Entities with core properties
- Value objects
- Business rules and validation
- Domain services (if needed)

#### Implementation Checklist
```markdown
- [ ] Create entity with minimal properties
- [ ] Add validation in constructor/factory
- [ ] Implement business methods
- [ ] Add value objects if needed
- [ ] Write unit tests
- [ ] Verify no external dependencies
```

#### Example Structure
```
domain/
├── entities/
│   └── Task.ext          # Core entity
├── value-objects/
│   └── TaskStatus.ext    # Value object
├── services/
│   └── TaskValidator.ext # Domain service
└── errors/
    └── TaskError.ext     # Domain exceptions
```

#### Quality Gates
- ✅ All business rules enforced
- ✅ 100% unit test coverage
- ✅ No framework dependencies
- ✅ No infrastructure dependencies

### Layer 2: Infrastructure (Persistence)

**Build Second** - Connect to external world

#### What to Build
- Repository implementations
- Database mappings
- External service clients
- File system operations

#### Implementation Checklist
```markdown
- [ ] Define repository interface
- [ ] Implement data access methods
- [ ] Add database mappings/schemas
- [ ] Handle data transformation
- [ ] Write integration tests
- [ ] Mock external dependencies
```

#### Example Structure
```
infrastructure/
├── repositories/
│   └── TaskRepository.ext     # Repository implementation
├── persistence/
│   └── TaskMapper.ext        # Data mapping
├── external/
│   └── EmailService.ext      # External service
└── config/
    └── DatabaseConfig.ext    # Configuration
```

#### Quality Gates
- ✅ Repository contract fulfilled
- ✅ Integration tests passing
- ✅ Proper error handling
- ✅ Connection management

### Layer 3: Application (Orchestration)

**Build Third** - Coordinate the flow

#### What to Build
- Use cases/application services
- Request/response DTOs
- Application-level validation
- Transaction management

#### Implementation Checklist
```markdown
- [ ] Create use case class
- [ ] Define request/response DTOs
- [ ] Implement business flow
- [ ] Add transaction boundaries
- [ ] Handle cross-cutting concerns
- [ ] Write unit tests with mocks
```

#### Example Structure
```
application/
├── use-cases/
│   └── CreateTask/
│       ├── CreateTaskUseCase.ext
│       ├── CreateTaskRequest.ext
│       └── CreateTaskResponse.ext
├── services/
│   └── NotificationService.ext
└── dto/
    └── TaskDTO.ext
```

#### Quality Gates
- ✅ Use case fully implemented
- ✅ Proper error handling
- ✅ Transaction boundaries clear
- ✅ Unit tests with mocked dependencies

### Layer 4: Framework (Entry Points)

**Build Last** - User interface

#### What to Build
- REST API endpoints
- GraphQL resolvers
- CLI commands
- Web UI components
- Message handlers

#### Implementation Checklist
```markdown
- [ ] Create endpoint/controller
- [ ] Add request validation
- [ ] Map to use case DTOs
- [ ] Handle responses
- [ ] Add authentication/authorization
- [ ] Write E2E tests
```

#### Example Structure
```
framework/
├── api/
│   └── TaskController.ext    # REST endpoint
├── cli/
│   └── TaskCommand.ext       # CLI command
├── web/
│   └── TaskComponent.ext     # UI component
└── messaging/
    └── TaskHandler.ext       # Message handler
```

#### Quality Gates
- ✅ API contract defined
- ✅ Input validation complete
- ✅ Error responses handled
- ✅ E2E tests passing

## Implementation Flow Diagram

```
Start
  ↓
[Domain Layer]
  ├─ Create entities
  ├─ Add business rules
  └─ Unit test ✓
      ↓
[Infrastructure Layer]
  ├─ Implement repositories
  ├─ Setup persistence
  └─ Integration test ✓
      ↓
[Application Layer]
  ├─ Create use cases
  ├─ Define DTOs
  └─ Unit test ✓
      ↓
[Framework Layer]
  ├─ Add endpoints
  ├─ Handle requests
  └─ E2E test ✓
      ↓
Deploy Vertical Slice
```

## Practical Example: User Registration

### Step 1: Domain Layer
```
1. Create User entity with email, password
2. Add email validation rules
3. Implement password hashing logic
4. Test: User creation, validation
Time: 1 hour
```

### Step 2: Infrastructure Layer
```
1. Create UserRepository interface
2. Implement database persistence
3. Add unique email constraint
4. Test: Save and retrieve user
Time: 1 hour
```

### Step 3: Application Layer
```
1. Create RegisterUserUseCase
2. Define registration request/response
3. Orchestrate validation and saving
4. Test: Complete registration flow
Time: 1.5 hours
```

### Step 4: Framework Layer
```
1. Create POST /register endpoint
2. Add request validation
3. Return appropriate responses
4. Test: Full E2E registration
Time: 1 hour
```

## Common Pitfalls to Avoid

### ❌ Starting with the Database
**Wrong**: Design database schema first
**Right**: Design domain model, then map to database

### ❌ Building UI First
**Wrong**: Create forms before business logic
**Right**: Ensure domain logic works, then add UI

### ❌ Skipping Layers
**Wrong**: Put business logic in controllers
**Right**: Each layer has clear responsibilities

### ❌ Over-Engineering Early Layers
**Wrong**: Add all possible fields to entity
**Right**: Add only what current story needs

## Parallel Development Strategy

When working in a team:

### Track A: Backend Developer
```
Day 1 AM: Domain layer
Day 1 PM: Infrastructure layer
Day 2 AM: Application layer
Day 2 PM: Integration
```

### Track B: Frontend Developer
```
Day 1 AM: UI mockups
Day 1 PM: Component structure
Day 2 AM: Connect to API (once ready)
Day 2 PM: Integration
```

### Synchronization Points
- After domain layer: Share entity definitions
- After application layer: Share API contracts
- After framework layer: Full integration testing

## Testing Strategy Per Layer

### Domain Layer Tests
- Pure unit tests
- No mocking needed
- Fast execution
- High coverage

### Infrastructure Layer Tests
- Integration tests
- Test containers or in-memory DB
- Verify actual persistence
- Moderate speed

### Application Layer Tests
- Unit tests with mocks
- Mock repositories and services
- Test orchestration logic
- Fast execution

### Framework Layer Tests
- E2E tests
- Full application context
- Real or test database
- Slower but comprehensive

## Incremental Deployment

Each layer completion can be a commit:

```bash
git commit -m "feat(domain): add User entity with validation"
git commit -m "feat(infrastructure): implement UserRepository"
git commit -m "feat(application): add RegisterUserUseCase"
git commit -m "feat(api): add POST /register endpoint"
```

## Success Metrics

Track your bottom-up implementation:

| Metric | Target | Indicates |
|--------|--------|-----------|
| Layer completion time | <2 hours each | Good sizing |
| Tests per layer | >3 tests | Adequate coverage |
| Defects found in layer | <2 | Good quality |
| Rework needed | <10% | Clear requirements |

## Remember

- **Bottom-up implementation** ensures solid foundations
- **Test each layer** before moving up
- **Keep layers independent** for maximum flexibility
- **Deploy complete slices** not partial layers