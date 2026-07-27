# Roadmap: Workstation Kevin dogfood

Status: Active  
Updated: 2026-07-27

## Destination

Workstation Kevin is the **capability dogfood path of record**: install a `kevin` CLI without cloning the monorepo, pull process skills from a **published `dist/hermes` artifact**, bind profile `kevin` to a **Kevin skills root** (not multi-agent `~/.hermes/skills`), and run coding sessions against a **single project git repo**. Isolated Kevin (`kevin-hermes`) stays real capital but is not the dogfood gate.

## Streams / order

Notation: `→` sequential · `∥` (or `||`) parallelizable · `{A ∥ B}` wave · `⚠ A ∥ B` collision watch

| # | Unit | Status | Purpose |
|---|------|--------|---------|
| — | **AGNT-11** packaging capital | Done | Monorepo + image + SF retire |
| 1 | **AGNT-13** Skills dist artifact | Done (live) | Rolling release `kevin-skills`; CI pack on main |
| 2 | **AGNT-12** Workstation CLI + host bootstrap | Done (live) | PATH `kevin`: setup/update/doctor/start + channel stale check |
| — | **runs-ledger-capture-envelope** | Done (live) | process_payload v2 identity envelope; capture early |
| 3 | **AGNT-14** Isolated clean-room / remote DX | Backlog | Provision & sandbox DX for image mode — not dogfood path |

**Order line:**

```text
AGNT-11 (done) → AGNT-13 (done) → AGNT-12 (done) → dogfood workstation → AGNT-14 (when intentional)
```

**⚠ collision watch (not a launch package):** AGNT-12 ∥ AGNT-13 share skills-root path, revision shape, and profile `external_dirs` — sequential reduced thrash (both shipped).

## NEXT

**No packaging unit claim required.** Prefer **Workstation Kevin dogfood** on a product repo (`kevin doctor` / `kevin` / `/work:continue` with identity envelope).

**AGNT-14** — Isolated clean-room / remote DX remains backlog (not the dogfood gate). Claim only when isolation work is intentional.

## Out of scope

- Reopening AGNT-11 packaging / SF migration
- git-cliff / semver / GH Releases as product versioning (ADR-002)
- Treating Docker / Isolated as the dogfood gate (ADR-003)
- Process-skill corpus evolution (`/skills:evolve`) as a roadmap unit
- Slack live / unattended wake re-home (already Done; residual only if broken)
- Multi-agent `setup.sh` redesign beyond “Kevin consumers leave `~/.hermes/skills`” (ADR-004 when CLI is live)

## Notes

- PM: Linear team **Agent Tools** (`AGNT`); project *Kevin v1 — Hermes factory foundation*
- Decisions: [ADR-003](../docs/agents/decisions/003-workstation-vs-isolated-kevin.md), [ADR-004](../docs/agents/decisions/004-workstation-cli-and-skills-distribution.md)
- Live channel verified 2026-07-27: release `git_sha` matches `~/.kevin/skills` after `kevin update` (tip `02d0e57…`)
- CLI install remains checkout/`install-kevin-cli.sh` (not in skills tarball)
- Per-unit `planning/*/session-state.md` dirs are done; no open `in_progress` claim
- Continue: do **not** invent NEXT as AGNT-14 unless user names isolation work