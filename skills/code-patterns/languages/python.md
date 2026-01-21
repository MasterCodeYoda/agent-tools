<!-- Last reviewed: 2026-01-21 -->

> This file is loaded on demand. See main SKILL.md for overview.

# Python Patterns and Standards

This skill provides Python-specific coding standards, patterns, and idioms for consistent, high-quality Python development.

## Python Version and Environment

- **Minimum Version**: Python 3.13+
- **Package Manager**: UV (preferred) or pip
- **Virtual Environment**: Always use venv
- **Type Checking**: mypy with strict mode

> **Python 3.14 Preview (October 2025)**: PEP 649 deferred evaluation of annotations (faster imports), PEP 728 TypedDict with extra items, and improved type hint error messages.

## Code Style and Formatting

### Tools Configuration

```toml
# pyproject.toml
[tool.ruff]
line-length = 100
target-version = "py313"

[tool.mypy]
python_version = "3.13"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

### Import Organization

```python
# Standard library imports
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any  # Use T | None instead of Optional[T] (Python 3.10+)

# Timezone-aware datetime (Python 3.12+ deprecates utcnow())
now = datetime.now(timezone.utc)  # Always use timezone-aware datetimes

# Third-party imports
import httpx
import pydantic
from fastapi import FastAPI

# Local application imports
from PROJECT_NAME.domain import models
from PROJECT_NAME.application import services

# Relative imports (only within same directory)
from .utils import helper_function
from .models import UserModel
```

### Type Hints

Always use type hints, even for "obvious" cases:

```python
# WRONG
def calculate_total(items):
    total = 0
    for item in items:
        total += item.price * item.quantity
    return total

# RIGHT
def calculate_total(items: list[OrderItem]) -> Decimal:
    total = Decimal("0")
    for item in items:
        total += item.price * item.quantity
    return total
```

## Pydantic Models

Use Pydantic for all data validation:

```python
from decimal import Decimal
from datetime import datetime
from pydantic import BaseModel, Field, field_validator, field_serializer

class Product(BaseModel):
    id: str = Field(..., description="Unique product identifier")
    name: str = Field(..., min_length=1, max_length=200)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    created_at: datetime
    updated_at: datetime | None = None

    model_config = {"str_strip_whitespace": True}

    @field_serializer("price")
    def serialize_price(self, value: Decimal) -> str:
        return str(value)

    @field_serializer("created_at", "updated_at")
    def serialize_datetime(self, value: datetime | None) -> str | None:
        return value.isoformat() if value else None

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Price must be positive")
        return v.quantize(Decimal("0.01"))
```

> **Note**: For high-performance serialization (10-100x faster than Pydantic), consider `msgspec` for internal data structures. Pydantic remains preferred for API validation due to better error messages.

## Dependency Injection

Prefer explicit dependency injection:

```python
# WRONG - Hidden dependencies
class UserService:
    def create_user(self, email: str) -> User:
        # Hidden dependency on global database
        user = User(email=email)
        database.save(user)  # Where does database come from?
        return user

# RIGHT - Explicit dependencies
class UserService:
    def __init__(self, repository: UserRepository):
        self._repository = repository

    def create_user(self, email: str) -> User:
        user = User(email=email)
        self._repository.save(user)
        return user
```

## Error Handling

### Custom Exceptions

Create domain-specific exceptions:

```python
class DomainError(Exception):
    """Base class for domain errors."""
    pass

class ValidationError(DomainError):
    """Raised when validation fails."""
    def __init__(self, field: str, message: str):
        self.field = field
        self.message = message
        super().__init__(f"{field}: {message}")

class NotFoundError(DomainError):
    """Raised when entity not found."""
    def __init__(self, entity_type: str, entity_id: str):
        self.entity_type = entity_type
        self.entity_id = entity_id
        super().__init__(f"{entity_type} with id {entity_id} not found")
```

### Functional Error Handling with Result Types

For explicit error handling without exceptions, consider the `returns` library:

```python
from returns.result import Result, Success, Failure
from returns.pipeline import is_successful

class UserService:
    def find_user(self, user_id: str) -> Result[User, UserNotFoundError]:
        user = self._repository.get(user_id)
        if user is None:
            return Failure(UserNotFoundError(user_id))
        return Success(user)

    def update_email(
        self, user_id: str, new_email: str
    ) -> Result[User, UserNotFoundError | ValidationError]:
        return self.find_user(user_id).bind(
            lambda user: self._validate_and_update(user, new_email)
        )

# Usage with pattern matching
result = service.find_user("123")
match result:
    case Success(user):
        print(f"Found: {user.name}")
    case Failure(error):
        print(f"Error: {error}")

# Or with is_successful
if is_successful(result):
    user = result.unwrap()
```

This pattern makes error cases explicit in type signatures and avoids exception-based control flow for expected failure cases.

### Context Managers

Use context managers for resource management:

```python
from contextlib import contextmanager
from typing import Generator

