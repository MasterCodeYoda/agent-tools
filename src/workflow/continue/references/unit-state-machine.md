# Unit phase state machine

**Load when:** portfolio router selected **unit** mode and a single claimable unit is claimed.

Replaces the old “walk the stage table top-to-bottom once.” The happy path is still one
continuous advance; **cycles are legal** when evidence guards pass.

## Loop

```text
classify(state from disk) →
  if await_user / blocked / done → stop (recap rules in gates.md) →
  else select enabled transition (guards) →
  invoke phase skill →
  record phase-return event (phase-return.md) →
  re-classify → repeat until stop gate
```

Do **not** invent transitions without evidence. Agent judgment alone is not a guard.

## States (default feature track)

| State | Meaning (disk signals) |
|-------|------------------------|
| `fuzzy` | Direction unchosen; idea still open |
| `needs_refine` | Direction chosen (incl. roadmap one-liner); requirements weak/missing/stale vs decision |
| `needs_plan` | Requirements clear & current; no approved implementation plan |
| `ready_execute` | Plan approved; work not started or mid-plan with remaining tasks |
| `needs_review` | Code exists for the slice; no valid review evidence yet (or review invalidated) |
| `needs_integrate` | Reviewed clean (valid evidence); not merged/integrated |
| `needs_compound` | Integrated/merged; neither compound capture nor `compound: none` |
| `done` | Integrated + compound disposition recorded |
| `await_user` | HITL gate (plan approval, merge confirm, triage, path choice, thrash bound) |
| `blocked` | Off-band blocker; cannot advance without external input |

**Non-feature tracks:** if `planning/conventions.md` assigns a track with its own process doc,
follow that doc’s states/gates instead of this table — same loop shape (classify → act →
re-classify).

## Classify (artifact + decision)

Read, in order of authority:

1. Governing decisions (ADRs / domain docs / PM decision fields the unit realizes)
2. `requirements.md` or PM issue ACs (file vs PM mode — `@workflow`)
3. `implementation-plan.md` + session-state approval signals
4. Branch / commits / worktree for this unit
5. Review evidence line (schema in `gates.md`)
6. Merge/integration evidence; compound note

**Skip-by-default** for brainstorm/refine only when the existing artifact is **consistent with
the current governing decision**. If the decision moved (stale phasing, renamed vendor with old
ceremony, ACs the decision no longer supports) → `needs_refine` (resize mode) even if a long
requirements doc exists. The most-detailed written artifact is not the authority; the current
decision is.

**Missing planning dir** for a named unit → usually `needs_refine` (shell is phase output).

## Events (from phase-return + soft-checks)

| Event | Typical source |
|-------|----------------|
| `DIRECTION_UNCLEAR` | classify / brainstorm stop |
| `DIRECTION_CHOSEN` | brainstorm converge / roadmap one-liner |
| `REQUIREMENTS_READY` | refine complete, ACs current |
| `REQUIREMENTS_STALE` | decision moved vs requirements |
| `PLAN_DRAFTED` | plan skill presenting approval |
| `PLAN_APPROVED` | user approved plan |
| `PLAN_REVISE` | user requested revise |
| `CODE_PROGRESSED` | execute made commits / task progress |
| `EXECUTE_GAP` | AC/plan gap, scope invalid mid-execute |
| `CODE_READY_FOR_REVIEW` | execute done or enough code for review gate |
| `REVIEW_CLEAN` | review pass + valid evidence, findings fixed per policy |
| `REVIEW_FINDINGS_CODE` | findings fixable in code |
| `REVIEW_FINDINGS_STRUCTURAL` | findings need plan/requirements change |
| `MERGED` | integrate complete |
| `COMPOUND_DONE` | compound or `compound: none` recorded |
| `USER_GATE` | any HITL stop |
| `THRASH_BOUND` | too many refine re-entries this unit (see bound) |

## Transitions (guards required)

| From | Event / guard | To | Invoke |
|------|---------------|-----|--------|
| `fuzzy` | direction unchosen | `await_user` or run brainstorm | `/workflow:brainstorm` (this unit only) |
| `fuzzy` | `DIRECTION_CHOSEN` | `needs_refine` | — |
| `needs_refine` | — | (run) | `/workflow:refine` (creates shell as needed) |
| `needs_refine` | `REQUIREMENTS_READY` | `needs_plan` | — |
| `needs_plan` | — | (run) | `/workflow:plan` |
| `needs_plan` | `PLAN_DRAFTED` | `await_user` | plan approval prompt only (no recap) |
| `needs_plan` | `PLAN_APPROVED` | `ready_execute` | — |
| `ready_execute` | — | (run) | `/workflow:execute` |
| `ready_execute` | `EXECUTE_GAP` + requirements/decision issue | `needs_refine` | re-refine (resize) |
| `ready_execute` | `EXECUTE_GAP` + plan structure only | `needs_plan` | re-plan |
| `ready_execute` | `CODE_READY_FOR_REVIEW` | `needs_review` | — |
| `needs_review` | — | (run) | `/workflow:review` (or equivalent) |
| `needs_review` | `REVIEW_FINDINGS_CODE` | `ready_execute` | fix, then re-review |
| `needs_review` | `REVIEW_FINDINGS_STRUCTURAL` | `needs_plan` or `needs_refine` | evidence-based |
| `needs_review` | `REVIEW_CLEAN` | `needs_integrate` | — |
| `needs_integrate` | merge needs confirm (default) | `await_user` | finish-branch confirm |
| `needs_integrate` | autonomous merge preconditions all true | (merge) → `needs_compound` | finish-branch |
| `needs_compound` | — | (run) | `/workflow:compound` or record skip |
| `needs_compound` | `COMPOUND_DONE` | `done` | update handoff pointer |
| any | soft-check theater review / missing compound on *prior* slice | fix first | see soft-checks.md |
| any | `THRASH_BOUND` | `await_user` | diagnose; do not silent-loop |

**Hard refuse (no transition):**

- `needs_review` / `ready_execute` → merge without valid review evidence
- gates-green alone → `REVIEW_CLEAN`
- invent `review: clean` theater
- push / open PR unless project push policy explicitly allows (never production promotion)

## Thrash bound

If the unit re-enters `needs_refine` or `needs_plan` from execute/review **more than 2 times**
in one `/continue` invocation (or without new external decision evidence), emit `THRASH_BOUND`
→ `await_user` with a short diagnosis (what oscillated, what evidence is missing). Do not
infinite re-plan.

## Multi-stream / horizon-only

If the “unit” is actually multi-stream with no single claimable scope → stop + offer
`/workflow:roadmap`. Do not invent streams inside the unit machine.

## Relationship to old stage table

Each old “Current state → Next phase” row is a **classify → primary transition** pair. The
machine adds explicit **backward** edges the table only implied (stale decision, structural
review findings, execute gaps).
