# Roadmap: Workstation Kevin dogfood

Status: Active  
Updated: 2026-07-26

## Destination

Workstation Kevin is the **capability dogfood path of record**: install a `kevin` CLI without cloning the monorepo, pull process skills from a **published `dist/hermes` artifact**, bind profile `kevin` to a **Kevin skills root** (not multi-agent `~/.hermes/skills`), and run coding sessions against a **single project git repo**. Isolated Kevin (`kevin-hermes`) stays real capital but is not the dogfood gate.

## Streams / order

Notation: `→` sequential · `∥` (or `||`) parallelizable · `{A ∥ B}` wave · `⚠ A ∥ B` collision watch

| # | Unit | Status | Purpose |
|---|------|--------|---------|
| — | **AGNT-11** packaging capital | Done | Monorepo + image + SF retire |
| 1 | **AGNT-13** Skills dist artifact | Done (local) | CI pack of `dist/hermes` + revision/manifest; stable fetch URL for CLI — live after push to main |
| 2 | **AGNT-12** Workstation CLI + host bootstrap | Done (local) | PATH `kevin`: setup/update/doctor/start; Hermes + profile; skills from artifact; project root |
| 3 | **AGNT-14** Isolated clean-room / remote DX | Backlog | Provision & sandbox DX for image mode — not dogfood path |

**Order line:**

```text
AGNT-11 (done) → AGNT-13 (done) → AGNT-12 (done) → AGNT-14
```

**⚠ collision watch (not a launch package):** AGNT-12 ∥ AGNT-13 share skills-root path, revision shape, and profile `external_dirs` — sequential reduces thrash.

## NEXT

**AGNT-14** — Isolated Kevin: clean-room provision and remote DX (backlog; not dogfood gate)

Workstation dogfood path is live locally (`kevin setup` / `kevin doctor` / `kevin start`).

## Out of scope

- Reopening AGNT-11 packaging / SF migration
- git-cliff / semver / GH Releases as product versioning (ADR-002)
- Treating Docker / Isolated as the dogfood gate (ADR-003)
- Process-skill corpus evolution (`/skills:evolve`) as a roadmap unit
- Slack live / unattended wake re-home (already Done; residual only if broken)
- Multi-agent `setup.sh` redesign beyond “Kevin consumers leave `~/.hermes/skills`” (ADR-004 when CLI is live)

## Notes

- PM: Linear team **Agent Tools** (`AGNT`); project *Kevin v1 — Hermes factory foundation*
- Decisions: [ADR-003](../docs/kevin/decisions/003-workstation-vs-isolated-kevin.md), [ADR-004](../docs/kevin/decisions/004-workstation-cli-and-skills-distribution.md)
- AGNT-14 after workstation dogfood is underway — not blocking CLI/artifact
- Continue: claim **AGNT-14** only when isolated provision is intentional; otherwise dogfood workstation
