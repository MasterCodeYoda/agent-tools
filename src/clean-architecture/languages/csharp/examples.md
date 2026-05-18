<!-- Last reviewed: 2026-03-21 -->

# C# Clean Architecture Examples

## Complete Feature Example: Task Management

This example shows a complete Task Management feature implementation across all layers.

### Domain Layer

```csharp
// Domain/ValueObjects/TaskPriority.cs
namespace Domain.ValueObjects;

public record TaskPriority
{
    public static readonly TaskPriority Low = new("Low", 1);
    public static readonly TaskPriority Medium = new("Medium", 2);
    public static readonly TaskPriority High = new("High", 3);
    public static readonly TaskPriority Critical = new("Critical", 4);

    public string Name { get; }
    public int Level { get; }

    private TaskPriority(string name, int level)
    {
        Name = name;
        Level = level;
    }

    public static Result<TaskPriority> FromName(string name) => name.ToLowerInvariant() switch
    {
        "low" => Result<TaskPriority>.Success(Low),
        "medium" => Result<TaskPriority>.Success(Medium),
        "high" => Result<TaskPriority>.Success(High),
        "critical" => Result<TaskPriority>.Success(Critical),
        _ => Result<TaskPriority>.Failure($"Unknown priority: {name}")
    };

    public override string ToString() => Name;
}
```

```csharp
// Domain/Events/TaskEvents.cs
namespace Domain.Events;

public record TaskCreatedEvent(
    string TaskId,
    string Title,
    string Priority,
    DateTimeOffset OccurredAt
) : IDomainEvent;

public record TaskCompletedEvent(
    string TaskId,
    DateTimeOffset CompletedAt,
    DateTimeOffset OccurredAt
) : IDomainEvent;
```

```csharp
// Domain/Entities/TaskItem.cs
namespace Domain.Entities;

public class TaskItem : EntityBase
{
    private string _title;
    private string? _description;
    private TaskPriority _priority;
    private bool _completed;
    private DateTimeOffset? _completedAt;

    public string Id { get; }
    public string Title => _title;
    public string? Description => _description;
    public TaskPriority Priority => _priority;
    public bool IsCompleted => _completed;
    public DateTimeOffset CreatedAt { get; }
    public DateTimeOffset? CompletedAt => _completedAt;

    public TaskItem(string title, TaskPriority priority, string? description = null)
        : this(Guid.NewGuid().ToString(), title, priority, description, false, DateTimeOffset.UtcNow, null)
    {
        RaiseDomainEvent(new TaskCreatedEvent(Id, title, priority.Name, DateTimeOffset.UtcNow));
    }

    // For reconstitution from persistence
    internal TaskItem(
        string id,
        string title,
        TaskPriority priority,
        string? description,
        bool completed,
        DateTimeOffset createdAt,
        DateTimeOffset? completedAt)
    {
        ValidateTitle(title);
        Id = id;
        _title = title;
        _priority = priority;
        _description = description;
        _completed = completed;
        CreatedAt = createdAt;
        _completedAt = completedAt;
    }

    public void UpdateTitle(string newTitle)
    {
        ValidateTitle(newTitle);
        _title = newTitle;
    }

    public void UpdateDescription(string? newDescription)
    {
        if (newDescription?.Length > 2000)
            throw new ArgumentException("Description too long (max 2000 chars)");

        _description = newDescription;
    }

    public void ChangePriority(TaskPriority newPriority)
    {
        _priority = newPriority;
    }

    public void Complete()
    {
        if (_completed)
            throw new InvalidOperationException("Task is already completed");

        _completed = true;
        _completedAt = DateTimeOffset.UtcNow;

        RaiseDomainEvent(new TaskCompletedEvent(Id, _completedAt.Value, DateTimeOffset.UtcNow));
    }

    private static void ValidateTitle(string title)
    {
        if (string.IsNullOrWhiteSpace(title))
            throw new ArgumentException("Title cannot be empty", nameof(title));

        if (title.Length > 200)
            throw new ArgumentException("Title too long (max 200 chars)", nameof(title));
    }
}
```

```csharp
// Domain/Repositories/ITaskRepository.cs
namespace Domain.Repositories;

public interface ITaskRepository
{
    Task<TaskItem?> FindByIdAsync(string id);
    Task<IReadOnlyList<TaskItem>> FindAllAsync();
    Task SaveAsync(TaskItem task);
}
```

### Application Layer

