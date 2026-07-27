# Runbook: Kevin unattended wake (E6 / AGNT-7)

**Status:** Active MVP — path of record (live gateway tick optional residual)  
**Profile:** `kevin` only — **not** personal Hermes default, **not** legacy `factory`  
**Scripts:** [`scripts/factory-wake/`](../../scripts/factory-wake/)  
**Related:** [kevin-v1.md](../kevin-v1.md) · [ADR-001 §7](../decisions/001-hermes-provisional-factory-host.md) · [hermes-kevin.md](./hermes-kevin.md) · J1 judgment · [pre-wake checklist](../../.agent-tools/) (process pack) · project decide [kevin-controller.md](./kevin-controller.md)

---

## Intent

Automated outer loop: Hermes **gateway + cron** under profile **`kevin`**, always preceded by
**fail-closed pre-wake**, always on an **isolated worktree**, always **claimable-only**
(never invent NEXT). Operator-as-controller (J1) remains valid until a live tick is proven.

---

## Preconditions

1. Bring-up hard bar: `./scripts/kevin-bring-up-check.sh`  
2. Coding-loop repo-class PASS recorded (AGNT-6) — do not treat wake as coding-parity substitute  
3. Disposable **git worktree** of the product repo (never dirty primary as cron `workdir`)  
4. Approvals remain fail-closed for unattended (see below)  
5. No silent `git pull` / setup on wake  

---

## Isolation rules (hard)

| Rule | Detail |
|------|--------|
| Workdir | Cron `--workdir` = absolute path to a **linked worktree** (`.git` is a file) |
| Primary | Never set workdir to an operator’s dirty primary checkout |
| Pre-wake | Unattended wrapper defaults `REQUIRE_WORKTREE=1` |
| Remote | No long-lived probe branches/PRs on product remotes without explicit policy |
| Profile | `hermes -p kevin` only for Kevin automation |

---

## Pre-wake (required before model)

### Unattended (default for this epic)

```bash
# From software-factory clone (scripts home):
export KEVIN_WAKE_ROOT=/absolute/path/to/product-worktree
export KEVIN_WAKE_PRIMARY_HINT=/absolute/path/to/product-primary   # optional safety
./scripts/factory-wake/kevin-pre-wake.sh
# exit 0 → may invoke continue; exit ≠ 0 → escalate once, do NOT re-drive
```

Wrapper forces worktree requirement and accepts `KEVIN_WAKE_*` or legacy `FACTORY_WAKE_*` env.

### Direct script (advanced)

```bash
export FACTORY_WAKE_ROOT=/absolute/path/to/product-worktree
export FACTORY_WAKE_REQUIRE_WORKTREE=1
export FACTORY_WAKE_PRIMARY_HINT=/absolute/path/to/product-primary
./scripts/factory-wake/pre-wake-project-check.sh || exit 1
```

Exit ≠ 0 → deliver status once; **do not** re-drive the same gate on a tight cron loop.

### Project decide (claimable judgment — after pre-wake)

Isolation is not enough: only drive continue when the project has a **claimable** unit and no escalate soft-check. Path of record: [kevin-controller.md](./kevin-controller.md).

```bash
export KEVIN_PROJECT_ROOT=/absolute/path/to/product-worktree
./scripts/kevin-controller.sh decide --json
# exit 0  → continue (claimable)
# exit 10 → idle (no NEXT — do not invent)
# exit 20 → escalate once; do not re-drive
```

---

## Gateway

```bash
hermes -p kevin gateway status
# Foreground (debug):
hermes -p kevin gateway run
# User service:
hermes -p kevin gateway install
hermes -p kevin gateway start
```

Cron jobs **do not fire** while the gateway is stopped. MVP ships the job **shape** even if
gateway remains operator-started later.

---

## Cron job template (claimable-only continue)

Prefer a **two-step** job: (1) pre-wake script as fail-closed gate, (2) agent prompt only if green.

### Option A — agent job with pre-wake in prompt (simple)

