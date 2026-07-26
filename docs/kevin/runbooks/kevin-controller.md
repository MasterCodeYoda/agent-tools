# Runbook: Kevin controller & project chrome (E9 / KEVN-10)

**Status:** Active MVP  
**Profile:** `kevin` only  
**Script:** [`scripts/kevin-controller.sh`](../../scripts/kevin-controller.sh)  
**Related:** [product-surface.md](../product-surface.md) · [ADR-001](../decisions/001-hermes-provisional-factory-host.md) · [kevin-control-plane.md](./kevin-control-plane.md) · [kevin-unattended-wake.md](./kevin-unattended-wake.md) · J1 judgment vertical

---

## Intent

Thin **product judgment loop** over the project disk plus **standing chrome** (phase · model map · capacity · yield/stuck).

| Layer | Owner |
|-------|--------|
| Process dialect | agent-tools (unchanged) |
| Project continuity | disk (planning, runs, memory) |
| Model / provider / usage UI | Hermes dashboard (KEVN-4) |
| Disk-gated continue \| escalate \| idle + project chrome | **this runbook / CLI** |

Read-only. Does **not** invent NEXT, claim units, write session-state, or fork phase tables.

---

## Commands

```bash
cd /path/to/software-factory   # or product project root

# Standing chrome (human table)
./scripts/kevin-controller.sh status

# Machine-friendly keys
./scripts/kevin-controller.sh status --json

# Judgment only
./scripts/kevin-controller.sh decide
./scripts/kevin-controller.sh decide --json
./scripts/kevin-controller.sh decide --chrome   # chrome then decision
```

`--root PATH` or env `KEVIN_PROJECT_ROOT` / `FACTORY_WAKE_ROOT` when cwd is not the project root.

---

## Standing chrome (`status`)

| Field | Source |
|-------|--------|
| Phase / NEXT | `.agent-tools/planning/session-state.md` (`next_unit`, NEXT body) |
| In progress | unit `session-state.md` with `status: in_progress` (and implementing/executing) |
| Pending gates | `pending_gate` on live units |
| Swarm | `.agent-tools/parallel/active-run` |
| Model map | `hermes/profile/config.yaml` + [packs/kevin-model-hierarchy.md](../../packs/kevin-model-hierarchy.md) |
| Capacity / windows | Honest pointer to [kevin-control-plane.md](./kevin-control-plane.md) (not stored on project) |
| Yield / stuck | thrash counters, review theater soft-check, last `events.ndjson` line |

---

## Decide contract (`decide`)

### Exit codes (stable)

| Code | Decision | Meaning |
|------|----------|---------|
| **0** | `continue` | Claimable unit (NEXT or in_progress); no escalate soft-check |
| **10** | `idle` | No claimable unit — **do not invent NEXT** |
| **20** | `escalate` | Human / judgment gate required |
| **2** | error | Bad args or unreadable project root |

### Reason codes (subset of J1 / Wave 5)

| Code | When |
|------|------|
| `CLAIMABLE` / `SAFE_BAND` | Named NEXT or in_progress; safe to drive continue |
| `E-PATH` | No claimable unit |
| `E-GATE` | `pending_gate` on live unit (plan/refine/merge HITL) |
| `E-REVIEW` | `review:` present without `method=` (theater) |
| `E-THRASH` | thrash_bound_hits or refine+plan reentries > 2 |
| `E-SWARM` | swarm `active-run` present — let swarm own the wave |

### Order of evaluation

1. Swarm active → escalate `E-SWARM`  
2. Pending human gate → escalate `E-GATE`  
3. Review theater → escalate `E-REVIEW`  
4. Thrash → escalate `E-THRASH`  
5. In progress → continue  
6. Named NEXT → continue  
7. Else → idle `E-PATH`

---

## Relation to pre-wake (KEVN-7)

| Gate | Script |
|------|--------|
| Isolation / worktree / dirty primary | `./scripts/factory-wake/kevin-pre-wake.sh` |
| Claimable + judgment band | `./scripts/kevin-controller.sh decide` |

Recommended unattended outer shell (conceptual):

```text
pre-wake (exit 0) → decide (exit 0) → hermes -p kevin … continue
                  → decide (10)     → idle / no model call
                  → decide (20)     → escalate once on channel; no re-drive
```

Pre-wake does **not** replace decide; decide does **not** replace pre-wake.

---

## Relation to control plane (KEVN-4)

- Dashboard: models, keys, usage windows.  
- Controller: project phase / yield / claimable decision.  
- Launch dashboard: `./scripts/kevin-control-plane.sh`

---

## Smoke

```bash
./scripts/kevin-controller.sh status
./scripts/kevin-controller.sh decide --json; echo exit:$?
```

On a healthy project with NEXT set and no HITL gates: expect `decision=continue` exit **0**.  
With empty NEXT and no in_progress: expect `idle` exit **10**.

---

## Out of scope

- Custom web/TUI chrome product  
- Auto-invoking continue / claiming work  
- Writing planning artifacts  
- Dual process dialect  
- Replacing Hermes dashboard for providers  

---

## Acceptance (KEVN-10)

1. This path of record exists  
2. Controller prints continue \| escalate \| idle with codes  
3. Never invents NEXT  
4. Standing chrome fields present  
5. Exit codes stable as above  
6. Linked from control-plane + unattended-wake  
7. Smoke passes on project  
