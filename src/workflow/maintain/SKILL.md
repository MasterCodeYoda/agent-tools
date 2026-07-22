---
name: workflow:maintain
description: Steward the workflow plant — always prune-check planning/, schedule-aware yield + memory (ask or skip), optional process seeds. Not drive (continue) and not capture (compound).
argument-hint: "[blank ritual | --all | --prune | --yield | --memory | --migrate-solutions | --level … | --focus … | scope path]"
user-invocable: true
---

# Maintain (`/workflow:maintain`)

**Stewardship entry** for the workflow family. Tend planning reclaim, line metrics, and memory
hygiene so drive (`:continue`) and capture (`:compound`) stay focused.

| This skill | Not this skill |
|------------|----------------|
| Prune-check completed `planning/` items (approval-gated purge) | Claim units / run phases |
| Yield glance from runs ledger | Capture a new lesson from just-finished work |
| Memory quality audit + promote/retire | Edit skill corpus (`/skills:evolve` skill-source only) |
| Optional process-seed pointers from yield | Deep multi-domain `/workflow:audit` |
| Cadence state (`state.yml`) | Author scaffolding (`/workflow:setup` creates; this reclaims) |

## User Input

```text
$ARGUMENTS
```

| Input | Behavior |
|-------|----------|
| *(empty)* | **Ritual** — always **prune check**; **yield** / **memory** only if due (ask) or state skip; process handoff if yield ran with clusters |
| `--all` / `full` | Force **all** jobs now (prune check + yield + memory; process handoff if clusters) — ignore due clocks |
| `--prune` / `prune` | Prune job only (optional scope: work item / dir / milestone as remaining args) |
| `--yield` / `yield` | Yield only (force) |
| `--memory` / `--maintain` | Memory only (force; legacy `--maintain` accepted) |
| `--migrate-solutions` | Memory job with legacy `docs/solutions/` migrate path (force) |
| `--level global\|project\|shared\|local\|memory` | Memory scoped (force; see memory ref) |
| `--focus staleness\|accuracy\|scope\|gaps` | Memory focused audit (force) |
| Combined job flags | Run the implied subset only (each forced) |
| Scope path without flags | Treated as **prune scope** under the ritual (still schedule-aware for yield/memory) |

**Bare vs force:** bare invocation is a **stewardship ritual** — schedule-aware for yield and
memory. Flags (and `--all`) **force** those jobs immediately. Prune **check** always runs on
bare and on `--all` / `--prune`. Cadence also drives **offers** from status / continue /
capture — see `references/cadence.md`.

## Mandatory loads

| When | Load |
|------|------|
| Always | Soft refuse list; control loop; `references/cadence.md` (per-job due) |
| Prune job | `references/prune.md` end-to-end |
| Yield job | @workflow `references/runs-ledger.md` (Yield glance section) |
| Memory job | `references/memory.md` end-to-end |
| Process seeds | @workflow `references/runs-ledger.md` (Process self-improvement); optional @skills `evolve/references/run-ledger-seeds.md` when skill-source |

## Control loop

```text
parse args → mode (ritual | forced subset | --all)
load cadence → compute yield_due, memory_due

if ritual (no job flags, or only prune scope):
  announce plan:
    prune: always (check)
    yield: due → will ask | not due → skip (show force path)
    memory: due → will ask | not due → skip (show force path)
  one gate when any of yield/memory is due:
    [run due only / run all / prune only / cancel]
  prune check (always, unless cancel)
  yield if approved or --all path
  memory if approved or --all path
  process handoff if yield ran and clusters stand out

if forced flags / --all:
  run selected jobs in order: prune → yield → memory → process handoff
  (skip unselected; --all selects all three)

update cadence state (cadence.md)
summarize → stop
```

**Never** claim a unit, append run events (except regenerating `yield.md`), merge, or patch
installed skills.

### Ritual announce (template)

