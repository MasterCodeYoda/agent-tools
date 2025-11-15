# Python Clean Architecture Guide

## Overview

This guide provides Python-specific patterns and idioms for implementing Clean Architecture. Python's dynamic nature requires extra discipline to maintain architectural boundaries.

## Python Type System for Clean Architecture

### Type Hints Are Essential

Always use type hints for architectural clarity:

```python
from typing import Protocol, Optional, List
from dataclasses import dataclass

# Clear contracts with type hints
class OrderRepository(Protocol):
    async def find_by_id(self, order_id: str) -> Optional[Order]: ...
    async def save(self, order: Order) -> None: ...
```

### Use Protocols for Interfaces

Python doesn't have interfaces, but Protocols serve the same purpose:

```python
from typing import Protocol, runtime_checkable

@runtime_checkable
class PaymentGateway(Protocol):
    def process_payment(self, amount: Money, token: str) -> PaymentResult: ...

# Check compliance at runtime
if not isinstance(gateway, PaymentGateway):
    raise TypeError("Invalid payment gateway implementation")
```

## Domain Layer Patterns

### Entities with Dataclasses

```python
from dataclasses import dataclass, field
from typing import List
from datetime import datetime
import uuid

@dataclass
class Order:
    customer_id: str
    _id: str = field(default_factory=lambda: str(uuid.uuid4()))
    _items: List[OrderItem] = field(default_factory=list, repr=False)
    _status: str = field(default="draft", repr=False)
    _created_at: datetime = field(default_factory=datetime.now)

    @property
    def id(self) -> str:
        return self._id

    @property
    def status(self) -> str:
        return self._status

    def add_item(self, product_id: str, quantity: int, price: Money) -> None:
        """Add item to order, enforcing business rules."""
        if self._status != "draft":
            raise ValueError("Cannot modify submitted order")
        if quantity <= 0:
            raise ValueError("Quantity must be positive")

        self._items.append(OrderItem(product_id, quantity, price))

    def submit(self) -> None:
        """Submit order for processing."""
        if not self._items:
            raise ValueError("Cannot submit empty order")
        if self._status != "draft":
            raise ValueError("Order already submitted")

        self._status = "submitted"
```

### Value Objects with Frozen Dataclasses

```python
from dataclasses import dataclass
from decimal import Decimal

@dataclass(frozen=True)
class Money:
    amount: Decimal
    currency: str

    def __post_init__(self):
        # Validation in __post_init__ for frozen dataclasses
        if self.amount < 0:
            raise ValueError("Amount cannot be negative")
        if len(self.currency) != 3:
            raise ValueError("Currency must be 3-letter code")

    def add(self, other: "Money") -> "Money":
        if self.currency != other.currency:
            raise ValueError("Cannot add different currencies")
        return Money(self.amount + other.amount, self.currency)

    def __str__(self) -> str:
        return f"{self.currency} {self.amount:.2f}"
```

### Domain Services

```python
from typing import List

class PricingService:
    """Domain service for complex pricing calculations."""

    def calculate_total(self, items: List[OrderItem], customer: Customer) -> Money:
        subtotal = sum(item.total for item in items)
        discount = self._calculate_discount(subtotal, customer)
        return subtotal.subtract(discount)

    def _calculate_discount(self, amount: Money, customer: Customer) -> Money:
        if customer.is_premium:
            return Money(amount.amount * Decimal("0.1"), amount.currency)
        return Money(Decimal("0"), amount.currency)
```

## Application Layer Patterns

### Use Cases with Pydantic

