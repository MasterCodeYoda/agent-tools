# Quality Checkpoints

Verify work meets standards at the right granularity for its decomposition mode (see @work):

- **Vertical-slice mode**: per-layer gates plus a slice-completion checkpoint.
- **Deliverable-partition mode**: per-deliverable gates plus a sub-issue-completion checkpoint with verbatim AC verification.

## Layer Quality Gates (vertical-slice mode)

### Domain Layer

**Code Quality:**
- [ ] No framework dependencies (pure business logic)
- [ ] No infrastructure dependencies (no database, files, network)
- [ ] Entities have validation
- [ ] Business rules enforced
- [ ] Value objects are immutable

**Testing:**
- [ ] Unit tests for entities
- [ ] Validation edge cases tested
- [ ] Business rule scenarios covered
- [ ] No mocking required (pure logic)
- [ ] Domain verification evidence when this layer changed (mutation summary **or** sabotage notes **or** skip reason) — see Domain verification path

**Common Issues:**
- Anemic domain models (logic in wrong layer)
- Leaky abstractions (infrastructure concerns)
- Missing validation
- Mutable state without protection

### Infrastructure Layer

**Code Quality:**
- [ ] Implements repository interfaces correctly
- [ ] Proper connection/session management
- [ ] Transaction boundaries respected
- [ ] Error handling for external failures
- [ ] Proper resource cleanup

**Testing:**
- [ ] Integration tests for repositories
- [ ] Error scenarios tested
- [ ] No business logic in repositories

**Common Issues:**
- Business logic in repositories
- Missing error handling
- Resource leaks
- N+1 query problems

### Application Layer

**Code Quality:**
- [ ] Single responsibility per use case
- [ ] Clear request/response DTOs
- [ ] Proper orchestration logic
- [ ] Transaction management defined
- [ ] No UI/HTTP concerns

**Testing:**
- [ ] Unit tests with mocked dependencies
- [ ] All use case paths tested
- [ ] Error scenarios handled

**Common Issues:**
- Fat use cases (doing too much)
- Missing transaction boundaries
- Authorization in wrong layer

### Framework Layer

**Code Quality:**
- [ ] Thin controllers (delegation only)
- [ ] Complete input validation
- [ ] Proper HTTP status codes
- [ ] Consistent error response format
- [ ] Security headers configured

**Testing:**
- [ ] E2E tests for happy path
- [ ] Error response tests
- [ ] Input validation tests

**Common Issues:**
- Business logic in controllers
- Missing input validation
- Incorrect status codes

## Vertical Slice Checkpoint (vertical-slice mode)

### Before Completion

**Functional:**
- [ ] Acceptance criteria met
- [ ] Works end-to-end
- [ ] Error messages user-friendly
- [ ] Performance acceptable

**Integration:**
- [ ] All layers connected properly
- [ ] Data flows correctly
- [ ] Transactions work end-to-end

**Quality:**
- [ ] Tests pass
- [ ] Linting passes
- [ ] No new warnings
- [ ] Code follows patterns
- [ ] Behavioral diff against main confirms only expected changes (when relevant)
- [ ] Domain verification evidence when domain/pure logic changed (mutation summary **or** sabotage notes **or** skip reason) — see Domain verification path

## Deliverable-Partition Quality Gates (deliverable-partition mode)

Per-deliverable gates replace per-layer gates. Each deliverable's shape determines its gates — a validator rule, a CI step, a hook installer, a contract type, or an infrastructure module each have different verification surfaces.

### Generic Per-Deliverable Gates

**Code Quality:**
- [ ] Deliverable is comprehensively built to its owned AC subset (no "minimal-now, full-later" partial shape)
- [ ] No business logic leaking into the wrong concern
- [ ] Public surface (API, CLI, config keys) is documented at the deliverable level

**Testing:**
- [ ] Positive-case test demonstrates the deliverable performs its function
- [ ] Negative-case test demonstrates the deliverable rejects what it should reject (especially for validators, contracts, or rule-enforcement deliverables)
- [ ] Integration evidence — the deliverable functions inside the system it ships to (CI run, validator pass on real code, hook firing on a real commit)

**AC Verification:**
- [ ] Every parent AC inherited by this sub-issue is verified verbatim — not a paraphrased equivalent
- [ ] Verification evidence is recorded (test name, CI run, manual check) so audit-on-close has a paper trail

