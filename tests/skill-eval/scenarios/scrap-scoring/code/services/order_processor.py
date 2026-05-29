"""Order processing service — production code for SCRAP scoring scenario."""

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


class OrderStatus(Enum):
    PENDING = "pending"
    VALIDATED = "validated"
    PRICED = "priced"
    FULFILLED = "fulfilled"
    CANCELLED = "cancelled"


@dataclass
class LineItem:
    product_id: str
    name: str
    quantity: int
    unit_price: float
    discount_percent: float = 0.0

    @property
    def subtotal(self) -> float:
        base = self.quantity * self.unit_price
        return base * (1 - self.discount_percent / 100)


@dataclass
class Order:
    id: str
    customer_id: str
    items: list[LineItem] = field(default_factory=list)
    status: OrderStatus = OrderStatus.PENDING
    total: float = 0.0
    tax: float = 0.0
    shipping: float = 0.0
    notes: Optional[str] = None


class ValidationError(Exception):
    pass


class OrderProcessor:
    def __init__(self, tax_rate: float = 0.08, free_shipping_threshold: float = 100.0):
        self.tax_rate = tax_rate
        self.free_shipping_threshold = free_shipping_threshold
        self.base_shipping = 9.99

    def validate_order(self, order: Order) -> list[str]:
        errors = []
        if not order.items:
            errors.append("Order must have at least one item")
        for item in order.items:
            if item.quantity <= 0:
                errors.append(f"Invalid quantity for {item.name}: {item.quantity}")
            if item.unit_price < 0:
                errors.append(f"Invalid price for {item.name}: {item.unit_price}")
            if item.discount_percent < 0 or item.discount_percent > 100:
                errors.append(f"Invalid discount for {item.name}: {item.discount_percent}")
        return errors

    def calculate_total(self, order: Order) -> float:
        subtotal = sum(item.subtotal for item in order.items)
        return subtotal

    def calculate_tax(self, subtotal: float) -> float:
        return round(subtotal * self.tax_rate, 2)

    def calculate_shipping(self, subtotal: float) -> float:
        if subtotal >= self.free_shipping_threshold:
            return 0.0
        return self.base_shipping

    def process_order(self, order: Order) -> Order:
        errors = self.validate_order(order)
        if errors:
            raise ValidationError("; ".join(errors))

        order.status = OrderStatus.VALIDATED
        subtotal = self.calculate_total(order)
        order.tax = self.calculate_tax(subtotal)
        order.shipping = self.calculate_shipping(subtotal)
        order.total = subtotal + order.tax + order.shipping
        order.status = OrderStatus.PRICED
        return order

    def fulfill_order(self, order: Order) -> Order:
        if order.status != OrderStatus.PRICED:
            raise ValidationError(f"Cannot fulfill order in status: {order.status.value}")
        order.status = OrderStatus.FULFILLED
        return order

    def cancel_order(self, order: Order) -> Order:
        if order.status == OrderStatus.FULFILLED:
            raise ValidationError("Cannot cancel a fulfilled order")
        order.status = OrderStatus.CANCELLED
        return order

    def apply_bulk_discount(self, order: Order, threshold: int, discount: float) -> Order:
        for item in order.items:
            if item.quantity >= threshold:
                item.discount_percent = discount
        return order

    def format_receipt(self, order: Order) -> str:
        lines = [f"Order: {order.id}", f"Customer: {order.customer_id}", ""]
        for item in order.items:
            lines.append(f"  {item.name} x{item.quantity} @ ${item.unit_price:.2f} = ${item.subtotal:.2f}")
        lines.append("")
        lines.append(f"  Subtotal: ${sum(i.subtotal for i in order.items):.2f}")
        lines.append(f"  Tax: ${order.tax:.2f}")
        lines.append(f"  Shipping: ${order.shipping:.2f}")
        lines.append(f"  Total: ${order.total:.2f}")
        return "\n".join(lines)
