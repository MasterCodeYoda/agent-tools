# AGNT-7 MVP dry-run evidence

**Date:** 2026-07-24  
**Host:** macOS · Hermes profile `kevin`  
**Scripts:** `scripts/factory-wake/kevin-pre-wake.sh`

## Results

| Case | Command | Exit | Notes |
|------|---------|------|-------|
| Primary (unattended) | `KEVIN_WAKE_ROOT=$SF ./scripts/factory-wake/kevin-pre-wake.sh` | **1** | FAIL: not a linked worktree (expected) |
| Disposable worktree | `KEVIN_WAKE_ROOT=/tmp/kevin-wake-smoke …` | **0** | OK: planning root + claimable signal; worktree=1 |

## Gateway / cron snapshot

| Check | Result |
|-------|--------|
| `hermes -p kevin gateway status` | not running (MVP residual — live tick nice) |
| `hermes -p kevin cron list` | no jobs (template in runbook; not auto-installed) |

## Verdict

**MVP path proven for isolation pre-wake.** Live gateway fire remains residual (operator enable).

## Logs (abridged)

### Primary fail

```text
KEVIN-PRE-WAKE: root=…/software-factory require_worktree=1
PRE-WAKE FAIL: … is not a linked worktree (.git file)
```

### Worktree pass

```text
KEVIN-PRE-WAKE: root=/tmp/kevin-wake-smoke require_worktree=1
PRE-WAKE OK: planning root: …/.agent-tools/planning
PRE-WAKE OK: claimable signal present
PRE-WAKE OK: root=/tmp/kevin-wake-smoke worktree=1
```
