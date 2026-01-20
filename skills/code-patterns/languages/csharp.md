> This file is loaded on demand. See main SKILL.md for overview.

# C# Patterns and Standards

This skill provides C#/.NET-specific coding standards, patterns, and idioms for building robust enterprise applications using Clean Architecture.

## Environment and Tooling

- **.NET Version**: .NET 8+
- **Language Version**: C# 12+ with nullable reference types enabled
- **IDE**: Visual Studio 2022 or VS Code with C# Dev Kit
- **Package Manager**: NuGet or dotnet CLI
- **Build Tool**: MSBuild via dotnet CLI
- **Testing**: xUnit, NUnit, or MSTest
- **Code Formatting**: CSharpier
- **Linting**: .editorconfig + Roslyn analyzers

## Project Structure

### Solution Organization

```
Solution/
├── src/
│   ├── Domain/                 # Domain Layer
│   │   └── Domain.csproj
│   ├── Application/            # Application Layer
│   │   └── Application.csproj
│   ├── Infrastructure/         # Infrastructure Layer
│   │   └── Infrastructure.csproj
│   └── WebApi/                 # Presentation Layer
│       └── WebApi.csproj
├── tests/
│   ├── Domain.Tests/
│   ├── Application.Tests/
│   ├── Infrastructure.Tests/
│   └── WebApi.Tests/
├── Solution.sln
└── Directory.Build.props       # Shared build properties
```

### Project References

```xml
<!-- Domain.csproj - No dependencies -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
  </PropertyGroup>
</Project>

<!-- Application.csproj - References Domain -->
<ItemGroup>
  <ProjectReference Include="../Domain/Domain.csproj" />
</ItemGroup>

<!-- Infrastructure.csproj - References Application -->
<ItemGroup>
  <ProjectReference Include="../Application/Application.csproj" />
</ItemGroup>

<!-- WebApi.csproj - References Application and Infrastructure -->
<ItemGroup>
  <ProjectReference Include="../Application/Application.csproj" />
  <ProjectReference Include="../Infrastructure/Infrastructure.csproj" />
</ItemGroup>
```

## Code Formatting

### CSharpier Configuration

```json
// .csharpierrc.json
{
  "printWidth": 120,
  "useTabs": false,
  "tabWidth": 4,
  "endOfLine": "auto"
}
```

### EditorConfig

```ini
# .editorconfig
root = true

[*.cs]
indent_style = space
indent_size = 4
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

# C# specific
csharp_style_var_for_built_in_types = true
csharp_style_var_when_type_is_apparent = true
csharp_style_expression_bodied_methods = when_on_single_line
csharp_style_expression_bodied_properties = true
csharp_prefer_braces = true
csharp_style_namespace_declarations = file_scoped
```

## Naming Conventions

### General Rules

```csharp
// File-scoped namespace (C# 10+)
namespace Domain.Accounts.Models;

// PascalCase for public members
public class Patient
{
    // PascalCase for properties
    public string PatientId { get; private set; }

    // camelCase for private fields
    private readonly string _internalId;

    // PascalCase for methods
    public void UpdateProfile(string firstName, string lastName)
    {
        // camelCase for local variables
        var fullName = $"{firstName} {lastName}";
    }

    // PascalCase for events
    public event EventHandler<PatientUpdatedEventArgs>? PatientUpdated;

    // SCREAMING_SNAKE_CASE for constants
    public const int MAX_NAME_LENGTH = 100;
}

// Interfaces start with 'I'
public interface IPatientRepository
{
    Task<Patient?> GetById(string patientId);
}

// Async method naming: Do NOT use the '*Async' suffix
// The return type (Task<T>) already signals async behavior
public async Task<Result<Patient>> CreatePatient(CreatePatientRequest request)
{
    // Implementation
}
```

## Model Terminology (NOT DTOs)

Following Clean Architecture, use specific terminology for models at each layer:

### Domain Models

Location: `Domain/{Context}/Models/`

```csharp
namespace Domain.Accounts.Models;

// Entity
public class Patient
{
    public string Id { get; private set; }
    public string Email { get; private set; }
    public DateTime CreatedAt { get; private set; }

    private Patient() { } // EF Core constructor

    public Patient(string email)
    {
        Id = Guid.NewGuid().ToString();
        Email = email;
        CreatedAt = DateTime.UtcNow;
    }
}

// Value Object
public record Address(
    string Street,
    string City,
    string State,
    string ZipCode
);

// Domain Event
public record PatientCreatedEvent(
    string PatientId,
    string Email,
    DateTime OccurredAt
);
```

### Application Models

Location: `Application/{Context}/` or `Application/Models/`

```csharp
// Request/Response Models (colocated with use case)
namespace Application.Accounts.CreatePatient;

public record CreatePatientRequest(
    string Email,
    string FirstName,
    string LastName
);

public record CreatePatientResponse(
    string PatientId,
    DateTime CreatedAt
);

// Shared Application Models
namespace Application.Models;

public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public Error? Error { get; }

    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(Error error) => new(false, default, error);
}
```

### External Models (NOT DTOs)

