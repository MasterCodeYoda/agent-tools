# Horizon altitudes (workflow triage)

Shared router for `/workflow` (status), `/workflow:brainstorm`, `/workflow:roadmap`, and
`/workflow:continue` (drive). Sub-skills enforce refuse rules; this table is the product-level
triage.

## Shared invariant

No durable path decision (`Chosen Direction`, stream list, committed NEXT) without an
**explicit user selection turn**.

## Altitude table

| User situation | Skill | Notes |
|----------------|-------|--------|
| “Where are we?” / portfolio glance / no action | `/workflow` | Read-only status — `references/status.md`; soft signals advisory only |
| Multi-unit program; streams/order missing or stale | `/workflow:roadmap` | Destination + `→` / `∥` / `{wave}` / NEXT |
| One fuzzy concept; direction unchosen | `/workflow:brainstorm` | Hard HITL diverge → user converge |
| One unit; requirements weak | `/workflow:refine` | Skip if track=micro (issue-as-plan) |
| Requirements clear; need how | `/workflow:plan` | Skip if track=micro |
| Research / evaluate / decide (not ship-by-default) | `/workflow:continue` on research track | Built-in research process — `references/tracks.md` |
| Session kickoff / drive known work | `/workflow:continue` | Portfolio mode: swarm resume/handoff or unit SM; track classify first |
| Explicit parallel wave at roadmap head | continue → `/swarm` | Auto when `∥` / `{wave}` + swarm ready |
| Empty continue; no **named** resolvable unit | continue **hard-stop** | Offer brainstorm / roadmap / name a unit — never invent. Missing `planning/<slug>/` alone is **not** hard-stop |

## Offer ≠ invoke

Continue may **name** roadmap/brainstorm and stop, or route a *claimed* unit into those phases.
It does not auto-author a roadmap. Swarm auto-handoff is the exception for **explicit** `∥`
groups (see continue portfolio router).

## Path / mode established (continue)

First match wins (summary — full rules in continue portfolio router):

1. Explicit args → unit mode  
2. Active swarm run → swarm resume  
3. Explicit `∥` / `{wave}` at head (≥2 claimable) → swarm handoff (or setup fallback)  
4. `in_progress` → unit  
5. Single resolvable NEXT → unit  
6. map-only / sequencing choice → hard_stop_choice  
7. Planned/PM queue → unit  
8. Else hard stop  

**Planned without roadmap still counts as established.** **Named NEXT without a planning dir
still counts as established** — claim and route (usually refine); the shell is phase output,
not a passport.

## Thin maps

Roadmaps are indexes (destination, claimable units, order, out of scope, NEXT) — not ACs,
task lists, or status SoT.
