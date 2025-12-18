---
name: python-patterns
description: Python-specific coding standards, patterns, and idioms for building robust applications with type safety, testing patterns, async/await, and Clean Architecture implementation in Python
---

# Python Patterns and Standards

This skill provides Python-specific coding standards, patterns, and idioms for consistent, high-quality Python development.

## Python Version and Environment

- **Minimum Version**: Python 3.13+
- **Package Manager**: UV (preferred) or pip
- **Virtual Environment**: Always use venv
- **Type Checking**: mypy with strict mode

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
from pathlib import Path
from typing import Any, Optional

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
from typing import Optional
from pydantic import BaseModel, Field, field_validator

class Product(BaseModel):
    id: str = Field(..., description="Unique product identifier")
    name: str = Field(..., min_length=1, max_length=200)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = {
        "str_strip_whitespace": True,
        "json_encoders": {
            Decimal: str,
            datetime: lambda v: v.isoformat(),
        }
    }

    @field_validator("price")
    @classmethod
    def validate_price(cls, v: Decimal) -> Decimal:
        if v <= 0:
            raise ValueError("Price must be positive")
        return v.quantize(Decimal("0.01"))
```

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
from typing import list[str]

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
from datetime import datetime
from decimal import Decimal
from unittest.mock import Mock, AsyncMock

@pytest.fixture
def sample_user():
    """Provides a sample user for testing."""
    return User(
        id="user-123",
        email="test@example.com",
        name="Test User",
        created_at=datetime.utcnow()
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
            created_at=datetime.utcnow()
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

    def get(self, id: str) -> Optional[T]: ...
    def save(self, entity: T) -> None: ...
    def delete(self, id: str) -> None: ...

# Can be used with any class that matches the protocol
class UserRepository:
    def get(self, id: str) -> Optional[User]:
        # Implementation
        pass

    def save(self, entity: User) -> None:
        # Implementation
        pass

    def delete(self, id: str) -> None:
        # Implementation
        pass

# Type checking works without inheritance
def process_entity[T](repo: Repository[T], entity_id: str) -> Optional[T]:
    return repo.get(entity_id)
```

### Method Bodies: Docstring is Sufficient

When a method has a docstring, no additional body statement is needed. The docstring serves as the method body.

```python
# WRONG - Unnecessary ellipsis with docstring
class Repository(Protocol):
    def get(self, id: str) -> Optional[T]:
        """Retrieve entity by ID."""
        ...  # Unnecessary!

# WRONG - Unnecessary pass with docstring
class Repository(Protocol):
    def get(self, id: str) -> Optional[T]:
        """Retrieve entity by ID."""
        pass  # Also unnecessary!

# RIGHT - Docstring alone is sufficient
class Repository(Protocol):
    def get(self, id: str) -> Optional[T]:
        """Retrieve entity by ID."""
        # The docstring IS the method body - nothing else needed

# Only use ellipsis when there's NO docstring
class Repository(Protocol):
    def get(self, id: str) -> Optional[T]: ...
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
from typing import Optional

class DataService:
    @cached_property
    def expensive_config(self) -> dict[str, Any]:
        """Load and parse config file (cached after first access)."""
        return self._load_config()

    @lru_cache(maxsize=128)
    def get_user(self, user_id: str) -> Optional[User]:
        """Cache user lookups."""
        return self._repository.get(user_id)
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
    role: Optional[str] = None

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

## CLI Patterns with Typer

```python
import typer
from typing import Optional
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
    output: Optional[Path] = typer.Option(
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
from typing import Optional

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