# Kevin coding-loop confidence — scorecard

**Gate:** [AGNT-6](https://linear.app/overlund-media/issue/AGNT-6)  
**Protocol:** [../../runbooks/kevin-coding-confidence.md](../../runbooks/kevin-coding-confidence.md)  
**Date:** 2026-07-24  
**Host:** Hermes profile `kevin` · model `claude-sonnet-4-5` / anthropic  
**Worktree:** `/Users/matthew.overlund/Source/OMG/software-factory-kevin-e5`  
**Branch:** `feat/AGNT-6-coding-loop-confidence-wt`

## Baseline (daily harness)

| Field | Value |
|-------|--------|
| Harness | Grok Build (primary daily) |
| Model class | Sonnet-class (matches kevin execute default) |
| Typical task | Multi-file docs/scripts implement with review |
| Band (turns) | **4** |
| Band (wall time) | **4** |
| Band (rework) | **4** |
| Band (thrash) | **4** |
| Notes | AGNT-2..5 sessions: process-fidelity strong on project docs/scripts |

## Tracers

| ID | Shape | Task | Status | Turns | Time | Rework | Thrash | Within ±1? | Notes |
|----|-------|------|--------|-------|------|--------|--------|------------|-------|
| T1 | Bug fix | Detect unexpanded `__HERMES_SKILLS_DIR__` in installed kevin config | **done** | 5 | 4 | 5 | 4 | **yes** | ~83s; commit `92ab157`; hermes tried /tmp verify write (refused) — minor thrash, DoD met |
| T2 | Multi-file | Wire gate into handoff + hermes README + kevin runbook | **done** | 5 | 5 | 5 | 5 | **yes** | ~49s; commit `67227e8`; 3 files exact |
| T3 | Recovery | Remove intentional bogus hard-fail; keep T1 check | **done** | 5 | 4 | 5 | 4 | **yes** | ~83s; commit `a94da68`; fault injection `e42ab40` then recovery |

### T1 detail

- **DoD:** Script fails if installed config still has placeholder; remediation points at apply wrapper.  
- **Commit:** `92ab157`  
- **Evidence:** `/tmp/kevin-t1.log`

### T2 detail

- **DoD:** Links from handoff, hermes README, hermes-kevin Related.  
- **Commit:** `67227e8`  
- **Evidence:** `/tmp/kevin-t2.log`

### T3 detail

- **Setup:** Intentional fault commit `e42ab40` (bogus required file).  
- **DoD:** Fault removed; T1 preserved; check exits 0.  
- **Commit:** `a94da68`  
- **Evidence:** `/tmp/kevin-t3.log`

## Verdict

| Field | Value |
|-------|--------|
| **Result** | **PASS** |
| **Completed tracers** | 3 / 3 |
| **Fail path (if FAIL)** | — |
| **AGNT-7 implement trust** | **Unblocked for implement-class work on project/docs/scripts** — still require pre-wake isolation for unattended wake epic itself |
| **Caveat** | Tracers were **software-factory system** (scripts/docs), not Spectral/Wildwood app code. Equitable band proven for this class; large multi-layer product-app loops remain a residual risk if ops demand that bar later. |
| **Signed** | 2026-07-24 operator session via hermes -p kevin + Grok Build continue |

## Session log pointers

| Tracer | Hermes evidence |
|--------|-----------------|
| T1 | `/tmp/kevin-t1.log` · commit 92ab157 |
| T2 | `/tmp/kevin-t2.log` · commit 67227e8 |
| T3 | `/tmp/kevin-t3.log` · commits e42ab40 → a94da68 |
