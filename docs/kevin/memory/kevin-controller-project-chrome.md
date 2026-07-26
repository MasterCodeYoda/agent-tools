---
name: kevin-controller-project-chrome
description: Project chrome + judgment is kevin-controller.sh (status|decide); exit 0/10/20; never invent NEXT; dashboard stays KEVN-4 substrate
type: lesson
applicability: project
related:
  - docs/runbooks/kevin-controller.md
  - scripts/kevin-controller.sh
  - KEVN-10
  - run_id:r-20260724-10
incident_date: null
job_phases: [continue, pre-wake]
promoted_at: null
promoted_to: null
source_harness: grok
---

# Kevin controller / project chrome

## Why

KEVN-4 dashboard covers models/usage. Operators and unattended wake still need a **disk lens** for phase/yield and a **claimable-only** continue|escalate|idle decision without inventing NEXT.

## How to apply

- Path of record: `docs/runbooks/kevin-controller.md`
- CLI: `./scripts/kevin-controller.sh status|decide`
- Exit codes: `0` continue · `10` idle · `20` escalate · `2` error
- Unattended: pre-wake (isolation) **then** `decide` (claimable) before model continue
- Never write project state from the controller; never invent NEXT on idle
- Capacity/windows remain best-available via control plane, not project files
