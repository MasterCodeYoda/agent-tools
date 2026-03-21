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

    def calculate_total(self, items: list[dict]) -> float:
        """Calculate total price for a list of items with quantity and price."""
        total = 0.0
        for item in items:
            subtotal = self.multiply(item["price"], item["quantity"])
            total = self.add(total, subtotal)
        return total
