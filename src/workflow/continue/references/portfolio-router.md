# Portfolio router (continue mode selection)

**Load when:** `/workflow:continue` has finished orientation soft-checks and must choose *how*
to drive work — before claiming a single unit into the phase machine. Bare `/workflow` only
**previews** this table (status report); it never claims or enters a mode.

Continue is the **drive entry**. This router picks a mode. It does not invent work units and
does not implement multi-item parallelism itself.

## Mode resolve (first match wins)

| # | Condition | Mode | Action |
|---|-----------|------|--------|
| 1 | Explicit target in `$ARGUMENTS` (issue id, PM URL, planning path, stable slug) | **unit** | Claim that unit (warn if leaving another `in_progress` behind). Skip auto-swarm. |
| 2 | `.agent-tools/swarm/active-run` present and run is `in_progress` or `terminal_pause` (or equivalent paused status) | **swarm_resume** | Run `/swarm:continue` semantics in this session (reconcile + orchestration loop). Do not claim a sequential unit from under the run. |
| 3 | Active roadmap/handoff **frontier** is an **explicit parallel group** (see eligibility) with **≥2 claimable** peers, and swarm is **ready** | **swarm_handoff** | Auto-handoff: start `/swarm` with goal = that wave’s item list (or resume if the same wave is already the active run). Announce one line: wave ids + “entering swarm.” |
| 4 | Same as row 3 but swarm **not** ready (no charter / no `.agent-tools/swarm` setup) | **fallback** | **One** ask: run `/swarm:setup` then handoff, **or** proceed sequential on the first claimable peer. If sequential, claim one unit only. |
| 5 | Live `status: in_progress` slice (project rules for live branch) | **unit** | Resume that unit’s phase machine. |
| 6 | Conventions / handoff / roadmap names a **resolvable single** NEXT (not map-only, not sequencing-choice-only) | **unit** | Claim that unit. |
| 7 | NEXT is **map-only**, **user sequencing choice**, or multi-option without a single resolvable unit | **hard_stop_choice** | Surface the choices (up to a short list). Do not invent a wave or a unit. |
| 8 | ≥1 resolvable `status: planned` unit (planning root) | **unit** | Claim next by roadmap/priority order (one unit). |
| 8b | No planned unit; conventions enable **PM queue**; closed filter matches | **unit** or **hard_stop_choice** | **Exactly one** match → claim. **Multiple** → hard_stop_choice with named list (max ~5). **Zero** → fall through. Never invent from open backlog or priority alone. |
| 9 | None of the above | **hard_stop** | Path not established — same template as continue SKILL. |

**Authority notes**

- Explicit args always win over roadmap `∥` auto-handoff.
- `in_progress` (row 5) wins over a parallel NEXT that would otherwise auto-swarm, so a live
  sequential slice is not abandoned for a wave.
- When mode is **swarm_resume** or **swarm_handoff**, do not also run the unit machine for a
  peer from the same wave.

## Explicit parallel-group eligibility (auto-swarm)

Auto-handoff **only** when **all** of the following hold:

1. **Notation present** at the active head (NEXT block and/or the stream order line that NEXT
   points at): `∥` (U+2225) or ASCII `||`, and/or a wave package `{A ∥ B ∥ …}` / `{A || B}`.
2. **≥2 distinct claimable peers** in that group (issue ids, slugs, or planning paths).
3. Peers are **not** ruled out by unfinished hard `→` predecessors outside the group.
4. Group is **not** only a `⚠ A ∥ B` collision note — collision lines are **watch** signals,
   not launch packages. Prefer sequential or ask once if the only `∥` is under `⚠`.
5. NEXT is **not** purely “user sequencing choice” / map-only without naming the group as the
   next package.

**Do not** invent a wave from “several planned units that look independent” without explicit
`∥` / `{wave}` grouping.

### Claimable peer

Same as continue’s resolvable unit: issue id / PM URL, existing `planning/<slug>/`, or stable
slug/name from the map — planning dir optional.

### Swarm ready

- `.agent-tools/charter/charter.md` exists (or project’s documented charter path), **and**
- `.agent-tools/swarm/` has been set up (`config.yml` and/or roles/references present per
  `/swarm:setup`).

If charter missing → row 4 fallback.

## Handoff package (swarm_handoff)

Build a concrete goal string for `/swarm`:

1. List peer ids from the explicit group (stable order: left-to-right in the notation).
2. Prefer issue keys when present (`SPEC-823, SPEC-828`).
3. One-line announce, then enter swarm orchestrator procedure (`@swarm`) with that goal.
4. Pre-launch confirmation inside swarm still applies (swarm’s own y/n) — continue does not
   strip swarm safety; it only removes the need for the *user* to guess `/swarm` vs
   `/workflow:continue`.

## Channel / claim addresses (explicit unit)

These count as **explicit target** (row 1) — not backlog invention:

- Issue key, PM URL, planning path, stable slug in `$ARGUMENTS`
- Pasted greppable claim block (see @workflow `planning/pm-integration.md`):

```text
workflow:claim
unit: LIN-456
intent: continue
channel: linear
note: optional steering
```

(`plant:claim` accepted as legacy synonym.) Resume: `workflow:resume` + `unit:`.

## PM queue (row 8b)

Only when conventions document a **closed** filter (e.g. label `workflow:claimable` + state +
assignee). Order SoT remains roadmap NEXT when present — PM queue is **not** a second NEXT
inventor. Multi-match → hard_stop_choice; never silent “most interesting.”

## Coexistence while sequential (unit mode)

When mode is **unit** and a swarm run is **also** `in_progress` on *other* items:

1. Read `sessions/<run-id>/state.yml`.
2. Treat items with live `in_flight` role or unmerged worktree as **off-limits**.
3. Claim only a disjoint unit; if none free, stop and say so (suggest letting swarm finish).

Separate state stores remain: continue → `planning/**/session-state.md` (under planning root);
swarm → `.agent-tools/swarm/`; runs → `.agent-tools/runs/`. Never write the other’s files.

## Notation quick reference

Full dialect: `@workflow:roadmap`. Summary:

| Token | Meaning |
|-------|---------|
| `→` | Sequential dependency |
| `∥` or `||` | Parallelizable peers (swarm-wave candidates when grouped at head) |
| `{A ∥ B}` | Named wave package |
| `⚠ A ∥ B` | Collision / same-layer watch — not auto-launch |