Location: `Infrastructure/{Context}/{System}/Models/`

```csharp
namespace Infrastructure.Accounts.Salesforce.Models;

// External Model - NO "DTO" suffix
public class SalesforceContact
{
    public string Id { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FirstName { get; set; } = string.Empty;
    public string LastName { get; set; } = string.Empty;
}

// Mapper for External Model ↔ Domain translation
public class SalesforcePatientMapper
{
    public Patient ToDomain(SalesforceContact contact)
    {
        // Map external representation to domain
    }

    public SalesforceContact ToExternal(Patient patient)
    {
        // Map domain to external representation
    }
}
```

### View Models

Location: `WebApi/Views/` or controller-adjacent

```csharp
namespace WebApi.Views;

// Response View Model
public class PatientView
{
    public string Id { get; set; }
    public string Email { get; set; }
    public string FullName { get; set; }
    public DateTime CreatedAt { get; set; }
}

// Rare: API Contract for special cases
namespace WebApi.Controllers.Contracts;

public class CreatePatientLegacyContract
{
    [Required]
    public string Email { get; set; } = string.Empty;

    // Legacy field mapping
    public string PatientEmail => Email;
}
```

## Error Handling

### Result Pattern

```csharp
public class Result<T>
{
    public bool IsSuccess { get; }
    public T? Value { get; }
    public Error? Error { get; }

    protected Result(bool isSuccess, T? value, Error? error)
    {
        IsSuccess = isSuccess;
        Value = value;
        Error = error;
    }

    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(Error error) => new(false, default, error);

    public Result<TNext> Map<TNext>(Func<T, TNext> map)
    {
        return IsSuccess
            ? Result<TNext>.Success(map(Value!))
            : Result<TNext>.Failure(Error!);
    }
}

public record Error(string Code, string Message);
```

### RFC 7807 Problem Details

All API errors should follow RFC 7807 standard:

```csharp
public static class ControllerExtensions
{
    public static IActionResult ValidationError(
        this ControllerBase controller,
        string field,
        string message)
    {
        return controller.Problem(
            detail: message,
            instance: controller.Request.Path,
            statusCode: StatusCodes.Status400BadRequest,
            title: "Validation Error",
            extensions: new Dictionary<string, object?>
            {
                ["field"] = field
            });
    }

    public static IActionResult NotFoundError(
        this ControllerBase controller,
        string resourceType,
        string resourceId)
    {
        return controller.Problem(
            detail: $"{resourceType} with id {resourceId} not found",
            instance: controller.Request.Path,
            statusCode: StatusCodes.Status404NotFound,
            title: "Resource Not Found");
    }

    public static IActionResult ToActionResult<T>(
        this Result<T> result)
    {
        return result.IsSuccess
            ? new OkObjectResult(result.Value)
            : new ObjectResult(new ProblemDetails
            {
                Status = 422,
                Title = "Business Logic Error",
                Detail = result.Error?.Message
            });
    }
}
```

## Dependency Injection

### Service Registration

```csharp
// Program.cs
var builder = WebApplication.CreateBuilder(args);

// Add services by layer
builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddWebApiServices();

// Application Layer registration
public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(
        this IServiceCollection services)
    {
        // Register all use cases
        services.AddScoped<ICreatePatientUseCase, CreatePatientUseCase>();

        // Register validators
        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

        // Register MediatR if using
        services.AddMediatR(cfg =>
            cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly()));

        return services;
    }
}
```

### Constructor Injection

```csharp
public class PatientService : IPatientService
{
    private readonly IPatientRepository _repository;
    private readonly ILogger<PatientService> _logger;
    private readonly IEmailService _emailService;

    public PatientService(
        IPatientRepository repository,
        ILogger<PatientService> logger,
        IEmailService emailService)
    {
        _repository = repository ?? throw new ArgumentNullException(nameof(repository));
        _logger = logger ?? throw new ArgumentNullException(nameof(logger));
        _emailService = emailService ?? throw new ArgumentNullException(nameof(emailService));
    }
}
```

## Entity Framework Core Patterns

### DbContext Configuration

```csharp
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Patient> Patients => Set<Patient>();
    public DbSet<Order> Orders => Set<Order>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Apply all configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(Assembly.GetExecutingAssembly());
    }
}

// Entity Configuration
public class PatientConfiguration : IEntityTypeConfiguration<Patient>
{
    public void Configure(EntityTypeBuilder<Patient> builder)
    {
        builder.ToTable("Patients");

        builder.HasKey(p => p.Id);

        builder.Property(p => p.Email)
            .IsRequired()
            .HasMaxLength(255);

        builder.HasIndex(p => p.Email)
            .IsUnique();

        // Value object configuration
        builder.OwnsOne(p => p.Address, address =>
        {
            address.Property(a => a.Street).HasMaxLength(200);
            address.Property(a => a.City).HasMaxLength(100);
            address.Property(a => a.State).HasMaxLength(2);
            address.Property(a => a.ZipCode).HasMaxLength(10);
        });
    }
}
```

### Repository Pattern

