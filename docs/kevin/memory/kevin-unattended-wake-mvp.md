---
name: kevin-unattended-wake-mvp
description: KEVN-7 MVP — kevin-pre-wake requires worktree; cron template; live gateway residual
type: pattern
applicability: project
related:
  - docs/runbooks/kevin-unattended-wake.md
  - scripts/factory-wake/kevin-pre-wake.sh
  - docs/evidence/kevin-unattended-wake/mvp-dry-run.md
  - r-20260724-6
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin unattended wake MVP

## Why

J1-bis proved substrate research only. Unattended implement on a dirty primary is the
failure mode. Kevin needs a product path: profile **kevin**, worktree-required pre-wake,
claimable-only continue, deliver-once on escalate.

## How to apply

1. Path of record: `docs/runbooks/kevin-unattended-wake.md`
2. Before any unattended model: `./scripts/factory-wake/kevin-pre-wake.sh` with
   `KEVIN_WAKE_ROOT` = linked worktree (defaults REQUIRE_WORKTREE=1)
3. Cron: `--workdir` absolute worktree; never primary dirty checkout
4. Live gateway tick is residual — path can ship without gateway running
5. Env synonyms: `KEVIN_WAKE_*` preferred; `FACTORY_WAKE_*` still accepted

## Gotchas

- Pre-wake claimable signal is not license to invent NEXT — continue still refuses invent.
- Do not re-drive await_user / pre-wake fail on a tight cron loop.
