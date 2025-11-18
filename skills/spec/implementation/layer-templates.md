# Layer Implementation Templates

This document provides language-agnostic templates and patterns for implementing each architectural layer in a vertical slice.

## Domain Layer Templates

### Entity Template
```
Entity: [EntityName]
├─ Properties (minimal for current story)
├─ Validation rules
├─ Business methods
└─ State transitions

Pattern:
- Encapsulate business rules
- Validate on creation
- Make invalid states unrepresentable
- No external dependencies
```

#### Example Structure
```
class [Entity]:
    Properties:
        - id: unique identifier
        - [property]: business data
        - createdAt: timestamp
        - updatedAt: timestamp

    Constructor/Factory:
        - Validate required fields
        - Enforce business rules
        - Set defaults

    Methods:
        - [businessMethod](): business operation
        - validate(): internal validation
        - [stateTransition](): change state
```

### Value Object Template
```
ValueObject: [ValueObjectName]
├─ Immutable properties
├─ Validation in constructor
├─ Equality by value
└─ No identity

Pattern:
- Always valid after creation
- Immutable
- Comparable by value
```

#### Example Structure
```
class [ValueObject]:
    Properties:
        - readonly value: underlying data

    Constructor:
        - Validate input
        - Throw if invalid

    Methods:
        - equals(other): value equality
        - toString(): string representation
        - [derivedProperty](): computed values
```

### Domain Service Template
```
DomainService: [ServiceName]
├─ Stateless operations
├─ Complex business logic
├─ Cross-entity operations
└─ Pure functions

Pattern:
- No state
- Domain logic only
- No infrastructure dependencies
```

## Infrastructure Layer Templates

### Repository Interface Template
```
Repository Interface: [Entity]Repository
├─ Core operations
├─ Query methods
├─ Command methods
└─ Return domain entities

Pattern:
- Define contract in domain/application
- Implement in infrastructure
- Return domain objects
```

#### Example Structure
```
interface [Entity]Repository:
    Commands:
        - create(entity): Entity
        - update(entity): Entity
        - delete(id): void

    Queries:
        - findById(id): Entity?
        - findAll(): Entity[]
        - [customQuery](): Entity[]
```

### Repository Implementation Template
```
Repository: [Database][Entity]Repository
├─ Implements interface
├─ Handles persistence
├─ Maps data to domain
└─ Manages transactions

Pattern:
- Separate data model from domain
- Handle connection/session
- Transform between layers
```

#### Example Structure
```
class [Implementation]Repository implements [Entity]Repository:
    Dependencies:
        - database: connection/client
        - mapper: data transformer

    Methods:
        create(entity):
            - Map to data model
            - Persist to database
            - Map back to domain
            - Return entity

        findById(id):
            - Query database
            - Map to domain
            - Return entity or null
```

### External Service Template
```
ExternalService: [ServiceName]Client
├─ API integration
├─ Error handling
├─ Retry logic
└─ Response mapping

Pattern:
- Wrap external APIs
- Handle failures gracefully
- Map to domain concepts
```

## Application Layer Templates

### Use Case Template
```
UseCase: [Action][Entity]UseCase
├─ Single responsibility
├─ Orchestrates flow
├─ Transaction boundary
└─ Returns DTO

Pattern:
- One use case per user action
- Coordinate domain and infrastructure
- Handle cross-cutting concerns
```

#### Example Structure
```
class [Action][Entity]UseCase:
    Dependencies:
        - repository: [Entity]Repository
        - [service]: DomainService
        - [external]: ExternalService

    execute(request):
        - Validate request
        - Begin transaction
        - Execute business logic
        - Call repositories
        - Commit transaction
        - Map to response
        - Return response
```

### Request/Response DTO Templates
```
Request: [Action][Entity]Request
├─ Input parameters
├─ No behavior
└─ Serializable

Response: [Action][Entity]Response
├─ Output data
├─ No behavior
└─ Serializable
```

#### Example Structure
```
class [Action]Request:
    Properties:
        - [field]: input value
        - [field]: input value

    Validation:
        - Required fields
        - Format validation
        - Business constraints

class [Action]Response:
    Properties:
        - id: created/updated id
        - [field]: output value
        - success: boolean
        - errors: error list
```

### Application Service Template
```
ApplicationService: [ServiceName]
├─ Coordinates use cases
├─ Handles workflows
├─ Manages transactions
└─ Cross-cutting concerns

Pattern:
- Higher-level orchestration
- Combine multiple use cases
- Handle complex workflows
```

## Framework Layer Templates

### REST API Controller Template
```
Controller: [Entity]Controller
├─ HTTP endpoints
├─ Request validation
├─ Response formatting
└─ Error handling

Pattern:
- Thin controllers
- Delegate to use cases
- Handle HTTP concerns only
```