@contextmanager
def database_transaction() -> Generator[Connection, None, None]:
    conn = get_connection()
    trans = conn.begin()
    try:
        yield conn
        trans.commit()
    except Exception:
        trans.rollback()
        raise
    finally:
        conn.close()

# Usage
with database_transaction() as conn:
    conn.execute(query)
```

## Async Patterns

### Async/Await Best Practices

```python
import asyncio

# WRONG - Blocking in async
async def fetch_all_wrong(urls: list[str]) -> list[str]:
    results = []
    for url in urls:
        result = await fetch(url)  # Sequential, slow
        results.append(result)
    return results

# RIGHT - Concurrent execution
async def fetch_all_right(urls: list[str]) -> list[str]:
    tasks = [fetch(url) for url in urls]
    return await asyncio.gather(*tasks)
```

### Async Context Managers

```python
class AsyncDatabase:
    async def __aenter__(self):
        self.conn = await aiopg.connect(DSN)
        return self.conn

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.conn.close()

# Usage
async def get_user(user_id: str) -> User:
    async with AsyncDatabase() as conn:
        result = await conn.fetchone(
            "SELECT * FROM users WHERE id = $1", user_id
        )
        return User(**result)
```

## Testing Patterns

### Test Structure and Organization

Follow the AAA pattern (Arrange, Act, Assert) for all tests:

```python
def test_user_can_update_profile():
    # Arrange - Set up test data and dependencies
    user = User(id="123", email="user@example.com")
    new_name = "Jane Doe"

    # Act - Execute the behavior being tested
    user.update_profile(name=new_name)

    # Assert - Verify the outcome
    assert user.name == new_name
    assert user.updated_at is not None
