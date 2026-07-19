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

**Owner:** `/workflow:setup` only (initialize and maintain). Full procedure with cases A–D,
preflight, dual-root repair, and refuse rules:

→ **`setup/references/planning-migration.md`**

Summary:

| Situation | Setup behavior |
|-----------|----------------|
| Preferred only | Hygiene only |
| Neither | Create preferred; never create legacy |
| Legacy only | **Migrate check** — propose move; require explicit yes; `git mv` when tracked |
| Both | **Dual-root repair** — user chooses finish-merge / conflict resolve / discard empty preferred / archive legacy |

**Hard refuse:** never create empty `.agent-tools/planning/` alongside a live `./planning/`
without migrating (that hides legacy work). Never delete a non-empty root without confirmation.

After successful migrate: only `.agent-tools/planning/` is live. Phase skills resolve preferred
first and do not move trees mid-loop.

## Git hygiene

Same rules as before, applied **inside the resolved root**:

- Root: ignore all except `.gitkeep`, `conventions.md`, `session-state.md` (top-level handoff),
  `roadmap.md`, `research-loop.md`, and intentional dialect exceptions.
- Per-item dirs: ignore all except `.gitkeep` (item work product is high-churn).

`/workflow:setup` authors hygiene under the **active** planning root after migration resolve.
