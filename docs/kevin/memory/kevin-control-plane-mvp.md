---
name: kevin-control-plane-mvp
description: Kevin control plane MVP = Hermes dashboard --isolated + policy pack + sync story (not custom app)
type: pattern
applicability: project
related:
  - scripts/kevin-control-plane.sh
  - docs/runbooks/kevin-control-plane.md
  - packs/kevin-model-hierarchy.md
  - r-20260724-3
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin control plane MVP (Hermes wrap)

## Why

ADR prefers Hermes dashboard as substrate. Custom chrome is KEVN-10. MVP is launch path + hierarchy policy + honest gaps.

## How to apply

1. `./scripts/kevin-control-plane.sh` → `hermes -p kevin dashboard --isolated`
2. Hierarchy: `packs/kevin-model-hierarchy.md` + `hermes/profile/config.yaml`
3. Usage windows: provider deep-links (Claude console explicit)
4. Sync: git SoT → apply script; UI overrides local only