```csharp
public interface IPatientRepository
{
    Task<Patient?> GetByIdAsync(string id, CancellationToken ct = default);
    Task<Patient?> GetByEmailAsync(string email, CancellationToken ct = default);
    Task AddAsync(Patient patient, CancellationToken ct = default);
    Task UpdateAsync(Patient patient, CancellationToken ct = default);
    Task DeleteAsync(string id, CancellationToken ct = default);
}

public class PatientRepository : IPatientRepository
{
    private readonly ApplicationDbContext _context;

    public PatientRepository(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<Patient?> GetByIdAsync(string id, CancellationToken ct = default)
    {
        return await _context.Patients
            .Include(p => p.Orders)
            .FirstOrDefaultAsync(p => p.Id == id, ct);
    }

    public async Task AddAsync(Patient patient, CancellationToken ct = default)
    {
        await _context.Patients.AddAsync(patient, ct);
        await _context.SaveChangesAsync(ct);
    }
}
```

## Testing Patterns

### Test Project Configuration

```xml
<!-- Domain.Tests.csproj -->
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <IsPackable>false</IsPackable>
    <IsTestProject>true</IsTestProject>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Microsoft.NET.Test.Sdk" Version="17.8.0" />
    <PackageReference Include="xunit" Version="2.6.1" />
    <PackageReference Include="xunit.runner.visualstudio" Version="2.5.3" />
    <PackageReference Include="coverlet.collector" Version="6.0.0" />
    <PackageReference Include="Moq" Version="4.20.69" />
    <PackageReference Include="FluentAssertions" Version="6.12.0" />
    <PackageReference Include="Bogus" Version="34.0.2" />
  </ItemGroup>
</Project>
```

### Test Organization and Naming

```csharp
// Test class naming: [ClassUnderTest]Tests
// Test method naming: [Method]_[Scenario]_[ExpectedResult]

public class OrderTests
{
    [Fact]
    public void Constructor_WithValidData_CreatesOrder()
    {
        // Test implementation
    }

    [Fact]
    public void AddItem_WhenOrderIsConfirmed_ThrowsInvalidOperationException()
    {
        // Test implementation
    }
}
```

### Domain Layer Testing

Pure unit tests with no external dependencies:

```csharp
// Domain.Tests/OrderTests.cs
public class OrderTests
{
    [Fact]
    public void CalculateTotal_WithMultipleItems_ReturnsCorrectSum()
    {
        // Arrange
        var order = new Order(customerId: "CUST-001");
        order.AddItem(new OrderItem("PROD-001", 10.50m, 2));
        order.AddItem(new OrderItem("PROD-002", 5.25m, 3));

        // Act
        var total = order.CalculateTotal();

        // Assert
        total.Should().Be(36.75m);
    }

    [Fact]
    public void ApplyDiscount_WithValidPercentage_ReducesTotal()
    {
        // Arrange
        var order = new Order("CUST-001");
        order.AddItem(new OrderItem("PROD-001", 100m, 1));

        // Act
        order.ApplyDiscount(0.20m); // 20% discount

        // Assert
        order.DiscountAmount.Should().Be(20m);
        order.FinalTotal.Should().Be(80m);
    }

    [Theory]
    [InlineData(OrderStatus.Pending, true)]
    [InlineData(OrderStatus.Processing, true)]
    [InlineData(OrderStatus.Shipped, false)]
    [InlineData(OrderStatus.Delivered, false)]
    [InlineData(OrderStatus.Cancelled, false)]
    public void CanModify_DependsOnStatus(OrderStatus status, bool expectedCanModify)
    {
        // Arrange
        var order = new Order("CUST-001") { Status = status };

        // Act
        var canModify = order.CanModify();

        // Assert
        canModify.Should().Be(expectedCanModify);
    }

    [Fact]
    public void Confirm_WhenPending_TransitionsToProcessing()
    {
        // Arrange
        var order = new Order("CUST-001");
        order.AddItem(new OrderItem("PROD-001", 10m, 1));

        // Act
        var events = order.Confirm();

        // Assert
        order.Status.Should().Be(OrderStatus.Processing);
        order.ConfirmedAt.Should().NotBeNull();
        events.Should().ContainSingle()
            .Which.Should().BeOfType<OrderConfirmedEvent>();
    }
}
```

### Application Layer Testing

Test use cases with mocked dependencies:

