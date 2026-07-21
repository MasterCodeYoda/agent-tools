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

**Loading policy:** Read [`MEMORY.md`](.agent-tools/memory/MEMORY.md) when compounding, debugging, or hitting an unfamiliar seam; open individual entry/solution files on demand. Do **not** auto-import the entire tree every turn. Capture via `/workflow:compound`; steward (yield + memory hygiene) via `/workflow:maintain`.
<!-- agent-tools:memory-link end -->
