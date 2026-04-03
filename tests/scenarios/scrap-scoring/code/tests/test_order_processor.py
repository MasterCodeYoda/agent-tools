"""Test suite for OrderProcessor — PLANTED VIOLATIONS for SCRAP scoring scenario."""

import os
import tempfile
from unittest.mock import MagicMock, patch, PropertyMock

from services.order_processor import (
    LineItem, Order, OrderProcessor, OrderStatus, ValidationError,
)

processor = OrderProcessor()


def _make_item(product_id="P1", name="Widget", quantity=1, unit_price=10.0, discount=0.0):
    return LineItem(product_id=product_id, name=name, quantity=quantity,
                    unit_price=unit_price, discount_percent=discount)


def _make_order(order_id="ORD-1", customer_id="C-1", items=None):
    return Order(id=order_id, customer_id=customer_id,
                 items=items or [_make_item()])


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-01: Oversized test with excessive setup and multiple phases
# SCRAP smells: large-example, multiple-phases, low-assertion-density
# Expected SCRAP: ~25+ (poor)
# ---------------------------------------------------------------------------
def test_full_order_lifecycle():
    # Phase 1: Create and validate
    items = [
        _make_item("P1", "Widget A", 2, 25.0, 0),
        _make_item("P2", "Widget B", 3, 15.0, 10),
        _make_item("P3", "Widget C", 1, 100.0, 0),
        _make_item("P4", "Widget D", 5, 8.0, 5),
    ]
    order = Order(id="ORD-100", customer_id="C-42", items=items)
    errors = processor.validate_order(order)
    assert errors == []

    # Phase 2: Process
    processed = processor.process_order(order)
    assert processed.status == OrderStatus.PRICED

    # Phase 3: Apply discount and reprocess
    processor.apply_bulk_discount(processed, 3, 15.0)
    reprocessed = processor.process_order(processed)

    # Phase 4: Fulfill
    fulfilled = processor.fulfill_order(reprocessed)
    assert fulfilled.status == OrderStatus.FULFILLED

    # Phase 5: Format receipt
    receipt = processor.format_receipt(fulfilled)
    assert "ORD-100" in receipt
    assert "C-42" in receipt


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-02: Heavy mocking — 4 mocks in a single test
# SCRAP smells: high-mocking
# Expected SCRAP: ~15 (questionable)
# ---------------------------------------------------------------------------
def test_process_order_with_mocked_internals():
    order = _make_order(items=[_make_item(quantity=2, unit_price=50.0)])
    with patch.object(processor, "validate_order", return_value=[]):
        with patch.object(processor, "calculate_total", return_value=100.0):
            with patch.object(processor, "calculate_tax", return_value=8.0):
                with patch.object(processor, "calculate_shipping", return_value=0.0):
                    result = processor.process_order(order)
    assert result.total == 108.0


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-03: Test with branching logic (conditional assertions)
# SCRAP smells: branches in test
# Expected SCRAP: ~12 (normal-high)
# ---------------------------------------------------------------------------
def test_validation_covers_all_error_types():
    test_cases = [
        ([], True),
        ([_make_item(quantity=0)], False),
        ([_make_item(unit_price=-5)], False),
        ([_make_item(discount=150)], False),
    ]
    for items, should_be_valid in test_cases:
        order = _make_order(items=items if items else None)
        if not items:
            order.items = []
        errors = processor.validate_order(order)
        if should_be_valid:
            assert errors == [], f"Expected no errors but got: {errors}"
        else:
            assert len(errors) > 0, f"Expected errors for items: {items}"


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-04: Temp resource work — creates temp files in a unit test
# SCRAP smells: temp-resource-work
# Expected SCRAP: ~10 (normal)
# ---------------------------------------------------------------------------
def test_receipt_can_be_written_to_file():
    order = _make_order()
    processor.process_order(order)
    receipt = processor.format_receipt(order)
    with tempfile.NamedTemporaryFile(mode="w", suffix=".txt", delete=False) as f:
        f.write(receipt)
        temp_path = f.name
    try:
        with open(temp_path) as f:
            content = f.read()
        assert "ORD-1" in content
    finally:
        os.unlink(temp_path)


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-05: Literal-heavy setup — large inline data blob
# SCRAP smells: literal-heavy-setup
# Expected SCRAP: ~8 (normal)
# ---------------------------------------------------------------------------
def test_bulk_order_total():
    items = [
        LineItem("P1", "Alpha", 10, 5.99, 0),
        LineItem("P2", "Beta", 20, 3.49, 5),
        LineItem("P3", "Gamma", 15, 7.99, 10),
        LineItem("P4", "Delta", 8, 12.99, 0),
        LineItem("P5", "Epsilon", 25, 2.49, 15),
        LineItem("P6", "Zeta", 3, 45.99, 0),
        LineItem("P7", "Eta", 12, 8.49, 20),
        LineItem("P8", "Theta", 6, 19.99, 5),
        LineItem("P9", "Iota", 30, 1.99, 0),
        LineItem("P10", "Kappa", 4, 35.99, 10),
        LineItem("P11", "Lambda", 7, 14.99, 0),
        LineItem("P12", "Mu", 18, 4.99, 25),
    ]
    order = Order(id="ORD-BULK", customer_id="C-WHOLESALE", items=items)
    processed = processor.process_order(order)
    assert processed.total > 0


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-06: Helper-hidden complexity — helpers mask real setup cost
# SCRAP smells: helper-hidden-complexity
# Expected SCRAP: ~12 (normal-high)
# ---------------------------------------------------------------------------
def _build_complex_order_with_discounts():
    """Helper that hides 10+ lines of setup."""
    items = [
        _make_item("P1", "Premium Widget", 5, 50.0, 10),
        _make_item("P2", "Standard Widget", 10, 25.0, 5),
        _make_item("P3", "Budget Widget", 20, 10.0, 0),
    ]
    order = _make_order("ORD-COMPLEX", "C-VIP", items)
    processor.apply_bulk_discount(order, 10, 15.0)
    processor.validate_order(order)
    return order


