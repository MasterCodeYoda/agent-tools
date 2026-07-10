# Decomposition Modes

Full doctrine for the two decomposition modes summarized in the parent @workflow skill — when and how to use each mode, why each works where it does, verbatim AC inheritance and backlog resize, implementation order within a mode, and the anti-patterns to avoid.

How an epic decomposes into stories or sub-issues depends on the work's shape. Two modes:

**Vertical Slice** — for incremental feature work delivering observable value, especially user-facing, in deployed systems where each slice ships and stakeholders see progress. Default for post-first-release feature increments.

**Deliverable-Partition** — for work that doesn't slice cleanly into user-facing increments, or where slicing risks process-induced slowdown or gaps in requirements / Definition of Done conformance. Two named sub-cases:

- *Foundation / pre-first-release*: greenfield scaffolding, validators, CI/CD, base contracts. No deployed surface yet to slice through.
- *Cross-cutting / large-effort*: post-first-release work like contract-first shared-library changes, compliance roll-outs, framework migrations, pipeline epics decomposed by event boundary.

Same mechanism for both deliverable-partition sub-cases: decompose by deliverable, AC traceability matrix in the parent epic, verbatim AC ownership in each sub-issue, per-deliverable Definition of Done.

## Vertical Slice — When and How

Build features end-to-end, not layer-by-layer.

**Layer-by-layer approach** — avoid within vertical-slice mode:

```
1. Build all domain entities
2. Build all repositories
3. Build all use cases
4. Build all API endpoints
5. Build UI
6. Integrate and test
```

**Vertical-slice approach**:

```
1. Pick highest priority user story
2. Build ONLY what's needed for that story through ALL layers
3. Ship it
4. Pick next story, repeat
```

## Deliverable-Partition — When and How

Decompose the epic into the artifacts it must produce, not into user-facing increments.

The "layer-by-layer is wrong" warning **does not apply** here — comprehensively building one deliverable (e.g., a CI pipeline, a validator rule, a contract type) to its owned AC subset is exactly the work.

**Deliverable-partition approach**:

```
1. List the artifacts the epic must produce (validator, CI, hooks, README, ...)
2. Partition the parent acceptance criteria across those artifacts —
   each parent AC owned by exactly one sub-issue, verbatim
3. Build each artifact comprehensively to its owned AC subset
4. Verify the AC traceability matrix has zero orphans before closing the parent
```

## Mode Selection

Pick **vertical slice** when:

- The system has users (or simulated equivalents) observing value at each slice.
- Each story can ship independently and deliver an observable increment.
- The epic spans Domain → Framework cleanly and stories don't share files extensively.

Pick **deliverable-partition** when:

- No deployed surface yet (greenfield / pre-first-release).
- The epic produces multiple distinct artifacts (validator rules, CI steps, hooks, contracts) rather than user-facing increments.
- Vertical slicing would force "minimal X, full X later" boundaries that risk silently weakening parent ACs.
- The epic touches a shared library/contract that downstream consumers must adopt incrementally.
- Compliance, refactor, or framework-migration work spans the system without a natural user-story shape.

When in doubt, default to vertical slice for feature work and deliverable-partition for foundation, infrastructure, or cross-cutting work.

## When Vertical Slicing Works Best

- **Faster time to value** — slices ship as they're ready and stakeholders observe progress.
- **Reduced risk** — small, end-to-end-tested slices isolate failures.
- **Better feedback** — users see progress immediately.
- **Easier integration** — continuous integration of complete features, not big-bang merges.
- **Clear progress signal** — working features, not "90% complete" partial layers.

These benefits assume a deployed surface and observers. Pre-first-release work, foundation work, and cross-cutting work that doesn't surface to a user typically does not realize them — picking vertical slicing in those situations imports the costs without the payoff.

## When Deliverable-Partition Works Better

- **Gap-prevention discipline** — verbatim AC ownership in each sub-issue plus an AC traceability matrix in the parent makes Definition-of-Done conformance auditable at a glance. No silent paraphrasing drift between parent and child.
- **No fictional value-delivery framing** — foundation / scaffolding work doesn't pretend each artifact is a user-visible increment.
- **Sequencing matches the work shape** — contracts before consumers; validators before the rules they enforce; CI before the gates it runs.
- **No "minimal X, full X later" temptation** — each sub-issue ships its deliverable comprehensively, not a partial first pass to be ratcheted in subsequent stories.

