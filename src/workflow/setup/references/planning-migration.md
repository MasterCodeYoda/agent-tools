# Planning root migration (`./planning/` → `.agent-tools/planning/`)

**Load when:** `/workflow:setup` (initialize or maintain) detects a planning-root situation
that is not already “preferred root only.” Full resolution rules: @workflow
`references/planning-root.md`.

This is a **setup-owned** migration. Continue and phase skills only *resolve* the active root;
they do not move trees mid-loop.

## Detect (always run early in setup)

Compute:

| Flag | Condition |
|------|-----------|
| `legacy` | `./planning/` exists as a directory |
| `preferred` | `.agent-tools/planning/` exists as a directory |
| `legacy_nonempty` | legacy has any file other than optional empty scaffolding |
| `preferred_nonempty` | preferred has any real content |

Classify case:

| Case | Meaning | Action |
|------|---------|--------|
| **A** | preferred only | No migrate. Ensure hygiene (§3.5). |
| **B** | neither | Create preferred empty hygiene; do not create legacy. |
| **C** | legacy only | **Migrate check** (below) — propose move to preferred. |
| **D** | both exist | **Dual-root repair** (below) — prefer preferred; reconcile or remove legacy. |

Report the case and a one-line inventory (top-level names under each root) **before** any move.

## Case C — legacy only (standard migration)

### C1. Preflight (read-only)

1. List top-level of `./planning/` (conventions, roadmap, item dirs, gitignores).
2. Note anything that looks like an **active** unit: `session-state.md` with
   `status: in_progress` or a live branch recorded.
3. Check git: is `planning/` tracked, ignored, or mixed? (Directory-local gitignore is normal.)
4. If worktrees exist with paths into `./planning/`, list them — migration may need path updates
   in session-state `worktree:` is unrelated; planning paths inside docs are string references.

### C2. Propose (user confirmation required)

Present:

```markdown
### Planning root migration

Detected legacy `./planning/` only. Preferred home is `.agent-tools/planning/`.

**Plan:**
1. `mkdir -p .agent-tools`
2. Move tree: `./planning` → `.agent-tools/planning` (prefer `git mv` when tracked)
3. Ensure root `.gitignore` + per-item hygiene under the new root
4. Grep repo for hard-coded `./planning/` in committed docs (AGENTS, CONTRIBUTING, README) —
   propose path updates (user approves each or batch)
5. Leave no second live root

**Active units:** [none | list]
**Proceed?** [y/n]
```

Do **not** migrate on silence or “continue the other work.” Require explicit yes.

### C3. Apply (after yes)

```text
1. mkdir -p .agent-tools
2. If .agent-tools/planning already exists → abort to Case D logic (should not happen in C)
3. Move:
   - git: git mv planning .agent-tools/planning   # when planning is tracked
   - else: mv planning .agent-tools/planning
4. Ensure .agent-tools/planning/.gitignore has canonical exceptions (setup §3.5)
5. For each item subdir: ensure .gitkeep + per-item .gitignore
6. Grep (committed files only) for:
   - `./planning/`
   - `` `planning/ `` in docs that mean repo-root planning
   Propose patches for AGENTS.md / CONTRIBUTING / README / docs that hard-code the old path.
   Do not bulk-rewrite gitignored planning item bodies unless user asks.
7. Soft-check session-state files under the new root for absolute paths to old planning/ —
   fix if found
8. Verify: preferred exists; legacy path gone
9. Report: "Planning root is now .agent-tools/planning/"
```

### C4. Decline (user says no)

- Record in the setup report: migration deferred; resolution remains legacy until next setup.
- Continue rest of setup (memory, runs, conventions) using **legacy** as planning root.
- Do not create an empty preferred root alongside (would flip resolution to empty preferred and
  hide live work — **forbidden**).

## Case D — both roots exist

**Danger:** resolution prefers preferred; legacy content may be invisible to continue.

### D1. Inventory both

Compare top-level names. Detect:

- Same logical files in both (conventions/roadmap) → content conflict risk  
- Active units only under legacy → **legacy has the live plant**  
- Preferred empty or only scaffolding → treat as incomplete migrate  

### D2. Repair options (user picks one)

1. **Finish migrate (legacy → preferred)** — if preferred is empty/scaffold-only: merge by moving
   legacy children into preferred (no overwrite of non-empty preferred files without confirm);
   then remove empty legacy.
2. **Merge with conflict list** — when both have real content: list conflicting paths; user
   chooses winner per path; then remove or archive the other.
3. **Discard empty preferred** — if preferred is empty and legacy is live: `rmdir` preferred
   scaffolding so resolution returns to legacy, then optionally run Case C migrate cleanly.
4. **Archive legacy** — if preferred is authoritative: move `./planning` →
   `./planning-legacy-archive-<date>/` or delete after user confirms nothing unique remains.

Never silently delete a non-empty root.

### D3. After repair

Exactly one live root. Preferred if migrated; legacy only if user explicitly deferred and
preferred was removed.

## Case B — neither

Create `.agent-tools/planning/` with `.gitkeep` + root `.gitignore` only. Do not create
`./planning/`.

## Git notes

- Prefer `git mv` so history follows when files were tracked.
- Many item files are gitignored — `mv` still moves them on disk; that is intended.
- If root `.gitignore` has a `planning/` exception line from old setups, note it; hygiene is
  directory-local under the planning root, so root exceptions are optional cleanup (user
  approve).

## Post-migration smoke (setup reports)

- [ ] `test -d .agent-tools/planning`  
- [ ] `test ! -d ./planning` (or archive path only)  
- [ ] conventions/roadmap paths resolve under preferred when present  
- [ ] continue orientation will resolve preferred first  

## What migration does not do

- Does not rewrite every skill string in the corpus (skills use “planning root” resolution)
- Does not migrate `docs/solutions/` (compound maintain)
- Does not move `.agent-tools/memory` or swarm state
- Does not invent conventions content