```python
from pydantic import BaseModel, Field
from typing import List, Optional
from datetime import datetime

# Request/Response models with validation
class CreateOrderRequest(BaseModel):
    customer_id: str = Field(..., min_length=1)
    items: List[OrderItemRequest]
    shipping_address: AddressRequest

    class Config:
        # Pydantic configuration
        str_strip_whitespace = True
        use_enum_values = True

class CreateOrderResponse(BaseModel):
    order_id: str
    total: dict  # Money serialized to dict
    status: str
    created_at: datetime

# Use case implementation
class CreateOrderUseCase:
    def __init__(
        self,
        order_repository: OrderRepository,
        customer_repository: CustomerRepository,
        pricing_service: PricingService
    ):
        self._order_repo = order_repository
        self._customer_repo = customer_repository
        self._pricing = pricing_service

    async def execute(self, request: CreateOrderRequest) -> CreateOrderResponse:
        # Load customer
        customer = await self._customer_repo.find_by_id(request.customer_id)
        if not customer:
            raise CustomerNotFoundError(request.customer_id)

        # Create order
        order = Order(customer_id=request.customer_id)

        # Add items
        for item_request in request.items:
            order.add_item(
                product_id=item_request.product_id,
                quantity=item_request.quantity,
                price=Money(item_request.price, item_request.currency)
            )

        # Calculate pricing
        total = self._pricing.calculate_total(order.items, customer)
        order.set_total(total)

        # Persist
        await self._order_repo.save(order)

        # Return response
        return CreateOrderResponse(
            order_id=order.id,
            total=total.to_dict(),
            status=order.status,
            created_at=order.created_at
        )
```

### File Organization Pattern

```python
# application/orders/create_order.py

from pydantic import BaseModel
from typing import List

# Request model
class CreateOrderRequest(BaseModel):
    customer_id: str
    items: List[OrderItemRequest]

# Response model
class CreateOrderResponse(BaseModel):
    order_id: str
    success: bool

# Use case
class CreateOrderUseCase:
    def __init__(self, repository: OrderRepository):
        self._repository = repository

    async def execute(self, request: CreateOrderRequest) -> CreateOrderResponse:
        # Implementation
        pass
```

## Infrastructure Layer Patterns

### Repository Implementation with SQLAlchemy

```python
from sqlalchemy.orm import Session
from sqlalchemy import select
from typing import Optional, List

from domain.entities import Order
from domain.repositories import OrderRepository
from .models import OrderModel

class SqlOrderRepository(OrderRepository):
    def __init__(self, session: Session):
        self._session = session

    async def find_by_id(self, order_id: str) -> Optional[Order]:
        stmt = select(OrderModel).where(OrderModel.id == order_id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if not model:
            return None

        return self._to_domain(model)

    async def save(self, order: Order) -> None:
        model = self._to_model(order)
        self._session.add(model)
        await self._session.commit()

    def _to_domain(self, model: OrderModel) -> Order:
        """Map database model to domain entity."""
        order = Order(customer_id=model.customer_id)
        order._id = model.id
        order._status = model.status
        order._created_at = model.created_at

        # Reconstruct items
        for item_model in model.items:
            order._items.append(self._item_to_domain(item_model))

        return order

    def _to_model(self, order: Order) -> OrderModel:
        """Map domain entity to database model."""
        return OrderModel(
            id=order.id,
            customer_id=order.customer_id,
            status=order.status,
            created_at=order.created_at,
            items=[self._item_to_model(item) for item in order._items]
        )
```

### Gateway Implementation

```python
import httpx
from typing import Optional

from application.gateways import PaymentGateway
from domain.value_objects import Money, PaymentResult

class StripePaymentGateway(PaymentGateway):
    def __init__(self, api_key: str, timeout: int = 30):
        self._api_key = api_key
        self._client = httpx.AsyncClient(timeout=timeout)
        self._base_url = "https://api.stripe.com/v1"

    async def process_payment(
        self,
        amount: Money,
        token: str
    ) -> PaymentResult:
        headers = {"Authorization": f"Bearer {self._api_key}"}
        data = {
            "amount": int(amount.amount * 100),  # Stripe uses cents
            "currency": amount.currency.lower(),
            "source": token
        }

        try:
            response = await self._client.post(
                f"{self._base_url}/charges",
                headers=headers,
                data=data
            )
            response.raise_for_status()

            charge = response.json()
            return PaymentResult(
                success=True,
                transaction_id=charge["id"],
                amount=amount
            )
        except httpx.HTTPStatusError as e:
            return PaymentResult(
                success=False,
                error_message=str(e),
                amount=amount
            )

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self._client.aclose()
```

## Frameworks Layer Patterns

### FastAPI Controllers