```csharp
// Application.Tests/CreateOrderHandlerTests.cs
public class CreateOrderHandlerTests
{
    private readonly Mock<IOrderRepository> _orderRepositoryMock;
    private readonly Mock<IProductRepository> _productRepositoryMock;
    private readonly Mock<ICustomerRepository> _customerRepositoryMock;
    private readonly Mock<IPaymentService> _paymentServiceMock;
    private readonly Mock<ILogger<CreateOrderHandler>> _loggerMock;
    private readonly CreateOrderHandler _handler;

    public CreateOrderHandlerTests()
    {
        _orderRepositoryMock = new Mock<IOrderRepository>();
        _productRepositoryMock = new Mock<IProductRepository>();
        _customerRepositoryMock = new Mock<ICustomerRepository>();
        _paymentServiceMock = new Mock<IPaymentService>();
        _loggerMock = new Mock<ILogger<CreateOrderHandler>>();

        _handler = new CreateOrderHandler(
            _orderRepositoryMock.Object,
            _productRepositoryMock.Object,
            _customerRepositoryMock.Object,
            _paymentServiceMock.Object,
            _loggerMock.Object);
    }

    [Fact]
    public async Task Handle_WithValidRequest_CreatesOrderSuccessfully()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = "CUST-001",
            Items = new[]
            {
                new OrderItemRequest { ProductId = "PROD-001", Quantity = 2 },
                new OrderItemRequest { ProductId = "PROD-002", Quantity = 1 }
            }
        };

        var customer = new Customer("CUST-001", "test@example.com");
        _customerRepositoryMock.Setup(x => x.GetByIdAsync("CUST-001"))
            .ReturnsAsync(customer);

        _productRepositoryMock.Setup(x => x.GetByIdAsync("PROD-001"))
            .ReturnsAsync(new Product("PROD-001", "Product 1", 10.50m, 100));

        _productRepositoryMock.Setup(x => x.GetByIdAsync("PROD-002"))
            .ReturnsAsync(new Product("PROD-002", "Product 2", 5.25m, 50));

        _paymentServiceMock.Setup(x => x.ProcessPaymentAsync(It.IsAny<PaymentRequest>()))
            .ReturnsAsync(Result<PaymentResponse>.Success(new PaymentResponse { TransactionId = "TXN-001" }));

        // Act
        var result = await _handler.Handle(request, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeTrue();
        result.Value.Should().NotBeNull();
        result.Value.OrderId.Should().NotBeNullOrEmpty();
        result.Value.Total.Should().Be(26.25m);

        _orderRepositoryMock.Verify(x => x.AddAsync(It.IsAny<Order>()), Times.Once);
        _paymentServiceMock.Verify(x => x.ProcessPaymentAsync(It.IsAny<PaymentRequest>()), Times.Once);
    }

    [Fact]
    public async Task Handle_WithInsufficientStock_ReturnsFailure()
    {
        // Arrange
        var request = new CreateOrderRequest
        {
            CustomerId = "CUST-001",
            Items = new[] { new OrderItemRequest { ProductId = "PROD-001", Quantity = 1000 } }
        };

        _customerRepositoryMock.Setup(x => x.GetByIdAsync("CUST-001"))
            .ReturnsAsync(new Customer("CUST-001", "test@example.com"));

        _productRepositoryMock.Setup(x => x.GetByIdAsync("PROD-001"))
            .ReturnsAsync(new Product("PROD-001", "Product 1", 10m, 5)); // Only 5 in stock

        // Act
        var result = await _handler.Handle(request, CancellationToken.None);

        // Assert
        result.IsSuccess.Should().BeFalse();
        result.Error.Code.Should().Be("INSUFFICIENT_STOCK");

        _orderRepositoryMock.Verify(x => x.AddAsync(It.IsAny<Order>()), Times.Never);
        _paymentServiceMock.Verify(x => x.ProcessPaymentAsync(It.IsAny<PaymentRequest>()), Times.Never);
    }
}
```

### Infrastructure Layer Testing

Test with real dependencies using test containers:

```csharp
// Infrastructure.Tests/SqlServerOrderRepositoryTests.cs
public class SqlServerOrderRepositoryTests : IAsyncLifetime
{
    private MsSqlContainer _sqlContainer;
    private ApplicationDbContext _context;
    private SqlServerOrderRepository _repository;

    public async Task InitializeAsync()
    {
        // Start SQL Server container
        _sqlContainer = new MsSqlBuilder()
            .WithImage("mcr.microsoft.com/mssql/server:2022-latest")
            .Build();

        await _sqlContainer.StartAsync();

        // Setup database context
        var options = new DbContextOptionsBuilder<ApplicationDbContext>()
            .UseSqlServer(_sqlContainer.GetConnectionString())
            .Options;

        _context = new ApplicationDbContext(options);
        await _context.Database.MigrateAsync();

        _repository = new SqlServerOrderRepository(_context);
    }

    public async Task DisposeAsync()
    {
        await _context.DisposeAsync();
        await _sqlContainer.StopAsync();
    }

    [Fact]
    public async Task AddAsync_PersistsOrderToDatabase()
    {
        // Arrange
        var order = new Order("CUST-001");
        order.AddItem(new OrderItem("PROD-001", 10m, 2));

        // Act
        await _repository.AddAsync(order);
        await _context.SaveChangesAsync();

        // Assert
        var savedOrder = await _repository.GetByIdAsync(order.Id);
        savedOrder.Should().NotBeNull();
        savedOrder!.CustomerId.Should().Be("CUST-001");
        savedOrder.Items.Should().HaveCount(1);
    }

    [Fact]
    public async Task GetByCustomerIdAsync_ReturnsCorrectOrders()
    {
        // Arrange
        var customerId = "CUST-001";
        var order1 = new Order(customerId);
        var order2 = new Order(customerId);
        var order3 = new Order("CUST-002"); // Different customer

        await _repository.AddAsync(order1);
        await _repository.AddAsync(order2);
        await _repository.AddAsync(order3);
        await _context.SaveChangesAsync();

        // Act
        var orders = await _repository.GetByCustomerIdAsync(customerId);

        // Assert
        orders.Should().HaveCount(2);
        orders.Should().AllSatisfy(o => o.CustomerId.Should().Be(customerId));
    }
}
```

