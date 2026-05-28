---
project: swarm
phase: 2
requirements_source: file
requirements_doc: ./planning/swarm/design.md
decomposition_mode: deliverable-partition
blocks: []
blocked_by: []
parallelizable_with: []
---

# Implementation Plan: `/swarm` Phase 2 — Orchestrator MVP

## Approach

Phase 2 turns the Phase 1 foundation into a working orchestrator. The orchestrator runs in
the **host session** (no tmux, no daemon): it ingests a backlog, classifies each item's
stage, dispatches role-specialized sub-agents in parallel waves via the host's **native
`Agent` tool** (each worker runs a `/workflow` command in a per-item worktree), parses strict
YAML returns, runs a between-wave merge sweep into `main` with test gates, and manages three
exit states. State is recoverable: `state.yml` is a hint, and `/swarm:continue` always
reconciles against disk + PM ground truth.

These are prompt artifacts. "Verification" = publisher/`setup.sh` clean + structural checks.
Full behavioral proof of AC10/AC12 requires a live dogfood run, which is **deferred to a
post-completion session** (see Out of Scope) — not part of Phase 2's Definition of Done.

### Key Insight

Author the contracts first (D1 worker-contract + D2 schemas), then the orchestrator (D3).
The orchestrator references the structured-return schema, state schema, and classification
rules constantly; writing those first makes D3 easier to get right and keeps the
worker-contract (prepended to every dispatch — the system's linchpin) authoritative.

## Parent Acceptance Criteria

(Handoff Phase 2 acceptance #10–14 verbatim, plus two derived criteria for publish + the
deferred roles/ copy.)

- [ ] **P2-AC10** — `/swarm <goal>` with a real (small) backlog: orchestrator classifies
  items, dispatches parallel sub-agents, processes wave returns, surfaces IN_FLIGHT_DECISIONs
  / TERMINAL_PAUSEs correctly.
- [ ] **P2-AC11** — `/swarm:continue` resumes from TERMINAL_PAUSE; reconciles `state.yml`
  against disk + PM ground truth; surfaces drift to user.
- [ ] **P2-AC12** — Merge sweep: clean case merges + cleanup; conflict triggers one-shot
  conflict-resolver dispatch; test-red triggers one-shot integration-fixer dispatch; second
  failure → TERMINAL_PAUSE.
- [ ] **P2-AC13** — Session logs at `.agent-tools/swarm/sessions/<run-id>/` with per-dispatch
  files and `orchestrator.md` log.
- [ ] **P2-AC14** — `active-run` pointer behavior matches design §8.4 (created on dispatch,
  cleared on GOAL_COMPLETE, preserved on TERMINAL_PAUSE).
- [ ] **P2-AC-ROLES** *(derived)* — `/swarm:init` now copies the six canonical role templates
  into `.agent-tools/swarm/roles/`, with local-edit detection
  (`keep-local/replace/merge/show-diff`, §7.9). Completes the AC5 piece deferred from Phase 1.
- [ ] **P2-AC-PUB** *(derived)* — `setup.sh` runs clean; publisher emits `swarm/`,
  `swarm-init/`, **and** `swarm-continue/` for claude+factory, `swarm/` only for grok.

## AC Traceability Matrix

| Parent AC | Owning deliverable |
|-----------|--------------------|
| P2-AC10 | D3 (depends on D1, D2) |
| P2-AC11 | D4 (depends on D2) |
| P2-AC12 | D3 (depends on D1 conflict-resolver + integration-fixer templates) |
| P2-AC13 | D3 (log format from D1 worker-contract) |
| P2-AC14 | D3 |
| P2-AC-ROLES | D5 (depends on D1) |
| P2-AC-PUB | D6 (depends on D3, D4) |

---

## Deliverable Breakdown

### D1 — Canonical role templates (`src/swarm/roles/`)

**Files (new):** `worker-contract.md`, `planner.md`, `implementer.md`, `reviewer.md`,
`conflict-resolver.md`, `integration-fixer.md`

- [ ] `worker-contract.md` — structured return schema, status-code semantics, brevity
  discipline (§7.6 verbatim), session-log writing requirement + format (§7.8), generic worker
  boundaries (§7.3). Mechanically prepended to every dispatch (§7.10).
- [ ] `planner.md`, `implementer.md`, `reviewer.md` — role identity line, the `/workflow`
  command each wraps, role-specific scope notes, role-specific status subset (§7.2).
  Role-deltas only; shared content stays in worker-contract.
- [ ] `conflict-resolver.md`, `integration-fixer.md` — one-shot ad-hoc roles, no `/workflow`
  wrap, `DONE`/`FAILED` only (§7.2).
- [ ] Worker self-awareness discipline: workers know their own role, not peers' (§7.3). No
  literal `<!-- -->` markers (publisher strips them).

### D2 — Reference schemas (`src/swarm/references/`)

**Files (new):** `state-yml-schema.md`, `config-yml-schema.md`,
`structured-return-schema.md`, `classification-rules.md`, `dispatch-mechanics.md`

- [ ] `structured-return-schema.md` — YAML-in-fenced-block return schema + parse rules
  (§7.4); malformed → BLOCKED.
- [ ] `state-yml-schema.md` — per-run `state.yml` schema + atomic-write strategy (§8.2, §8.5).
- [ ] `config-yml-schema.md` — `config.yml` schema + test-command discovery cascade (§8.1,
  §8.6).
- [ ] `classification-rules.md` — stage classification sources + incremental re-classification
  (§6.2).
- [ ] `dispatch-mechanics.md` — wave scheduling (§6.4), dispatch assembly + worktree deferral
  (§6.5), **merge orchestration detail** (§6.8). Merge sweep lives here, not a new file —
  staying within the design's file set.

### D3 — `/swarm <goal>` orchestrator loop (full `src/swarm/SKILL.md`)

**Files:** `src/swarm/SKILL.md` (replace Phase 1 `<goal>` stub + upgrade bare `/swarm`)
**Owns:** P2-AC10, P2-AC12, P2-AC13, P2-AC14

- [ ] Goal interpretation + backlog ingestion (PM-first via MCP, file fallback) + pre-launch
  confirmation (§6.1).
- [ ] Initial + incremental classification (§6.2, via D2 rules).
- [ ] Main loop A–H: merge sweep → re-classify → in-process host-side refinement → goal check
  → wave scheduling → dispatch → await returns → exit-state triage (§6.3).
- [ ] Dispatch mechanics: single-message N-parallel `Agent`-tool dispatch, prompt assembly
  (worker-contract + role + charter + item context + resume), model selection per role,
  strict worktree deferral to `/git:worktree-create` / `/git:worktree-delete` (§6.5).
- [ ] Wave completion: parse returns, atomic `state.yml` write, stage advance (§6.6).
- [ ] Merge orchestration: clean / conflict→conflict-resolver / test-red→integration-fixer /
  second-failure→TERMINAL_PAUSE (§6.8).
- [ ] Exit-state model: GOAL_COMPLETE / IN_FLIGHT_DECISION / TERMINAL_PAUSE (§6.7) +
  active-run create/clear/preserve (§8.4) + session-log writing (§7.8).
- [ ] Upgrade bare `/swarm` summary to read `active-run` + sessions and report current run
  state.

### D4 — `/swarm:continue` with reconciliation (`src/swarm/continue/SKILL.md`)

**Files (new):** `src/swarm/continue/SKILL.md` (`name: swarm:continue`)
**Owns:** P2-AC11

- [ ] Read `active-run`; load `state.yml`; handle absent/malformed pointer (§6.9, §8.4).
- [ ] Never trust `state.yml`; re-classify all non-merged items from disk + PM; surface
  drift; confirm with user; rewrite reconciled state; re-enter main loop at merge sweep
  (§6.9).

### D5 — `/swarm:init` roles/ copy (enhance `src/swarm/init/SKILL.md`)

**Files:** `src/swarm/init/SKILL.md` (edit)
**Owns:** P2-AC-ROLES

- [ ] Copy `src/swarm/roles/*` → `.agent-tools/swarm/roles/` on fresh init.
- [ ] Local-edit detection on re-init: diff vs canonical, offer
  `keep-local/replace-with-canonical/merge/show-diff`; never silently overwrite (§7.9).
- [ ] Remove the Phase 1 "roles deferred to Phase 2" note.

### D6 — Documentation + publish verification

**Files:** `README.md` (edit); `setup.sh`; publisher
**Owns:** P2-AC-PUB

- [ ] README: mark `/swarm <goal>` + `/swarm:continue` available; brief orchestrator
  overview; sessions/`active-run` note.
- [ ] `setup.sh` clean; verify `swarm/` + `swarm-init/` + `swarm-continue/` for claude+factory,
  `swarm/` only for grok; confirm `<!-- -->` survival for any new literal-comment content.

#### Gap-prevention check (before Phase 2 closes)

- [ ] Every parent AC owned by exactly one deliverable; matrix has zero orphans.
- [ ] `src/swarm/` contains only the design's file set (SKILL.md, init/, continue/, roles/ ×6,
  references/ ×5) — **no** `cli-addenda.md` / `cross-cli-dispatch.md` (Phase 3).