```python
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Dict, Any

from application.orders import CreateOrderUseCase, CreateOrderRequest
from .dependencies import get_create_order_use_case

router = APIRouter(prefix="/orders", tags=["orders"])

class CreateOrderDTO(BaseModel):
    """HTTP request DTO."""
    customer_id: str
    items: List[Dict[str, Any]]
    shipping_address: Dict[str, str]

@router.post(
    "/",
    status_code=status.HTTP_201_CREATED,
    response_model=Dict[str, Any]
)
async def create_order(
    dto: CreateOrderDTO,
    use_case: CreateOrderUseCase = Depends(get_create_order_use_case)
):
    """Create a new order."""
    try:
        # Convert HTTP DTO to application request
        request = CreateOrderRequest(
            customer_id=dto.customer_id,
            items=[OrderItemRequest(**item) for item in dto.items],
            shipping_address=AddressRequest(**dto.shipping_address)
        )

        # Execute use case
        response = await use_case.execute(request)

        # Convert response to HTTP response
        return {
            "order_id": response.order_id,
            "total": response.total,
            "status": response.status,
            "created_at": response.created_at.isoformat()
        }

    except CustomerNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except DomainError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
```

### Dependency Injection with Dependencies

```python
# frameworks/web/dependencies.py

from functools import lru_cache
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends

from application.orders import CreateOrderUseCase
from infrastructure.repositories import SqlOrderRepository
from infrastructure.gateways import StripePaymentGateway
from .database import get_db_session
from .config import get_settings

@lru_cache()
def get_order_repository(
    session: AsyncSession = Depends(get_db_session)
) -> OrderRepository:
    return SqlOrderRepository(session)

@lru_cache()
def get_payment_gateway() -> PaymentGateway:
    settings = get_settings()
    return StripePaymentGateway(settings.stripe_api_key)

def get_create_order_use_case(
    repository: OrderRepository = Depends(get_order_repository),
    gateway: PaymentGateway = Depends(get_payment_gateway)
) -> CreateOrderUseCase:
    return CreateOrderUseCase(repository, gateway)
```

## Testing Patterns

### Domain Layer Tests

```python
import pytest
from decimal import Decimal
from domain.entities import Order
from domain.value_objects import Money

class TestOrder:
    def test_create_order(self):
        # Given
        customer_id = "customer-123"

        # When
        order = Order(customer_id=customer_id)

        # Then
        assert order.customer_id == customer_id
        assert order.status == "draft"
        assert len(order._items) == 0

    def test_add_item_to_order(self):
        # Given
        order = Order(customer_id="customer-123")

        # When
        order.add_item("product-1", 2, Money(Decimal("10.00"), "USD"))

        # Then
        assert len(order._items) == 1
        assert order._items[0].quantity == 2

    def test_cannot_modify_submitted_order(self):
        # Given
        order = Order(customer_id="customer-123")
        order.add_item("product-1", 1, Money(Decimal("10.00"), "USD"))
        order.submit()

        # When/Then
        with pytest.raises(ValueError, match="Cannot modify submitted order"):
            order.add_item("product-2", 1, Money(Decimal("5.00"), "USD"))
```

### Application Layer Tests

```python
import pytest
from unittest.mock import Mock, AsyncMock
from application.orders import CreateOrderUseCase, CreateOrderRequest

@pytest.mark.asyncio
async def test_create_order_use_case():
    # Given
    mock_repo = AsyncMock(spec=OrderRepository)
    mock_customer_repo = AsyncMock(spec=CustomerRepository)
    mock_customer_repo.find_by_id.return_value = Mock(id="customer-123")

    use_case = CreateOrderUseCase(
        order_repository=mock_repo,
        customer_repository=mock_customer_repo
    )

    request = CreateOrderRequest(
        customer_id="customer-123",
        items=[{"product_id": "prod-1", "quantity": 2, "price": 10.00}]
    )

    # When
    response = await use_case.execute(request)

    # Then
    assert response.success is True
    assert response.order_id is not None
    mock_repo.save.assert_called_once()
```

### Infrastructure Layer Tests

```python
import pytest
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from infrastructure.repositories import SqlOrderRepository
from domain.entities import Order

@pytest.fixture
async def test_session():
    """Create test database session."""
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSession(engine) as session:
        yield session

@pytest.mark.asyncio
async def test_repository_save_and_find(test_session):
    # Given
    repository = SqlOrderRepository(test_session)
    order = Order(customer_id="customer-123")
    order.add_item("product-1", 2, Money(Decimal("10.00"), "USD"))

    # When
    await repository.save(order)
    retrieved = await repository.find_by_id(order.id)

    # Then
    assert retrieved is not None
    assert retrieved.id == order.id
    assert retrieved.customer_id == "customer-123"
    assert len(retrieved._items) == 1
```

