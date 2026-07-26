---
name: profile-skill-bindings-track-published-names
description: Profile channel/skill bindings must match published skill directory names after renames
type: gotcha
applicability: project
related:
  - hermes/profile/config.yaml
  - tools/publish-skills.sh
  - run_id:r-20260726-1
incident_date: null
job_phases: [review, execute]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Profile skill bindings must track published names

## Why

Hermes profile configs (and Slack `channel_skill_bindings`) name skills by **directory id**
as published into `dist/<agent>/skills/`. When the corpus renames a family (`workflow` →
`work`, `workflow-continue` → `work-continue`), code and SKILL.md can be correct while the
**profile still binds old ids**. Channel routing and “available skills” then silently miss.

AGNT-11 review found this lag after the work-family rename.

## How to apply

1. After any skill **directory rename** or publish-agent rekey, grep profile trees:
   `hermes/profile/**`, packs, and any `channel_skill_bindings` / `external_dirs` docs.
2. Diff binding names against `ls dist/hermes/skills` (or the target agent’s dist).
3. Treat mismatch as a **review lens** on packaging PRs — not only a docs find-replace.
4. Prefer fail-closed checks in install paths when a required profile cannot be shown after
   soft CLI-flag fallbacks (`|| true` install variants still need a hard post-condition).
