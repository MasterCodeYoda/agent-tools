# Layer Patterns in Clean Architecture

## Overview

Clean Architecture organizes code into four concentric layers, each with specific responsibilities and constraints.

```
Domain → Application → Infrastructure → Frameworks
(inner)                                  (outer)
```

## Domain Layer

### Purpose
The heart of the software - pure business logic independent of any technology.

### Contains
- **Entities**: Core business objects with identity
- **Value Objects**: Immutable descriptive objects
- **Domain Services**: Business operations spanning multiple entities
- **Domain Events**: Significant business occurrences
- **Repository Interfaces**: Abstractions for data access
- **Domain Exceptions**: Business rule violations

### Responsibilities
- Enforce business rules and invariants
- Model the problem domain accurately
- Maintain consistency within aggregates
- Define the ubiquitous language

### What It MUST NOT Know About
- Databases, APIs, or any I/O
- Frameworks or libraries
- Application workflows
- User interfaces
- External services

### Example Structure
```
domain/
├── entities/
│   ├── order.py
│   ├── customer.py
│   └── product.py
├── value_objects/
│   ├── money.py
│   ├── address.py
│   └── email.py
├── services/
│   ├── pricing_service.py
│   └── tax_calculator.py
├── events/
│   ├── order_placed.py
│   └── payment_processed.py
├── exceptions/
│   └── domain_exceptions.py
└── repositories/
    └── order_repository.py  # Interface only
```

### Domain Patterns

#### Rich Domain Model
```
# GOOD - Rich model with behavior
class Order:
    def __init__(self, customer_id):
        self._customer_id = customer_id
        self._items = []
        self._status = OrderStatus.DRAFT

    def add_item(self, product, quantity):
        if self._status != OrderStatus.DRAFT:
            raise InvalidOperationError("Cannot modify submitted order")
        self._validate_product(product)
        self._items.append(OrderItem(product, quantity))

    def submit(self):
        if not self._items:
            raise InvalidOperationError("Cannot submit empty order")
        self._status = OrderStatus.SUBMITTED
        return OrderSubmitted(self.id, self.total)

# BAD - Anemic model
class Order:
    customer_id: str
    items: list
    status: str
    # No behavior, just data
```

#### Value Object Immutability
```
class Money:
    def __init__(self, amount, currency):
        self._amount = Decimal(str(amount))
        self._currency = currency

    def add(self, other):
        if other._currency != self._currency:
            raise CurrencyMismatchError()
        # Return new instance, don't modify
        return Money(self._amount + other._amount, self._currency)

    def __eq__(self, other):
        return (self._amount == other._amount and
                self._currency == other._currency)
```

## Application Layer

### Purpose
Orchestrates domain objects to accomplish use cases. Defines what the system does.

### Contains
- **Use Cases**: Application-specific business rules
- **Request/Response DTOs**: Input/output for use cases
- **Application Services**: Use case implementations
- **Application Events**: Application-level occurrences
- **Port Interfaces**: Contracts for external services

### Responsibilities
- Coordinate domain objects
- Implement use case workflows
- Transaction management
- Convert between domain and DTOs
- Trigger infrastructure services

### What It Knows About
- Domain layer (entities, services, repositories)
- Its own request/response models

### What It MUST NOT Know About
- Specific infrastructure implementations
- Framework details (HTTP, CLI, etc.)
- Database schemas
- External service details

### Example Structure
```
application/
├── use_cases/
│   ├── create_order/
│   │   ├── create_order_use_case.py
│   │   ├── create_order_request.py
│   │   └── create_order_response.py
│   ├── process_payment/
│   │   ├── process_payment_use_case.py
│   │   ├── process_payment_request.py
│   │   └── process_payment_response.py
│   └── ship_order/
│       └── ...
├── services/
│   └── notification_service.py  # Interface
└── views/
    └── order_view.py  # Shared read model
```

### Application Patterns

#### Use Case Pattern
```
class CreateOrderUseCase:
    def __init__(self,
                 order_repository: OrderRepository,
                 product_repository: ProductRepository,
                 notification_service: NotificationService):
        self._order_repo = order_repository
        self._product_repo = product_repository
        self._notifier = notification_service

    def execute(self, request: CreateOrderRequest) -> CreateOrderResponse:
        # Validate request
        self._validate_request(request)

        # Load domain objects
        customer = self._load_customer(request.customer_id)
        products = self._load_products(request.items)

        # Execute domain logic
        order = Order.create(customer)
        for item in request.items:
            product = products[item.product_id]
            order.add_item(product, item.quantity)

        # Persist
        self._order_repo.save(order)

        # Side effects
        self._notifier.notify_order_created(order)

        # Return response
        return CreateOrderResponse(
            order_id=order.id,
            total=order.total,
            status=order.status
        )
```