```csharp
// Application/UseCases/CreateTask/CreateTaskUseCase.cs
namespace Application.UseCases.CreateTask;

public record CreateTaskRequest(
    string Title,
    string Priority,
    string? Description = null
);

public record CreateTaskResponse(
    string TaskId,
    string Title,
    string Priority,
    DateTimeOffset CreatedAt
);

public class CreateTaskUseCase(
    ITaskRepository taskRepository,
    IMediator mediator)
    : IUseCase<CreateTaskRequest, Result<CreateTaskResponse>>
{
    public async Task<Result<CreateTaskResponse>> ExecuteAsync(CreateTaskRequest request)
    {
        // Validate priority using Result pattern
        var priorityResult = TaskPriority.FromName(request.Priority);
        if (!priorityResult.IsSuccess)
            return Result<CreateTaskResponse>.Failure(priorityResult.Error!);

        if (string.IsNullOrWhiteSpace(request.Title))
            return Result<CreateTaskResponse>.Failure("Title is required");

        // Create domain entity — business rules enforced in constructor
        var task = new TaskItem(request.Title, priorityResult.Value!, request.Description);

        // Collect events before save
        var events = task.GetDomainEvents();

        // Persist
        await taskRepository.SaveAsync(task);
        task.ClearDomainEvents();

        // Dispatch domain events after successful save
        foreach (var domainEvent in events)
        {
            await mediator.Publish(domainEvent);
        }

        return Result<CreateTaskResponse>.Success(new CreateTaskResponse(
            task.Id,
            task.Title,
            task.Priority.Name,
            task.CreatedAt));
    }
}
```

### Infrastructure Layer

```csharp
// Infrastructure/Persistence/Entities/TaskEntity.cs
namespace Infrastructure.Persistence.Entities;

public class TaskEntity
{
    public string Id { get; set; } = string.Empty;
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Priority { get; set; } = string.Empty;
    public bool IsCompleted { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset? CompletedAt { get; set; }
}
```

```csharp
// Infrastructure/Persistence/AppDbContext.cs
namespace Infrastructure.Persistence;

public class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<TaskEntity> Tasks => Set<TaskEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<TaskEntity>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Title).IsRequired().HasMaxLength(200);
            entity.Property(e => e.Description).HasMaxLength(2000);
            entity.Property(e => e.Priority).IsRequired().HasMaxLength(20);
            entity.Property(e => e.IsCompleted).IsRequired();
            entity.Property(e => e.CreatedAt).IsRequired();
        });
    }
}
```

```csharp
// Infrastructure/Persistence/Repositories/EfTaskRepository.cs
namespace Infrastructure.Persistence.Repositories;

public class EfTaskRepository(AppDbContext context) : ITaskRepository
{
    public async Task<TaskItem?> FindByIdAsync(string id)
    {
        var entity = await context.Tasks.FindAsync(id);
        return entity is null ? null : ToDomain(entity);
    }

    public async Task<IReadOnlyList<TaskItem>> FindAllAsync()
    {
        var entities = await context.Tasks
            .OrderByDescending(t => t.CreatedAt)
            .ToListAsync();

        return entities.Select(ToDomain).ToList().AsReadOnly();
    }

    public async Task SaveAsync(TaskItem task)
    {
        var entity = await context.Tasks.FindAsync(task.Id);

        if (entity is null)
        {
            entity = new TaskEntity();
            context.Tasks.Add(entity);
        }

        // Map domain to persistence
        entity.Id = task.Id;
        entity.Title = task.Title;
        entity.Description = task.Description;
        entity.Priority = task.Priority.Name;
        entity.IsCompleted = task.IsCompleted;
        entity.CreatedAt = task.CreatedAt;
        entity.CompletedAt = task.CompletedAt;

        await context.SaveChangesAsync();
    }

    private static TaskItem ToDomain(TaskEntity entity)
    {
        var priority = TaskPriority.FromName(entity.Priority).Value!;

        return new TaskItem(
            entity.Id,
            entity.Title,
            priority,
            entity.Description,
            entity.IsCompleted,
            entity.CreatedAt,
            entity.CompletedAt);
    }
}
```

### Frameworks Layer

```csharp
// WebApi/Controllers/TasksController.cs
namespace WebApi.Controllers;

[ApiController]
[Route("api/v1/tasks")]
public class TasksController(CreateTaskUseCase createTaskUseCase) : ControllerBase
{
    public record CreateTaskDto(string Title, string Priority, string? Description = null);

    [HttpPost]
    public async Task<IActionResult> CreateTask([FromBody] CreateTaskDto dto)
    {
        var request = new CreateTaskRequest(dto.Title, dto.Priority, dto.Description);
        var result = await createTaskUseCase.ExecuteAsync(request);

        return result.Match<IActionResult>(
            onSuccess: response => CreatedAtAction(
                nameof(GetTask),
                new { id = response.TaskId },
                response),
            onFailure: error => BadRequest(new ProblemDetails { Detail = error }));
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetTask(string id)
    {
        // Omitted for brevity — delegates to GetTaskUseCase
        throw new NotImplementedException();
    }
}
```

```csharp
// WebApi/Program.cs — DI registration
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Infrastructure
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlite(builder.Configuration.GetConnectionString("DefaultConnection")));

// Repositories
builder.Services.AddScoped<ITaskRepository, EfTaskRepository>();

// Use cases
builder.Services.AddScoped<CreateTaskUseCase>();

// MediatR for domain event dispatch
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof(CreateTaskUseCase).Assembly));

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.MapControllers();
app.Run();
```

