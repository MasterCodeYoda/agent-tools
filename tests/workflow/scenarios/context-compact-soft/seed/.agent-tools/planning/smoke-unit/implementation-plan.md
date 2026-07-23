---
project: smoke-unit
work_item: null
blocks: []
blocked_by: []
parallelizable_with: []
---

# Implementation Plan: Smoke counter clamp

Toy unit for workflow harness only.

## Approach

Extend `src/counter.py` with a clamp helper and a trivial CLI flag. No real product domain.

## Structure outline

| Phase | What lands | Verify |
|-------|------------|--------|
| 1 | `increment` happy path | `python -m src.counter` prints 3 |
| 2 | `clamp(value, lo, hi)` | unit assert |
| 3 | `--start` CLI flag | manual run |
| 4 | tests for clamp | pytest or assert script |

## Breakdown

- [x] Task 1 — `increment` non-negative step (seed baseline)
- [ ] Task 2 — add `clamp(value, lo, hi)` raising on lo > hi
- [ ] Task 3 — wire optional start value in `main`
- [ ] Task 4 — add a small test module for clamp

## Out of scope

Anything outside this toy counter.