### Sub-issue Completion Checkpoint

**Functional:**
- [ ] Every inherited verbatim parent AC is verified
- [ ] Deliverable functions in the system it ships to (not just in isolation)

**Integration:**
- [ ] Deliverable composes with prior-shipped deliverables in the dependency chain
- [ ] No regression in prior-closed sub-issues' verified ACs

**Quality:**
- [ ] Tests pass
- [ ] Linting / type checks pass
- [ ] No new warnings
- [ ] Code follows patterns
- [ ] Behavioral diff against main confirms only expected changes (when relevant)
- [ ] Domain verification evidence when domain/pure logic changed (mutation summary **or** sabotage notes **or** skip reason) — see Domain verification path

**Gap-prevention (project-level audit):**
- [ ] No parent AC has been silently weakened during decomposition
- [ ] If any AC could not be met, a tracking issue exists with explicit approval to defer
- [ ] Verbatim fidelity is to the **current** parent AC, not the original text — if the governing decision changed, the parent AC set was re-sized first and children re-inherited (a resized AC is not a "silently weakened" one; see @work (`planning/pm-integration.md`) › Backlog Resize)

## Slice / Sub-issue Completion Protocol

### When to Commit

Commit at the completion of each **vertical slice** (story) in vertical-slice mode, or each **sub-issue** (deliverable) in deliverable-partition mode. NOT at:
- Session boundaries only
- Feature/epic completion only
- Arbitrary "stopping points"

### Slice / Sub-issue Completion Checklist

Before moving to the next slice or sub-issue:

- [ ] All acceptance criteria for THIS slice/sub-issue met (in deliverable-partition mode: every inherited verbatim parent AC verified)
- [ ] Tests pass for THIS slice/sub-issue
- [ ] **Decision-reconciliation at close** (see below)
- [ ] Code committed with descriptive message and issue ID
- [ ] PM tool updated (issue marked Done)
- [ ] Session state updated (if tracking)

#### Decision-Reconciliation at Close

Before marking the work done, reconcile the **governing decision record + any docs/ACs this change touched** against the **code as built**. This is the forcing function that keeps docs and code from drifting (and it applies whatever decision-record genre the project uses — see @work (`references/decision-records.md`)):

