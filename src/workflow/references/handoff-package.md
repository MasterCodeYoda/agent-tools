# Handoff package (unit ↔ swarm)

**Load when:** continue may pause between phases for a later session/agent, swarm assembles a
worker dispatch, or two coding agents split operator vs implementer work.

**Default (personal / same-session):** after plan approve, continue **stays in-session** and runs
execute. Handoff package is **optional** — use when crossing sessions, CLIs, or swarm workers.
Do not invent emit-and-stop as the default path.

## One dialect

Swarm `@swarm` `roles/worker-contract.md` structured return and this package share the **same
field names** for artifacts and status. Unit continue does not invent a second schema.

| Producer | Consumer | Shape |
|----------|----------|--------|
| Continue (optional pause) | Next session / coding worker | `handoff_package` YAML on session-state or chat |
| Swarm orchestrator | Worker | Dispatch prompt + worker-contract |
| Worker / phase host | Orchestrator or continue | Structured return YAML (worker-contract) |

Canonical return schema authority for swarm: `@swarm` `references/structured-return-schema.md`
(and `@swarm` `roles/worker-contract.md`). Unit mode **maps** phase-return events into the same
status vocabulary when emitting a package.

## `handoff_package` (outbound — work to resume)

Write under session-state or as a fenced YAML block when pausing after a phase:

```yaml
handoff_package:
  schema_version: 1
  unit: SPEC-851
  run_id: r-20260718-1
  track: feature | micro | research
  role_hint: operator | implementer | reviewer
  phase_next: execute | review | integrate | compound | refine | plan
  from_state: ready_execute
  planning_root: .agent-tools/planning   # or legacy ./planning
  paths:
    session_state: <path>
    requirements: <path or null>      # file mode
    plan: <path or null>              # feature track
    work_item: LIN-123                # PM mode key
  workspace:
    branch: feat/SPEC-851
    worktree: <path or null>
  constraints: |
    Short bullets: merge policy, out of scope, known landmines
  acs_pointer: "PM LIN-123 description" | "planning/.../requirements.md"
  steering_note: <optional one-liner>
  source_channel: cli | linear | github | chat
```

**Resume:** next agent loads `paths.session_state`, re-classifies (classify wins over
`phase_next`), enters unit SM or executes the named phase. Never invent a different unit.

## Structured return (inbound — work finished by a worker)

Same fields as swarm worker-contract (subset always required):

```yaml
status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED | APPROVED | FIX_REQUESTED | FAILED
item: <issue-key>
role: planner | implementer | reviewer | operator | conflict-resolver | integration-fixer
summary: |
  2-4 sentences

artifacts:
  branch: <name or null>
  worktree: <path or null>
  commits: [<sha>, ...]
  files_changed: [<path>, ...]
  planning_docs: [<path>, ...]
  test_status: pass | fail | not-run | not-applicable
  test_command: <command or null>

concerns: []
needs: []
blocker: null
fix_list: []
next_action_recommended: <one phrase>
run_id: r-YYYYMMDD-N          # optional but preferred for runs ledger
track: feature | micro | research
```

### Map return → unit SM events

| Return `status` | Typical unit events |
|-----------------|---------------------|
| `DONE` (implementer) | `CODE_PROGRESSED` and/or `CODE_READY_FOR_REVIEW` |
| `DONE_WITH_CONCERNS` | same + record concerns in session-state |
| `APPROVED` (reviewer) | `REVIEW_CLEAN` + valid evidence line still required |
| `FIX_REQUESTED` | `REVIEW_FINDINGS_CODE` (+ fix_list → execute) |
| `NEEDS_CONTEXT` | `USER_GATE` / `await_user` |
| `BLOCKED` | `blocked` |
| `FAILED` | `blocked` or re-dispatch per swarm rules |

**Review evidence schema** (`gates.md`) is still required before merge — `APPROVED` alone is not
theater-proof without method/date/verdict/P1–P3/disposition.

## Operator vs coding worker (roles, not products)

| Role | Typical phases |
|------|----------------|
| **operator** | continue orient, roadmap, refine, plan approval, integrate policy, compound, recap, swarm host refine |
| **implementer** | execute (and micro direct-issue) |
| **reviewer** | review with depth by track |

Same agent may play both in one session (default). Split only when useful.

## Swarm alignment

- Orchestrator continues to prepend full `@swarm` `roles/worker-contract.md` on dispatch (boundaries + brevity).
- Do **not** dual-maintain a forked return schema in workflow — change `@swarm` structured-return-schema
  + worker-contract together; this file only maps unit continue ↔ that schema.
- Unit continue **never** writes swarm `state.yml`; swarm never owns unit phase-return.

## Anti-patterns

- Emit handoff after every plan by default (violates same-session personal default)
- Different field names for the same artifact between swarm and unit
- Treating structured return as substitute for disk session-state / commits
- Skipping review evidence because status was `APPROVED`