```csharp
// WebApi/Middleware/ResultExceptionMiddleware.cs
namespace WebApi.Middleware;

public class ResultExceptionMiddleware(RequestDelegate next)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (ArgumentException ex)
        {
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = 400,
                Detail = ex.Message
            });
        }
        catch (InvalidOperationException ex)
        {
            context.Response.StatusCode = StatusCodes.Status409Conflict;
            await context.Response.WriteAsJsonAsync(new ProblemDetails
            {
                Status = 409,
                Detail = ex.Message
            });
        }
    }
}
```

### Testing

```csharp
// Domain.Tests/Entities/TaskItemTests.cs
namespace Domain.Tests.Entities;

public class TaskItemTests
{
    [Fact]
    public void Create_ValidTask_ShouldSucceed()
    {
        var task = new TaskItem("Write tests", TaskPriority.High);

        Assert.Equal("Write tests", task.Title);
        Assert.Equal(TaskPriority.High, task.Priority);
        Assert.False(task.IsCompleted);
        Assert.NotEmpty(task.Id);
    }

    [Fact]
    public void Create_EmptyTitle_ShouldThrow()
    {
        Assert.Throws<ArgumentException>(() => new TaskItem("", TaskPriority.Low));
    }

    [Fact]
    public void Complete_UncompletedTask_ShouldRaiseEvent()
    {
        var task = new TaskItem("Deploy service", TaskPriority.Critical);
        task.ClearDomainEvents(); // clear creation event

        task.Complete();

        Assert.True(task.IsCompleted);
        Assert.NotNull(task.CompletedAt);

        var events = task.GetDomainEvents();
        Assert.Single(events);
        Assert.IsType<TaskCompletedEvent>(events[0]);
    }

    [Fact]
    public void Complete_AlreadyCompleted_ShouldThrow()
    {
        var task = new TaskItem("Fix bug", TaskPriority.Medium);
        task.Complete();

        Assert.Throws<InvalidOperationException>(() => task.Complete());
    }

    [Fact]
    public void ChangePriority_ShouldUpdateValue()
    {
        var task = new TaskItem("Review PR", TaskPriority.Low);

        task.ChangePriority(TaskPriority.High);

        Assert.Equal(TaskPriority.High, task.Priority);
    }
}
```

```csharp
// Application.Tests/UseCases/CreateTaskUseCaseTests.cs
using NSubstitute;

namespace Application.Tests.UseCases;

public class CreateTaskUseCaseTests
{
    private readonly ITaskRepository _repository;
    private readonly IMediator _mediator;
    private readonly CreateTaskUseCase _useCase;

    public CreateTaskUseCaseTests()
    {
        _repository = Substitute.For<ITaskRepository>();
        _mediator = Substitute.For<IMediator>();
        _useCase = new CreateTaskUseCase(_repository, _mediator);
    }

    [Fact]
    public async Task Execute_ValidRequest_ShouldReturnSuccess()
    {
        var request = new CreateTaskRequest("Build feature", "High", "Implement task management");

        var result = await _useCase.ExecuteAsync(request);

        Assert.True(result.IsSuccess);
        Assert.Equal("Build feature", result.Value!.Title);
        Assert.Equal("High", result.Value.Priority);
        await _repository.Received(1).SaveAsync(Arg.Any<TaskItem>());
        await _mediator.Received().Publish(Arg.Any<TaskCreatedEvent>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Execute_InvalidPriority_ShouldReturnFailure()
    {
        var request = new CreateTaskRequest("Build feature", "Urgent");

        var result = await _useCase.ExecuteAsync(request);

        Assert.False(result.IsSuccess);
        Assert.Contains("Unknown priority", result.Error);
        await _repository.DidNotReceive().SaveAsync(Arg.Any<TaskItem>());
    }

    [Fact]
    public async Task Execute_EmptyTitle_ShouldReturnFailure()
    {
        var request = new CreateTaskRequest("", "High");

        var result = await _useCase.ExecuteAsync(request);

        Assert.False(result.IsSuccess);
        Assert.Contains("Title is required", result.Error);
    }
}
```

## Summary

This example demonstrates:
- **Domain layer** with rich entity (`TaskItem`), value object (`TaskPriority`), domain events, and repository interface
- **Application layer** with use case returning `Result<T>`, domain event dispatch after persistence
- **Infrastructure layer** with EF Core repository, DbContext configuration, and domain/persistence mapping
- **Frameworks layer** with thin controller, DI registration, and error-handling middleware
- **Testing** with domain unit tests and application-layer tests using NSubstitute

Key patterns shown:
- Private backing fields with public read-only access
- Domain events raised inside entity behavior methods
- Result pattern for expected failures (no exceptions for validation)
- Separate persistence entities mapped to domain entities
- Controller delegates entirely to use case — no business logic in framework layer
