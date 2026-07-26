---
name: kevin-auth-packaging
description: Portable Kevin auth is names-only templates + kevin-auth-packaging runbook; API keys and OAuth; never commit or blind-overwrite live .env
type: lesson
applicability: project
related:
  - docs/runbooks/kevin-auth-packaging.md
  - hermes/profile/.env.template
  - KEVN-9
  - run_id:2026-07-24-mxn3k-kevn-8-9
incident_date: null
job_phases: [continue, execute]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Kevin auth packaging

## Why

Bring-up failed as a snowflake when secrets lived only in one operator's head. Teammates need a **names-only** inventory and dual path (API key vs OAuth) without secrets in git.

## How to apply

- Path of record: `docs/runbooks/kevin-auth-packaging.md`
- Repo: `hermes/profile/.env.template` + `distribution.yaml` `env_requires` (all `required: false`)
- Live: `~/.hermes/profiles/kevin/.env` and/or `auth.json` — never commit values
- Path A: API keys in `.env`; Path B: `hermes -p kevin auth …` OAuth / subscription-style
- Guardrails: never copy secrets into the repo; never blind-script-overwrite live `.env` (apply preserves user-owned paths)
- Slack secret **names** cross-ref KEVN-8 / `packs/kevin-slack.env.example` — do not duplicate Slack packaging here
- Link from `hermes-kevin.md` and `kevin-control-plane.md`; do not maintain a second drifting secret matrix