#### Request/Response Models
```
# Colocated with use case
class CreateOrderRequest:
    customer_id: str
    items: List[OrderItemRequest]
    shipping_address: AddressRequest

class CreateOrderResponse:
    order_id: str
    total: Money
    status: str
    estimated_delivery: date

# Shared view model
class OrderView:
    @classmethod
    def from_entity(cls, order: Order) -> 'OrderView':
        return cls(
            id=order.id,
            customer_id=order.customer_id,
            total=order.total,
            items=[ItemView.from_entity(i) for i in order.items]
        )
```

## Infrastructure Layer

### Purpose
Implements interfaces defined by inner layers. Handles all I/O operations.

### Contains
- **Repository Implementations**: Database access
- **Gateway Implementations**: External service integrations
- **Message Queue Adapters**: Async communication
- **File System Access**: File operations
- **Cache Implementations**: Caching strategies
- **Email/SMS Senders**: Communication services

### Responsibilities
- Implement repository interfaces
- Handle database transactions
- Call external APIs
- Manage file I/O
- Handle caching
- Send notifications

### What It Knows About
- Domain entities (to map to/from database)
- Application interfaces (to implement)
- External service APIs
- Database schemas

### What It MUST NOT Know About
- Use case implementation details
- Framework-specific request/response
- Controllers or presenters

### Example Structure
```
infrastructure/
├── repositories/
│   ├── sql_order_repository.py
│   ├── mongo_customer_repository.py
│   └── redis_cache_repository.py
├── gateways/
│   ├── stripe_payment_gateway.py
│   ├── sendgrid_email_gateway.py
│   └── s3_storage_gateway.py
├── messaging/
│   ├── rabbitmq_publisher.py
│   └── kafka_consumer.py
└── persistence/
    ├── database.py
    ├── migrations/
    └── mappings/
```

### Infrastructure Patterns

#### Repository Implementation
```
class SqlOrderRepository(OrderRepository):
    def __init__(self, db_session):
        self._session = db_session

    def find_by_id(self, order_id: OrderId) -> Optional[Order]:
        row = self._session.query(OrderModel).filter_by(id=order_id).first()
        if not row:
            return None
        return self._to_domain(row)

    def save(self, order: Order) -> None:
        model = self._to_model(order)
        self._session.add(model)
        self._session.commit()

    def _to_domain(self, model: OrderModel) -> Order:
        # Map database model to domain entity
        order = Order(model.customer_id)
        order._id = model.id
        order._status = OrderStatus(model.status)
        # ... map other fields
        return order

    def _to_model(self, order: Order) -> OrderModel:
        # Map domain entity to database model
        return OrderModel(
            id=order.id,
            customer_id=order.customer_id,
            status=order.status.value,
            # ... map other fields
        )
```

#### Gateway Implementation
```
class StripePaymentGateway(PaymentGateway):
    def __init__(self, api_key: str):
        self._stripe = stripe
        self._stripe.api_key = api_key

    def process_payment(self, amount: Money, token: str) -> PaymentResult:
        try:
            charge = self._stripe.Charge.create(
                amount=int(amount.amount * 100),
                currency=amount.currency.lower(),
                source=token
            )
            return PaymentResult(
                success=True,
                transaction_id=charge.id
            )
        except stripe.error.CardError as e:
            return PaymentResult(
                success=False,
                error=str(e)
            )
```

## Frameworks Layer

### Purpose
The outermost layer containing frameworks, tools, and delivery mechanisms.

### Contains
- **Web Frameworks**: REST APIs, GraphQL endpoints
- **CLI Interfaces**: Command-line tools
- **GUI Frameworks**: Desktop or web UIs
- **Message Handlers**: Queue consumers
- **Scheduled Jobs**: Cron tasks, batch processes
- **Database Drivers**: Actual database connections
- **Configuration**: Environment setup

### Responsibilities
- Receive external input
- Validate input format
- Convert to application requests
- Call use cases
- Convert responses to output format
- Handle framework-specific concerns

