"""Order processing service — PLANTED VIOLATIONS for evolve scenario testing."""

from decimal import Decimal


# VIOLATION DQV-03: Docstring documents only 2 of 4 parameters
# Missing: priority, callback
def process_order(
    order_id: str,
    items: list[dict],
    priority: int = 0,
    callback: callable = None,
) -> dict:
    """Process an order and return the result.

    Args:
        order_id: The unique order identifier.
        items: List of item dictionaries with 'name', 'price', 'qty' keys.

    Returns:
        dict: Processing result with 'status' and 'total' keys.
    """
    # VIOLATION DQV-06: Raises ValueError and ConnectionError
    # but neither is documented in the docstring
    if not order_id:
        raise ValueError("order_id is required")

    if not items:
        raise ValueError("At least one item is required")

    total = Decimal("0")
    for item in items:
        price = Decimal(str(item["price"]))
        qty = item["qty"]
        total += price * qty

    if priority > 5:
        raise ConnectionError("Priority queue service unavailable")

    result = {"status": "processed", "total": float(total), "order_id": order_id}

    if callback:
        callback(result)

    return result


# VIOLATION DQV-05: Docstring documents 'weight' parameter that doesn't exist.
# Actual parameter is 'dimensions'.
def calculate_shipping(
    destination: str,
    dimensions: dict,
) -> Decimal:
    """Calculate shipping cost for an order.

    Args:
        destination: The shipping destination address.
        weight: The package weight in kilograms.

    Returns:
        Decimal: The calculated shipping cost.
    """
    base_cost = Decimal("5.99")
    volume = dimensions.get("length", 1) * dimensions.get("width", 1) * dimensions.get("height", 1)

    if volume > 1000:
        base_cost += Decimal("10.00")

    return base_cost


# GOOD: Properly documented function for comparison
def format_receipt(order_id: str, items: list[dict], total: Decimal) -> str:
    """Format a receipt for display or printing.

    Args:
        order_id: The unique order identifier.
        items: List of item dictionaries with 'name', 'price', 'qty' keys.
        total: The order total.

    Returns:
        str: Formatted receipt as a multi-line string.

    Example:
        >>> format_receipt("ORD-123", [{"name": "Widget", "price": 9.99, "qty": 2}], Decimal("19.98"))
        'Order ORD-123\\n  Widget x2 - $9.99\\nTotal: $19.98'
    """
    lines = [f"Order {order_id}"]
    for item in items:
        lines.append(f"  {item['name']} x{item['qty']} - ${item['price']}")
    lines.append(f"Total: ${total}")
    return "\n".join(lines)
