<!-- Last reviewed: 2026-01-21 -->

# C# Clean Architecture Guide

## Overview

This guide provides C#-specific patterns and idioms for implementing Clean Architecture. C# and .NET provide excellent support for Clean Architecture through interfaces, dependency injection, and strong typing.

## C# Type System for Clean Architecture

### Interfaces for Abstractions

C# interfaces define contracts between layers:

```csharp
// Domain layer - Repository interface
namespace Domain.Repositories
{
    public interface ITaskRepository
    {
        Task SaveAsync(Domain.Entities.Task task);
        Task<Domain.Entities.Task?> FindByIdAsync(string id);
        Task<IEnumerable<Domain.Entities.Task>> FindAllAsync();
    }
}

// Application layer - Use case interface
namespace Application.Common
{
    public interface IUseCase<TRequest, TResponse>
    {
        Task<TResponse> ExecuteAsync(TRequest request);
    }
}
```

### Nullable Reference Types

Enable nullable reference types in C# 8.0+:

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net9.0</TargetFramework>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
```

### C# 13 Features (November 2024)

C# 13 with .NET 9 introduces:
- `params` collections (not just arrays): `void Log(params ReadOnlySpan<string> messages)`
- Improved `lock` with `System.Threading.Lock` type
- Partial properties in partial classes
- `\e` escape sequence for ANSI escape

Most Clean Architecture code doesn't need these immediately, but `params` collections improve API flexibility.

## Domain Layer Patterns

### Entities

```csharp
namespace Domain.Entities
{
    public class Task
    {
        private string _description;
        private bool _completed;
        private DateTimeOffset? _completedAt;

        public string Id { get; }
        public string Description => _description;
        public bool IsCompleted => _completed;
        public DateTimeOffset CreatedAt { get; }
        public DateTimeOffset? CompletedAt => _completedAt;

        public Task(string description) : this(description, Guid.NewGuid().ToString(), DateTimeOffset.UtcNow)
        {
        }

        public Task(string description, string id, DateTimeOffset? createdAt = null)
        {
            ValidateDescription(description);

            Id = id;
            _description = description;
            _completed = false;
            CreatedAt = createdAt ?? DateTimeOffset.UtcNow;
            _completedAt = null;
        }

        public void Complete(DateTimeOffset? completedAt = null)
        {
            if (_completed)
            {
                throw new InvalidOperationException("Task is already completed");
            }

            _completed = true;
            _completedAt = completedAt ?? DateTimeOffset.UtcNow;
        }

        private static void ValidateDescription(string description)
        {
            if (string.IsNullOrWhiteSpace(description))
            {
                throw new ArgumentException("Description cannot be empty", nameof(description));
            }

            if (description.Length > 500)
            {
                throw new ArgumentException("Description too long (max 500 chars)", nameof(description));
            }
        }
    }
}
```

### Value Objects

```csharp
namespace Domain.ValueObjects
{
    public class Money : IEquatable<Money>
    {
        public decimal Amount { get; }
        public string Currency { get; }

        public Money(decimal amount, string currency)
        {
            if (amount < 0)
            {
                throw new ArgumentException("Amount cannot be negative", nameof(amount));
            }

            if (string.IsNullOrWhiteSpace(currency) || currency.Length != 3)
            {
                throw new ArgumentException("Currency must be 3-letter code", nameof(currency));
            }

            Amount = amount;
            Currency = currency.ToUpperInvariant();
        }

        public Money Add(Money other)
        {
            if (Currency != other.Currency)
            {
                throw new InvalidOperationException("Cannot add different currencies");
            }

            return new Money(Amount + other.Amount, Currency);
        }

        public bool Equals(Money? other)
        {
            if (other is null) return false;
            return Amount == other.Amount && Currency == other.Currency;
        }

        public override bool Equals(object? obj) => Equals(obj as Money);

        public override int GetHashCode() => HashCode.Combine(Amount, Currency);

        public override string ToString() => $"{Currency} {Amount:F2}";
    }
}
```

### Records for Immutable Data

C# 9.0+ records are perfect for value objects:

```csharp
namespace Domain.ValueObjects
{
    // Simple immutable record (no validation needed)
    public record Address(
        string Street,
        string City,
        string State,
        string ZipCode
    );

