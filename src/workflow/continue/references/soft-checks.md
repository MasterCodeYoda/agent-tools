# Continue soft-checks

Apply on **every** `/workflow:continue` orientation (before portfolio mode resolve), and after
a completed slice when picking up again.

**Severity by entry:**

| Entry | Soft-check role |
|-------|-----------------|
| `/workflow:continue` | **Actionable** — events for the unit machine / portfolio router; may force work on a prior slice before claiming new work |
| bare `/workflow` (status) | **Advisory only** — same detection checklist; surface in the status report; **never** remediate, claim, or block (status does not claim) |

Unless noted otherwise below, procedures describe the **continue (actionable)** path.

## Review theater

If the most recently completed code-bearing slice has a `review:` line missing `method=` or
findings counts (theater evidence), **surface it** and either re-run `/workflow:review` +
remediate or rewrite **valid** evidence (`gates.md` schema) **before** portfolio claim of new
work. Treat as `needs_review` on that prior unit if still claimable.

## Compound skip

If the most recently completed integrated slice has neither a compound capture note nor a
`compound: none — <reason>` line, surface it and either compound or record the skip before new
work. Treat as `needs_compound` on that unit.

## Thrash counters (per run_id)

If the claimed (or prior open) unit has `reentry_counts` already at thrash bound
(`refine_from_execute_or_review` + `plan_from_execute_or_review` re-entries from execute/review
**> 2** for this `run_id`), or `thrash_bound_hits ≥ 1` unresolved, **diagnose before** another
refine/plan loop. Offer process memory capture; do **not** edit workflow skills in-place.

## Context craft (advisory)

When claiming or resuming a code-bearing unit, soft-surface if:

- No `codebase-research.md` and no recorded `codebase research: skipped — …` for non-trivial work  
- **Feature/hard** unit with no `design-discussion.md` and no recorded
  `design discussion: skipped — …` when about to plan or execute  
- Substantial plan missing a **Structure outline** segment (only Approach + task dump)  
- Session-state shows repeated failure without an **Intentional Compaction** snapshot  

Do **not** block claim solely for this — fold research/design/structure/compaction into the
next phase skill (`refine` / `plan` / `execute`). Full norms: @workflow
`references/context-engineering.md`.

## Process gap → corpus (not in-loop rewrite)

Repeated theater, thrash, or fidelity misses across runs are **evidence** for corpus
improvement — never auto-mutate skills from continue. Soft-mention once when evidence is thick.

| Where you are | What to do |
|---------------|------------|
| **Skill source** (agent-tools / checkout with `/skills:evolve`) | Capture process memory, then schedule **`/skills:evolve`** with seeds: `run_ids` + hypothesized gap + candidate skill paths |
| **Consumer project** (published workflow only) | Capture process memory (`type: process`); take the gap **upstream** to the skill source. Do **not** invent a workflow-local improve command or edit installed skills |

Seed fields (portable — no skill-source file required to record them): `run_ids`, `symptoms`,
`hypothesized_gap`, `candidate_skills`, optional `severity_guess`.

## Stewardship due (optional, non-blocking)

Load due/signal rules from @workflow `maintain/references/cadence.md` (read
`.agent-tools/memory/state.yml` + ledger counts).

| Host | Behavior |
|------|----------|
| **`/workflow:continue`** | On **end-of-loop stop / recap / hard_stop** (not every phase-return): if `due AND signal`, **one** approval prompt — run `/workflow:maintain` now / snooze 3d / skip once. Never auto-run. Never block claim. |
| Bare **`/workflow`** (status) | Advisory line only when due — do not prompt multi-choice or write state |
| Mid-drive phase-return | Do **not** interrupt for maintain |

`signal` examples: ≥5 closed runs since last yield; rework/thrash/fidelity flags; memory never
maintained. Full formula in cadence.md.

**Compat:** `/workflow:continue --yield` still accepted → hand off to
`/workflow:maintain --yield` (no unit claim).

## Active swarm

If `active-run` is present, portfolio-router rows 2–4 take precedence over soft-check-driven
new claims on swarm-owned items.