```

### Pytest Configuration

```python
# pyproject.toml
[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
python_files = "test_*.py"
python_classes = "Test*"
python_functions = "test_*"
addopts = [
    "--strict-markers",
    "--cov=src",
    "--cov-report=term-missing:skip-covered",
    "--cov-report=html",
    "--cov-fail-under=80",
]
markers = [
    "unit: Unit tests (fast, no I/O)",
    "integration: Integration tests (may use real dependencies)",
    "e2e: End-to-end tests (full stack)",
    "slow: Tests that take >1s to run",
]
asyncio_mode = "auto"
```

### Fixtures and Test Data

```python
# conftest.py
import pytest
from datetime import datetime, timezone
from decimal import Decimal
from unittest.mock import Mock, AsyncMock

@pytest.fixture
def sample_user():
    """Provides a sample user for testing."""
    return User(
        id="user-123",
        email="test@example.com",
        name="Test User",
        created_at=datetime.now(timezone.utc)
    )

@pytest.fixture
def mock_repository():
    """Provides a mock repository with common setup."""
    repo = Mock(spec=UserRepository)
    repo.get.return_value = None  # Default to not found
    repo.find_all.return_value = []
    return repo

@pytest.fixture
def mock_email_service():
    """Provides a mock email service."""
    service = Mock(spec=EmailService)
    service.send.return_value = True
    return service

# Fixture with cleanup
@pytest.fixture
def temp_database():
    """Provides a temporary database for integration tests."""
    db = create_test_database()
    yield db
    db.cleanup()  # Runs after test completes

# Parametrized fixture
@pytest.fixture(params=["admin", "user", "guest"])
def user_role(request):
    """Provides different user roles for testing."""
    return request.param
```

### Domain Layer Testing

Domain tests should be pure, fast, and comprehensive:

```python
# tests/domain/test_order.py
import pytest
from decimal import Decimal
from PROJECT_NAME.domain.models import Order, OrderItem, InsufficientInventoryError

class TestOrder:
    """Tests for Order entity."""

    def test_order_calculates_total_correctly(self):
        # No mocks needed - pure domain logic
        order = Order(id="order-1")
        order.add_item(OrderItem(product_id="p1", price=Decimal("10.00"), quantity=2))
        order.add_item(OrderItem(product_id="p2", price=Decimal("5.50"), quantity=1))

        assert order.total == Decimal("25.50")

    def test_order_cannot_exceed_max_items(self):
        order = Order(id="order-1", max_items=2)
        order.add_item(OrderItem(product_id="p1", price=Decimal("10.00"), quantity=1))
        order.add_item(OrderItem(product_id="p2", price=Decimal("5.00"), quantity=1))

        with pytest.raises(TooManyItemsError):
            order.add_item(OrderItem(product_id="p3", price=Decimal("15.00"), quantity=1))

    @pytest.mark.parametrize("status,can_modify", [
        ("pending", True),
        ("processing", True),
        ("shipped", False),
        ("delivered", False),
        ("cancelled", False),
    ])
    def test_order_modification_depends_on_status(self, status, can_modify):
        order = Order(id="order-1", status=status)

        if can_modify:
            order.add_item(OrderItem(product_id="p1", price=Decimal("10.00"), quantity=1))
            assert len(order.items) == 1
        else:
            with pytest.raises(OrderNotModifiableError):
                order.add_item(OrderItem(product_id="p1", price=Decimal("10.00"), quantity=1))
```

### Application Layer Testing

Application tests mock external dependencies:

```python
# tests/application/test_create_order.py
import pytest
from unittest.mock import Mock, call
from PROJECT_NAME.application.orders.create import CreateOrderUseCase, CreateOrderRequest

class TestCreateOrderUseCase:
    """Tests for CreateOrderUseCase."""

    def test_create_order_success(self, mock_repository, mock_email_service):
        # Arrange
        use_case = CreateOrderUseCase(mock_repository, mock_email_service)
        request = CreateOrderRequest(
            customer_id="cust-123",
            items=[{"product_id": "p1", "quantity": 2}]
        )

        # Mock repository responses
        mock_repository.get_customer.return_value = Customer(id="cust-123", email="customer@example.com")
        mock_repository.get_product.return_value = Product(id="p1", price=Decimal("10.00"), stock=10)

        # Act
        response = use_case.execute(request)

        # Assert
        assert response.order_id is not None
        assert response.total == Decimal("20.00")
        mock_repository.save.assert_called_once()
        mock_email_service.send.assert_called_once()

    def test_create_order_insufficient_inventory(self, mock_repository):
        # Arrange
        use_case = CreateOrderUseCase(mock_repository, Mock())
        request = CreateOrderRequest(
            customer_id="cust-123",
            items=[{"product_id": "p1", "quantity": 100}]
        )

        mock_repository.get_product.return_value = Product(id="p1", price=Decimal("10.00"), stock=5)

        # Act & Assert
        with pytest.raises(InsufficientInventoryError) as exc_info:
            use_case.execute(request)

        assert exc_info.value.requested == 100
        assert exc_info.value.available == 5
        mock_repository.save.assert_not_called()
```

### Infrastructure Layer Testing

Test with real dependencies when possible:

```python
# tests/infrastructure/test_postgres_repository.py
import pytest
import psycopg2
from testcontainers.postgres import PostgresContainer

@pytest.fixture(scope="module")
def postgres_container():
    """Provides a PostgreSQL test container."""
    with PostgresContainer("postgres:15") as postgres:
        yield postgres

@pytest.fixture
def db_connection(postgres_container):
    """Provides a database connection for tests."""
    conn = psycopg2.connect(postgres_container.get_connection_url())
    yield conn
    conn.close()

@pytest.mark.integration
class TestPostgresUserRepository:
    """Integration tests for PostgresUserRepository."""

    def test_save_and_retrieve_user(self, db_connection):
        # Use real database, not mocks
        repository = PostgresUserRepository(db_connection)
        user = User(id="user-1", email="test@example.com")

        # Save
        repository.save(user)

        # Retrieve
        retrieved = repository.get("user-1")
        assert retrieved is not None
        assert retrieved.email == "test@example.com"

    def test_find_by_email(self, db_connection):
        repository = PostgresUserRepository(db_connection)

        # Create test data
        user1 = User(id="user-1", email="alice@example.com")
        user2 = User(id="user-2", email="bob@example.com")
        repository.save(user1)
        repository.save(user2)

        # Test search
        found = repository.find_by_email("alice@example.com")
        assert found is not None
        assert found.id == "user-1"
```

### API/Framework Layer Testing

Test HTTP contracts and request/response handling:

```python
# tests/api/test_user_endpoints.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock

@pytest.fixture
def client(mock_use_cases):
    """Provides a test client with mocked use cases."""
    app = create_app(use_cases=mock_use_cases)
    return TestClient(app)

@pytest.mark.e2e
class TestUserEndpoints:
    """Tests for user API endpoints."""

    def test_create_user_endpoint(self, client, mock_use_cases):
        # Mock use case response
        mock_use_cases.create_user.return_value = CreateUserResponse(
            user_id="user-123",
            created_at=datetime.now(timezone.utc)
        )

        # Make request
        response = client.post("/users", json={
            "email": "new@example.com",
            "name": "New User"
        })

        # Assert HTTP layer behavior
        assert response.status_code == 201
        assert response.json()["user_id"] == "user-123"

        # Verify use case was called correctly
        mock_use_cases.create_user.assert_called_once()
        call_args = mock_use_cases.create_user.call_args[0][0]
        assert call_args.email == "new@example.com"

    def test_validation_error_returns_400(self, client):
        response = client.post("/users", json={
            "email": "invalid-email",  # Invalid format
            "name": ""  # Empty name
        })

        assert response.status_code == 400
        errors = response.json()["errors"]
        assert len(errors) == 2
```

### Async Testing

```python
# tests/test_async_service.py
import pytest
import asyncio
from unittest.mock import AsyncMock

@pytest.mark.asyncio
async def test_async_user_service():
    # Arrange
    mock_repo = AsyncMock(spec=AsyncUserRepository)
    mock_repo.get.return_value = User(id="123", email="test@example.com")

    service = AsyncUserService(mock_repo)

    # Act
    user = await service.get_user("123")

    # Assert
    assert user.email == "test@example.com"
    mock_repo.get.assert_awaited_once_with("123")

@pytest.mark.asyncio
async def test_concurrent_operations():
    service = AsyncDataService()

    # Run multiple operations concurrently
    results = await asyncio.gather(
        service.fetch_data("source1"),
        service.fetch_data("source2"),
        service.fetch_data("source3"),
    )

    assert len(results) == 3
    assert all(r is not None for r in results)
```

### Testing Utilities

```python
# tests/utils.py
from typing import Any
from unittest.mock import MagicMock

def create_mock_with_spec(spec_class: type, **attributes) -> MagicMock:
    """Create a mock with a spec and preset attributes."""
    mock = MagicMock(spec=spec_class)
    for key, value in attributes.items():
        setattr(mock, key, value)
    return mock

class AsyncContextManagerMock:
    """Mock for async context managers."""
    def __init__(self, return_value=None):
        self.return_value = return_value

    async def __aenter__(self):
        return self.return_value

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        pass

# Time-based testing
from freezegun import freeze_time

@freeze_time("2024-01-01 12:00:00")
def test_expiration_check():
    token = create_token(expires_in_hours=1)

    # Token is valid now
    assert token.is_valid()

    # Move time forward
    with freeze_time("2024-01-01 13:00:01"):
        # Token should be expired
        assert not token.is_valid()
```

### Property-Based Testing

```python
from hypothesis import given, strategies as st
from hypothesis import assume

@given(
    email=st.emails(),
    age=st.integers(min_value=0, max_value=150),
    name=st.text(min_size=1, max_size=100)
)
def test_user_creation_with_valid_inputs(email, age, name):
    """Test user creation with various valid inputs."""
    user = User(email=email, age=age, name=name)

    assert user.email == email
    assert user.age == age
    assert user.name == name
    assert user.is_valid()

@given(st.lists(st.integers(), min_size=1))
def test_sorting_preserves_length(items):
    """Property: sorting preserves list length."""
    sorted_items = sorted(items)
    assert len(sorted_items) == len(items)
```

### Test Coverage and Quality

```python
# Ensure critical paths are tested
class TestCriticalUserFlow:
    """Critical user flow tests that must always pass."""

    @pytest.mark.critical
    def test_user_registration_flow(self):
        """Test complete user registration flow."""
        # This test should cover:
        # 1. User provides registration data
        # 2. Data is validated
        # 3. User is created in system
        # 4. Confirmation email is sent
        # 5. User can log in
        pass

    @pytest.mark.critical
    @pytest.mark.timeout(5)  # Must complete within 5 seconds
    def test_user_authentication(self):
        """Test user authentication performance."""
        pass

# Skip tests conditionally
@pytest.mark.skipif(
    not os.environ.get("INTEGRATION_TESTS"),
    reason="Integration tests disabled"
)
def test_external_api_integration():
    pass

# Mark expected failures
@pytest.mark.xfail(reason="Feature not yet implemented")
def test_upcoming_feature():
    pass
```

## Protocol and ABC Usage

Use protocols for structural typing:

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class Repository[T](Protocol):
    """Protocol for repository pattern."""

    def get(self, id: str) -> T | None: ...
    def save(self, entity: T) -> None: ...
    def delete(self, id: str) -> None: ...

# Can be used with any class that matches the protocol
class UserRepository:
    def get(self, id: str) -> User | None:
        # Implementation
        pass

    def save(self, entity: User) -> None:
        # Implementation
        pass

    def delete(self, id: str) -> None:
        # Implementation
        pass

# Type checking works without inheritance
def process_entity[T](repo: Repository[T], entity_id: str) -> T | None:
    return repo.get(entity_id)
```

### Method Bodies: Docstring is Sufficient

When a method has a docstring, no additional body statement is needed. The docstring serves as the method body.

```python
# WRONG - Unnecessary ellipsis with docstring
class Repository(Protocol):
    def get(self, id: str) -> T | None:
        """Retrieve entity by ID."""
        ...  # Unnecessary!

# WRONG - Unnecessary pass with docstring
class Repository(Protocol):
    def get(self, id: str) -> T | None:
        """Retrieve entity by ID."""
        pass  # Also unnecessary!

# RIGHT - Docstring alone is sufficient
class Repository(Protocol):
    def get(self, id: str) -> T | None:
        """Retrieve entity by ID."""
        # The docstring IS the method body - nothing else needed

# Only use ellipsis when there's NO docstring
class Repository(Protocol):
    def get(self, id: str) -> T | None: ...
    def save(self, entity: T) -> None: ...
```

This applies to **both** `Protocol` and `ABC` abstract methods. A comprehensive docstring makes `...` or `pass` redundant and clutters the code.

## Dataclasses vs Pydantic

Choose the right tool:

```python
from dataclasses import dataclass, field
from pydantic import BaseModel

# Use dataclass for simple data containers
@dataclass
class Point:
    x: float
    y: float
    z: float = 0.0

# Use Pydantic for validation and serialization
class UserInput(BaseModel):
    email: EmailStr
    age: int = Field(gt=0, le=150)
    name: str = Field(min_length=1, max_length=100)
```

## Logging Best Practices

Use structured logging:

```python
import structlog

logger = structlog.get_logger()

class UserService:
    def create_user(self, email: str) -> User:
        logger.info(
            "Creating user",
            email=email,
            service="UserService",
            action="create_user"
        )

        try:
            user = User(email=email)
            self._repository.save(user)

            logger.info(
                "User created successfully",
                user_id=user.id,
                email=email
            )
            return user

        except Exception as e:
            logger.error(
                "Failed to create user",
                email=email,
                error=str(e),
                exc_info=True
            )
            raise
```

## Performance Patterns

### Caching

```python
from functools import lru_cache, cached_property
from typing import Any

class DataService:
    @cached_property
    def expensive_config(self) -> dict[str, Any]:
        """Load and parse config file (cached after first access)."""
        return self._load_config()

    @lru_cache(maxsize=128)
    def get_user(self, user_id: str) -> User | None:
        """Cache user lookups."""
        return self._repository.get(user_id)
```

### Updating Immutable Objects (Python 3.13+)

```python
import copy
from dataclasses import dataclass

@dataclass(frozen=True)
class Config:
    host: str
    port: int
    debug: bool = False

config = Config(host="localhost", port=8080)
# Create copy with updated field
new_config = copy.replace(config, debug=True)
```

### Generators for Large Data

```python
# WRONG - Loads everything into memory
def get_all_users() -> list[User]:
    return [User(**row) for row in db.fetch_all("SELECT * FROM users")]

# RIGHT - Yields one at a time
def get_all_users() -> Generator[User, None, None]:
    cursor = db.cursor("SELECT * FROM users")
    for row in cursor:
        yield User(**row)
```

## Common Gotchas

### Mutable Default Arguments

```python
# WRONG
def append_to_list(item, target=[]):
    target.append(item)
    return target

# RIGHT
def append_to_list(item, target=None):
    if target is None:
        target = []
    target.append(item)
    return target
```

### Late Binding in Loops

```python
# WRONG
funcs = []
for i in range(5):
    funcs.append(lambda: i)  # All will return 4

# RIGHT
funcs = []
for i in range(5):
    funcs.append(lambda i=i: i)  # Capture current value
```

## Package Structure

### __init__.py Patterns

```python
# project/domain/__init__.py
# Explicit re-exports
from .models import User as User
from .models import Product as Product
from .services import UserService as UserService

# NEVER use __all__
# __all__ = ["User", "Product", "UserService"]  # WRONG
```

### Private vs Public

```python
# _internal.py - Private module (not for external use)
def _helper_function():
    pass

# public.py - Public module
from ._internal import _helper_function

def public_function():
    return _helper_function()
```

## FastAPI Patterns

### Model Naming Conventions

Use clear, purpose-driven names for your models:

```python
# Request models - data coming INTO the API
class CreateUserRequest(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)
    role: str | None = None

# Response models - data going OUT of the API
class UserResponse(BaseModel):
    id: str
    email: str
    name: str
    created_at: datetime

    @classmethod
    def from_domain(cls, user: User) -> "UserResponse":
        """Convert domain entity to API response."""
        return cls(
            id=user.id,
            email=user.email,
            name=user.name,
            created_at=user.created_at
        )

# View models - shared response structures for complex queries
class UserListView(BaseModel):
    users: list[UserResponse]
    total: int
    page: int
    per_page: int
```

### Dependency Injection

```python
from fastapi import Depends, FastAPI
from typing import Annotated

async def get_repository() -> UserRepository:
    return UserRepository()

async def get_service(
    repo: Annotated[UserRepository, Depends(get_repository)]
) -> UserService:
    return UserService(repo)

@app.post("/users", response_model=UserResponse, status_code=201)
async def create_user(
    request: CreateUserRequest,
    service: Annotated[UserService, Depends(get_service)]
) -> UserResponse:
    user = await service.create_user(request)
    return UserResponse.from_domain(user)
```

### Configuration with Pydantic Settings

Use `pydantic-settings` for type-safe configuration:

```python
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field, SecretStr

class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Database
    database_url: str = Field(alias="DATABASE_URL")
    database_pool_size: int = Field(default=5, ge=1, le=20)

    # API Keys (use SecretStr for sensitive data)
    stripe_api_key: SecretStr = Field(alias="STRIPE_API_KEY")

    # Feature flags
    enable_cache: bool = Field(default=True)
    debug_mode: bool = Field(default=False)

# Usage with FastAPI dependency
from functools import lru_cache

@lru_cache
def get_settings() -> Settings:
    return Settings()

# Access in application
settings = get_settings()
# settings.stripe_api_key.get_secret_value()  # For sensitive values
```

Install with: `uv add pydantic-settings`

## Draft/Submission Patterns

Multi-step forms often require backend support for saving partial data (drafts) before final submission. These patterns handle the draft lifecycle with optimistic locking and state management.

### Draft Entity Pattern

Model drafts as first-class domain entities with lifecycle states:

```python
from datetime import datetime, timezone
from enum import Enum
from typing import Generic, TypeVar
from pydantic import BaseModel, Field

class DraftStatus(str, Enum):
    """Draft lifecycle states."""
    ACTIVE = "active"        # Currently being edited
    SUBMITTED = "submitted"  # Final submission complete
    EXPIRED = "expired"      # Abandoned or timed out
    CANCELLED = "cancelled"  # Explicitly cancelled by user

TData = TypeVar("TData", bound=BaseModel)

class Draft(BaseModel, Generic[TData]):
    """Generic draft entity for multi-step form data."""
    id: str
    user_id: str
    status: DraftStatus = DraftStatus.ACTIVE
    data: TData
    current_step: str
    completed_steps: list[str] = Field(default_factory=list)
    version: int = 1  # For optimistic locking
    created_at: datetime
    updated_at: datetime
    expires_at: datetime | None = None

    def is_active(self) -> bool:
        """Check if draft can still be modified."""
        if self.status != DraftStatus.ACTIVE:
            return False
        if self.expires_at and datetime.now(timezone.utc) > self.expires_at:
            return False
        return True

    def mark_step_complete(self, step_id: str) -> None:
        """Mark a step as completed."""
        if step_id not in self.completed_steps:
            self.completed_steps.append(step_id)
        self.updated_at = datetime.now(timezone.utc)

    def can_submit(self, required_steps: list[str]) -> bool:
        """Check if all required steps are complete."""
        return all(step in self.completed_steps for step in required_steps)
```

### Draft Repository Pattern

Abstract draft persistence with optimistic locking:

```python
from abc import ABC, abstractmethod
from typing import Generic, TypeVar

class DraftRepository(ABC, Generic[TData]):
    """Repository interface for draft persistence."""

    @abstractmethod
    async def create(self, draft: Draft[TData]) -> Draft[TData]:
        """Create a new draft."""

    @abstractmethod
    async def get(self, draft_id: str, user_id: str) -> Draft[TData] | None:
        """Retrieve a draft by ID and user."""

    @abstractmethod
    async def update(
        self,
        draft: Draft[TData],
        expected_version: int
    ) -> Draft[TData]:
        """
        Update draft with optimistic locking.

        Raises:
            ConcurrentModificationError: If version mismatch
        """

    @abstractmethod
    async def delete(self, draft_id: str, user_id: str) -> bool:
        """Delete a draft. Returns True if deleted."""

    @abstractmethod
    async def find_active_by_user(
        self,
        user_id: str,
        draft_type: str
    ) -> list[Draft[TData]]:
        """Find all active drafts for a user."""


class ConcurrentModificationError(Exception):
    """Raised when draft was modified by another request."""
    def __init__(self, draft_id: str, expected: int, actual: int):
        self.draft_id = draft_id
        self.expected_version = expected
        self.actual_version = actual
        super().__init__(
            f"Draft {draft_id} was modified. "
            f"Expected version {expected}, found {actual}"
        )
```

### Draft Use Cases

Application layer use cases for draft management:

```python
from dataclasses import dataclass
from typing import TypeVar, Generic

TData = TypeVar("TData", bound=BaseModel)

@dataclass
class SaveDraftRequest(Generic[TData]):
    """Request to save draft progress."""
    draft_id: str | None
    user_id: str
    data: TData
    current_step: str
    completed_steps: list[str]
    version: int | None = None  # None for new drafts

@dataclass
class SaveDraftResponse:
    """Response after saving draft."""
    draft_id: str
    version: int
    saved_at: datetime

class SaveDraftUseCase(Generic[TData]):
    """Save or update a draft with optimistic locking."""

    def __init__(
        self,
        repository: DraftRepository[TData],
        id_generator: Callable[[], str],
    ):
        self._repository = repository
        self._generate_id = id_generator

    async def execute(self, request: SaveDraftRequest[TData]) -> SaveDraftResponse:
        now = datetime.now(timezone.utc)

        if request.draft_id is None:
            # Create new draft
            draft = Draft[TData](
                id=self._generate_id(),
                user_id=request.user_id,
                data=request.data,
                current_step=request.current_step,
                completed_steps=request.completed_steps,
                created_at=now,
                updated_at=now,
            )
            saved = await self._repository.create(draft)
        else:
            # Update existing draft
            existing = await self._repository.get(request.draft_id, request.user_id)

            if existing is None:
                raise DraftNotFoundError(request.draft_id)

            if not existing.is_active():
                raise DraftNotActiveError(request.draft_id, existing.status)

            # Update fields
            existing.data = request.data
            existing.current_step = request.current_step
            existing.completed_steps = request.completed_steps
            existing.updated_at = now

            # Optimistic locking - will raise if version mismatch
            saved = await self._repository.update(
                existing,
                expected_version=request.version or existing.version
            )

        return SaveDraftResponse(
            draft_id=saved.id,
            version=saved.version,
            saved_at=saved.updated_at,
        )


@dataclass
class SubmitDraftRequest:
    """Request to submit a completed draft."""
    draft_id: str
    user_id: str
    version: int

class SubmitDraftUseCase(Generic[TData]):
    """Finalize and submit a draft."""

    def __init__(
        self,
        repository: DraftRepository[TData],
        required_steps: list[str],
        on_submit: Callable[[Draft[TData]], Awaitable[None]],
    ):
        self._repository = repository
        self._required_steps = required_steps
        self._on_submit = on_submit

    async def execute(self, request: SubmitDraftRequest) -> None:
        draft = await self._repository.get(request.draft_id, request.user_id)

        if draft is None:
            raise DraftNotFoundError(request.draft_id)

        if not draft.is_active():
            raise DraftNotActiveError(request.draft_id, draft.status)

        if not draft.can_submit(self._required_steps):
            missing = [s for s in self._required_steps if s not in draft.completed_steps]
            raise IncompleteSubmissionError(request.draft_id, missing)

        # Process the submission (domain-specific logic)
        await self._on_submit(draft)

        # Mark as submitted
        draft.status = DraftStatus.SUBMITTED
        draft.updated_at = datetime.now(timezone.utc)

        await self._repository.update(draft, expected_version=request.version)
```

### Draft API Endpoints

FastAPI routes for draft management:

```python
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated

router = APIRouter(prefix="/drafts", tags=["drafts"])

# Request/Response models for API layer
class SaveDraftApiRequest(BaseModel):
    """API request for saving draft."""
    data: dict  # Partial form data
    current_step: str
    completed_steps: list[str]
    version: int | None = None

class DraftApiResponse(BaseModel):
    """API response for draft operations."""
    draft_id: str
    version: int
    saved_at: datetime
    status: DraftStatus

class ConflictErrorResponse(BaseModel):
    """Response for concurrent modification conflicts."""
    error: str = "conflict"
    message: str
    current_version: int


@router.post(
    "/{draft_type}",
    response_model=DraftApiResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_draft(
    draft_type: str,
    request: SaveDraftApiRequest,
    user: Annotated[User, Depends(get_current_user)],
    use_case: Annotated[SaveDraftUseCase, Depends(get_save_draft_use_case)],
) -> DraftApiResponse:
    """Create a new draft."""
    result = await use_case.execute(
        SaveDraftRequest(
            draft_id=None,
            user_id=user.id,
            data=request.data,
            current_step=request.current_step,
            completed_steps=request.completed_steps,
        )
    )
    return DraftApiResponse(
        draft_id=result.draft_id,
        version=result.version,
        saved_at=result.saved_at,
        status=DraftStatus.ACTIVE,
    )


@router.put(
    "/{draft_type}/{draft_id}",
    response_model=DraftApiResponse,
    responses={
        409: {"model": ConflictErrorResponse},
    },
)
async def update_draft(
    draft_type: str,
    draft_id: str,
    request: SaveDraftApiRequest,
    user: Annotated[User, Depends(get_current_user)],
    use_case: Annotated[SaveDraftUseCase, Depends(get_save_draft_use_case)],
) -> DraftApiResponse:
    """Update an existing draft with optimistic locking."""
    try:
        result = await use_case.execute(
            SaveDraftRequest(
                draft_id=draft_id,
                user_id=user.id,
                data=request.data,
                current_step=request.current_step,
                completed_steps=request.completed_steps,
                version=request.version,
            )
        )
        return DraftApiResponse(
            draft_id=result.draft_id,
            version=result.version,
            saved_at=result.saved_at,
            status=DraftStatus.ACTIVE,
        )
    except ConcurrentModificationError as e:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail={
                "error": "conflict",
                "message": "Draft was modified by another request. Please refresh.",
                "current_version": e.actual_version,
            },
        )


@router.post(
    "/{draft_type}/{draft_id}/submit",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def submit_draft(
    draft_type: str,
    draft_id: str,
    version: int,
    user: Annotated[User, Depends(get_current_user)],
    use_case: Annotated[SubmitDraftUseCase, Depends(get_submit_draft_use_case)],
) -> None:
    """Submit a completed draft."""
    try:
        await use_case.execute(
            SubmitDraftRequest(
                draft_id=draft_id,
                user_id=user.id,
                version=version,
            )
        )
    except IncompleteSubmissionError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail={
                "error": "incomplete",
                "message": "Cannot submit incomplete draft",
                "missing_steps": e.missing_steps,
            },
        )


@router.get(
    "/{draft_type}/{draft_id}",
    response_model=DraftDetailResponse,
)
async def get_draft(
    draft_type: str,
    draft_id: str,
    user: Annotated[User, Depends(get_current_user)],
    repository: Annotated[DraftRepository, Depends(get_draft_repository)],
) -> DraftDetailResponse:
    """Retrieve a draft with its current data."""
    draft = await repository.get(draft_id, user.id)

    if draft is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Draft not found",
        )

    return DraftDetailResponse.from_domain(draft)
```

### Draft Expiration Pattern

Background task to expire abandoned drafts:

```python
from datetime import timedelta
import asyncio

class DraftExpirationService:
    """Service to expire abandoned drafts."""

    def __init__(
        self,
        repository: DraftRepository,
        expiration_hours: int = 24,
    ):
        self._repository = repository
        self._expiration_delta = timedelta(hours=expiration_hours)

    async def expire_stale_drafts(self) -> int:
        """
        Mark stale drafts as expired.

        Returns count of expired drafts.
        """
        cutoff = datetime.now(timezone.utc) - self._expiration_delta
        expired_count = await self._repository.expire_before(cutoff)
        return expired_count


# Background task runner
async def run_draft_expiration(service: DraftExpirationService) -> None:
    """Run draft expiration on a schedule."""
    while True:
        try:
            count = await service.expire_stale_drafts()
            if count > 0:
                logger.info(f"Expired {count} stale drafts")
        except Exception as e:
            logger.error(f"Draft expiration failed: {e}")

        # Run every hour
        await asyncio.sleep(3600)
```

### Auto-Save Pattern (Backend Support)

Debounced auto-save with version tracking from the inklings reference:

```python
from datetime import datetime
from typing import Optional

class AutoSaveRequest(BaseModel):
    """Request for auto-save (partial updates)."""
    draft_id: str
    data: dict  # Partial data to merge
    version: int

class AutoSaveResponse(BaseModel):
    """Response with new version for next save."""
    version: int
    saved_at: datetime

class AutoSaveUseCase:
    """
    Handle auto-save requests with version tracking.

    Merges partial data updates to support debounced saves
    from the frontend.
    """

    def __init__(self, repository: DraftRepository):
        self._repository = repository

    async def execute(
        self,
        request: AutoSaveRequest,
        user_id: str,
    ) -> AutoSaveResponse:
        draft = await self._repository.get(request.draft_id, user_id)

        if draft is None:
            raise DraftNotFoundError(request.draft_id)

        if not draft.is_active():
            raise DraftNotActiveError(request.draft_id, draft.status)

        # Merge partial data with existing data
        merged_data = {**draft.data.model_dump(), **request.data}
        draft.data = type(draft.data)(**merged_data)
        draft.updated_at = datetime.now(timezone.utc)

        try:
            saved = await self._repository.update(
                draft,
                expected_version=request.version
            )
            return AutoSaveResponse(
                version=saved.version,
                saved_at=saved.updated_at,
            )
        except ConcurrentModificationError:
            # For auto-save, we can optionally force-save or return the conflict
            # This depends on your UX requirements
            raise
```

## CLI Patterns with Typer

```python
import typer
from pathlib import Path

app = typer.Typer(help="PROJECT_NAME CLI")

@app.command()
def process(
    input_file: Path = typer.Argument(
        ...,
        help="Input file to process",
        exists=True,
        file_okay=True,
        dir_okay=False,
        readable=True,
    ),
    output: Path | None = typer.Option(
        None,
        "--output",
        "-o",
        help="Output file (default: stdout)",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Enable verbose output",
    ),
) -> None:
    """Process the input file."""
    if verbose:
        typer.echo(f"Processing {input_file}")

    result = process_file(input_file)

    if output:
        output.write_text(result)
        typer.echo(f"Written to {output}")
    else:
        typer.echo(result)
```

## Security Patterns

### Input Validation

```python
import re

def sanitize_filename(filename: str) -> str:
    """Remove potentially dangerous characters from filename."""
    # Remove path separators and null bytes
    filename = filename.replace("/", "").replace("\\", "").replace("\0", "")

    # Keep only safe characters
    safe_name = re.sub(r"[^a-zA-Z0-9._-]", "", filename)

    # Prevent directory traversal
    if ".." in safe_name:
        raise ValueError("Invalid filename")

    return safe_name
```

### SQL Safety

```python
# WRONG - SQL Injection vulnerable
def get_user_wrong(user_id: str):
    query = f"SELECT * FROM users WHERE id = '{user_id}'"
    return db.execute(query)

# RIGHT - Parameterized query
def get_user_right(user_id: str):
    query = "SELECT * FROM users WHERE id = %s"
    return db.execute(query, (user_id,))
```

Remember: When in doubt, refer to the main AGENTS.md for project-wide standards and the `clean-architecture` skill for architectural patterns.