    // Record with validation using property initialization
    public record ValidatedAddress(
        string Street,
        string City,
        string State,
        string ZipCode
    )
    {
        public string Street { get; init; } = !string.IsNullOrWhiteSpace(Street)
            ? Street
            : throw new ArgumentException("Street is required", nameof(Street));
        public string City { get; init; } = !string.IsNullOrWhiteSpace(City)
            ? City
            : throw new ArgumentException("City is required", nameof(City));
    }
}
```

## Application Layer Patterns

### Use Cases with Records (C# 9+)

Use records for immutable request/response models:

```csharp
namespace Application.UseCases.CreateTask
{
    // Request record (immutable, value semantics)
    public record CreateTaskRequest(string Description)
    {
        public void Validate()
        {
            if (string.IsNullOrWhiteSpace(Description))
            {
                throw new ValidationException("Description is required");
            }
        }
    }

    // Response record
    public record CreateTaskResponse(
        string TaskId,
        bool Created,
        DateTimeOffset CreatedAt
    );

    // Use Case with primary constructor (C# 12+)
    public class CreateTaskUseCase(ITaskRepository taskRepository)
        : IUseCase<CreateTaskRequest, CreateTaskResponse>
    {
        public async Task<CreateTaskResponse> ExecuteAsync(CreateTaskRequest request)
        {
            request.Validate();

            var task = new Domain.Entities.Task(request.Description);
            await taskRepository.SaveAsync(task);

            return new CreateTaskResponse(
                task.Id,
                true,
                task.CreatedAt
            );
        }
    }
}
```

Alternative with traditional constructor (if needed for explicit field access):

```csharp
public class CreateTaskUseCase : IUseCase<CreateTaskRequest, CreateTaskResponse>
{
    private readonly ITaskRepository _taskRepository;

    public CreateTaskUseCase(ITaskRepository taskRepository)
    {
        _taskRepository = taskRepository;
    }

    public async Task<CreateTaskResponse> ExecuteAsync(CreateTaskRequest request)
    {
        request.Validate();

        var task = new Domain.Entities.Task(request.Description);
        await _taskRepository.SaveAsync(task);

        return new CreateTaskResponse(task.Id, true, task.CreatedAt);
    }
}
```

### MediatR Pattern (Optional)

Using MediatR for decoupled communication:

```csharp
// Request as record
public record CreateTaskCommand(string Description) : IRequest<CreateTaskResult>;

// Result as record
public record CreateTaskResult(string TaskId);

// Handler with primary constructor (C# 12+)
public class CreateTaskCommandHandler(ITaskRepository repository)
    : IRequestHandler<CreateTaskCommand, CreateTaskResult>
{
    public async Task<CreateTaskResult> Handle(
        CreateTaskCommand request,
        CancellationToken cancellationToken)
    {
        var task = new Task(request.Description);
        await repository.SaveAsync(task);

        return new CreateTaskResult(task.Id);
    }
}
```

## Infrastructure Layer Patterns

### Repository Implementation with Entity Framework

```csharp
namespace Infrastructure.Persistence.Repositories
{
    // Using primary constructor (C# 12+)
    public class EfTaskRepository(AppDbContext context) : ITaskRepository
    {
        public async Task SaveAsync(Domain.Entities.Task task)
        {
            var entity = await context.Tasks
                .FirstOrDefaultAsync(t => t.Id == task.Id);

            if (entity == null)
            {
                entity = new TaskEntity();
                context.Tasks.Add(entity);
            }

            // Map domain to persistence
            entity.Id = task.Id;
            entity.Description = task.Description;
            entity.IsCompleted = task.IsCompleted;
            entity.CreatedAt = task.CreatedAt;
            entity.CompletedAt = task.CompletedAt;

            await context.SaveChangesAsync();
        }

        public async Task<Domain.Entities.Task?> FindByIdAsync(string id)
        {
            var entity = await context.Tasks.FindAsync(id);

            if (entity == null)
                return null;

            // Map persistence to domain
            return new Domain.Entities.Task(entity.Description, entity.Id);
        }

        public async Task<IEnumerable<Domain.Entities.Task>> FindAllAsync()
        {
            var entities = await context.Tasks
                .OrderByDescending(t => t.CreatedAt)
                .ToListAsync();

            return entities.Select(e =>
                new Domain.Entities.Task(e.Description, e.Id));
        }
    }
}
```

### DbContext Configuration

```csharp
namespace Infrastructure.Persistence
{
    public class AppDbContext : DbContext
    {
        public DbSet<TaskEntity> Tasks { get; set; }