## Project Structure

```
src/
├── domain/                      # Domain layer (pure Python)
│   ├── __init__.py
│   ├── entities/
│   │   ├── __init__.py
│   │   ├── order.py
│   │   └── customer.py
│   ├── value_objects/
│   │   ├── __init__.py
│   │   ├── money.py
│   │   └── address.py
│   ├── services/
│   │   └── pricing_service.py
│   ├── repositories/            # Interfaces only
│   │   └── order_repository.py
│   └── exceptions.py
│
├── application/                 # Application layer
│   ├── __init__.py
│   └── orders/
│       ├── __init__.py
│       ├── create_order.py     # UseCase + Request + Response
│       ├── update_order.py
│       └── views.py             # Shared read models
│
├── infrastructure/              # Infrastructure layer
│   ├── __init__.py
│   ├── repositories/
│   │   ├── __init__.py
│   │   ├── sql_order_repository.py
│   │   └── models.py           # SQLAlchemy models
│   └── gateways/
│       ├── __init__.py
│       └── stripe_gateway.py
│
└── frameworks/                  # Frameworks layer
    ├── __init__.py
    └── web/                     # FastAPI
        ├── __init__.py
        ├── main.py              # App setup
        ├── routers/
        │   ├── __init__.py
        │   └── orders.py
        ├── dependencies.py      # DI configuration
        └── config.py           # Settings
```

## Python-Specific Tools

### Development Tools

```bash
# Code formatting
ruff format .

# Linting
ruff check .

# Type checking
mypy src/

# Testing
pytest
pytest --cov=src --cov-report=html

# Security scanning
bandit -r src/
```

### Dependencies (pyproject.toml)

```toml
[project]
name = "clean-architecture-example"
version = "0.1.0"
dependencies = [
    # Web framework
    "fastapi>=0.104.0",
    "uvicorn[standard]>=0.24.0",

    # Database
    "sqlalchemy>=2.0.0",
    "alembic>=1.12.0",
    "asyncpg>=0.29.0",  # PostgreSQL

    # Validation
    "pydantic>=2.5.0",

    # HTTP client
    "httpx>=0.25.0",
]

[project.optional-dependencies]
dev = [
    # Testing
    "pytest>=7.4.0",
    "pytest-asyncio>=0.21.0",
    "pytest-cov>=4.1.0",

    # Code quality
    "ruff>=0.1.0",
    "mypy>=1.7.0",
    "bandit>=1.7.0",

    # Development
    "ipython>=8.17.0",
]
```

## Common Python Pitfalls

### 1. Mutable Default Arguments

```python
# ❌ BAD
def create_order(items=[]):  # Mutable default
    order = Order()
    order.items = items  # Shared between calls!

# ✅ GOOD
def create_order(items=None):
    if items is None:
        items = []
    order = Order()
    order.items = items
```

### 2. Not Using Protocols

```python
# ❌ BAD - No clear contract
class SqlRepository:
    def save(self, entity):
        pass

# ✅ GOOD - Clear protocol
from typing import Protocol

class Repository(Protocol):
    def save(self, entity: Entity) -> None: ...
```

### 3. Mixing Sync and Async

```python
# ❌ BAD - Mixing paradigms
class UseCase:
    def execute(self, request):  # Sync
        data = await self.repo.find()  # Async - Error!

# ✅ GOOD - Consistent async
class UseCase:
    async def execute(self, request):
        data = await self.repo.find()
```

### 4. Not Handling None

```python
# ❌ BAD
order = repository.find_by_id(order_id)
total = order.calculate_total()  # Error if None!

# ✅ GOOD
order = repository.find_by_id(order_id)
if not order:
    raise OrderNotFoundError(order_id)
total = order.calculate_total()
```

## Summary

Python Clean Architecture requires:
- **Type hints** for clarity
- **Protocols** for interfaces
- **Dataclasses** for entities and value objects
- **Pydantic** for validation
- **Proper async/await** usage
- **Strong testing** to catch runtime errors

The dynamic nature of Python makes architectural discipline even more important.