### Web API Integration Testing

```csharp
// WebApi.Tests/PatientControllerIntegrationTests.cs
public class PatientControllerIntegrationTests : IClassFixture<WebApplicationFactory<Program>>
{
    private readonly WebApplicationFactory<Program> _factory;
    private readonly HttpClient _client;

    public PatientControllerIntegrationTests(WebApplicationFactory<Program> factory)
    {
        _factory = factory.WithWebHostBuilder(builder =>
        {
            builder.ConfigureTestServices(services =>
            {
                // Remove production database
                services.RemoveAll<DbContextOptions<ApplicationDbContext>>();

                // Add in-memory database for testing
                services.AddDbContext<ApplicationDbContext>(options =>
                {
                    options.UseInMemoryDatabase($"TestDb_{Guid.NewGuid()}");
                });

                // Add test authentication
                services.AddAuthentication("Test")
                    .AddScheme<TestAuthenticationSchemeOptions, TestAuthenticationHandler>(
                        "Test", options => { });
            });
        });

        _client = _factory.CreateClient(new WebApplicationFactoryClientOptions
        {
            AllowAutoRedirect = false
        });

        _client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Test");
    }

    [Fact]
    public async Task CreatePatient_WithValidData_Returns201Created()
    {
        // Arrange
        var request = new CreatePatientRequest
        {
            Email = "test@example.com",
            FirstName = "John",
            LastName = "Doe",
            DateOfBirth = new DateTime(1990, 1, 1)
        };

        // Act
        var response = await _client.PostAsJsonAsync("/api/patients", request);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Created);

        var content = await response.Content.ReadFromJsonAsync<PatientResponse>();
        content.Should().NotBeNull();
        content!.Email.Should().Be(request.Email);

        response.Headers.Location.Should().NotBeNull();
    }

    [Fact]
    public async Task GetPatient_WithInvalidId_Returns404NotFound()
    {
        // Act
        var response = await _client.GetAsync("/api/patients/invalid-id");

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.NotFound);

        var problemDetails = await response.Content.ReadFromJsonAsync<ProblemDetails>();
        problemDetails.Should().NotBeNull();
        problemDetails!.Type.Should().Be("https://httpstatuses.com/404");
        problemDetails.Title.Should().Be("Not Found");
    }

    [Fact]
    public async Task UpdatePatient_WithoutAuthorization_Returns401Unauthorized()
    {
        // Arrange
        _client.DefaultRequestHeaders.Authorization = null; // Remove auth

        var request = new UpdatePatientRequest { FirstName = "Jane" };

        // Act
        var response = await _client.PutAsJsonAsync("/api/patients/123", request);

        // Assert
        response.StatusCode.Should().Be(HttpStatusCode.Unauthorized);
    }
}
```

### Test Data Builders

```csharp
// Tests.Common/Builders/OrderBuilder.cs
public class OrderBuilder
{
    private string _customerId = "CUST-001";
    private List<OrderItem> _items = new();
    private OrderStatus _status = OrderStatus.Pending;
    private decimal _discountPercentage = 0;

    public OrderBuilder WithCustomerId(string customerId)
    {
        _customerId = customerId;
        return this;
    }

    public OrderBuilder WithItem(string productId, decimal price, int quantity)
    {
        _items.Add(new OrderItem(productId, price, quantity));
        return this;
    }

    public OrderBuilder WithStatus(OrderStatus status)
    {
        _status = status;
        return this;
    }

    public OrderBuilder WithDiscount(decimal percentage)
    {
        _discountPercentage = percentage;
        return this;
    }

    public Order Build()
    {
        var order = new Order(_customerId);

        foreach (var item in _items)
        {
            order.AddItem(item);
        }

        if (_discountPercentage > 0)
        {
            order.ApplyDiscount(_discountPercentage);
        }

        // Use reflection for testing different states
        if (_status != OrderStatus.Pending)
        {
            var statusProperty = typeof(Order).GetProperty("Status");
            statusProperty?.SetValue(order, _status);
        }

        return order;
    }
}

// Usage in tests
[Fact]
public void Order_WithTestBuilder_SimplifiesTestSetup()
{
    // Arrange
    var order = new OrderBuilder()
        .WithCustomerId("CUST-123")
        .WithItem("PROD-001", 10m, 2)
        .WithItem("PROD-002", 5m, 3)
        .WithDiscount(0.10m)
        .Build();

    // Assert
    order.CustomerId.Should().Be("CUST-123");
    order.Items.Should().HaveCount(2);
    order.FinalTotal.Should().Be(31.50m); // (20 + 15) * 0.9
}
```

### Test Data Generation with Bogus

