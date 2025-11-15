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
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
  </PropertyGroup>
</Project>
```

## Domain Layer Patterns

### Entities

```csharp
namespace Domain.Entities
{
    public class Task
    {
        private string _description;
        private bool _completed;
        private DateTime? _completedAt;

        public string Id { get; }
        public string Description => _description;
        public bool IsCompleted => _completed;
        public DateTime CreatedAt { get; }
        public DateTime? CompletedAt => _completedAt;

        public Task(string description) : this(description, Guid.NewGuid().ToString())
        {
        }

        public Task(string description, string id)
        {
            ValidateDescription(description);

            Id = id;
            _description = description;
            _completed = false;
            CreatedAt = DateTime.UtcNow;
            _completedAt = null;
        }

        public void Complete()
        {
            if (_completed)
            {
                throw new InvalidOperationException("Task is already completed");
            }

            _completed = true;
            _completedAt = DateTime.UtcNow;
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
    public record Address(
        string Street,
        string City,
        string State,
        string ZipCode
    )
    {
        public Address : this(Street, City, State, ZipCode)
        {
            if (string.IsNullOrWhiteSpace(Street))
                throw new ArgumentException("Street is required");
            if (string.IsNullOrWhiteSpace(City))
                throw new ArgumentException("City is required");
            // ... more validation
        }
    }
}
```

## Application Layer Patterns

### Use Cases with DTOs

```csharp
namespace Application.UseCases.CreateTask
{
    // Request DTO
    public class CreateTaskRequest
    {
        public string Description { get; set; } = string.Empty;

        public void Validate()
        {
            if (string.IsNullOrWhiteSpace(Description))
            {
                throw new ValidationException("Description is required");
            }
        }
    }

    // Response DTO
    public class CreateTaskResponse
    {
        public string TaskId { get; set; } = string.Empty;
        public bool Created { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // Use Case
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

            return new CreateTaskResponse
            {
                TaskId = task.Id,
                Created = true,
                CreatedAt = task.CreatedAt
            };
        }
    }
}
```

### MediatR Pattern (Optional)

Using MediatR for decoupled communication:

```csharp
// Request
public class CreateTaskCommand : IRequest<CreateTaskResult>
{
    public string Description { get; set; }
}

// Handler
public class CreateTaskCommandHandler
    : IRequestHandler<CreateTaskCommand, CreateTaskResult>
{
    private readonly ITaskRepository _repository;

    public CreateTaskCommandHandler(ITaskRepository repository)
    {
        _repository = repository;
    }

    public async Task<CreateTaskResult> Handle(
        CreateTaskCommand request,
        CancellationToken cancellationToken)
    {
        var task = new Task(request.Description);
        await _repository.SaveAsync(task);

        return new CreateTaskResult { TaskId = task.Id };
    }
}
```

## Infrastructure Layer Patterns

### Repository Implementation with Entity Framework

```csharp
namespace Infrastructure.Persistence.Repositories
{
    public class EfTaskRepository : ITaskRepository
    {
        private readonly AppDbContext _context;

        public EfTaskRepository(AppDbContext context)
        {
            _context = context;
        }

        public async Task SaveAsync(Domain.Entities.Task task)
        {
            var entity = await _context.Tasks
                .FirstOrDefaultAsync(t => t.Id == task.Id);

            if (entity == null)
            {
                entity = new TaskEntity();
                _context.Tasks.Add(entity);
            }

            // Map domain to persistence
            entity.Id = task.Id;
            entity.Description = task.Description;
            entity.IsCompleted = task.IsCompleted;
            entity.CreatedAt = task.CreatedAt;
            entity.CompletedAt = task.CompletedAt;

            await _context.SaveChangesAsync();
        }

        public async Task<Domain.Entities.Task?> FindByIdAsync(string id)
        {
            var entity = await _context.Tasks.FindAsync(id);

            if (entity == null)
                return null;

            // Map persistence to domain
            return new Domain.Entities.Task(entity.Description, entity.Id);
        }

        public async Task<IEnumerable<Domain.Entities.Task>> FindAllAsync()
        {
            var entities = await _context.Tasks
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

## Frameworks Layer Patterns

### ASP.NET Core Controllers

```csharp
namespace WebApi.Controllers
{
    [ApiController]
    [Route("api/v1/[controller]")]
    public class TasksController : ControllerBase
    {
        private readonly IMediator _mediator;

        public TasksController(IMediator mediator)
        {
            _mediator = mediator;
        }

        [HttpPost]
        public async Task<ActionResult<TaskDto>> CreateTask(
            [FromBody] CreateTaskDto dto)
        {
            var command = new CreateTaskCommand
            {
                Description = dto.Description
            };

            var result = await _mediator.Send(command);

            return CreatedAtAction(
                nameof(GetTask),
                new { id = result.TaskId },
                new TaskDto
                {
                    Id = result.TaskId,
                    Description = dto.Description
                });
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<TaskDto>>> GetTasks()
        {
            var query = new GetAllTasksQuery();
            var tasks = await _mediator.Send(query);

            return Ok(tasks.Select(t => new TaskDto
            {
                Id = t.Id,
                Description = t.Description,
                IsCompleted = t.IsCompleted
            }));
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

```csharp
namespace Application.Tests.UseCases
{
    public class CreateTaskUseCaseTests
    {
        private readonly Mock<ITaskRepository> _repositoryMock;
        private readonly CreateTaskUseCase _useCase;

        public CreateTaskUseCaseTests()
        {
            _repositoryMock = new Mock<ITaskRepository>();
            _useCase = new CreateTaskUseCase(_repositoryMock.Object);
        }

        [Fact]
        public async Task Execute_ValidRequest_ShouldCreateTask()
        {
            // Arrange
            var request = new CreateTaskRequest
            {
                Description = "New task"
            };

            // Act
            var response = await _useCase.ExecuteAsync(request);

            // Assert
            Assert.True(response.Created);
            Assert.NotEmpty(response.TaskId);
            _repositoryMock.Verify(r => r.SaveAsync(It.IsAny<Task>()), Times.Once);
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
  <PackageReference Include="Swashbuckle.AspNetCore" Version="6.*" />

  <!-- Entity Framework -->
  <PackageReference Include="Microsoft.EntityFrameworkCore" Version="7.*" />
  <PackageReference Include="Microsoft.EntityFrameworkCore.Sqlite" Version="7.*" />

  <!-- MediatR (optional) -->
  <PackageReference Include="MediatR" Version="12.*" />

  <!-- Testing -->
  <PackageReference Include="xunit" Version="2.*" />
  <PackageReference Include="Moq" Version="4.*" />
  <PackageReference Include="FluentAssertions" Version="6.*" />
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

C# and .NET features for Clean Architecture:
- **Interfaces** define clear contracts
- **Dependency Injection** built into ASP.NET Core
- **Entity Framework** for persistence abstraction
- **Records** for immutable value objects
- **Nullable reference types** prevent null errors
- **Async/await** for scalable I/O

The .NET ecosystem provides excellent tooling and patterns that align naturally with Clean Architecture principles.