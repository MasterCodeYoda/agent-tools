# taskcli (scenario seed)

A tiny CLI task manager built incrementally by the `cli-task-manager` swarm scenario. The
seed ships a command registry (`taskcli/cli.py`), a `version` command, and shared integration
tests (`tests/test_integration.py`). The backlog fills in the rest.

## Engineered surfaces (why this seed is shaped the way it is)

- **Shared command registry** — both the `add`/`list` item and the `complete`/`delete` item
  register handlers in the same `COMMANDS` dict in `taskcli/cli.py`, at the same insertion
  point. Built in parallel, they collide at merge → exercises the **conflict-resolver**.
- **Empty-store invariant** — `tests/test_integration.py::test_readonly_commands_on_empty_store`
  requires read-only commands to exit 0 on a fresh, empty store. A `stats` command computing
  *percentage completed* trips divide-by-zero on an empty store: its own unit tests (with
  sample tasks) pass, but this shared test breaks post-merge → exercises the
  **integration-fixer**.

These are *likely*, not guaranteed — real workers write the code. The scenario tunes from
observed dogfood runs.