```csharp
// Tests.Common/Fakers/CustomerFaker.cs
public class CustomerFaker : Faker<Customer>
{
    public CustomerFaker()
    {
        CustomInstantiator(f => new Customer(
            id: f.Random.Guid().ToString(),
            email: f.Internet.Email(),
            firstName: f.Name.FirstName(),
            lastName: f.Name.LastName()
        ));

        RuleFor(c => c.DateOfBirth, f => f.Date.Between(
            DateTime.Today.AddYears(-80),
            DateTime.Today.AddYears(-18)
        ));

        RuleFor(c => c.PhoneNumber, f => f.Phone.PhoneNumber());
    }
}

// Usage in tests
[Fact]
public void BulkImport_WithManyCustomers_PerformsEfficiently()
{
    // Arrange
    var faker = new CustomerFaker();
    var customers = faker.Generate(1000);
    var service = new CustomerImportService();

    // Act
    var stopwatch = Stopwatch.StartNew();
    var result = service.BulkImport(customers);
    stopwatch.Stop();

    // Assert
    result.ImportedCount.Should().Be(1000);
    stopwatch.ElapsedMilliseconds.Should().BeLessThan(5000);
}
```

### Property-Based Testing with FsCheck

```csharp
// Install-Package FsCheck.Xunit

[Property]
public Property Order_Total_Should_Equal_Sum_Of_Items()
{
    return Prop.ForAll<List<(decimal price, int quantity)>>(items =>
    {
        // Skip empty lists
        if (!items.Any() || items.Any(i => i.price <= 0 || i.quantity <= 0))
            return true;

        var order = new Order("CUST-001");
        decimal expectedTotal = 0;

        foreach (var (price, quantity) in items)
        {
            order.AddItem(new OrderItem($"PROD-{Guid.NewGuid()}", price, quantity));
            expectedTotal += price * quantity;
        }

        return Math.Abs(order.CalculateTotal() - expectedTotal) < 0.01m;
    });
}

[Property]
public bool Discount_Should_Never_Make_Total_Negative(decimal originalPrice, decimal discountPercentage)
{
    if (originalPrice <= 0) return true;

    var order = new Order("CUST-001");
    order.AddItem(new OrderItem("PROD-001", Math.Abs(originalPrice), 1));

    // Clamp discount between 0 and 100%
    var discount = Math.Min(Math.Max(discountPercentage, 0), 1);
    order.ApplyDiscount(discount);

    return order.FinalTotal >= 0;
}
```

### Snapshot Testing

```csharp
// Install-Package Verify.Xunit

public class SerializationTests
{
    [Fact]
    public Task Order_Serialization_MatchesSnapshot()
    {
        // Arrange
        var order = new OrderBuilder()
            .WithCustomerId("CUST-001")
            .WithItem("PROD-001", 10.50m, 2)
            .WithItem("PROD-002", 5.25m, 1)
            .WithDiscount(0.10m)
            .Build();

        // Act
        var json = JsonSerializer.Serialize(order, new JsonSerializerOptions
        {
            WriteIndented = true
        });

        // Assert - Creates/compares snapshot file
        return Verify(json);
    }
}
```

### Performance Testing

```csharp
// Install-Package BenchmarkDotNet

[MemoryDiagnoser]
[SimpleJob(RuntimeMoniker.Net80)]
public class OrderCalculationBenchmarks
{
    private Order _smallOrder;
    private Order _largeOrder;

    [GlobalSetup]
    public void Setup()
    {
        _smallOrder = new Order("CUST-001");
        _smallOrder.AddItem(new OrderItem("PROD-001", 10m, 1));

        _largeOrder = new Order("CUST-002");
        for (int i = 0; i < 1000; i++)
        {
            _largeOrder.AddItem(new OrderItem($"PROD-{i}", 10m, 1));
        }
    }

    [Benchmark]
    public decimal CalculateSmallOrder() => _smallOrder.CalculateTotal();

    [Benchmark]
    public decimal CalculateLargeOrder() => _largeOrder.CalculateTotal();
}

// Run with: dotnet run -c Release
```

### Test Helpers and Extensions

```csharp
// Tests.Common/Extensions/HttpResponseMessageExtensions.cs
public static class HttpResponseMessageExtensions
{
    public static async Task<T> DeserializeContentAsync<T>(this HttpResponseMessage response)
    {
        var json = await response.Content.ReadAsStringAsync();
        return JsonSerializer.Deserialize<T>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        }) ?? throw new InvalidOperationException("Failed to deserialize response");
    }

    public static async Task<ProblemDetails> GetProblemDetailsAsync(this HttpResponseMessage response)
    {
        return await response.DeserializeContentAsync<ProblemDetails>();
    }
}

// Tests.Common/Helpers/DatabaseHelper.cs
public static class DatabaseHelper
{
    public static async Task ResetDatabaseAsync(ApplicationDbContext context)
    {
        await context.Database.EnsureDeletedAsync();
        await context.Database.EnsureCreatedAsync();
    }

    public static async Task SeedTestDataAsync(ApplicationDbContext context)
    {
        var customers = new CustomerFaker().Generate(10);
        context.Customers.AddRange(customers);

        var products = new ProductFaker().Generate(20);
        context.Products.AddRange(products);

        await context.SaveChangesAsync();
    }
}
```

