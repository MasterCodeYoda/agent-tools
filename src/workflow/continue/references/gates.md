# Continue hard gates (mandatory load)

**Load when:** unit mode is active — before review, integrate, autonomous merge, or end-of-loop
recap. These contracts are **not optional**; skipping them is a process bug.

## Path not established

Continue never invents a next unit (no fatigue “you decide,” no residual-only initiative).
Scaffolding `planning/<slug>/` for a **named** NEXT is allowed. Named-without-shell is claimable.

Hard-stop template (portfolio `hard_stop` mode):

```markdown
### Path not established — stopping

Continue will not invent a next unit.

**Options:**
1. Name a concrete unit (issue id, slug, or `planning/<slug>/`) and re-run `/workflow:continue`
2. `/workflow:brainstorm` — single fuzzy concept
3. `/workflow:roadmap` — multi-unit destination + order (or resequence)
```

## Review gate — operational definition

**Project hygiene gates (typecheck, lint, test, build, architecture validators, issue-ref, etc.)
are never a substitute for the review phase.** Green gates ≠ reviewed. Slice size does not skip
review. **Depth** may scale by track (`quick` | `standard` | `deep` — @workflow
`references/tracks.md`); evidence schema is always required for code-bearing work. Review skill
**infers** depth (track → user flag → diff heuristics) and proceeds without confirmation unless
ambiguous standard vs deep.

A slice is **reviewed** only when all hold:

1. A real review pass ran: `/workflow:review` (preferred), `/code-review`, or structured
   multi-lens review with P1–P3 and a verdict — not a casual self-glance while gates are green.
2. Confirmed P1–P3 findings fixed (or deferred only as conventions allow — typically P4/nits or
   deferred with a follow-up issue id). Honor stricter project bars when present.
3. **Valid review evidence** recorded before integration (PM comment preferred; session-state
   minimum).

### Valid review evidence (schema)

| Field | Required content |
|-------|------------------|
| `method` | `workflow-review` \| `code-review` \| `structured-agents` (name the lenses) |
| `date` | ISO date of the review pass |
| `verdict` | `clean` \| `findings-fixed` (after remediation) — not free-form "LGTM" |
| `findings` | Counts by priority, e.g. `P1=0 P2=2 P3=1` (zeros explicit when none) |
| `disposition` | One line: fixed, deferred (with issue id), or `none` |

Minimum handoff line:

```text
review: findings-fixed | 2026-07-09 | method=workflow-review | P1=0 P2=2 P3=1 | disposition=all fixed in <sha>
```

**Invalid (treat as not reviewed):** `review: clean` without method/counts; "I looked at the
diff"; gates green as review; PM comment that only restates gates; any claim that cannot name
method + P1–P3 counts. **Do not invent evidence** to unblock merge.

## Autonomous merge preconditions (hard ratchet)

When conventions authorize autonomous local merge (personal factory profile does by default),
**all** must be true; else **do not merge** (fall back to merge confirm / `await_user`):

1. Reviewed-clean with **valid** evidence schema above.
2. Every project gate from conventions passes cleanly.
3. All task requirements + constraints for the slice are met (ACs / plan DoD).
4. Loop recap includes the **Review findings & disposition** block (below) when recap applies.

"Clean validation pass" in conventions means (1)+(2)+(3)+(4), never gates alone.
Push/PR remain user-initiated unless push policy explicitly allows.

## Compound after integrate

After merge, before advancing the top-level next-pickup pointer:

1. Run `/workflow:compound`, **or**
2. Record `compound: none — <one-line reason>`.

Do not silently skip. Soft-check on next orient if the most recently completed slice lacks both.

## Where to stop (HITL) → `await_user`

- Path not established / sequencing choice
- Direction or requirements need the user’s call
- Plan approval (`/workflow:plan`) — **approval prompt only; no end-of-loop recap**
- Review findings that need triage decision
- Review missing for code-bearing slice
- Integration/merge confirmation by default (unless autonomous preconditions met)
- Auto-invoked continue after a full slice already completed this session — ask before a new slice
- Thrash bound (unit-state-machine.md)
- Any AskUserQuestion-class decision

Pushing/PRs: always user-initiated unless project push policy explicitly allows main-push at
agent judgment — never production promotion.

## End-of-loop recap

**Required** before stop (slice complete, paused without approval UI, blocked) **except** at a
**user-approval stop** (plan approval, brainstorm converge choice, merge confirm, triage choose,
other approve/choose UI). At approval stops: phase prompt only — no recap.

### Always include (when recap applies)

| Block | Content |
|-------|---------|
| **Slice** | Work item id + one-line title |
| **Phases run** | Phases actually run this invocation (may include re-entries) |
| **Where left** | Next state / gate / pickup |
| **Branch / commits** | If code moved |
| **Mode** | `unit` · `swarm_handoff` · `swarm_resume` · `path-not-established` · … |
| **Steering** | When relevant: silent · offered steering_note · user choice |

### Review findings & disposition (code path)

If execute produced commits or slice is at/past "code exists", and stop is not an approval
exception:

```markdown
### Review findings & disposition
- **method:** /workflow:review (or structured-agents: <lenses>)
- **depth:** quick | standard | deep
- **target:** <range or paths>
- **findings:** P1=n · P2=n · P3=n
- **disposition:** <fixed | deferred to ISSUE | none>
- **verdict:** APPROVE | REQUEST_CHANGES → remediated
```

Rules: no code-path recap without this block; gates on a separate line; empty findings still
report zeros; if stopped before review: `Review: not run — stopped at <gate>`. Non-code loops:
`Review: n/a — no code this loop`.
