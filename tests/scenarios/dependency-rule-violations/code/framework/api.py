"""FastAPI framework layer — route handlers."""

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from infrastructure.database import get_db, OrderRepository

router = APIRouter()


@router.post("/orders")
def create_order(customer_id: int, items: list, db: Session = Depends(get_db)):
    # VIOLATION DRV-03: Business logic in controller
    # Discount calculation and validation belong in domain layer

    if not items:
        return {"error": "Order must have at least one item"}

    total = 0.0
    for item in items:
        price = item["price"] * item["quantity"]

        # Business rule: bulk discount — this is domain logic
        if item["quantity"] > 10:
            price *= 0.9  # 10% bulk discount
        if item["quantity"] > 50:
            price *= 0.85  # additional 15% for large orders

        total += price

    # Business rule: minimum order — this is domain logic
    if total < 10.0:
        return {"error": "Minimum order is $10"}

    # Business rule: VIP check — this is domain logic
    vip_customers = [1, 2, 3, 42]
    if customer_id in vip_customers:
        total *= 0.95  # VIP discount

    repo = OrderRepository(db)
    order = repo.save({"customer_id": customer_id, "total": total, "items": items})

    # VIOLATION DRV-06: Returning ORM entity directly in API response
    # Should map to a response DTO
    return order


@router.get("/orders/{order_id}")
def get_order(order_id: int, db: Session = Depends(get_db)):
    repo = OrderRepository(db)
    order = repo.find_by_id(order_id)
    # VIOLATION DRV-06: ORM entity in response
    return order