### Test Categories and Filtering

```csharp
// Mark tests with traits for categorization
public class PaymentServiceTests
{
    [Fact]
    [Trait("Category", "Unit")]
    public void ProcessPayment_WithValidCard_Succeeds()
    {
        // Unit test
    }

    [Fact]
    [Trait("Category", "Integration")]
    [Trait("RequiresPaymentGateway", "true")]
    public async Task ProcessPayment_WithRealGateway_Succeeds()
    {
        // Integration test requiring external service
    }
}

// Run specific categories:
// dotnet test --filter "Category=Unit"
// dotnet test --filter "Category!=Integration"
// dotnet test --filter "RequiresPaymentGateway!=true"
```

## Async/Await Patterns

### Async All the Way

```csharp
// WRONG - Blocking async code
public Patient GetPatient(string id)
{
    return _repository.GetByIdAsync(id).Result; // ❌ Blocks thread
}

// RIGHT - Async all the way
public async Task<Patient> GetPatientAsync(string id)
{
    return await _repository.GetByIdAsync(id);
}
```

### ConfigureAwait

```csharp
// In library code - use ConfigureAwait(false)
public async Task<Result<Patient>> ProcessAsync(string id)
{
    var patient = await _repository
        .GetByIdAsync(id)
        .ConfigureAwait(false); // Don't capture context

    // Process patient
    return Result<Patient>.Success(patient);
}

// In ASP.NET Core - generally not needed (no SynchronizationContext)
public async Task<IActionResult> GetPatient(string id)
{
    var patient = await _service.GetPatientAsync(id); // No ConfigureAwait needed
    return Ok(patient);
}
```

### Parallel Processing

```csharp
// Process multiple items concurrently
public async Task<List<ProcessResult>> ProcessBatchAsync(List<string> ids)
{
    var tasks = ids.Select(ProcessItemAsync);
    var results = await Task.WhenAll(tasks);
    return results.ToList();
}

// With concurrency limit
public async Task<List<ProcessResult>> ProcessBatchWithLimitAsync(
    List<string> ids,
    int maxConcurrency = 5)
{
    using var semaphore = new SemaphoreSlim(maxConcurrency);
    var tasks = ids.Select(async id =>
    {
        await semaphore.WaitAsync();
        try
        {
            return await ProcessItemAsync(id);
        }
        finally
        {
            semaphore.Release();
        }
    });

    return (await Task.WhenAll(tasks)).ToList();
}
```

## LINQ Best Practices

### Query Syntax vs Method Syntax

```csharp
// Method syntax (preferred for simple queries)
var activePatients = patients
    .Where(p => p.IsActive)
    .OrderBy(p => p.LastName)
    .ThenBy(p => p.FirstName)
    .Select(p => new PatientView
    {
        Id = p.Id,
        FullName = $"{p.FirstName} {p.LastName}"
    })
    .ToList();

// Query syntax (consider for complex joins)
var ordersWithPatients =
    from order in orders
    join patient in patients on order.PatientId equals patient.Id
    where order.Status == OrderStatus.Active
    select new OrderView
    {
        OrderId = order.Id,
        PatientName = patient.FullName,
        Total = order.Total
    };
```

### Avoiding Multiple Enumeration

```csharp
// WRONG - Multiple enumeration
public void ProcessPatients(IEnumerable<Patient> patients)
{
    if (patients.Any()) // First enumeration
    {
        var count = patients.Count(); // Second enumeration
        foreach (var patient in patients) // Third enumeration
        {
            // Process
        }
    }
}

// RIGHT - Single enumeration
public void ProcessPatients(IEnumerable<Patient> patients)
{
    var patientList = patients.ToList(); // Single enumeration
    if (patientList.Count > 0)
    {
        foreach (var patient in patientList)
        {
            // Process
        }
    }
}
```

## Controller Patterns

### Thin Controllers

```csharp
[ApiController]
[Route("api/[controller]")]
public class PatientsController : ControllerBase
{
    private readonly IMediator _mediator;

    public PatientsController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpPost]
    [ProducesResponseType(typeof(CreatePatientResponse), 201)]
    [ProducesResponseType(typeof(ProblemDetails), 400)]
    public async Task<IActionResult> CreatePatient(
        [FromBody] CreatePatientRequest request)
    {
        // Thin controller - just coordination
        var result = await _mediator.Send(request);

        return result.IsSuccess
            ? CreatedAtAction(nameof(GetPatient), new { id = result.Value.Id }, result.Value)
            : result.ToActionResult();
    }

    [HttpGet("{id}")]
    [ProducesResponseType(typeof(PatientView), 200)]
    [ProducesResponseType(typeof(ProblemDetails), 404)]
    public async Task<IActionResult> GetPatient(string id)
    {
        var query = new GetPatientQuery(id);
        var result = await _mediator.Send(query);

        return result.IsSuccess
            ? Ok(result.Value)
            : result.ToActionResult();
    }
}
```

## Validation with FluentValidation

