---
name: workflow:maintain
description: Steward the agent-tools plant — regenerate run yield, audit memory quality, and surface process seeds. Not drive (continue) and not capture (compound).
argument-hint: "[blank full | --yield | --memory | --migrate-solutions | --level … | --focus …]"
user-invocable: true
---

# Maintain (`/workflow:maintain`)

**Stewardship entry** for the workflow family. Tend line metrics and memory hygiene so drive
(`:continue`) and capture (`:compound`) stay focused.

| This skill | Not this skill |
|------------|----------------|
| Yield glance from runs ledger | Claim units / run phases |
| Memory quality audit + promote/retire | Capture a new lesson from just-finished work |
| Optional process-seed pointers from yield | Edit skill corpus (`/skills:evolve` skill-source only) |
| Cadence state (`state.yml`) | Deep multi-domain `/workflow:audit` |

## User Input

```text
$ARGUMENTS
```

| Input | Jobs |
|-------|------|
| *(empty)* / full | **Yield** (if applicable) → **memory** → optional **process handoff** |
| `--yield` / `yield` | Yield only |
| `--memory` / `--maintain` | Memory only (legacy flag accepted) |
| `--migrate-solutions` | Memory job with legacy `docs/solutions/` migrate path |
| `--level global\|project\|shared\|local\|memory` | Memory scoped (see memory ref) |
| `--focus staleness\|accuracy\|scope\|gaps` | Memory focused audit |
| Combined flags | Run the implied subset only |

Explicit invocation **always runs immediately** (ignores due interval). Cadence only drives
**offers** from status / continue / capture — see `references/cadence.md`.

## Mandatory loads

| When | Load |
|------|------|
| Always | Soft refuse list below; job order |
| Due / offer context | `references/cadence.md` |
| Yield job | @workflow `references/runs-ledger.md` (Yield glance section) |
| Memory job | `references/memory.md` end-to-end |
| Process seeds | @workflow `references/runs-ledger.md` (Process self-improvement); optional @skills `evolve/references/run-ledger-seeds.md` when skill-source |

## Control loop

```text
parse args → select jobs
for each selected job in order:
  yield → memory → process handoff (only after full or when yield showed clusters)
update cadence state (cadence.md)
summarize → stop
```

**Never** claim a unit, append run events (except regenerating `yield.md`), merge, or patch
installed skills.

## Job 1 — Yield

**Skip entirely** only when user scoped `--memory` / level / focus without yield.

1. If `.agent-tools/runs/` missing → report “runs scaffold missing — `/workflow:setup`” and
   continue to memory if selected. Do **not** invent KPIs.
2. If `ledger.yml` has fewer than 5 closed runs → write or update `yield.md` with honest
   “insufficient sample (N closed)” table (no fake rates), summarize, set `last_yield_at` only
   if you regenerated the file.
3. Else regenerate `.agent-tools/runs/yield.md` from `ledger.yml` (+ cheap open-run peek from
   `events.ndjson` if useful) per **Yield document shape** in `runs-ledger.md`.
4. Summarize KPIs to the user. Flag structural notes (thrash/rework clusters, fidelity dips).
5. **Never** hand-edit vanity numbers — only regenerate from ledger.

## Job 2 — Memory

**Skip** when user scoped `--yield` only.

Load and follow **`references/memory.md`** (auto-detect, tiers, promote, migrate, apply with
approval, update `last_maintain_at` / `last_maintain_result`).

## Job 3 — Process handoff (optional, full runs or thick yield)

After yield (and memory if run), if rework/thrash/fidelity clusters stand out:

1. List candidate `run_id`s + one-line symptoms (do not invent).
2. Offer (user-gated): process memory entry via `/workflow:compound` with `type: process` and
   `related: [run_ids]`, **or** skill-source `/skills:evolve` with seeds, **or** skip.
3. **Never** auto-patch skills. Consumer projects keep evidence and escalate upstream.

## Cadence write-back

On session complete: update `.agent-tools/memory/state.yml` per `references/cadence.md`
(`last_stewardship_at`, job timestamps, clear snooze unless user snoozed).

## Compat shims (other skills)

| Legacy | Behavior |
|--------|----------|
| `/workflow:continue --yield` / `yield` | Redirect: run **this** skill yield-only (or tell user to `/workflow:maintain --yield`) — do **not** claim a unit |
| `/workflow:compound --maintain …` | Redirect: run **this** skill with the same maintain flags |

## What `/workflow:maintain` does not do

- Does **not** drive work (`:continue`) or invent NEXT
- Does **not** capture unit learnings (that is bare `:compound`)
- Does **not** replace `/workflow:audit`
- Does **not** edit the skill corpus mid-loop
- Does **not** hard-stop continue or block claim when due
- Does **not** spam PM with yield metrics

## Related

- **`@workflow:continue`** — drive; may **offer** maintain when due+signal (approval-gated)
- **`@workflow`** (bare) — status; advisory stewardship line only
- **`@workflow:compound`** — capture; due line points here
- **`@workflow:setup`** — scaffolds memory + runs
- **`@skills:evolve`** — skill-source only; consumes run seeds
