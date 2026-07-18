# Horizon altitudes (workflow triage)

Shared router for `/workflow:brainstorm`, `/workflow:roadmap`, and `/workflow:continue`.
Sub-skills enforce refuse rules; this table is the product-level triage.

## Shared invariant

No durable path decision (`Chosen Direction`, stream list, committed NEXT) without an
**explicit user selection turn**.

## Altitude table

| User situation | Skill | Notes |
|----------------|-------|--------|
| Multi-unit program; streams/order missing or stale | `/workflow:roadmap` | Owns destination framing for horizons |
| One fuzzy concept; direction unchosen | `/workflow:brainstorm` | Hard HITL diverge → user converge |
| One unit; requirements weak | `/workflow:refine` | |
| Requirements clear; need how | `/workflow:plan` | |
| Drive known next unit through the loop | `/workflow:continue` | Silent when path clear |
| Empty continue; no **named** resolvable unit | continue **hard-stop** | Offer brainstorm / roadmap / name a unit — never invent. Missing `planning/<slug>/` alone is **not** hard-stop |

## Offer ≠ invoke

Continue and brainstorm may **name** roadmap (or each other) and stop. They do not auto-run
another user-invoked skill unless the user invoked it this turn.

## Path established (continue pre-claim)

First match wins: explicit args → `in_progress` → conventions/handoff NEXT → roadmap NEXT →
planned/PM queue → else hard stop. **Planned without roadmap still counts as established.**
**Named NEXT without a planning dir still counts as established** — claim and route (usually
refine); the shell is phase output, not a passport.

## Thin maps

Roadmaps are indexes (destination, claimable units, order, out of scope, NEXT) — not ACs,
task lists, or status SoT.
