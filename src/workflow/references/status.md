# Workflow status (bare `/workflow`)

**Load when:** user invokes bare **`/workflow`** (family parent, no drive intent). This is the
**orientation entry** — portfolio glance only. Drive work with **`/workflow:continue`**.

Mirrors bare `/swarm`: summarize → stop. Never claim, phase-invoke, ledger-append, merge, or
auto-swarm from status.

## Arguments

```text
$ARGUMENTS
```

| Input | Behavior |
|-------|----------|
| *(empty)* | Full portfolio status |
| Work item ID / PM URL / planning path / slug | **Focused status** on that unit only (still read-only) |
| Help / “list commands” / family overview (no unit target) | Short command table from parent skill + stop — skip deep scan if nothing else asked |
| Unknown junk | Full status + one line: drive with `/workflow:continue …` |

Do **not** treat bare + target as drive. Drive always says `/workflow:continue`.

## Read-only contract (hard)

Status **must not**:

- Claim a unit or write `session-state.md` / handoff / roadmap
- Invoke phase skills (`:refine`, `:plan`, `:execute`, `:review`, `:compound`, …)
- Append runs-ledger events or close-run
- Soft-check **remediate** (re-run review, force compound, rewrite evidence)
- Enter swarm orchestrator or `/swarm:continue`
- Create worktrees, merge, push, or edit conventions

Status **may** (and should):

- Resolve planning root and read conventions, roadmap/handoff, `planning/*/session-state.md`
  frontmatter + Current Focus (light scan — not full history dumps)
- Read `.agent-tools/swarm/active-run` + light `state.yml` summary when present
- Peek `.agent-tools/runs/yield.md` age (optional)
- **Surface** soft-check signals as advisory lines (same checklist as continue
  `soft-checks.md`, severity = report only)
- **Preview** which portfolio mode `/workflow:continue` would enter (mode name + target) without entering it

## Scan procedure

1. **Planning root** — `references/planning-root.md`. Prefer `.agent-tools/planning/`; legacy
   `./planning/` if preferred missing. If neither exists → **not initialized** report (below).
2. **Conventions** — `planning/conventions.md` if present (sparse overlay; note presence only
   unless a field affects the summary, e.g. PM queue enabled).
3. **Swarm** — if `.agent-tools/swarm/active-run` present, summarize run id / status / item
   stages lightly (same spirit as bare `/swarm`). Do not resume.
4. **Units** — scan `planning/*/session-state.md` (and dialect paths conventions name):
   `in_progress`, resolvable NEXT, planned queue heads. Prefer frontmatter + Current Focus.
5. **Roadmap / handoff** — NEXT, head notation (`→` / `∥` / `{wave}` / `⚠`), map-only or
   sequencing-choice flags.
6. **Soft signals** — apply continue soft-check *detection* only (theater review evidence,
   missing compound disposition, thrash near/at bound, stale yield offer). List; do not fix.
7. **Mode preview** — dry-run portfolio-router first-match using continue
   `references/portfolio-router.md` rules, as if `$ARGUMENTS` were empty (or the focused unit
   for focused status). Emit mode + target; do not act.
8. **Emit report** (template below) → **stop**.

### Focused status (args name a unit)

Resolve the unit; report its track/state/artifacts/branch/worktree/soft signals for that unit
only; still preview “continue would claim this unit” vs “not resolvable.” Do not claim.

### Not initialized

```markdown
### Workflow status

**Planning root:** not found (no `.agent-tools/planning/` or `./planning/`)

**Suggested:** `/workflow:setup` to scaffold planning hygiene + optional conventions.
```

Stop. Do not invent a queue.

## Report template

```markdown
### Workflow status

**Planning root:** `<path>` · conventions: present | absent
**Swarm:** idle | active `<run-id>` (`<status>`) — <one-line stage glance>
**In progress:** <unit · phase/state · path> | none
**NEXT / head:** <unit or roadmap head · notation> | none
**Claimable (preview):** <short list or “none”>
**Soft signals (advisory):** <list or “none”>
**Continue would:** `<mode>` → <target or hard_stop reason>

**Drive:** `/workflow:continue` · focused: `/workflow:continue <id|path|slug>`
**Other:** `/workflow:roadmap` · `/workflow:brainstorm` · `/swarm` · `/workflow:setup`
```

Keep it **short** — dashboard, not a skill essay. Omit empty optional lines if noisy; never
omit **Continue would** or the drive line when a planning root exists.

### Help-only (no work intent)

If the user clearly wants the family command list / philosophy and not a portfolio glance,
summarize the parent skill’s command table and stop. Prefer status when intent is ambiguous
and a planning root exists.

## Relationship to continue

| | `/workflow` (status) | `/workflow:continue` (drive) |
|--|----------------------|------------------------------|
| Scan planning / swarm | Yes | Yes |
| Soft-checks | Surface only | Actionable (may block claim / force remediation) |
| Portfolio router | Preview mode | Enter mode and run |
| Phase / swarm work | Never | Yes when path established |
| Invent NEXT | Never | Never |

Same scan sources; different exit. Do not implement a second claim dialect here — status
defers all mutation to continue and phase skills.
