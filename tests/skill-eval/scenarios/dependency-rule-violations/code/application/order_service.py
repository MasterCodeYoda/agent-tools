"""Application layer — order use cases."""

from sqlalchemy.orm import Session

# Correct: application layer imports from domain
from domain.order import Order, OrderStatus

# VIOLATION: application layer imports infrastructure directly
# Should depend on domain-defined repository interface instead
from infrastructure.database import OrderRepository


class OrderService:
    def __init__(self, db: Session):
        self.repo = OrderRepository(db)

    def get_order(self, order_id: int) -> Order:
        return self.repo.find_by_id(order_id)

    def create_order(self, customer_id: int, items: list) -> Order:
        order = Order(
            id=0,
            customer_id=customer_id,
            status="draft",  # string instead of enum
            total=0.0,
            items=items,
        )
        self.repo.save(order)
        return order

    # VIOLATION DRV-04: Raw SQL in application layer
    # Queries should live in infrastructure/repository, not here
    def get_orders_by_status(self, status: str, db: Session):
        result = db.execute(
            "SELECT * FROM orders WHERE status = :status",
            {"status": status},
        )
        return result.fetchall()
