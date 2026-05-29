# taskcli Backlog

Local backlog (file mode) for the `/swarm` orchestrator. Items carry dependency metadata so
the scheduler can build parallel waves. `taskcli/cli.py` already has a `COMMANDS` registry and
a `version` command; `tests/test_integration.py` has shared invariants every item keeps green.

---

## CTM-1 — Core model + store

**Status:** refined

Build the foundation the commands depend on.

**Acceptance criteria:**
- `taskcli/models.py` defines a `Task` (title: str, done: bool).
- `taskcli/store.py` loads/saves a list of tasks to a JSON store path; loading a missing or
  empty store yields an empty list (no error).
- Unit tests cover load/save round-trip and the empty/missing-store case.

**Dependencies:**
- blocks: [CTM-2, CTM-3, CTM-4, CTM-5]
- blocked_by: []
- parallelizable_with: []

---

## CTM-2 — `add` and `list` commands

**Status:** refined

**Acceptance criteria:**
- `add "<title>"` appends an open task to the store; exits 0.
- `list` prints all tasks (open + done); exits 0 on an empty store.
- Both commands register in `taskcli/cli.py`'s `COMMANDS` dict.
- Unit tests for add + list, including `list` on an empty store.

**Dependencies:**
- blocks: [CTM-5]
- blocked_by: [CTM-1]
- parallelizable_with: [CTM-4]
  # NOTE: CTM-2 and CTM-3 both edit the COMMANDS registry in cli.py — deliberately NOT
  # declared parallelizable with each other, so they land in one wave and collide at merge.

---

## CTM-3 — `complete` and `delete` commands

**Status:** refined

**Acceptance criteria:**
- `complete <index>` marks the task at that index done; exits 0.
- `delete <index>` removes the task at that index; exits 0.
- Both commands register in `taskcli/cli.py`'s `COMMANDS` dict.
- Out-of-range index is handled gracefully (nonzero exit, no crash, store intact).
- Unit tests for complete + delete + out-of-range.

**Dependencies:**
- blocks: []
- blocked_by: [CTM-1]
- parallelizable_with: [CTM-4]

---

## CTM-4 — search

**Status:** unrefined

We want users to be able to find tasks. Make search work.

_(Deliberately vague — the orchestrator should run host-side `/workflow:refine` to turn this
into concrete acceptance criteria before planning it.)_

**Dependencies:**
- blocks: []
- blocked_by: [CTM-1]
- parallelizable_with: [CTM-2, CTM-3]

---

## CTM-5 — `stats` command

**Status:** refined

**Acceptance criteria:**
- `stats` prints the total task count and the **percentage of tasks completed**; exits 0.
- Registers in `taskcli/cli.py`'s `COMMANDS` dict.
- Unit tests cover stats with a mix of open/done tasks.

**Dependencies:**
- blocks: []
- blocked_by: [CTM-1, CTM-2]
- parallelizable_with: []
  # NOTE: "percentage completed" on an empty store is a divide-by-zero edge case. The shared
  # integration test requires read-only commands to exit 0 on an empty store, so a naive
  # implementation passes its own unit tests but breaks the integration test post-merge.
