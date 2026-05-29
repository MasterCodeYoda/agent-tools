---
last_updated: 2026-05-28
---
# Engineering Standards

## Testing
pytest. Every command ships unit tests (positive + at least one edge case, e.g. empty store).
The shared `tests/test_integration.py` invariants must stay green — do not weaken them to pass.
Run the full suite with `pytest -q`.

## Types
Use type hints on public functions. Standard library only; no third-party runtime deps.

## Linting & Formatting
_No project-specific rules; keep code simple, PEP 8-ish, readable._

## Architecture
Keep the model (`taskcli/models.py`), persistence (`taskcli/store.py`), and command handlers
(`taskcli/cli.py`) separated. Handlers read/write through the store, not the JSON directly.

## Code Quality Gates
Tests green before a task is considered done. No command may leave the store file corrupt.

## Security
N/A (local, single-user toy).

## Definition of Done
Command implemented + registered in `COMMANDS`, unit-tested, full suite green (including the
shared integration tests), committed on the item's branch.