        public AppDbContext(DbContextOptions<AppDbContext> options)
            : base(options)
        {
        }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<TaskEntity>(entity =>
            {
                entity.HasKey(e => e.Id);
                entity.Property(e => e.Description)
                    .IsRequired()
                    .HasMaxLength(500);
                entity.Property(e => e.IsCompleted)
                    .IsRequired();
                entity.Property(e => e.CreatedAt)
                    .IsRequired();
            });
        }
    }
}
```

### EF Core 9 Improvements

EF Core 9 provides:
- Better LINQ translation (more queries run on database)
- Improved `Contains` for large lists
- `ExecuteUpdateAsync`/`ExecuteDeleteAsync` improvements
- Better AOT compilation support

For complex repositories, consider bulk operations:
```csharp
// Bulk update without loading entities
await context.Tasks
    .Where(t => t.Status == "pending" && t.CreatedAt < cutoff)
    .ExecuteUpdateAsync(s => s.SetProperty(t => t.Status, "expired"));
```

## Frameworks Layer Patterns

### ASP.NET Core Controllers

```csharp
namespace WebApi.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class TasksController(IMediator mediator) : ControllerBase
    {
        [HttpPost]
        public async Task<ActionResult<TaskDto>> CreateTask(
            [FromBody] CreateTaskDto dto)
        {
            var command = new CreateTaskCommand(dto.Description);
            var result = await mediator.Send(command);

            return CreatedAtAction(
                nameof(GetTask),
                new { id = result.TaskId },
                new TaskDto(result.TaskId, dto.Description));
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TaskDto>>> GetTasks()
        {
            var query = new GetAllTasksQuery();
            var tasks = await mediator.Send(query);

            return Ok(tasks.Select(t => new TaskDto(t.Id, t.Description, t.IsCompleted)));
        }
    }
}
```

### Dependency Injection Setup

```csharp
// Program.cs (.NET 6+)
var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Add DbContext
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// Register repositories
builder.Services.AddScoped<ITaskRepository, EfTaskRepository>();

// Register use cases
builder.Services.AddScoped<CreateTaskUseCase>();
builder.Services.AddScoped<ListTasksUseCase>();

// Add MediatR (optional)
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

var app = builder.Build();

// Configure pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

## Testing Patterns

### Domain Layer Tests

```csharp
namespace Domain.Tests.Entities
{
    public class TaskTests
    {
        [Fact]
        public void Create_ValidTask_ShouldSucceed()
        {
            // Arrange & Act
            var task = new Task("Learn C#");

            // Assert
            Assert.Equal("Learn C#", task.Description);
            Assert.False(task.IsCompleted);
            Assert.NotNull(task.Id);
        }

        [Fact]
        public void Create_EmptyDescription_ShouldThrow()
        {
            // Arrange & Act & Assert
            Assert.Throws<ArgumentException>(() => new Task(""));
        }

        [Fact]
        public void Complete_UncompletedTask_ShouldSucceed()
        {
            // Arrange
            var task = new Task("Test task");

            // Act
            task.Complete();

            // Assert
            Assert.True(task.IsCompleted);
            Assert.NotNull(task.CompletedAt);
        }

        [Fact]
        public void Complete_AlreadyCompletedTask_ShouldThrow()
        {
            // Arrange
            var task = new Task("Test task");
            task.Complete();

            // Act & Assert
            Assert.Throws<InvalidOperationException>(() => task.Complete());
        }
    }
}
```

### Application Layer Tests

Using NSubstitute for mocking:

```csharp
using NSubstitute;

namespace Application.Tests.UseCases
{
    public class CreateTaskUseCaseTests
    {
        private readonly ITaskRepository _repository;
        private readonly CreateTaskUseCase _useCase;

        public CreateTaskUseCaseTests()
        {
            _repository = Substitute.For<ITaskRepository>();
            _useCase = new CreateTaskUseCase(_repository);
        }

        [Fact]
        public async Task Execute_ValidRequest_ShouldCreateTask()
        {
            // Arrange
            var request = new CreateTaskRequest("New task");

            // Act
            var response = await _useCase.ExecuteAsync(request);

            // Assert
            Assert.True(response.Created);
            Assert.NotEmpty(response.TaskId);
            await _repository.Received(1).SaveAsync(Arg.Any<Task>());
        }
    }
}
```