```csharp
public class CreatePatientValidator : AbstractValidator<CreatePatientRequest>
{
    public CreatePatientValidator()
    {
        RuleFor(x => x.Email)
            .NotEmpty().WithMessage("Email is required")
            .EmailAddress().WithMessage("Invalid email format")
            .MaximumLength(255).WithMessage("Email too long");

        RuleFor(x => x.FirstName)
            .NotEmpty().WithMessage("First name is required")
            .MaximumLength(100).WithMessage("First name too long")
            .Matches(@"^[a-zA-Z\s'-]+$").WithMessage("Invalid characters in first name");

        RuleFor(x => x.DateOfBirth)
            .LessThan(DateTime.Today).WithMessage("Date of birth must be in the past")
            .GreaterThan(DateTime.Today.AddYears(-120)).WithMessage("Invalid date of birth");
    }
}
```

## Logging with Serilog

```csharp
// Program.cs
builder.Host.UseSerilog((context, configuration) =>
    configuration
        .ReadFrom.Configuration(context.Configuration)
        .Enrich.FromLogContext()
        .Enrich.WithMachineName()
        .Enrich.WithEnvironmentName()
        .WriteTo.Console()
        .WriteTo.File("logs/log-.txt", rollingInterval: RollingInterval.Day));

// Structured logging in service
public class PatientService
{
    private readonly ILogger<PatientService> _logger;

    public async Task<Result<Patient>> CreatePatientAsync(CreatePatientRequest request)
    {
        _logger.LogInformation(
            "Creating patient with email {Email}",
            request.Email); // Structured property

        try
        {
            // Create patient

            _logger.LogInformation(
                "Patient created successfully with ID {PatientId}",
                patient.Id);

            return Result<Patient>.Success(patient);
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Failed to create patient with email {Email}",
                request.Email);

            return Result<Patient>.Failure(new Error("CREATE_FAILED", "Failed to create patient"));
        }
    }
}
```

## Security Patterns

### API Authentication with JWT

```csharp
// Program.cs
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.Authority = builder.Configuration["Auth0:Domain"];
        options.Audience = builder.Configuration["Auth0:Audience"];
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy =>
        policy.RequireClaim("role", "admin"));

    options.AddPolicy("PatientAccess", policy =>
        policy.RequireAssertion(context =>
            context.User.HasClaim("role", "admin") ||
            context.User.HasClaim("role", "patient")));
});

// Controller with authorization
[Authorize]
[ApiController]
[Route("api/[controller]")]
public class PatientsController : ControllerBase
{
    [HttpGet("{id}")]
    [Authorize(Policy = "PatientAccess")]
    public async Task<IActionResult> GetPatient(string id)
    {
        // Implementation
    }

    [HttpDelete("{id}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> DeletePatient(string id)
    {
        // Implementation
    }
}
```

### Input Validation and Sanitization

```csharp
public static class InputSanitizer
{
    private static readonly Regex SqlInjectionPattern =
        new(@"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|UNION|ALTER|CREATE)\b)",
            RegexOptions.IgnoreCase);

    public static string SanitizeSql(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return string.Empty;

        // Remove potential SQL injection patterns
        return SqlInjectionPattern.Replace(input, string.Empty);
    }

    public static string SanitizeHtml(string input)
    {
        if (string.IsNullOrWhiteSpace(input))
            return string.Empty;

        // Use HtmlEncoder to prevent XSS
        return HtmlEncoder.Default.Encode(input);
    }

    public static string SanitizeFileName(string fileName)
    {
        // Remove invalid path characters
        var invalidChars = Path.GetInvalidFileNameChars();
        var sanitized = string.Join("", fileName.Split(invalidChars));

        // Prevent directory traversal
        sanitized = sanitized.Replace("..", "");
        sanitized = sanitized.Replace("/", "");
        sanitized = sanitized.Replace("\\", "");

        return sanitized;
    }
}
```

## Performance Patterns

### Caching with IMemoryCache

```csharp
public class CachedPatientService : IPatientService
{
    private readonly IPatientService _innerService;
    private readonly IMemoryCache _cache;
    private readonly ILogger<CachedPatientService> _logger;

    public CachedPatientService(
        IPatientService innerService,
        IMemoryCache cache,
        ILogger<CachedPatientService> logger)
    {
        _innerService = innerService;
        _cache = cache;
        _logger = logger;
    }

    public async Task<Patient?> GetPatientAsync(string id)
    {
        var cacheKey = $"patient_{id}";

        if (_cache.TryGetValue<Patient>(cacheKey, out var cached))
        {
            _logger.LogDebug("Cache hit for patient {PatientId}", id);
            return cached;
        }

        var patient = await _innerService.GetPatientAsync(id);

        if (patient != null)
        {
            var cacheOptions = new MemoryCacheEntryOptions
            {
                SlidingExpiration = TimeSpan.FromMinutes(5),
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(30)
            };

            _cache.Set(cacheKey, patient, cacheOptions);
        }

        return patient;
    }
}
```

Remember: Follow Clean Architecture principles, maintain clear layer boundaries, and prioritize testability and maintainability.