- [ ] Each touched decision record / domain doc still describes what the code now does. Where the build taught better → **rewrite the doc to the new target** (in place, per the project's convention); where the doc named a real constraint the code dropped → **fix the code**.
- [ ] No closed AC references a surface, vendor, or ceremony the built system doesn't have.
- [ ] The reconciliation is recorded as **evidence** — name the doc and the line(s) changed, or assert "no drift" against the diff. A bare checkbox is not evidence.
- [ ] Scope is the change's **blast radius**, never a corpus sweep.

Docs may legitimately run *ahead* of code during a build window; they may not run *stale behind* a closed issue. An issue does not close while its governing decision doc and its built code disagree.

### Commit Command Template

```bash
git add [specific files for this slice]
git commit -m "$(cat <<'EOF'
feat(scope): description (ISSUE-ID)

- Implementation detail 1
- Implementation detail 2

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

### PM Tool Update

Immediately after commit:
- **Linear**: Update issue state to Done
- **Jira**: Transition issue to Done
- **Manual**: Update issue status in your tracker

### Warning Signs

You may have batched commits if:
- More than one story's worth of changes uncommitted
- Multiple Linear/Jira issues stuck in "In Progress"
- Large `git diff` output spanning multiple features
- Anxiety about losing accumulated work

## Security Checkpoint

### Basic Security

- [ ] Input validation on all endpoints
- [ ] SQL injection prevention
- [ ] Authentication where needed
- [ ] Authorization checks in place
- [ ] Sensitive data not logged
- [ ] Secrets not in code

### Data Protection

- [ ] Passwords hashed (never plain text)
- [ ] PII handled appropriately
- [ ] Encryption for sensitive data

## Performance Checkpoint

### Response Time

- [ ] API response reasonable
- [ ] No obvious N+1 queries
- [ ] Database queries efficient

### Resource Usage

- [ ] No memory leaks
- [ ] Connections properly pooled
- [ ] Appropriate timeouts

## Test Strategy

### Test Pyramid

```
    E2E     (10%) - Critical paths
  Integration (20%) - Repository, services
    Unit    (70%) - Domain, use cases
```

For testing methodology and strategy selection, see @test-strategy.

### Coverage Floors and Quality Verification

Coverage is a **floor** (find untested code), not a goal. Use quality verification to ensure tests actually catch bugs.

| Layer | Coverage Floor | Quality Verification | Mutation Target |
|-------|---------------|---------------------|-----------------|
| Domain | 85% | Mutation **or** sabotage (see Domain verification path) | 80%+ when tool run; else sabotage evidence |
| Application | 75% | Sabotage test — manually break logic, confirm tests fail | 70%+ if tool used (P2 if 50-69%); else sabotage |
| Infrastructure | 60% | Integration completeness — all repository paths exercised | N/A |
| Framework | 50% | E2E happy path — critical user journeys covered | Targeted on validation logic only if tool |

See @test-strategy (`references/test-quality.md`, `references/mutation-testing.md`) for mutation testing tools, configuration, and the sabotage test technique. Strategy fit (including property-based tests for parsers/transforms): @test-strategy SKILL + `references/property-testing.md`.

### Domain verification path (slice / task complete)

**Vocabulary (do not conflate):**

| Term | Meaning |
|------|---------|
| **Process evidence (execute DoD)** | Before unit complete: record mutation summary **or** sabotage notes **or** skip reason |
| **Review P2** | Missing that evidence on domain/pure-logic changes → should-fix finding; not automatic REQUEST CHANGES / merge block |
| **CI signal (optional)** | Project may report incremental mutation on critical paths; not a universal score breaker |

When the change touches **domain** (or other pure business logic — including pure application rules with real conditionals; thin orchestration stays sabotage/example only), record quality evidence before calling the unit done. Prefer the cheapest path that still verifies tests catch faults:

**Predicate (shared with review):** if domain/pure-logic files are in the diff → evidence or explicit skip reason. Express “triviality” only via skip reason (e.g. rename-only, pure type renames, comment-only) — do not invent a separate “non-trivial” gate.

```
IF mutation tool available AND domain/pure-logic files changed:
  1. Incremental mutate on those files only (not full repo)
  2. Timebox: classify survivors (equivalent vs real gap); kill real gaps with minimal strong tests
  3. Record: files mutated, score or survivor summary, remaining accepted skips
ELSE:
  1. Sabotage 3–5 critical paths in the changed domain logic
     (boundary ops, guards, return values — see test-quality.md)
  2. Confirm tests fail under sabotage; revert; strengthen tests if any sabotage survived
  3. Record: paths sabotaged, caught/missed, tests added
SKIP (with one-line reason) when:
  - No domain/pure-logic in the diff (docs-only, config-only, pure wiring)
  - Change is infrastructure/external wrappers where mutation has near-zero value
```

This is a **process gate with evidence**, not a universal CI mutation-score threshold. Do not install mutation tools mid-slice solely for ceremony; sabotage + recorded evidence satisfies DoD for that unit. Recommend tool install as follow-up when domain work is recurring.

**Property-fit:** if the slice owns parsers, codecs, serializers, or wide-range pure rules, prefer property-based tests (+ few example anchors) per @test-strategy — do not force PBT on CRUD.

## Pre-Commit Checklist

Before committing a slice:

- [ ] All acceptance criteria met
- [ ] Tests written and passing
- [ ] Linting passes
- [ ] No console errors
- [ ] Plan checkbox updated
- [ ] Session state reflects progress
- [ ] Domain verification evidence recorded when domain/pure logic changed (mutation summary **or** sabotage notes **or** skip reason)

## Quality Questions

Before marking complete, ask:

1. Would you deploy this to production?
2. Can another developer understand this?
3. Are edge cases handled?
4. Is the code maintainable?
5. Does it follow team patterns?
6. For non-trivial changes, is there a simpler, more elegant approach?

## When Quality Can't Be Met

If standards can't be met immediately:

```markdown
## Technical Debt Record
- **Issue**: [What standard wasn't met]
- **Reason**: [Why deferred]
- **Impact**: [Risk]
- **Remediation**: [How to fix]
- **Priority**: [When to address]
```

Document in session state and create follow-up task.