## Out of Scope (Phase 2)

- **End-to-end dogfood run** on a small real backlog — **deferred to a post-completion
  session** (expanded from the plan's proposal). Phase 2 DoD does not require it.
- Cross-CLI worker dispatch, `cli-addenda.md`, `cross-cli-dispatch.md`, per-role CLI
  selection — **Phase 3**.
- File-collision pre-detection, multiple concurrent runs, `/swarm:gc`, `/swarm:status` —
  design "future v2".

## Technical Decisions

- **Contracts-first ordering** (D1+D2 before D3) — see Key Insight.
- **Merge sweep documented in `dispatch-mechanics.md`**, not a new file — honors "no files
  outside the design's set."
- **Native `Agent`-tool dispatch only** (Claude host) — shell-out is Phase 3; design §10.2
  targets Claude-host for Phase 2.
- **Dogfood deferred** — full AC10/AC12 proof needs a live run; treated as a separate
  post-completion session per user direction.

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Orchestrator loop logic errors only surface at runtime | High | High | Contracts-first; deferred dogfood on a tiny backlog before real use |
| Merge sweep fix-it paths hard to test | Med | High | Encode exact one-shot-then-PAUSE semantics from §6.8; dogfood a deliberate conflict |
| Worker returns malformed → orchestrator context bloat | Med | Med | Strict brevity discipline (§7.6) in worker-contract; malformed → BLOCKED |
| `state.yml` drift after crash | Med | Med | Reconcile-always in `/swarm:continue`; atomic writes |

## Implementation Order

1. **D1** role templates → 2. **D2** schemas → 3. **D3** orchestrator → 4. **D4** continue →
5. **D5** init roles/ copy → 6. **D6** docs + publish. (D1/D2 independent of each other; both
gate D3/D4.)

## Definition of Done (Phase 2)

- [ ] All six deliverables complete; matrix zero orphans.
- [ ] `setup.sh` clean; publisher shows the three invocable skills correctly.
- [ ] `src/swarm/` matches the design's exact file set.
- [ ] README updated.
- [ ] Committed per `/git:commit`; **no push**.
- [ ] Dogfood run scheduled as a separate post-completion session (not blocking DoD).