### What It Knows About
- All inner layers (to wire together)
- Framework-specific details
- Input/output formats
- Configuration and setup

### Example Structure
```
frameworks/
├── web/
│   ├── app.py  # FastAPI/Flask/Django app
│   ├── controllers/
│   │   ├── order_controller.py
│   │   └── customer_controller.py
│   ├── middleware/
│   │   ├── auth_middleware.py
│   │   └── error_handler.py
│   └── validators/
│       └── request_validators.py
├── cli/
│   ├── commands/
│   │   └── process_orders_command.py
│   └── main.py
├── workers/
│   └── order_processor_worker.py
└── config/
    ├── settings.py
    └── dependency_injection.py
```

### Framework Patterns

#### Controller Pattern
```
class OrderController:
    def __init__(self, create_order_use_case: CreateOrderUseCase):
        self._create_order = create_order_use_case

    @post("/orders")
    def create_order(self, request: HttpRequest) -> HttpResponse:
        # Parse HTTP request
        data = request.json()

        # Validate format
        self._validate_http_request(data)

        # Convert to application request
        app_request = CreateOrderRequest(
            customer_id=data["customerId"],
            items=[OrderItemRequest(**item) for item in data["items"]]
        )

        # Call use case
        try:
            response = self._create_order.execute(app_request)
        except DomainException as e:
            return HttpResponse(status=400, body={"error": str(e)})

        # Convert to HTTP response
        return HttpResponse(
            status=201,
            body={
                "orderId": response.order_id,
                "total": response.total.to_dict(),
                "status": response.status
            }
        )
```

#### Dependency Injection Setup
```
# Composition root - wires everything together
class Container:
    def __init__(self):
        # Infrastructure
        self.db = Database(CONNECTION_STRING)
        self.order_repo = SqlOrderRepository(self.db)
        self.payment_gateway = StripePaymentGateway(STRIPE_KEY)

        # Application
        self.create_order_use_case = CreateOrderUseCase(
            order_repository=self.order_repo,
            payment_gateway=self.payment_gateway
        )

        # Framework
        self.order_controller = OrderController(
            create_order_use_case=self.create_order_use_case
        )

# Wire to framework
container = Container()
app.route("/orders", methods=["POST"])(container.order_controller.create_order)
```

## Layer Communication Patterns

### Inward Dependencies Only
```
Allowed:
Framework → Infrastructure → Application → Domain

Not Allowed:
Domain → Application (Domain knows nothing about Application)
Application → Infrastructure (Application uses interfaces)
Infrastructure → Framework (Infrastructure doesn't know Framework)
```

### Data Flow Example
```
1. HTTP Request arrives at Framework layer
2. Controller validates and converts to Application Request
3. Use Case orchestrates Domain objects
4. Domain enforces business rules
5. Infrastructure persists through Repository
6. Application returns Response
7. Framework converts to HTTP Response
```

### Interface Placement
- **Repository Interfaces**: Domain or Application layer
- **Gateway Interfaces**: Application layer
- **Service Interfaces**: Application layer
- **Implementations**: Infrastructure layer

## Common Anti-Patterns to Avoid

### 1. Leaking Layers
```
# BAD - Domain depending on infrastructure
class Order:
    def save(self):
        db.execute("INSERT INTO orders...")  # Domain knows about DB!

# GOOD - Domain stays pure
class Order:
    # Just business logic, no persistence
```

### 2. Fat Controllers
```
# BAD - Business logic in controller
class OrderController:
    def create_order(self, request):
        # 100 lines of business logic here

# GOOD - Controller just coordinates
class OrderController:
    def create_order(self, request):
        return self.use_case.execute(request)
```

### 3. Anemic Domain
```
# BAD - No behavior in domain
class Order:
    id: str
    items: list
    # Just data, no methods

# GOOD - Rich domain with behavior
class Order:
    def add_item(self, item):
        # Business logic here
```

### 4. Generic Repositories
```
# BAD - Generic CRUD
interface Repository<T>:
    find(id)
    save(entity)
    delete(id)
    update(entity)

# GOOD - Domain-specific
interface OrderRepository:
    find_pending_orders()
    find_by_customer(customer_id)
    save(order)
```

## Summary

Each layer has a specific purpose:
- **Domain**: What the business is
- **Application**: What the system does
- **Infrastructure**: How it connects to the world
- **Frameworks**: How users interact with it

Maintain strict boundaries and the dependency rule to achieve true architectural independence.