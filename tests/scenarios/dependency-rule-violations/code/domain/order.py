"""Order domain model — PLANTED VIOLATIONS for evolve scenario testing."""

from dataclasses import dataclass
from enum import Enum

# VIOLATION DRV-01: Domain imports from infrastructure (SQLAlchemy)
from sqlalchemy import Column, Integer, String
from sqlalchemy.orm import DeclarativeBase


class OrderStatus(Enum):
    DRAFT = "draft"
    SUBMITTED = "submitted"
    FULFILLED = "fulfilled"


# VIOLATION DRV-02: Anemic domain model — no behavior, just data
@dataclass
class Order:
    id: int
    customer_id: int
    status: str  # string instead of OrderStatus enum — also weak typing
    total: float
    items: list

    # No business methods — no add_item(), no submit(), no validate()
    # All logic lives in the controller (see framework/api.py)


# VIOLATION DRV-01 continued: Domain entity using ORM base class
class OrderModel(DeclarativeBase):
    __tablename__ = "orders"
    id = Column(Integer, primary_key=True)
    customer_id = Column(Integer)
    status = Column(String)
    total = Column(Integer)


# VIOLATION DRV-05: No repository interface defined in domain layer
# The application layer imports infrastructure directly instead of
# depending on a domain-defined abstraction like:
#
#   class OrderRepository(Protocol):
#       def find_by_id(self, order_id: int) -> Order: ...
#       def save(self, order: Order) -> None: ...
