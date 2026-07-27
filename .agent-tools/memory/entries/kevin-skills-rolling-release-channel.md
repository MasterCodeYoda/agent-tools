---
name: kevin-skills-rolling-release-channel
description: Publish dist/hermes as rolling GH Release tag kevin-skills for stable public URL
type: pattern
applicability: project
related:
  - docs/agents/runbooks/kevin-skills-dist.md
  - .github/workflows/kevin-skills-dist.yml
  - docs/agents/decisions/004-workstation-cli-and-skills-distribution.md
  - run_id:r-20260726-2
incident_date: null
job_phases: [plan, execute]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Kevin skills: rolling Release channel

## Why

Workstation Kevin needs a **stable anonymous download URL** for process skills without
cloning the monorepo. GitHub Actions artifacts expire and need auth; semver Releases per
commit are theater. A **mutable tag** `kevin-skills` updated on each green `main` pack
gives one stable URL while the monorepo remains SoT.

## How to apply

1. Pack with `tools/pack-kevin-skills.sh` (dialect hermes → product kevin stamp → tar + sha256 + manifest).
2. CI: `.github/workflows/kevin-skills-dist.yml` upserts release assets.
3. Revision: `publish-agent=kevin`, `render-dialect=hermes` (ADR-005) — not host-named product.
3. Install interim: `tools/install-kevin-skills.sh --from-url` → `~/.kevin/skills` (copy).
4. Do **not** document `setup.sh` → `~/.hermes/skills` as the Kevin product path.
