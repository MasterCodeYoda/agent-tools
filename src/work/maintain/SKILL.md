---
name: work:maintain
description: Steward workflow scaffolding — always prune-check planning/ + AGENTS.md hygiene, schedule-aware yield + memory (ask or skip), optional process seeds. Not drive (continue) and not capture (compound).
argument-hint: "[blank ritual | --all | --prune | --agents | --yield | --memory | --migrate-solutions | --level … | --focus … | scope path]"
user-invocable: true
---

# Maintain (`/work:maintain`)

**Stewardship entry** for the work family. Tend planning reclaim, line metrics, and memory
hygiene so drive (`:continue`) and capture (`:compound`) stay focused.

| This skill | Not this skill |
|------------|----------------|
| Prune-check completed `planning/` items (approval-gated purge) | Claim units / run phases |
| AGENTS.md hygiene check (orienting pointers; approval-gated apply) | Wipe AGENTS without confirmation |
| Yield glance from runs ledger | Capture a new lesson from just-finished work |
| Memory quality audit + promote/retire | Edit skill corpus (`/skills:evolve` skill-source only) |
| Optional process-seed pointers from yield | Deep multi-domain `/work:audit` |
| Cadence state (`state.yml`) | Author scaffolding (`/work:setup` creates; this reclaims) |

## User Input

```text
$ARGUMENTS
```

| Input | Behavior |
|-------|----------|
| *(empty)* | **Ritual** — always **prune check** + **AGENTS check**; **yield** / **memory** only if due (ask) or state skip; process handoff if yield ran with clusters |
| `--all` / `full` | Force **all** jobs now (prune + agents + yield + memory; process handoff if clusters) — ignore due clocks |
| `--prune` / `prune` | Prune job only (optional scope: work item / dir / milestone as remaining args) |
| `--agents` / `agents` | AGENTS.md hygiene only (force) |
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
| Agents hygiene job | `references/agents-hygiene.md` end-to-end |
| Yield job | @work `references/runs-ledger.md` (Yield glance section) |
| Memory job | `references/memory.md` end-to-end |
| Process seeds | @work `references/runs-ledger.md` (Process self-improvement); optional @skills `evolve/references/run-ledger-seeds.md` when skill-source |

## Control loop

```text
parse args → mode (ritual | forced subset | --all)
load cadence → compute yield_due, memory_due

if ritual (no job flags, or only prune scope):
  announce plan:
    prune: always (check)
    agents: always (check) — AGENTS.md orienting-pointers sweep
    yield: due → will ask | not due → skip (show force path)
    memory: due → will ask | not due → skip (show force path)
  one gate when any of yield/memory is due:
    [run due only / run all / prune+agents only / cancel]
  prune check (always, unless cancel)
  agents hygiene check (always, unless cancel)
  yield if approved or --all path
  memory if approved or --all path
  process handoff if yield ran and clusters stand out

if forced flags / --all:
  run selected jobs in order: prune → agents → yield → memory → process handoff
  (skip unselected; --all selects all four primary jobs)

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
| agents | always — will scan AGENTS.md (apply still gated) |
| yield | due (last regenerated <N>d ago, interval <I>d) — ask | not due (last <N>d ago) — skip. Force: `/work:maintain --yield` |
| memory | due (…) — ask | not due (…) — skip. Force: `/work:maintain --memory` |

Choices when yield and/or memory due: **run due only** / **run all** / **prune+agents only** / **cancel**
When neither due: proceed to prune + agents checks only (no extra gate).
```

## Job order

1. **Prune** (check always on ritual / `--all` / `--prune`)
2. **Agents hygiene** (check always on ritual / `--all` / `--agents`)
3. **Yield** (when selected)
4. **Memory** (when selected)
5. **Process handoff** (optional; only after yield ran this session, or when existing `yield.md` is thick enough to cluster — never invent)

## Job 1 — Prune (planning reclaim)

**When:** ritual bare (always check); `--all`; `--prune`; or ritual with a scope path.

Load and follow **`references/prune.md`** end-to-end.

- **Check** = enumerate → verify → classify → present summary. Non-destructive.
- **Purge** = only after an **explicit** second confirmation. Never implied by “run maintain”,
  “run due only”, or “run all”.
