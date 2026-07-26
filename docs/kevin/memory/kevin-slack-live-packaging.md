---
name: kevin-slack-live-packaging
description: Kevin Slack is kevin-named packs + kevin-slack-live runbook; factory packs are historical; live smoke residual is OK without tokens
type: lesson
applicability: project
related:
  - docs/runbooks/kevin-slack-live.md
  - packs/kevin-slack-setup.md
  - AGNT-8
  - run_id:2026-07-24-mxn3k-kevn-8-9
incident_date: null
job_phases: [continue, execute]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Kevin Slack live packaging

## Why

H3 already shipped **factory** Slack packaging. Kevin must not rebrand as `factory`. Live Socket Mode needs a **kevin** path of record, hard allowlists, and an honest residual when tokens are missing.

## How to apply

- Path of record: `docs/runbooks/kevin-slack-live.md`
- Packs: `packs/kevin-slack.{env.example,manifest.json}` + `kevin-slack-setup.md`
- Profile: `hermes -p kevin` gateway; `platform_toolsets.slack` + channel binding placeholders in `hermes/profile/config.yaml`
- Keep `packs/factory-slack-*` as historical dogfood; do not treat them as Kevin SoT
- AC7 live smoke: tick residual if no tokens; never invent PASS
- After pull: `./scripts/apply-kevin-profile.sh --force -y` before live gateway smoke
