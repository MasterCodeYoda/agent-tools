---
last_updated: 2026-05-28
---
# Project: taskcli

## Identity
A tiny command-line task manager. Tasks have a title and a status (open/done) and persist to
a JSON store file. Single-user, local, no network.

## Stack
Python ≥ 3.10, standard library only. Tests with pytest. Packaged as the `taskcli` package
with a `COMMANDS` registry + dispatcher in `taskcli/cli.py`.

## Surfaces
A single CLI: `taskcli <command> [args]`. Commands register in `taskcli/cli.py`'s `COMMANDS`
dict; each is a handler `(argv, store_path) -> int`.

## Domain Vocabulary
- **Task**: title + status (`open` | `done`), persisted in the JSON store.
- **Store**: the JSON file (default `tasks.json`) holding all tasks.

## Stakeholders
Solo developer / the swarm harness.

## Out of Scope
Networking, multi-user, due dates, priorities, subtasks. Keep it minimal.
