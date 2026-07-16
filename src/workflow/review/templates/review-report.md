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

### Positive Observations

- [Good pattern followed]
- [Well-tested area]
- [Clean implementation]

### Review Agents Used
- [List of agents and focus areas]

## Verdict

[ ] **APPROVE** - No P1 issues, all acceptance criteria met (if plan available), code is ready
[ ] **REQUEST CHANGES** - P1 issues or unmet acceptance criteria must be addressed
[ ] **COMMENT** - Suggestions but no blockers
```

### Actionable Next Steps

```markdown
## Next Steps

**If P1 issues found:**
1. Address each P1 finding before merging
2. Re-run review after fixes: `/workflow:review [target]`

**If approved:**
1. Merge when ready
2. Consider P2/P3 items for follow-up

**Options:**
1. **Fix P1 issues** - Address critical findings now
2. **Create follow-up tasks** - Track P2/P3 for later
3. **Re-review** - Run again after changes
4. **Export findings** - Save to file for tracking
```

