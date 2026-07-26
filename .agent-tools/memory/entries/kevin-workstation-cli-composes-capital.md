---
name: kevin-workstation-cli-composes-capital
description: Product kevin CLI composes skills install + Hermes profile install; owns PATH name over thin alias
type: pattern
applicability: project
related:
  - docs/kevin/runbooks/kevin-workstation-cli.md
  - docs/kevin/decisions/004-workstation-cli-and-skills-distribution.md
  - tools/kevin/kevin
  - tools/install-kevin-cli.sh
  - run_id:r-20260726-3
incident_date: null
job_phases: [plan, execute]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Kevin workstation CLI composes capital

## Why

Workstation bootstrap looks large until you inventory existing pieces: skills pack/install
(AGNT-13), Hermes `profile install` + placeholder substitution, upstream Hermes binary.
The product gap is a **PATH-owned multi-command surface** (`setup` / `update` / `doctor` /
`start`) and **correct skills root binding** (`~/.kevin/skills`), not a second package
manager. Hermes `--alias` creates a thin `kevin` → `hermes -p kevin` that **collides** with
the product CLI name — never treat that alias as product setup.

## How to apply

1. Install CLI: `tools/install-kevin-cli.sh` → `$PREFIX/bin/kevin` + share profile + skills installer.
2. Bootstrap: `kevin setup` (or `--from-file` local pack) → skills root + staged profile + substitute `external_dirs`.
3. Do **not** pass Hermes `--alias` from product setup; reinstall product `kevin` last if clobbered.
4. Doctor hard bar: hermes, profile, skills revision, no placeholder, git project root; auth is soft.
5. Session: `cd <repo> && kevin` → `hermes -p kevin` with cwd as home.

## Gotchas

- Nested profile path (`hermes/profile/`) cannot be installed via bare monorepo git URL — **stage a profile bundle** with the CLI.
- Prefer packaging sources when re-staging so `~/.kevin/profile-src` does not stay stale after share updates.