```markdown
**Stewardship ritual**
| Job | Plan |
|-----|------|
| prune | always — will scan `planning/` (purge still gated) |
| yield | due (last regenerated <N>d ago, interval <I>d) — ask | not due (last <N>d ago) — skip. Force: `/workflow:maintain --yield` |
| memory | due (…) — ask | not due (…) — skip. Force: `/workflow:maintain --memory` |

Choices when yield and/or memory due: **run due only** / **run all** / **prune only** / **cancel**
When neither due: proceed to prune check only (no extra gate).
```

## Job order

1. **Prune** (check always on ritual / `--all` / `--prune`)
2. **Yield** (when selected)
3. **Memory** (when selected)
4. **Process handoff** (optional; only after yield ran this session, or when existing `yield.md` is thick enough to cluster — never invent)

## Job 1 — Prune (planning reclaim)

**When:** ritual bare (always check); `--all`; `--prune`; or ritual with a scope path.

Load and follow **`references/prune.md`** end-to-end.

- **Check** = enumerate → verify → classify → present summary. Non-destructive.
- **Purge** = only after an **explicit** second confirmation. Never implied by “run maintain”,
  “run due only”, or “run all”.
- Optional scope (work item / dir / milestone) narrows the sweep; default is all of `planning/`.
- On completion (even report-only / cancel purge): write `last_prune_at` + `last_prune_result`
  per cadence.md.

**Skip entirely** only when the user forced a non-prune subset (`--yield` / `--memory` / level /
focus / migrate without `--prune` or `--all`).

## Job 2 — Yield

**When:** forced (`--yield` / `--all`); or ritual and due and user approved (due only / run all).

**Skip** when not selected, or ritual and not due (state the skip + force path), or user chose
prune only / cancel.

1. If `.agent-tools/runs/` missing → report “runs scaffold missing — `/workflow:setup`” and
   continue to next selected job. Do **not** invent KPIs.
2. If `ledger.yml` has fewer than 5 closed runs → write or update `yield.md` with honest
   “insufficient sample (N closed)” table (no fake rates), summarize, set `last_yield_at` only
   if you regenerated the file.
3. Else regenerate `.agent-tools/runs/yield.md` from `ledger.yml` (+ cheap open-run peek from
   `events.ndjson` if useful) per **Yield document shape** in `runs-ledger.md`.
4. Summarize KPIs to the user. Flag structural notes (thrash/rework clusters, fidelity dips).
5. **Never** hand-edit vanity numbers — only regenerate from ledger.

## Job 3 — Memory

**When:** forced (`--memory` / `--maintain` / level / focus / migrate / `--all`); or ritual and
due and user approved.

**Skip** when not selected, or ritual and not due (state the skip + force path), or user chose
prune only / cancel.

Load and follow **`references/memory.md`** (auto-detect, tiers, promote, migrate, apply with
approval, update `last_maintain_at` / `last_maintain_result`).

## Job 4 — Process handoff (optional)

After a **yield job that ran this session** (and memory if also run), if rework/thrash/fidelity
clusters stand out:

1. List candidate `run_id`s + one-line symptoms (do not invent).
2. Offer (user-gated): process memory entry via `/workflow:compound` with `type: process` and
   `related: [run_ids]`, **or** skill-source `/skills:evolve` with seeds, **or** skip.
3. **Never** auto-patch skills. Consumer projects keep evidence and escalate upstream.

If yield was skipped this session, do **not** invent clusters from cold start; optional peek at
an existing thick `yield.md` only when structural flags are already written there.

## Cadence write-back

On session complete: update `.agent-tools/memory/state.yml` per `references/cadence.md`
(`last_stewardship_at`, per-job timestamps including prune, clear snooze unless user snoozed).

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
- Does **not** purge planning items without an explicit confirmation gate (check ≠ delete)
- Does **not** force yield/memory on bare ritual when not due (use `--yield` / `--memory` / `--all`)

## Related

- **`@workflow:continue`** — drive; may **offer** maintain when due+signal (approval-gated)
- **`@workflow`** (bare) — status; advisory stewardship line only
- **`@workflow:compound`** — capture; due line points here; migrate before purging NEEDS-MIGRATION items
- **`@workflow:setup`** — scaffolds planning / memory / runs (inverse of prune reclaim)
- **`@skills:evolve`** — skill-source only; consumes run seeds