def _process_and_format(order):
    """Another helper hiding the process-then-format dance."""
    processed = processor.process_order(order)
    receipt = processor.format_receipt(processed)
    return processed, receipt


def test_complex_order_formatting():
    order = _build_complex_order_with_discounts()
    processed, receipt = _process_and_format(order)
    assert "ORD-COMPLEX" in receipt


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-07: Duplication cluster — three structurally identical tests
# These should be a coverage-matrix candidate for table-driving
# ---------------------------------------------------------------------------
def test_shipping_free_for_100():
    order = _make_order(items=[_make_item(quantity=10, unit_price=10.0)])
    processed = processor.process_order(order)
    assert processed.shipping == 0.0


def test_shipping_free_for_200():
    order = _make_order(items=[_make_item(quantity=10, unit_price=20.0)])
    processed = processor.process_order(order)
    assert processed.shipping == 0.0


def test_shipping_free_for_500():
    order = _make_order(items=[_make_item(quantity=10, unit_price=50.0)])
    processed = processor.process_order(order)
    assert processed.shipping == 0.0


# ---------------------------------------------------------------------------
# VIOLATION SCRAP-08: Duplication cluster — harmful (repeated complex setup)
# Three tests with identical multi-step setup scaffolding that should be
# extracted into a shared fixture
# ---------------------------------------------------------------------------
def test_fulfilled_order_has_correct_total():
    items = [_make_item("P1", "A", 2, 30.0), _make_item("P2", "B", 1, 50.0)]
    order = Order(id="ORD-F1", customer_id="C-1", items=items)
    processor.validate_order(order)
    processed = processor.process_order(order)
    fulfilled = processor.fulfill_order(processed)
    assert fulfilled.total > 0


def test_fulfilled_order_has_correct_status():
    items = [_make_item("P1", "A", 2, 30.0), _make_item("P2", "B", 1, 50.0)]
    order = Order(id="ORD-F2", customer_id="C-1", items=items)
    processor.validate_order(order)
    processed = processor.process_order(order)
    fulfilled = processor.fulfill_order(processed)
    assert fulfilled.status == OrderStatus.FULFILLED


def test_fulfilled_order_receipt_contains_id():
    items = [_make_item("P1", "A", 2, 30.0), _make_item("P2", "B", 1, 50.0)]
    order = Order(id="ORD-F3", customer_id="C-1", items=items)
    processor.validate_order(order)
    processed = processor.process_order(order)
    fulfilled = processor.fulfill_order(processed)
    receipt = processor.format_receipt(fulfilled)
    assert "ORD-F3" in receipt


# ---------------------------------------------------------------------------
# GOOD TESTS — included as positive observation baselines
# ---------------------------------------------------------------------------
def test_empty_order_fails_validation():
    order = Order(id="ORD-E", customer_id="C-1", items=[])
    errors = processor.validate_order(order)
    assert "at least one item" in errors[0]


def test_tax_calculation():
    assert processor.calculate_tax(100.0) == 8.0


def test_shipping_below_threshold():
    assert processor.calculate_shipping(50.0) == 9.99


def test_cancel_fulfilled_order_raises():
    import pytest
    order = _make_order()
    order.status = OrderStatus.FULFILLED
    with pytest.raises(ValidationError, match="Cannot cancel"):
        processor.cancel_order(order)