```bash
# Create a disposable worktree first, then:
WT=/absolute/path/to/product-worktree
SF=/absolute/path/to/software-factory

hermes -p kevin cron create "every 6h" \
  --name kevin-wake-continue \
  --workdir "$WT" \
  --deliver local \
  --skill continue \
  "$(cat <<EOF
You are Kevin unattended wake under Hermes profile kevin.

HARD RULES:
1. Run pre-wake first (if not already run by wrapper):
   KEVIN_WAKE_ROOT=$WT KEVIN_WAKE_REQUIRE_WORKTREE=1 $SF/scripts/factory-wake/kevin-pre-wake.sh
   If pre-wake fails: stop. Deliver failure once. Do NOT invent work. Do NOT re-drive.
2. Only claim a unit already named on disk (roadmap NEXT / in_progress / explicit issue).
3. Never invent NEXT from backlog scrape or fatigue.
4. On await_user / E-MERGE / escalate: deliver once; stop; do not tight-loop.
5. Approvals fail-closed — no YOLO for unattended.
6. Do not push/PR unless automation overlay explicitly allows; never force-push; never touch dirty primary.

If nothing claimable after pre-wake would have failed closed — idle cleanly.
EOF
)"
```

Pause until gateway is intentionally enabled:

```bash
hermes -p kevin cron pause <job-id>
hermes -p kevin cron list
```

### Option B — script-first watchdog (no model on red)

Use `--script` with a small host script that runs `kevin-pre-wake.sh` and prints `[SILENT]` or
failure text; only chain agent on green. Promote such a script under `scripts/factory-wake/` on
second use.

---

## Approvals (fail-closed)

| Setting | Unattended expectation |
|---------|------------------------|
| Interactive | `approvals.mode: manual` + deny floor (kevin profile) |
| Cron / unattended | Fail-closed — do **not** set YOLO / auto-approve shell for wake jobs |
| Integrate | Honor project merge policy vs automation always-PR overlay (one dialect) |

Verify profile:

```bash
hermes profile show kevin
# inspect ~/.hermes/profiles/kevin/config.yaml approvals:
```

---

## Claimable-only / invent refuse

- Pre-wake looks for **claimable signal** (NEXT / in_progress / roadmap) — still not authority to invent.  
- Continue skill hard-stops when path not established.  
- Empty claimable → **idle**, not “pick something.”  

---

## await_user / escalate (deliver once)

| Gate | Behavior |
|------|----------|
| await_user (plan, merge, triage) | Deliver once to configured channel/local; stop |
| E-MERGE / E-PATH / thrash | Same — no tight re-drive |
| Pre-wake fail | Status once; no model claim |

Disk evidence: worktree `session-state.md` + `.agent-tools/runs/events.ndjson`.

---

## No long-lived remote pollution

- Prefer local-only or short-lived branches for wake probes  
- Close PRs / delete branches when probe complete  
- Do not leave automation remotes on product main  

---

## Failure matrix

| Symptom | Cause | Recovery |
|---------|-------|----------|
| Pre-wake: not a worktree | REQUIRE_WORKTREE=1 on primary | Create linked worktree; set `KEVIN_WAKE_ROOT` |
| Pre-wake: no claimable signal | No NEXT / idle project | Idle; do not invent; set roadmap NEXT when ready |
| Pre-wake: dirty primary | ROOT equals PRIMARY_HINT and dirty | Use disposable worktree |
| Cron never fires | Gateway stopped | `hermes -p kevin gateway start` or `run` |
| Job uses wrong cwd | Missing `--workdir` | Recreate job with absolute worktree path |
| Invented work | Prompt/skills drifted | Fix prompt; compound process lesson; re-export pack if needed |
| Using `factory` profile | Legacy dogfood | Migrate to `kevin` |

---

## Dry-run verification (MVP evidence)

```bash
SF=/path/to/software-factory
# 1) Primary must FAIL unattended pre-wake:
KEVIN_WAKE_ROOT="$SF" "$SF/scripts/factory-wake/kevin-pre-wake.sh"; echo $?   # expect 1

# 2) Worktree must PASS (when project has claimable NEXT):
git -C "$SF" worktree add /tmp/kevin-wake-smoke main
KEVIN_WAKE_ROOT=/tmp/kevin-wake-smoke "$SF/scripts/factory-wake/kevin-pre-wake.sh"; echo $?  # expect 0
git -C "$SF" worktree remove /tmp/kevin-wake-smoke
```

Record results under [../evidence/kevin-unattended-wake/](../evidence/kevin-unattended-wake/).

---

## Out of scope

- Live Slack transport ([AGNT-8](https://linear.app/overlund-media/issue/AGNT-8))  
- Coding-loop re-gate ([AGNT-6](https://linear.app/overlund-media/issue/AGNT-6) already repo-class PASS)  
- Silent pull/setup on wake  
- Shell-out architecture  
- Personal default Hermes profile for Kevin  

---

## Residual (nice)

- Live gateway start + one `hermes -p kevin cron tick` / scheduled fire with deliver-once proof  
- Installed paused job on kevin profile  
