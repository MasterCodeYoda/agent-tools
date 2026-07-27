---
name: kevin-profile-config-as-code
description: Ship Kevin Hermes profile as native distribution under hermes/profile; apply via install + skills-path substitute
type: pattern
applicability: project
related:
  - hermes/profile/
  - scripts/apply-kevin-profile.sh
  - docs/runbooks/hermes-kevin.md
  - docs/decisions/001-hermes-provisional-factory-host.md
  - r-20260724-1
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin profile config-as-code (Hermes distribution)

## Why

Custom YAML merge scripts reinvent what Hermes already does: `profile install` / `update`
preserve user-owned paths (`.env`, `auth.json`, sessions, memories). E1 is host **binding**,
not process IP.

## How to apply

1. Author `hermes/profile/` as a distribution root: `distribution.yaml` (`name: kevin`),
   `config.yaml`, `SOUL.md`, `.env.template`, empty `skills/`, `.no-bundled-skills`.
2. Keep `config.yaml` **versioned** (policy only). Ignore only real secrets (`.env`).
3. Use `skills.external_dirs: [__HERMES_SKILLS_DIR__]` in git; substitute absolute
   `$HOME/.hermes/skills` **after** install on the installed file (not temp staging as
   install source — temp breaks `profile update` source tracking).
4. Apply: `./scripts/apply-kevin-profile.sh` (fail loud if managed skills dir missing).
5. Never auto-delete legacy `factory` profile; migrate docs only.

## Gotchas

- Installing from `mktemp` stages records a disposable source — always install from the
  stable repo path.
- Raw `hermes profile install` without the wrapper leaves the skills placeholder unexpanded.
- `hermes profile list` table is awkward to parse; use `hermes profile show kevin` for exists checks.
