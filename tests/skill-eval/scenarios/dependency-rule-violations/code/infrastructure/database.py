"""Database infrastructure — concrete implementation."""

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

engine = create_engine("sqlite:///orders.db")
SessionLocal = sessionmaker(bind=engine)


def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


class OrderRepository:
    """Concrete repository — correctly in infrastructure layer."""

    def __init__(self, db: Session):
        self.db = db

    def find_by_id(self, order_id: int):
        return self.db.query(OrderModel).filter_by(id=order_id).first()

    def save(self, order):
        self.db.add(order)
        self.db.commit()


# Note: This import would normally come from domain, but domain's OrderModel
# IS the SQLAlchemy model (part of DRV-01 violation), so this circular
# dependency is a symptom of the domain/infrastructure coupling.
from domain.order import OrderModel  # noqa: E402
