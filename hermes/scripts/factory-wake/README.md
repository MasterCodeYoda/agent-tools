# Kevin / factory wake scripts

**Purpose:** Host-side implementations of the portable pre-wake contract  
(`@workflow` / process pack: `workflow/references/pre-wake-checklist.md`).

**Kevin profile:** `hermes -p kevin` only. Directory name `factory-wake` is historical (J1-bis);
product language is **Kevin**.

**Process SoT:** agent-tools. **Do not** fork checklist semantics into one-off prompts only —
update agent-tools if the contract changes, then re-run setup.

## Layout

| Path | Role |
|------|------|
| `kevin-pre-wake.sh` | **Unattended default** — requires linked worktree (`REQUIRE_WORKTREE=1`) |
| `pre-wake-project-check.sh` | Core fail-closed project / cwd / claimable orientation check |
| (future) | Green-before-claim, PR hygiene — **promote on second use** |

## Env

| Variable | Alias | Meaning |
|----------|-------|---------|
| `KEVIN_WAKE_ROOT` | `FACTORY_WAKE_ROOT` | Repo root to check (default: cwd) |
| `KEVIN_WAKE_REQUIRE_WORKTREE` | `FACTORY_WAKE_REQUIRE_WORKTREE` | `1` = must be linked worktree |
| `KEVIN_WAKE_PRIMARY_HINT` | `FACTORY_WAKE_PRIMARY_HINT` | Primary checkout path for dirty-primary refuse |

`kevin-pre-wake.sh` defaults `REQUIRE_WORKTREE=1`. The bare project check defaults to `0`
(interactive dogfood).

## Usage

```bash
# Unattended (Kevin) — from software-factory, pointing at product worktree:
export KEVIN_WAKE_ROOT=/path/to/product-worktree
export KEVIN_WAKE_PRIMARY_HINT=/path/to/product-primary   # optional
./scripts/factory-wake/kevin-pre-wake.sh
echo $?   # 0 = ok to wake continue; non-zero = escalate / do not claim

# Interactive / relaxed (no worktree force):
./scripts/factory-wake/pre-wake-project-check.sh
```

Hermes cron / controller should run **kevin-pre-wake** (or project-check with
`REQUIRE_WORKTREE=1`) **before** invoking the model. Exit ≠ 0 → deliver status once; do not
re-drive the same gate.

Path of record: [docs/runbooks/kevin-unattended-wake.md](../../docs/runbooks/kevin-unattended-wake.md)

## Promote-on-second-use

First time: exploratory shell in session. Second time the same deterministic check recurs:
add a named script here. Skills describe *how*; scripts *do*.
