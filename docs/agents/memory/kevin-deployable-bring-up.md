---
name: kevin-deployable-bring-up
description: E4 path of record is hermes-kevin runbook + hard readiness check; soft doctor gaps ≠ fail
type: pattern
applicability: project
related:
  - docs/runbooks/hermes-kevin.md
  - scripts/kevin-bring-up-check.sh
  - scripts/apply-kevin-profile.sh
  - r-20260724-4
promoted_at: null
promoted_to: null
source_harness: factory
---

# Kevin deployable bring-up (E4)

## Why

E1–E3 shipped pieces (profile apply, process pack, control plane) but operators still needed a
**single ordered path** from install to worktree orientation. Doctor “green forever” is the wrong
bar — missing `.env`/keys is expected until the operator fills secrets.

## How to apply

1. Path of record: `docs/runbooks/hermes-kevin.md` § Bring-up (E4).
2. Sequence: install Hermes → agent-tools `./setup.sh` → `./scripts/apply-kevin-profile.sh` →
   doctor readiness bar → secrets → isolated SF worktree smoke (status/orientation, not coding-loop PASS).
3. Hard check assist: `./scripts/kevin-bring-up-check.sh` (exit 0 = hard bar; WARN = soft auth).
4. Never reintroduce `factory` as Kevin path of record; control plane is optional after base smoke.
5. Defer unattended wake (AGNT-7) and coding confidence (AGNT-6).

## Gotchas

- Raw `hermes profile install` leaves `__HERMES_SKILLS_DIR__` unexpanded — always prefer the apply wrapper.
- Doctor exit non-zero for advisories is still OK if the doctor command ran and hard checks pass.
