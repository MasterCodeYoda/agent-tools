"""Test suite for Calculator — PLANTED VIOLATIONS for evolve scenario testing."""

from unittest.mock import patch

from services.calculator import Calculator


calc = Calculator()


# VIOLATION WTS-01: Assertion-free test — runs code but never checks result
def test_division_runs():
    result = calc.divide(10, 2)
    # No assertion! This test passes even if divide returns garbage.
    # It only fails on an unhandled exception.


# VIOLATION WTS-02: Weak assertion — only checks truthiness
def test_multiply_returns_something():
    result = calc.multiply(3, 4)
    assert result  # Only fails if result is 0, None, False, or empty
    # calc.multiply(3, 4) returning 999 would still pass


# VIOLATION WTS-03: Tautological assertion — mirrors production logic
def test_add_tautological():
    a, b = 5, 3
    result = calc.add(a, b)
    assert result == a + b  # If add() is broken, this is broken the same way


# VIOLATION WTS-04: Computed expected value
def test_subtract_computed():
    result = calc.subtract(10, 3)
    assert result == 10 - 3  # Should be: assert result == 7


# VIOLATION WTS-05: Mocking an internal collaborator
def test_calculate_total_mocks_internals():
    items = [{"price": 10.0, "quantity": 2}, {"price": 5.0, "quantity": 3}]
    with patch.object(calc, "multiply", return_value=20.0):
        # Mocking multiply — an internal method of the same class
        # This test is coupled to implementation details, not behavior
        result = calc.calculate_total(items)
    assert result == 40.0  # 20.0 + 20.0 from mocked multiply


# VIOLATION WTS-06: Multiple behaviors in one test
def test_all_operations():
    assert calc.add(2, 3) == 5
    assert calc.subtract(10, 4) == 6
    assert calc.multiply(3, 7) == 21
    assert calc.divide(15, 3) == 5.0
    # Which operation broke? Test name doesn't help either.


# VIOLATION WTS-07: Testing a static guarantee
def test_calculator_has_add_method():
    assert hasattr(calc, "add")
    # The type system already guarantees this. If add() didn't exist,
    # every other test would fail at import time.


# VIOLATION WTS-08: Wrong strategy — parser tested with examples only
# parse_expression is a data transformation / parser that should use
# property-based testing to cover edge cases (negative numbers, whitespace,
# operator ambiguity). Example-based tests miss the input space.
def test_parse_addition():
    left, op, right = calc.parse_expression("3 + 4")
    assert left == 3.0
    assert op == "+"
    assert right == 4.0


def test_parse_subtraction():
    left, op, right = calc.parse_expression("10 - 2")
    assert left == 10.0
    assert op == "-"
    assert right == 2.0


# GOOD TEST — included as a positive observation baseline
def test_divide_by_zero_raises():
    import pytest

    with pytest.raises(ValueError, match="Cannot divide by zero"):
        calc.divide(10, 0)


# GOOD TEST — clear, specific, literal expected value
def test_add_simple():
    assert calc.add(2, 3) == 5