## Project Structure

```
src/
├── Domain/
│   ├── Entities/
│   │   └── Task.cs
│   ├── ValueObjects/
│   │   └── Money.cs
│   ├── Repositories/
│   │   └── ITaskRepository.cs
│   └── Exceptions/
│       └── DomainException.cs
│
├── Application/
│   ├── Common/
│   │   └── IUseCase.cs
│   ├── UseCases/
│   │   ├── CreateTask/
│   │   │   ├── CreateTaskRequest.cs
│   │   │   ├── CreateTaskResponse.cs
│   │   │   └── CreateTaskUseCase.cs
│   │   └── ListTasks/
│   └── Services/
│       └── INotificationService.cs
│
├── Infrastructure/
│   ├── Persistence/
│   │   ├── AppDbContext.cs
│   │   ├── Entities/
│   │   │   └── TaskEntity.cs
│   │   └── Repositories/
│   │       └── EfTaskRepository.cs
│   └── Services/
│       └── EmailNotificationService.cs
│
└── WebApi/  // or Presentation
    ├── Controllers/
    │   └── TasksController.cs
    ├── Filters/
    │   └── ExceptionFilter.cs
    ├── Program.cs
    └── appsettings.json
```

## C#-Specific Tools

### NuGet Packages

```xml
<ItemGroup>
  <!-- Web API -->
  <PackageReference Include="Microsoft.AspNetCore.App" />
  <PackageReference Include="Swashbuckle.AspNetCore" Version="7.1.0" />

  <!-- Entity Framework -->
  <PackageReference Include="Microsoft.EntityFrameworkCore" Version="9.0.0" />
  <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="9.0.0" />

  <!-- MediatR (optional) -->
  <PackageReference Include="MediatR" Version="12.4.0" />

  <!-- Testing -->
  <PackageReference Include="xunit" Version="2.9.2" />
  <PackageReference Include="NSubstitute" Version="5.3.0" />
  <PackageReference Include="FluentAssertions" Version="7.0.0" />
</ItemGroup>
```

### Code Analysis

```xml
<PropertyGroup>
  <EnableNETAnalyzers>true</EnableNETAnalyzers>
  <AnalysisLevel>latest</AnalysisLevel>
  <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
</PropertyGroup>

<ItemGroup>
  <PackageReference Include="StyleCop.Analyzers" Version="1.*" />
  <PackageReference Include="SonarAnalyzer.CSharp" Version="9.*" />
</ItemGroup>
```

## Common C# Pitfalls

### 1. Not Using Async/Await Properly

```csharp
// ❌ BAD - Blocking async code
public Task GetTask(string id)
{
    var task = repository.FindByIdAsync(id).Result; // Blocks!
    return task;
}

// ✅ GOOD - Proper async
public async Task<Task> GetTaskAsync(string id)
{
    var task = await repository.FindByIdAsync(id);
    return task;
}
```

### 2. Exposing Entity Framework Entities

```csharp
// ❌ BAD - EF entity as domain entity
[Table("Tasks")]
public class Task  // This is EF entity, not domain!
{
    [Key]
    public string Id { get; set; }
}

// ✅ GOOD - Separate domain and persistence
namespace Domain.Entities
{
    public class Task { /* Pure domain */ }
}

namespace Infrastructure.Persistence.Entities
{
    public class TaskEntity { /* EF entity */ }
}
```

### 3. Anemic Domain Model

```csharp
// ❌ BAD - Anemic model
public class Task
{
    public string Id { get; set; }
    public bool Completed { get; set; }  // Just properties!
}

// ✅ GOOD - Rich domain model
public class Task
{
    private bool _completed;

    public void Complete()
    {
        if (_completed)
            throw new InvalidOperationException("Already completed");
        _completed = true;
    }
}
```

## Summary

C# 13 and .NET 9 features for Clean Architecture:
- **Interfaces** define clear contracts
- **Primary constructors** (C# 12+) reduce DI boilerplate
- **Dependency Injection** built into ASP.NET Core
- **Entity Framework Core 9** for persistence abstraction
- **Records** for immutable value objects and DTOs
- **Nullable reference types** prevent null errors
- **Async/await** for scalable I/O
- **TimeProvider** for testable datetime operations

The .NET ecosystem provides excellent tooling and patterns that align naturally with Clean Architecture principles.