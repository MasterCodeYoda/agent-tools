---
name: workflow:roadmap
description: Chart or resequence a multi-unit work horizon — destination, thin claimable streams, order, and NEXT — user-approved map for continue to consume
argument-hint: "[optional: initiative/goal text, 'update', 'resequence', or path to existing roadmap]"
user-invocable: true
---

# Horizon Roadmap (`/workflow:roadmap`)

Chart a **multi-unit** body of work: name the destination, list **claimable** streams (or order
existing units), set dependencies/parallelization, and leave a consumable **NEXT** pointer for
`/workflow:continue`.

**Plan, don't do.** This skill produces a map and order — not ACs, tasks, or code.

**Shared invariant:** no durable stream list or committed NEXT without an **explicit user
approval turn**. Draft; user approves before write.

## User Input

```text
$ARGUMENTS
```

| Input | Meaning |
|-------|---------|
| Empty / goal text | Chart a new map or open an existing one for update |
| `update` / `resequence` | Load existing map; revise order/streams with approval |
| Path to roadmap / workstream dir | Target that artifact |

## When to use

- Multiple independently claimable units; order or decomposition is unclear.
- Cold-start / path-not-established from `/workflow:continue`.
- Resequence after reality changed.

**Not this skill**

- Single fuzzy concept → `/workflow:brainstorm`
- Exact requirements for one unit → `/workflow:refine`
- Task breakdown → `/workflow:plan`
- Driving the loop → `/workflow:continue`

### Bail if single unit

If charting shows **one** claimable unit and no multi-stream structure, **stop without writing a
map**. Offer `/workflow:brainstorm` or `/workflow:refine` instead.

A claimable unit is something continue can pick: a stable slug/name, a `planning/<item>/` path
(optional at claim time), a PM issue id, or an explicit stub the user accepts as next work —
**not** a phase of one story and not an AC list. **Missing planning dir does not make a named
stream unclaimable** — continue claims it and enters refine/plan, which create the shell.

## Modes

Pick early (state it to the user):

| Mode | When | Focus |
|------|------|--------|
| **Decompose** | Few/no claimable units yet | Destination + thin streams that will become units |
| **Sequence** | Units already exist (PM, planned session-states, workstreams) | Order only (`→` / `∥`); do **not** invent a new destination if SoT already has one |

## Dialects (layout)

**Default (no conventions):** `planning/roadmap.md` (sequence-overlay / single-file map).

**Honor existing:** if `planning/initiatives/` + `planning/workstreams/` already exist, update
those instead of inventing a second SoT. Do not create hybrid sprawl for new projects unless the
user asks.

`planning/conventions.md` may name the dialect; absent → default file.

## Protocol

1. **Destination.** One or two lines: what "this horizon is done" looks like. (Decompose always;
   Sequence only if missing.)
2. **Breadth-first frontier.** List streams or existing units — don't deep-dive one thread.
   Don't invent fake streams you can't claim later.
3. **Order & deps.** Use the formal notation below. Note blockers and collision watches.
4. **Out of scope** for this horizon.
5. **NEXT.** One resolvable unit, an explicit **wave package** (`{A ∥ B}`), or **map-only** /
   sequencing-choice prose. Named NEXT without a planning shell is still consumable. Continue
   auto-handoffs to swarm only for **explicit** `∥` / `{wave}` groups at the active head —
   never invents a wave from ungrouped peers.
6. **Present draft → user approves → then write.** Never write durable map before approval.
7. **Stop.** Do not refine or implement.

### HITL checklist (confirm before write)

- [ ] Destination  
- [ ] Stream/unit list (thin)  
- [ ] Order / parallelization  
- [ ] Out of scope  
- [ ] NEXT (or map-only)  
- [ ] Explicit user approve  

## Default artifact (`planning/roadmap.md`)

```markdown
# Roadmap: [horizon title]

Status: Active
Updated: [date]

## Destination

[One or two lines — what done looks like]

## Streams / order

Notation: `→` sequential · `∥` (or `||`) parallelizable · `{A ∥ B}` wave · `⚠ A ∥ B` collision watch

1. [claimable unit or stream name] — [one-line purpose]
2. …

Example order line: `Wave 0 → Wave 1 → (Wave 2 ∥ Wave 3) → Wave 4`

## NEXT

[resolvable unit | `{A ∥ B}` wave package | `map-only` | user sequencing choice — list options]

## Out of scope

- [ruled out for this horizon]

## Notes

[optional: depends-on, ⚠ collision watches, links to initiatives/workstreams]
```

### Notation (formal — continue consumes this)

| Token | Meaning | Continue behavior |
|-------|---------|-------------------|
| `→` | Hard sequential dependency | Right side not claimable until left done |
| `∥` or `||` | Parallelizable independent peers | At active head with ≥2 claimable peers → **auto-handoff swarm** when swarm is ready |
| `{A ∥ B}` | Named wave package | Preferred form for a swarm goal list |
| `⚠ A ∥ B` | Soft collision (same layer / watch) | **Not** auto-launch; prefer sequential or caution |
| `map-only` / sequencing choice | No single resolvable NEXT | hard-stop / surface choice — do not invent |

ASCII `||` is an accepted fallback for `∥` (U+2225). Informal `//` in chat means the same as `∥`
but maps should use `∥` or `||`.

**Thin only:** no acceptance criteria, no task lists, no status SoT (PM/session-state own status).
Titles are mnemonics when PM owns the issue.

### Initiative + workstream dialect (when already in use)

- `planning/initiatives/<name>.md` — objective, priority order, guardrails  
- `planning/workstreams/<slug>.md` — purpose, success, depends-on, link to item dir when started  
- Keep streams thin; point continue at handoff `NEXT` or first incomplete workstream's unit  

## Relationship to continue

- **`/workflow:continue` is the drive entry** — it **consumes** NEXT / order notation; it does
  **not** author this map. Bare `/workflow` only **previews** the same path (status).
- Portfolio mode (see `@workflow:continue`): explicit target → active swarm resume →
  **explicit `∥` / `{wave}` auto-handoff** → in_progress → single NEXT → planned queue →
  hard-stop.
- On slice complete, continue may advance a **pointer**; it must not rewrite stream structure.

## What this skill does not do

- Does **not** invent ACs or implementation plans.  
- Does **not** auto-run from continue (continue only offers this command).  
- Does **not** create PM issues unless the user explicitly asks as a separate step.  
- Does **not** replace refine/plan for a single unit.

## Key principles

- **Destination first** — scope every stream against it.  
- **Claimable units** — if continue can't pick it by name/id, it isn't a stream yet (shell optional).  
- **Index, not store** — detail lives in unit planning/PM, not the map.  
- **Approve before write** — durable path decisions are user-gated.  
- **Signal, not ceremony** — bail when one unit is enough.
