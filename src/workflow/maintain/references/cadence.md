# Stewardship cadence

**Load when:** detecting whether maintain jobs are due, writing cadence state after a maintain
run, or soft-offering maintain from status / continue / compound capture.

## State file

Canonical clock: **`.agent-tools/memory/state.yml`** (same file memory maintain already
updates — one plant clock, not a second tree).

```yaml
schema_version: 1
interval_days: 7
last_stewardship_at: null   # ISO-8601 — last /workflow:maintain session that completed
last_yield_at: null         # ISO-8601 — last successful yield.md regenerate
last_maintain_at: null      # ISO-8601 — last memory-quality job (compat + scoped --memory)
last_prune_at: null         # ISO-8601 — last prune check completed (report and/or purge)
snooze_until: null          # ISO-8601 — suppress due offers until this time
last_maintain_result: null  # memory job summary (p1/p2/p3/promoted/…)
last_prune_result: null     # { confirmed_complete, needs_migration, kept, purged, cancelled }
last_stewardship_result: null  # optional: { prune, yield, memory, process_seeds }
solutions_migrated_from_docs: false
```

**Migration:** if `last_stewardship_at` is missing/null, treat offer-due using
`last_maintain_at` and/or `last_yield_at` when present. If `last_prune_at` /
`last_prune_result` are missing, treat as never pruned (telemetry only — prune is not
calendar-due). On next successful `/workflow:maintain`, set `last_stewardship_at` and the
relevant job timestamps. Setup may create the file with nulls; never clobber user values when
filling new keys.

## Per-job due (bare ritual)

```text
interval = state.interval_days or 7
now = current time

yield_due   = (last_yield_at is null) OR (now - last_yield_at >= interval)
memory_due  = (last_maintain_at is null) OR (now - last_maintain_at >= interval)

# prune is state-driven, not calendar-driven:
# bare ritual always runs the prune CHECK (not a due clock)
```

Bare `/workflow:maintain` (ritual):

1. Always run prune **check**.
2. If `yield_due` and/or `memory_due`: **ask** (one gate) before running those jobs.
3. If not due: **state the skip** with last age + force path
   (`/workflow:maintain --yield` / `--memory` / `--all`).
4. Flags and `--all` **force** the selected jobs and **ignore** these clocks.

## Offer due (status / continue / compound soft prompts)

```text
if snooze_until is set and now < snooze_until:
  offer_due = false
else:
  prune_leftover =
    last_prune_result exists AND
    (confirmed_complete > purged OR needs_migration > 0 OR cancelled == true)

  offer_due =
    yield_due
    OR memory_due
    OR prune_leftover
    OR (last_stewardship_at is null)
    OR (now - last_stewardship_at >= interval)   # quiet nudge if nothing else fired
```

Legacy alias: treat bare name **`due`** in soft-checks as **`offer_due`**.

## Signal formula (for post-continue / strong offer)

```text
closed_since_yield =
  count of ledger.yml runs with closed date > last_yield_at
  (if last_yield_at null: all closed runs)

process_flags =
  any closed run since last_stewardship_at with rework: true
  OR thrash_bound_hits > 0
  OR fidelity.review in {theater, missing}
  OR fidelity.compound in {missing}
  (if no last_stewardship_at: look at last 5 closed runs)

memory_never = last_maintain_at is null AND .agent-tools/memory/ exists with entries or solutions

prune_leftover = (same as offer_due prune_leftover)

signal =
  (closed_since_yield >= 5)
  OR process_flags
  OR memory_never
  OR prune_leftover
  OR (.agent-tools/runs/ missing while planning/workflow is otherwise active — soft: "scaffold missing")
```

## Offer policy (who may prompt)

| Host | May offer? | May run maintain body? |
|------|------------|------------------------|
| **`/workflow:maintain`** | n/a | **Yes** (explicit) — ritual or forced |
| Bare **`/workflow`** (status) | Advisory line only when `offer_due` | **Never** |
| **`/workflow:continue`** | After stop / end-of-loop recap when `offer_due AND signal` — **one** approval prompt | Only if user says yes (then hand off to maintain procedure — **ritual**, not silent `--all`) |
| **`/workflow:compound`** (capture) | Soft due line → point at `:maintain` (no longer runs memory maintain inline) | **Never** (compat: `--maintain` args → maintain skill) |

**Never** block unit claim, phase transition, or capture because maintain is due.

### Approval choices (when offering from continue)

```text
1. Run now — invoke /workflow:maintain (bare ritual: prune check + schedule-aware yield/memory)
2. Snooze 3d — set snooze_until = now + 3 days; continue prior work
3. Skip once — no state write; do not re-offer this same stop
```

### Soft status line (read-only)

```markdown
**Stewardship:** due (yield and/or memory clock; and/or prune leftover; <signal summary>). Run `/workflow:maintain`.
```

Or when not due: omit, or one quiet "last maintain <date>" only if useful.

## After a successful maintain run

1. Set `last_stewardship_at` to now when the user ends the maintain session (any jobs completed
   or intentionally stopped after announce).
2. If prune job ran (check finished, even if purge cancelled or clean): set `last_prune_at`;
   set `last_prune_result` per prune.md.
3. If yield job ran (including "insufficient N" write with honest summary): set `last_yield_at`
   when `yield.md` was regenerated; if skipped for missing scaffold, leave `last_yield_at`
   unchanged.
4. If memory job ran to completion (proposal shown, even if user approved zero writes): set
   `last_maintain_at` to now; update `last_maintain_result` per memory procedure.
5. Clear `snooze_until` unless user chose snooze mid-run.
6. Optionally set `last_stewardship_result` with per-job outcomes, e.g.
   `{ prune: clean|proposed|purged|skipped, yield: ok|skipped|n/a, memory: ok|skipped|n/a, process_seeds: N }`.

Partial runs (user aborts after prune, before yield): still stamp prune fields; only stamp
`last_stewardship_at` when the user ends the maintain session or completes remaining jobs /
explicitly stops.

**Do not** stamp `last_yield_at` / `last_maintain_at` when those jobs were schedule-skipped on a
ritual run — only when the job body actually ran.
