# Continue soft-checks

Apply on **every** `/workflow:continue` orientation (before portfolio mode resolve), and after
a completed slice when picking up again.

Soft-checks are **events** for the unit machine / portfolio router: they can force work on a
prior slice before claiming new work.

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

## Process gap → corpus (not in-loop rewrite)

Repeated theater, thrash, or fidelity misses across runs are **evidence** for corpus
improvement — never auto-mutate skills from continue. Soft-mention once when evidence is thick.

| Where you are | What to do |
|---------------|------------|
| **Skill source** (agent-tools / checkout with `/skills:evolve`) | Capture process memory, then schedule **`/skills:evolve`** with seeds: `run_ids` + hypothesized gap + candidate skill paths |
| **Consumer project** (published workflow only) | Capture process memory (`type: process`); take the gap **upstream** to the skill source. Do **not** invent a workflow-local improve command or edit installed skills |

Seed fields (portable — no skill-source file required to record them): `run_ids`, `symptoms`,
`hypothesized_gap`, `candidate_skills`, optional `severity_guess`.

## Yield glance (optional, non-blocking)

If `.agent-tools/runs/yield.md` is older than 7 days **and** ≥5 closed runs exist since last
generate, soft-offer regenerate from ledger (shape in `runs-ledger.md`). User can force with
`/workflow:continue --yield`. Never block claim for metrics.

## Active swarm

If `active-run` is present, portfolio-router rows 2–4 take precedence over soft-check-driven
new claims on swarm-owned items.