- Optional scope (work item / dir / milestone) narrows the sweep; default is all of `planning/`.
- On completion (even report-only / cancel purge): write `last_prune_at` + `last_prune_result`
  per cadence.md.

**Skip entirely** only when the user forced a non-prune subset (`--yield` / `--memory` /
`--agents` alone / level / focus / migrate without `--prune` or `--all`).

## Job 1b — AGENTS.md hygiene

**When:** ritual bare (always check); `--all`; `--agents`.

Load and follow **`references/agents-hygiene.md`** end-to-end.

- **Check** = inventory → classify → present summary. Non-destructive.
- **Apply** = only after an **explicit** second confirmation. Never implied by “run maintain”
  or “run all”.
- On completion (even report-only / cancel apply): write `last_agents_at` + `last_agents_result`
  per cadence.md.

**Skip entirely** only when the user forced a subset that excludes agents (`--prune` alone,
`--yield` / `--memory` / level / focus / migrate without `--agents` or `--all`).

## Job 2 — Yield

**When:** forced (`--yield` / `--all`); or ritual and due and user approved (due only / run all).

**Skip** when not selected, or ritual and not due (state the skip + force path), or user chose
prune only / cancel.

1. If `.agent-tools/runs/` missing → report “runs scaffold missing — `/work:setup`” and
   continue to next selected job. Do **not** invent KPIs.
2. If `ledger.yml` has fewer than 5 closed runs → write or update `yield.md` with honest
   “insufficient sample (N closed)” table (no fake rates), summarize, set `last_yield_at` only
   if you regenerated the file.
3. Else regenerate `.agent-tools/runs/yield.md` from `ledger.yml` (+ cheap open-run peek from
   `events.ndjson` if useful) per **Yield document shape** in `runs-ledger.md`.
4. Summarize KPIs to the user. Flag structural notes (thrash/rework clusters, fidelity dips).
   **Rework rate** uses ledger `rework` only (execute/review→refine/plan or thrash) — not
   `review_fix_cycles`. When identity fields exist, include a short by-harness glance.
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
2. Offer (user-gated): process memory entry via `/work:compound` with `type: process` and
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
| `/work:continue --yield` / `yield` | Redirect: run **this** skill yield-only (or tell user to `/work:maintain --yield`) — do **not** claim a unit |
| `/work:compound --maintain …` | Redirect: run **this** skill with the same maintain flags |

## Process invariants (stewardship reminders)

Surface lightly when yield or memory jobs run (do not invent a second drive loop):

1. **Script promote-on-second-use** — if the same deterministic gate/check (pre-wake, green-before-claim,
   close-shipped, disk hygiene) was hand-rolled twice, soft-recommend a **named script** under
   host or project `scripts/`. Skills describe *how*; scripts *do*. See
   @work `references/pre-wake-checklist.md`.  
2. **Escalate receipts** — veto/escalate stops should appear in `.agent-tools/runs/` events, not
   only chat (`runs-ledger.md`).  
3. **Dated rules** — incident-class lessons should use the compound dated-rule template
   ([compound/templates/dated-rule.md](../compound/templates/dated-rule.md)) when missing
   date/verify/load-when.

## What `/work:maintain` does not do

- Does **not** drive work (`:continue`) or invent NEXT
- Does **not** capture unit learnings (that is bare `:compound`)
- Does **not** replace `/work:audit`
- Does **not** edit the skill corpus mid-loop
- Does **not** hard-stop continue or block claim when due
- Does **not** spam PM with yield metrics
- Does **not** purge planning items without an explicit confirmation gate (check ≠ delete)
- Does **not** rewrite AGENTS.md without an explicit apply confirmation (check ≠ apply)
- Does **not** force yield/memory on bare ritual when not due (use `--yield` / `--memory` / `--all`)

## Related

- **`@work:continue`** — drive; may **offer** maintain when due+signal (approval-gated)
- **`@work`** (bare) — status; advisory stewardship line only
- **`@work:compound`** — capture; due line points here; migrate before purging NEEDS-MIGRATION items
- **`@work:setup`** — scaffolds planning / memory / runs (inverse of prune reclaim)
- **`@skills:evolve`** — skill-source only; consumes run seeds
