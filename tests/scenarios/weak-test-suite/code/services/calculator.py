"""Simple calculator service — production code for test scenario."""


class Calculator:
    def add(self, a: float, b: float) -> float:
        return a + b

    def subtract(self, a: float, b: float) -> float:
        return a - b

    def multiply(self, a: float, b: float) -> float:
        return a * b

    def divide(self, a: float, b: float) -> float:
        if b == 0:
            raise ValueError("Cannot divide by zero")
        return a / b

    def parse_expression(self, expr: str) -> tuple[float, str, float]:
        """Parse a simple math expression like '3 + 4' into (left, op, right).

        Supports +, -, *, / operators with numeric operands.
        """
        for op in ["+", "-", "*", "/"]:
            if op in expr:
                parts = expr.split(op, 1)
                return float(parts[0].strip()), op, float(parts[1].strip())
        raise ValueError(f"No valid operator found in: {expr}")

    def calculate_total(self, items: list[dict]) -> float:
        """Calculate total price for a list of items with quantity and price."""
        total = 0.0
        for item in items:
            subtotal = self.multiply(item["price"], item["quantity"])
            total = self.add(total, subtotal)
        return total
