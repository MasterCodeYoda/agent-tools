---
name: gumclaw-ops-import-split-ip
description: GumClaw patterns map to factory via split IP — process in agent-tools, wake/host in factory
type: process
applicability: project
related:
  - docs/research-gumclaw-how-i-work.md
  - docs/process-ip-wave5.md
  - .agent-tools/planning/gumclaw-ops-import/plan.md
  - docs/decisions/001-hermes-provisional-factory-host.md
promoted_at: null
promoted_to: null
source_harness: factory
---

# GumClaw ops import — split IP

## Why

GumClaw proves Hermes + cron + disk policy + script accretion ships real work. Stealing patterns without IP placement either forks process dialect into the factory host or buries portable project behavior in Hermes-only config.

## How to apply

1. **Portable project behavior** is in agent-tools Wave 5 (landed 2026-07-23): `approval-boundaries.md`, `pre-wake-checklist.md`, compound `dated-rule.md`, runs `ESCALATE`/`HUMAN_VETO`. Re-export pack after evolve.  
2. **Host wake** → factory `scripts/factory-wake/`, runbook Wave 5 section, Hermes profile/SOUL bind; J1-bis still residual.  
3. **Never** turn on Hermes MEMORY as project-disk SoT; never auto-mutate process pack from cron.  
4. Pre-wake exit ≠ 0 → hard_stop / idle; do not invent NEXT.  
5. Reject multi-domain employee scope; product stays project-bound software factory.

## See also

- Plan work packages WP-A…F in `.agent-tools/planning/gumclaw-ops-import/plan.md`
