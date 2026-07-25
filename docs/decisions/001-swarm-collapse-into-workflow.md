# Parallel orchestration is a workflow continue mode — not a top-level family

## Decision

Multi-item parallel orchestration (formerly the **`/swarm` skill family**) is **collapsed
into** the `/workflow` control plane as a **drive mode** of `/workflow:continue`. There is
**no** top-level `/swarm`, `/swarm:continue`, or `/swarm:setup` surface.

Charter authoring and parallel-mode project scaffolding (config, role templates, umbrella
gitignore, AGENTS charter-link) are owned by **`/workflow:setup` only**. No second setup
command is invented or retained.

The metaphor **plant** is removed from process language and claim dialects. Prefer *process*,
*planning root*, *runs*, *disk*, *scaffolding*.

Family rename of `workflow` (e.g. away from Grok’s reserved `/workflow`) is **deferred** until
after this collapse lands.

## Rationale

1. **Operator intent frequency.** Real slash invocations in high-traffic projects
   (Spectral, Wildwood, ZzzAPI) are overwhelmingly `/workflow:continue`. Explicit `/swarm*`
   is rare; ZzzAPI never ran a swarm session despite setup. Top-level slash surface should
   track how work is entered, not how complex the optional batch path is.

2. **Architecture already said so.** Portfolio routing treated swarm as auto-handoff from
   continue on explicit `∥` / `{wave}` groups, with resume via active-run. A second family
   duplicated the entry story and forced a false “sibling brand” for naming.

3. **Capability ≠ product surface.** Multi-item waves shipped real work (Wildwood/Spectral
   session history). That machinery stays as load-on-demand procedure under continue’s
   **parallel** mode. Deleting the brand deletes the competing UX, not the engine.

4. **One setup.** Charter + planning + memory + runs + parallel config belong in one
   idempotent initializer (`/workflow:setup`). A split `/swarm:setup` trained operators to
   think parallel was optional product install rather than optional mode readiness.

5. **Plant.** The metaphor required onboarding, collided with claim tags (`plant:claim`), and
   added no precision over *process* / *planning root* / *runs*.

## Alternatives considered

| Alternative | Why rejected |
|-------------|--------------|
| Keep `/swarm` as rare override + document `/user:…` disambiguation | Leaves a second lifestyle entry that operators do not use; keeps naming dualism. |
| Deprecate `/swarm` with long alias period | User requirement: **delete**, not deprecate. Functionality survives only via collapse. |
| Delete parallel orchestration entirely | Session/ledger history shows multi-item waves delivered real merges; capability stays. |
| Rename workflow before collapse | Doubles blast radius; rename deferred until one control plane is settled. |
| Keep `plant:` claim synonyms | Contradicts full plant purge; `workflow:claim` is enough. |
| New setup command for charter-only | Invents surface; charter folds into existing `/workflow:setup`. |

## Current shape (in force)

| Concern | Home |
|---------|------|
| Portfolio status | bare `/workflow` → `references/status.md` (includes active parallel run summary) |
| Drive | `/workflow:continue` → portfolio router |
| Unit mode | phase state machine (default daily path) |
| Parallel mode | `workflow/parallel/` procedures; entered by active-run resume, explicit `∥`/`{wave}` handoff, or multi-item continue args — **not** a slash family |
| Setup | `/workflow:setup` — planning, conventions, memory, runs, **charter**, parallel config/roles |
| On-disk parallel state | **`.agent-tools/parallel/`** (config, roles, sessions, active-run). Former `.agent-tools/swarm/` is obsolete; setup renames if found |
| Process IP tests | `tests/swarm/` harness may keep directory name short-term; not a user `/swarm` command |
| Family name `workflow` | unchanged until a later decision |

## Rejected forever

- Top-level `/swarm*` operator commands in published skills
- “Plant” as process metaphor or claim dialect (`plant:claim`, “steward the plant”, etc.)
- Framing parallel mode as a thematic sibling product that needs its own brand
