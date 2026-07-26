---
name: kevin-coding-loop-confidence-pass
description: KEVN-6 PASS repo-class — hermes -p kevin tracers vs Grok baseline; scorecard SoT
type: lesson
applicability: project
related:
  - docs/runbooks/kevin-coding-confidence.md
  - docs/evidence/kevin-coding-confidence/scorecard.md
  - docs/decisions/001-hermes-provisional-factory-host.md
  - r-20260724-5
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin coding-loop confidence PASS (repo class)

## Why

ADR-001 required a real implement gate before trusting Hermes as the coding host.
Packaging (E1–E4) is not that gate. KEVN-6 ran three direct-loop tracers on
`hermes -p kevin` and scored them against the operator’s daily harness band.

## How to apply

1. Protocol: `docs/runbooks/kevin-coding-confidence.md`
2. Evidence: `docs/evidence/kevin-coding-confidence/scorecard.md`
3. Tracers must use **kevin** direct loop — shell-out is fail path C only.
4. **PASS (2026-07-24)** covers project docs/scripts class on software-factory worktree.
5. Large multi-layer product-app loops (Spectral-class) remain optional residual — re-run gate if that bar becomes required.
6. KEVN-7 may use implement automation with isolation, but still owns wake/pre-wake DoD.

## Gotchas

- Hermes may attempt `/tmp` verify scripts that host policy refuses — task can still pass if DoD is met.
- Do not declare PASS from doctor/skills alone.
