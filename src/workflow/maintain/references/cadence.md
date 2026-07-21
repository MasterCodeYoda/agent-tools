# Stewardship cadence

**Load when:** detecting whether maintain is due, writing cadence state after a maintain
run, or soft-offering maintain from status / continue / compound capture.

## State file

Canonical clock: **`.agent-tools/memory/state.yml`** (same file memory maintain already
updates — one plant clock, not a second tree).

```yaml
schema_version: 1
interval_days: 7
last_stewardship_at: null   # ISO-8601 — last /workflow:maintain that finished yield and/or memory
last_yield_at: null         # ISO-8601 — last successful yield.md regenerate
last_maintain_at: null      # ISO-8601 — last memory-quality job (compat + scoped --memory)
snooze_until: null          # ISO-8601 — suppress due offers until this time
last_maintain_result: null  # memory job summary (p1/p2/p3/promoted/…)
last_stewardship_result: null  # optional: { yield: ok|skipped|n/a, memory: ok|skipped|n/a, process_seeds: N }
solutions_migrated_from_docs: false
```

**Migration:** if `last_stewardship_at` is missing/null, treat due using
`last_maintain_at` (and/or `last_yield_at` when present). On next successful
`/workflow:maintain`, set `last_stewardship_at` (and the relevant job timestamps).

Setup may create the file with nulls; never clobber user values when filling new keys.

## Due formula

```text
interval = state.interval_days or 7
now = current time

if snooze_until is set and now < snooze_until:
  due = false
else:
  anchor = last_stewardship_at
           or last_maintain_at
           or last_yield_at
           or null
  due = (anchor is null) OR (now - anchor >= interval days)
```

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

signal =
  (closed_since_yield >= 5)
  OR process_flags
  OR memory_never
  OR (.agent-tools/runs/ missing while planning/workflow is otherwise active — soft: "scaffold missing")
```

## Offer policy (who may prompt)

| Host | May offer? | May run maintain body? |
|------|------------|------------------------|
| **`/workflow:maintain`** | n/a | **Yes** (explicit) |
| Bare **`/workflow`** (status) | Advisory line only when `due` | **Never** |
| **`/workflow:continue`** | After stop / end-of-loop recap when `due AND signal` — **one** approval prompt | Only if user says yes (then hand off to maintain procedure) |
| **`/workflow:compound`** (capture) | Soft due line → point at `:maintain` (no longer runs memory maintain inline) | **Never** (compat: `--maintain` args → full maintain skill) |

**Never** block unit claim, phase transition, or capture because maintain is due.

### Approval choices (when offering)

```text
1. Run now — invoke /workflow:maintain (full default jobs)
2. Snooze 3d — set snooze_until = now + 3 days; continue prior work
3. Skip once — no state write; do not re-offer this same stop
```

### Soft status line (read-only)

```markdown
**Stewardship:** due (last <N>d ago; <signal summary>). Run `/workflow:maintain`.
```

Or when not due: omit, or one quiet "last maintain <date>" only if useful.

## After a successful maintain run

1. Set `last_stewardship_at` to now.
2. If yield job ran (including "insufficient N" write/skip with honest summary): set `last_yield_at` when `yield.md` was regenerated; if skipped for missing scaffold, leave `last_yield_at` unchanged.
3. If memory job ran to completion (proposal shown, even if user approved zero writes): set `last_maintain_at` to now; update `last_maintain_result` per memory procedure.
4. Clear `snooze_until` unless user chose snooze mid-run.
5. Optionally set `last_stewardship_result` with job outcomes.

Partial runs (user aborts after yield, before memory): still stamp `last_yield_at` if yield finished; only stamp `last_stewardship_at` when the user ends the maintain session or completes remaining jobs / explicitly stops.