#### Example Structure
```
class [Entity]Controller:
    Dependencies:
        - createUseCase: Create[Entity]UseCase
        - updateUseCase: Update[Entity]UseCase
        - [otherUseCases]: UseCase

    Endpoints:
        POST /[entities]:
            - Validate request body
            - Map to use case request
            - Execute use case
            - Map to HTTP response
            - Return with status code

        GET /[entities]/{id}:
            - Extract path parameter
            - Execute query
            - Return entity or 404

        PUT /[entities]/{id}:
            - Validate request
            - Execute update
            - Return updated entity
```

### GraphQL Resolver Template
```
Resolver: [Entity]Resolver
├─ Type definitions
├─ Query resolvers
├─ Mutation resolvers
└─ Field resolvers

Pattern:
- Map GraphQL to use cases
- Handle GraphQL-specific concerns
- Efficient data fetching
```

### CLI Command Template
```
Command: [Action][Entity]Command
├─ Command parsing
├─ Option handling
├─ Output formatting
└─ Error display

Pattern:
- Parse arguments
- Call use cases
- Format output
- Handle errors gracefully
```

### Message Handler Template
```
Handler: [Event][Entity]Handler
├─ Message parsing
├─ Event processing
├─ Error handling
└─ Acknowledgment

Pattern:
- Parse message
- Execute use case
- Handle failures
- Manage acknowledgments
```

## File Organization Patterns

### File-per-Use-Case Structure
```
application/
└── [entity]/
    ├── create/
    │   ├── Create[Entity]UseCase
    │   ├── Create[Entity]Request
    │   └── Create[Entity]Response
    ├── update/
    │   ├── Update[Entity]UseCase
    │   ├── Update[Entity]Request
    │   └── Update[Entity]Response
    └── shared/
        └── [Entity]DTO
```

### Layer-Based Structure
```
src/
├── domain/
│   └── [entity]/
│       ├── [Entity]
│       ├── [Entity]Repository (interface)
│       └── [Entity]Service
├── application/
│   └── [entity]/
│       └── [UseCases]
├── infrastructure/
│   └── [entity]/
│       └── [Repository]Implementation
└── framework/
    └── [entity]/
        └── [Entity]Controller
```

### Feature-Based Structure
```
features/
└── [feature-name]/
    ├── domain/
    │   └── [Entities]
    ├── application/
    │   └── [UseCases]
    ├── infrastructure/
    │   └── [Repositories]
    └── api/
        └── [Controllers]
```

## Common Patterns Across Layers

### Result Pattern
```
Result<T>:
    - Success(value: T)
    - Failure(error: Error)

Usage:
    - Return from methods that can fail
    - Avoid exceptions for control flow
    - Explicit error handling
```

### Factory Pattern
```
Factory: [Entity]Factory
    - create(params): Entity
    - createFrom[Source](source): Entity
    - Encapsulate complex creation
    - Ensure valid entities
```

### Mapper Pattern
```
Mapper: [Entity]Mapper
    - toDomain(data): Entity
    - toData(entity): DataModel
    - toDTO(entity): DTO
    - Handle transformations between layers
```

### Specification Pattern
```
Specification: [Condition]Specification
    - isSatisfiedBy(entity): boolean
    - and(other): Specification
    - or(other): Specification
    - Encapsulate business rules
```

## Testing Templates Per Layer

### Domain Test Template
```
Test: [Entity]Test
    - Test valid creation
    - Test validation rules
    - Test business methods
    - Test state transitions
    - No mocks needed
```

### Repository Test Template
```
Test: [Repository]Test
    - Setup test database
    - Test CRUD operations
    - Test queries
    - Verify mappings
    - Use test containers
```

### Use Case Test Template
```
Test: [UseCase]Test
    - Mock repositories
    - Mock external services
    - Test happy path
    - Test error cases
    - Verify orchestration
```

### API Test Template
```
Test: [Endpoint]Test
    - Setup test server
    - Test HTTP methods
    - Test status codes
    - Test response format
    - Full E2E flow
```

## Quality Checklist Per Layer

### Domain Layer
- [ ] No external dependencies
- [ ] Business rules enforced
- [ ] Immutable where appropriate
- [ ] Comprehensive unit tests

### Infrastructure Layer
- [ ] Implements interfaces correctly
- [ ] Handles connection failures
- [ ] Proper transaction management
- [ ] Integration tests pass

### Application Layer
- [ ] Single responsibility per use case
- [ ] Proper error handling
- [ ] Transaction boundaries defined
- [ ] Unit tests with mocks

### Framework Layer
- [ ] Input validation complete
- [ ] Proper HTTP status codes
- [ ] Error responses formatted
- [ ] E2E tests comprehensive