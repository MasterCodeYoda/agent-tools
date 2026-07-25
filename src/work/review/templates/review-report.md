# Review report templates

Load when emitting the review summary, verdict, and next steps.

### Summary Report

```markdown
## Code Review Complete

**Target**: [PR #X / git range / files]
**Scope**: [X files, +Y/-Z lines]
**Depth**: [Quick/Standard/Deep]

### Findings Summary

| Priority | Count | Status |
|----------|-------|--------|
| P1 Critical | X | BLOCKS MERGE |
| P2 Important | Y | Should fix |
| P3 Nice to Have | Z | Optional |

### P1 Findings (Critical)

[List each P1 finding with details]

### P2 Findings (Important)

[List each P2 finding]

### P3 Findings (Nice to Have)

[List each P3 finding]

### Acceptance Criteria Status (if plan available)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| [Criterion 1] | MET / UNMET / PARTIAL | [file:line or explanation] |
| [Criterion 2] | MET / UNMET / PARTIAL | [file:line or explanation] |

**Definition of Done**: [X]/[Y] items verified
**Planned Tasks**: [X]/[Y] reflected in changes
**Scope Creep**: [None detected / Items found outside plan scope]

### Remediation Verification (if prior findings exist)

| Prior finding | Remediation range | Code/test evidence | Refutation and sabotage result |
|---------------|-------------------|--------------------|--------------------------------|
| [Finding ID] | [base...head] | [file:line / test] | [stands / incomplete / regression found] |

### Positive Observations

- [Good pattern followed]
- [Well-tested area]
- [Clean implementation]

### Review Agents Used
- [List of agents and focus areas]

## Verdict

[ ] **APPROVE** - No unresolved P1-P3 findings, all acceptance criteria met (if plan available), code is ready
[ ] **REQUEST CHANGES** - P1 issues or unmet acceptance criteria must be addressed
[ ] **COMMENT** - Suggestions but no blockers

**Integration evidence (required for integration-ready APPROVE):**
`review: [clean|findings-fixed] | [YYYY-MM-DD] | method=work-review | P1=[X] P2=[Y] P3=[Z] | disposition=[none|all fixed in <sha>|deferred to <issue-id>]`

Use `clean` only when no findings were raised. Use `findings-fixed` after every finding is fixed
or deferred as project conventions permit. Do not emit integration-ready evidence otherwise.
```

### Actionable Next Steps

```markdown
## Next Steps

**If findings are present:**
1. Address each P1-P3 finding, or defer only as project conventions permit with a follow-up issue
2. Re-run review after fixes: `/work:review [target]`

**If approved:**
1. Record the integration evidence above
2. Merge when ready

**Options:**
1. **Fix findings** - Address confirmed findings now
2. **Create permitted follow-ups** - Record convention-approved deferrals
3. **Re-review** - Run again after changes
4. **Export findings** - Save to file for tracking
```
