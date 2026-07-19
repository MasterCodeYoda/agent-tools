# Phase return contract

**Load when:** unit state machine is about to invoke a phase skill, and again immediately after
that phase returns control to continue.

Phase skills remain authoritative for *how* they run. Continue needs a **small structured
outcome** so re-classification and transitions are evidence-based, not narrative guesswork.

## Host obligation

After each phase invocation in a `/continue` loop, the **host agent** records a return block
(in working memory for the loop; persist a one-liner into session-state **Last Session Summary**
or Current Focus when the stop is durable):

```yaml
phase_return:
  phase: brainstorm | refine | plan | execute | review | integrate | compound
  status: completed | await_user | blocked | failed
  events: []   # from unit-state-machine.md event names
  evidence: "" # one line: artifact path, SHA, review counts, gate name, etc.
  next_hint: "" # optional; classify() still wins over this hint
```

### Examples

```yaml
phase_return:
  phase: refine
  status: completed
  events: [REQUIREMENTS_READY]
  evidence: "planning/SPEC-851/requirements.md ACs match ADR-117"
  next_hint: needs_plan
```

```yaml
phase_return:
  phase: execute
  status: completed
  events: [CODE_READY_FOR_REVIEW, CODE_PROGRESSED]
  evidence: "3 commits on feat/SPEC-851; plan tasks 4/4"
  next_hint: needs_review
```

```yaml
phase_return:
  phase: execute
  status: blocked
  events: [EXECUTE_GAP, REQUIREMENTS_STALE]
  evidence: "AC3 assumes old vendor name; decision record renamed 2026-07-12"
  next_hint: needs_refine
```

```yaml
phase_return:
  phase: review
  status: completed
  events: [REVIEW_FINDINGS_CODE]
  evidence: "P1=0 P2=2 P3=0; fix in code"
  next_hint: ready_execute
```

```yaml
phase_return:
  phase: plan
  status: await_user
  events: [PLAN_DRAFTED, USER_GATE]
  evidence: "implementation-plan.md draft presented"
  next_hint: await_user
```

## Rules

1. **Classify still wins.** `next_hint` is advisory; re-read disk + decisions before
   transitioning.
2. **Events must be justified** by `evidence`. No event without a locatable fact.
3. **`await_user`** stops the continue loop under recap exception rules (`gates.md`).
4. Phase skills are not required to emit this YAML themselves if the host can derive it
   honestly from what the phase just did — but the host **must** produce the block before the
   next transition.
5. Multiple events allowed when all are true (e.g. `CODE_PROGRESSED` + `CODE_READY_FOR_REVIEW`).

## Optional session-state fields (light only)

When non-derivable across sessions:

```yaml
# in session-state.md frontmatter or body — only if needed
pending_gate: plan_approval | merge_confirm | triage | sequencing_choice | none
last_transition: "ready_execute→needs_refine (REQUIREMENTS_STALE)"
```

Do not create a second orchestrator-state file. Prefer re-derive; write only what classify
cannot reconstruct.
