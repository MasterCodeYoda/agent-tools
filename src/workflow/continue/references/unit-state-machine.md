# Unit phase state machine

**Load when:** portfolio router selected **unit** mode and a single claimable unit is claimed.

Replaces the old “walk the stage table top-to-bottom once.” The happy path is still one
continuous advance; **cycles are legal** when evidence guards pass.

**Also load:** @workflow `references/tracks.md` (track classification), `references/planning-root.md`
(path root), `phase-return.md` (runs append).

## Loop

```text
classify track → classify state (disk + decisions) →
  if await_user / blocked / done → stop (recap rules in gates.md) →
  else select enabled transition (guards) →
  invoke phase skill →
  record phase-return event (phase-return.md) + append runs event →
  re-classify → repeat until stop gate
```

Do **not** invent transitions without evidence. Agent judgment alone is not a guard.

## Track first

Before the feature state table, classify **track** (`feature` | `micro` | `research` | custom
from conventions) per `references/tracks.md`. User flags win. Record `track:` on session-state
when set.

- **micro** → micro process in tracks.md (direct-issue execute; skip refine/plan shells).
- **research** → research process in tracks.md (conclusion deliverable; not-done signals).
- **feature** → states/transitions below.
- **Custom** → conventions process doc overrides the feature table for that unit.

Named unit without planning shell: **micro** if micro rules match; else usually `needs_refine`
(shell is phase output) — **not** automatic full refine when the issue is already the plan.

## States (feature track)

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

## Classify (artifact + decision)

Read, in order of authority:

1. Track classification (tracks.md) + conventions overrides
2. Governing decisions (ADRs / domain docs / PM decision fields the unit realizes)
3. `requirements.md` or PM issue ACs (file vs PM mode — `@workflow`)
4. `implementation-plan.md` + session-state approval signals (feature; micro uses issue-as-plan)
5. Branch / commits / worktree for this unit
6. Review evidence line (schema in `gates.md`)
7. Merge/integration evidence; compound note

**Skip-by-default** for brainstorm/refine only when the existing artifact is **consistent with
the current governing decision**. If the decision moved (stale phasing, renamed vendor with old
ceremony, ACs the decision no longer supports) → `needs_refine` (resize mode) even if a long
requirements doc exists. The most-detailed written artifact is not the authority; the current
decision is.

**Missing planning dir** for a named unit → micro if eligible; else usually `needs_refine`.

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
| `needs_plan` | `PLAN_APPROVED` | `ready_execute` | — (same-session execute next; no emit-and-stop default) |
| `ready_execute` | — | (run) | `/workflow:execute` |
| `ready_execute` | `EXECUTE_GAP` + requirements/decision issue | `needs_refine` | re-refine (resize) |
| `ready_execute` | `EXECUTE_GAP` + plan structure only | `needs_plan` | re-plan |
| `ready_execute` | `CODE_READY_FOR_REVIEW` | `needs_review` | — |
| `needs_review` | — | (run) | `/workflow:review` (depth from track; infer, don't ask) |
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
**for this `run_id`** (across sessions — use `reentry_counts` on session-state; not only within
one `/continue` invocation), and without new external decision evidence, emit `THRASH_BOUND`
→ `await_user` with a short diagnosis (what oscillated, what evidence is missing). Do not
infinite re-plan.

On thrash: soft-offer process memory capture with run evidence. **Never** rewrite workflow
skills in-place. Corpus text changes only in the skill source via `/skills:evolve` when that
skill is installed; consumer projects keep evidence and take gaps upstream (see soft-checks
Process gap table).

## Multi-stream / horizon-only

If the “unit” is actually multi-stream with no single claimable scope → stop + offer
`/workflow:roadmap`. Do not invent streams inside the unit machine.

## Relationship to old stage table

Each old “Current state → Next phase” row is a **classify → primary transition** pair. The
machine adds explicit **backward** edges the table only implied (stale decision, structural
review findings, execute gaps).
