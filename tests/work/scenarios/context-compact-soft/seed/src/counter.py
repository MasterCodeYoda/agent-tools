"""Minimal counter — enough surface for a fake mid-phase execute unit."""

from __future__ import annotations


def increment(value: int, step: int = 1) -> int:
    if step < 0:
        raise ValueError("step must be non-negative")
    return value + step


def main() -> None:
    n = 0
    for _ in range(3):
        n = increment(n)
    print(n)


if __name__ == "__main__":
    main()
