# greeter Backlog

Local backlog (file mode). This scenario has **no seeded charter** — run `/swarm:init` first;
it authors the charter from the detected stack, then `/swarm backlog.md` runs the orchestrator.

Commands auto-discover from `greeter/commands/` (each module exposes `NAME` + `run(argv)`), so
the two items below touch different files and run as a clean parallel wave.

---

## GI-1 — `hello` command

**Status:** refined

**Acceptance criteria:**
- New module `greeter/commands/hello.py` with `NAME = "hello"` and `run(argv)` that prints a
  greeting and exits 0.
- Unit test covering `hello`.

**Dependencies:**
- blocks: []
- blocked_by: []
- parallelizable_with: [GI-2]

---

## GI-2 — `bye` command

**Status:** refined

**Acceptance criteria:**
- New module `greeter/commands/bye.py` with `NAME = "bye"` and `run(argv)` that prints a
  farewell and exits 0.
- Unit test covering `bye`.

**Dependencies:**
- blocks: []
- blocked_by: []
- parallelizable_with: [GI-1]