## Issues state the current target, not a migration narrative

An issue (and each AC) describes **what the system is when the work is done**, not the process of getting there — unless that process *is* the deliverable (a runbook, a migration tool, a cutover the issue exists to perform). Cutover ceremony — soak, promote, blue-green, parallel-run, rollback-drill — is admissible only when there's a production surface to cut over *from*; on a pre-launch system, an AC prescribing "soak before promoting" is dead ceremony, not a requirement. When a vendor or technology name changes in an issue, **do not find-replace and move on** — re-read every AC against the current target; phasing and ceremony rarely survive a decision that collapses the architecture.

**Verbatim AC inheritance binds a child to the *current* parent AC, not the original text.** When the parent *decision* changes, re-size the parent AC set first, then children re-inherit. Fidelity is to the current decision, never to superseded AC text — editing a stale AC down to match the new decision is correctness, not a fidelity violation. (The strict no-drop ratchet is correct for compliance/contract work; resize is the explicit escape hatch for everything else, gated on a recorded decision change.) When a decision changes, re-size the backlog rather than annotating it — see @workflow (`planning/pm-integration.md`) › Backlog Resize.

A smell to act on, not a hard cap: a pre-launch epic carrying many ACs — or any AC naming a process the system has no surface to run — is a signal to re-size before planning consumes it. Count ACs against the current decision's surface, not against what was previously written.

## Bottom-Up Implementation (within a vertical slice)

Within a vertical slice, plan **top-down** (user story → layers) and implement **bottom-up**:

1. **Domain Layer First** — pure business logic, no dependencies
2. **Application Layer** — use cases, orchestration (depends on domain abstractions)
3. **Infrastructure Layer** — data access, external services (implements application interfaces)
4. **Framework Layer** — API endpoints, UI

This order follows the dependency rule: each layer depends only on layers inside it. Infrastructure implements the interfaces that Application defines.

Testing integrates naturally with bottom-up implementation: write tests for each layer as you build it upward. See @test-strategy for strategy selection.

In **deliverable-partition** mode, the dependency rule still applies inside each deliverable, but the per-deliverable shape varies — a validator rule, a CI pipeline step, or a hook installer doesn't necessarily span four layers. Plan deliverables in their dependency order (e.g., contracts before consumers; library scaffold before validator rules that operate on the library).

## Common Pitfalls

### Over-Engineering the First Slice

**Wrong**: Building everything a feature might need
```python
class Task:
    def __init__(self, title, description, status, priority,
                 assignee, labels, attachments, comments, ...):
```

**Right**: Building only what the current story needs
```python
class Task:
    def __init__(self, title, description):
```

### Building Horizontal Infrastructure (within vertical-slice mode)

When you're slicing a feature vertically, resist drifting into building all repository methods, all service abstractions, or all use-case shapes upfront. Stay within the slice's needs.

**Wrong** — all repository methods upfront for a feature where the slice only needs `create()`:
```python
class TaskRepository:
    def create(self, task): ...
    def update(self, task): ...
    def delete(self, task_id): ...
    def find_by_status(self, status): ...
```

**Right** — only what the current story needs:
```python
class TaskRepository:
    def create(self, task): ...
```

This pitfall does **not** apply in deliverable-partition mode. There, comprehensively building one deliverable (e.g., a complete CI pipeline, a fully-specified contract type) to its owned AC subset is exactly the work, not a smell.

### Premature Abstraction

**Wrong**: Complex inheritance before patterns emerge
```python
class BaseEntity: ...
class AuditableEntity(BaseEntity): ...
class Task(AuditableEntity): ...
```

**Right**: Simple, direct implementation
```python
@dataclass
class Task:
    id: str
    title: str
```

### Skipping Quality Gates

**Wrong**: Moving to next task with failing tests
**Right**: Fix failures immediately, maintain green builds

### 80% Done Syndrome

**Wrong**: Moving to next feature before current is complete
**Right**: Ship complete features, then move on
