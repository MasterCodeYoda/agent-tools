# Planning root and path resolution

**Load when:** any `/workflow:*` phase reads or writes planning artifacts, conventions,
session-state, or roadmaps.

## Planning root (canonical)

| Priority | Path | When |
|----------|------|------|
| **1** | `.agent-tools/planning/` | Directory exists (preferred home) |
| **2** | `./planning/` | Legacy / not yet migrated |

**Resolution:** use the highest-priority path that **exists as a directory**. If neither
exists, **create** `.agent-tools/planning/` (via `/workflow:setup` or first phase that needs
a shell). Do **not** create both.

**Shorthand in skills:** bare `planning/` means **relative to the resolved planning root**
unless an absolute or repo-root path is explicit. Examples:

- `planning/conventions.md` → `<root>/conventions.md`
- `planning/<slug>/session-state.md` → `<root>/<slug>/session-state.md`
- `planning/roadmap.md` → `<root>/roadmap.md`

## Related durable homes (not under planning root)

| Path | Role |
|------|------|
| `.agent-tools/memory/` | L3 shared agent knowledge |
| `.agent-tools/runs/` | Run event spine + closed-run ledger (see `runs-ledger.md`) |
| `.agent-tools/charter/`, `.agent-tools/swarm/` | Swarm setup |

## Migration (legacy `./planning/`)

When maintaining setup and only `./planning/` exists:

1. Report legacy location.
2. Offer move to `.agent-tools/planning/` (user confirms).
3. Move contents; keep a one-line note in the session if useful.
4. Do not leave two live roots. After move, only `.agent-tools/planning/` is active.

Compatibility during a single horizon: if both exist, **prefer `.agent-tools/planning/`** and
warn once that `./planning/` is ignored until removed.

## Git hygiene

Same rules as before, applied **inside the resolved root**:

- Root: ignore all except `.gitkeep`, `conventions.md`, `session-state.md` (top-level handoff),
  `roadmap.md`, and intentional dialect exceptions.
- Per-item dirs: ignore all except `.gitkeep` (item work product is high-churn).

`/workflow:setup` authors hygiene under the **preferred** root (`.agent-tools/planning/`).
