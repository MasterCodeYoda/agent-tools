# Direct issue execution (micro track)

Load from `/workflow:execute` **or** from `/workflow:continue` when unit track is **micro**
(@workflow `references/tracks.md`). This is a first-class track process, not only an execute
side door.

## When to use

- Bug fixes with clear reproduction steps
- Small enhancements / chores / docs with well-defined scope
- Tasks where the issue description (or user paste) **is the plan**
- User flags: `micro` | `direct` | `small`
- Continue classified **micro** (labels or issue-as-plan heuristics)

**Do not use** when: new public contract, multi-module design still open, ambiguous success,
multi-unit program, or user asks for full plan.

## Flow

```
1. Fetch issue (or use paste) via Issue Retrieval Strategy — @workflow PM integration
2. Extract title, description, ACs if present
3. Confirm scope with user (issue confirmation = plan approval on micro)
4. Ensure working branch ≠ main (branch naming @workflow)
5. Mint run_id / track=micro on session-state if continue host has not
6. Execute with standard Execution Loop (quality-checkpoints, tests)
7. Review depth=quick — still valid evidence schema (gates.md)
8. Integrate: autonomous local merge if conventions allow + ratchet green; else confirm
9. Compound disposition (capture or compound: none — <reason>)
10. PM Done + workflow:merged egress line when PM mode
```

Minimal session-state is enough (no `requirements.md` / `implementation-plan.md` required).
Prefer recording under planning root when multi-session pause is likely.

## Escalation (mandatory)

If scope grows mid-flight:

1. Pause execution
2. Reclassify track → **feature**
3. Enter `needs_plan` or `needs_refine` with evidence (EXECUTE_GAP)
4. Resume via continue unit machine — do not pretend micro still holds

## Relationship

- Continue classifies micro before feature SM — named-without-shell can be micro when eligible
- Swarm implementer roles may still use full plan; micro is the sequential personal path
- Process IP changes from repeated micro mis-routes → `/skills:evolve`, not ad-hoc skill edits
