<!-- agent-tools:charter-link begin -->
## Project Charter

This project uses a structured charter at `.agent-tools/charter/`.

The charter captures durable project identity, engineering standards, and workflow conventions.
Shared ground truth when parallel mode or any session loads project conventions.

Files (load in order when needed; earlier take precedence on conflict):

1. [`.agent-tools/charter/charter.md`](.agent-tools/charter/charter.md) — entry + precedence + index
2. [`.agent-tools/charter/project.md`](.agent-tools/charter/project.md) — identity, stack, surfaces
3. [`.agent-tools/charter/engineering.md`](.agent-tools/charter/engineering.md) — standards, DoD
4. [`.agent-tools/charter/workflow.md`](.agent-tools/charter/workflow.md) — PM, branch, merge, review

**Loading policy:** Parallel mode and function dispatches **explicitly read** needed charter
files during orientation. Pure unit-mode `/work:*` sessions (including continue in unit mode)
do **not** auto-load the full charter set. Use textual references only — no `@` auto-import
of charter.
<!-- agent-tools:charter-link end -->

<!-- agent-tools:memory-link begin -->
## Project agent memory

This project keeps **shared agent working knowledge** under [`.agent-tools/memory/`](.agent-tools/memory/).

| Path | Contents |
|------|----------|
| [`MEMORY.md`](.agent-tools/memory/MEMORY.md) | Index of entries (and a pointer to solutions) |
| `entries/` | Patterns, gotchas, lessons, process invariants |
| `solutions/` | Debugging post-mortems by category |

**What it is:** portable, git-committed knowledge any harness should use — how we got burned, how to operate, reusable patterns.

**What it is not:** ADRs (`docs/decisions/`), CONTRIBUTING/gates, Codex/domain docs, planning scratch, or personify voice.

**Loading policy:** Read [`MEMORY.md`](.agent-tools/memory/MEMORY.md) when compounding, debugging, or hitting an unfamiliar seam; open individual entry/solution files on demand. Do **not** auto-import the entire tree every turn. Capture via `/work:compound`; steward (prune + yield + memory) via `/work:maintain`.
<!-- agent-tools:memory-link end -->
