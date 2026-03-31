---
name: workflow:review
description: Flexible code review for PRs, git ranges, files, or uncommitted changes
argument-hint: "[PR number, git range, file paths, or 'changes' for uncommitted]"
---

# Flexible Code Review

Review code changes with configurable depth - supports PRs, git ranges, specific files, or uncommitted changes.

## User Input

```text
$ARGUMENTS
```

## Target Detection

Parse input to determine review target:

| Input Pattern | Review Target | Action |
|--------------|---------------|--------|
| `123` or `#123` | Pull Request | `gh pr view 123` |
| `PR-123` or `pr 123` | Pull Request | `gh pr view 123` |
| `main..HEAD` | Git range | `git diff main..HEAD` |
| `main from tag 'v1.0' to HEAD` | Natural language range | Parse and convert to git range |
| `origin/main...feature` | Three-dot range | `git diff origin/main...feature` |
| `./src/` or `path/to/file` | Files/directories | Review specified paths |
| `changes` or empty | Uncommitted | `git diff` (staged + unstaged) |
| `staged` | Staged only | `git diff --staged` |

### Natural Language Parsing

Support human-readable range descriptions:

```
"main from tag 'production' to HEAD"
  -> git log production..HEAD

"changes since last release"
  -> git diff $(git describe --tags --abbrev=0)..HEAD

"commits on feature branch"
  -> git diff main...HEAD
```

## Setup Phase

### 1. Identify Changes

Run all git commands from the working directory. Do not use `git -C <path>` unless the working directory cannot be the
target repo.

```bash
# For PR
gh pr view $PR_NUMBER --json files,additions,deletions,title,body

# For git range
git diff --stat $RANGE
git log --oneline $RANGE

# For files/directories
git diff -- $PATHS
git status -- $PATHS

# For uncommitted
git status
git diff
git diff --staged
```

### 2. Understand Scope

Analyze changes to determine:
- Total files changed
- Lines added/removed
- Languages/technologies involved
- Affected components/layers
- Test coverage changes

### 3. Locate Plan and Acceptance Criteria (if available)

Check whether an implementation plan or requirements exist for the changes under review. The source depends on the
requirements source mode:

```bash
# Check for planning docs in the repo
ls ./planning/*/implementation-plan.md 2>/dev/null
ls ./planning/*/session-state.md 2>/dev/null
ls ./planning/*/requirements.md 2>/dev/null
```

**Determine requirements source**:
1. If `session-state.md` exists and has `requirements_source: pm` → use PM mode
2. If `session-state.md` exists and has `requirements_source: file` → use file mode
3. If `requirements.md` exists → file mode
4. If no `requirements.md` but a `work_item` is recorded in session state → PM mode
5. If reviewing a PR with issue references (e.g., `LIN-123`, `PROJ-456`) → fetch criteria from PM issue

**File mode**: Load and extract:
- Acceptance criteria from `requirements.md`
- Definition of Done checklist from `implementation-plan.md`
- Task breakdown (to verify all planned tasks were addressed)

**PM mode**: Fetch acceptance criteria from the PM issue using the Issue Retrieval Strategy from @workflow-guide
(PM integration). Also load Definition of Done and task breakdown from `implementation-plan.md` (which exists in both
modes).

**If no plan or criteria found**: Skip the acceptance criteria review agent — code quality review proceeds as normal.
Note the absence in the review output:
```markdown
**Acceptance Criteria**: No plan, requirements doc, or linked PM issue found — criteria verification skipped.
```

### 4. Select Review Depth

Based on scope, recommend depth:

| Depth | When to Use | Agents |
|-------|-------------|--------|
| **Quick** | Small changes (<100 lines, <5 files) | 2 |
| **Standard** | Most reviews | 5 |
| **Deep** | Large/complex changes, security-sensitive | 8 |

Ask user to confirm: "This looks like a [quick/standard/deep] review. Proceed?"

## Agent Orchestration

For review criteria and quality standards, reference @workflow-guide (`implementation/quality-checkpoints.md`)

### Quick Review (2 agents)

Run in parallel:

**code-quality-reviewer**:
- Code clarity and readability
- Pattern consistency
- Obvious bugs or issues
- Test coverage

**security-basics**:
- Input validation
- Obvious vulnerabilities
- Sensitive data handling

### Standard Review (5 agents)

Run in parallel:

**code-quality-reviewer**: (as above)

**security-sentinel**:
- OWASP Top 10 checks
- Authentication/authorization
- Data protection
- Injection vulnerabilities

**performance-oracle**:
- N+1 queries
- Inefficient algorithms
- Resource leaks
- Caching opportunities

**architecture-strategist**:
- Layer violations
- Dependency direction
- Pattern consistency
- Coupling/cohesion

**test-reviewer** — References @test-strategy:
- Test coverage for changed code
- Test quality and assertion strength (see `references/test-quality.md`)
- Edge cases for changed logic
- Regression risk assessment
- If mutation tool available: flag domain logic changes lacking mutation testing coverage

**acceptance-criteria-verifier** (only when plan/requirements/PM issue found in §3):
- Load acceptance criteria from the appropriate source: `requirements.md` (file mode) or PM issue (PM mode) via
  Issue Retrieval Strategy from @workflow-guide (PM integration)
- Cross-reference each acceptance criterion against the changes — is it addressed?
- Check the plan's Definition of Done checklist — are all items satisfiable from the diff?
- Verify all planned tasks are reflected in the changes (no missing slices)
- Flag criteria that appear unmet or only partially addressed as P1 findings
- Flag planned tasks with no corresponding changes as P2 findings
- If the plan has an Out of Scope section, verify nothing out-of-scope crept in

### Deep Review (8+ agents)

Standard agents (including acceptance-criteria-verifier when plan available) plus:

**domain-expert** (based on file types):
- Language-specific best practices
- Framework conventions
- Idiomatic code

**data-integrity-guardian**:
- Database migrations
- Data consistency
- Transaction handling

**observability-analyst**:
- Logging adequacy
- Monitoring hooks
- Debug-ability

## Findings Structure

### Priority Classification

**P1 - Critical (Blocks Merge)**
- Security vulnerabilities
- Data corruption risks
- Breaking changes
- Critical bugs

**P2 - Important (Should Fix)**
- Performance issues
- Architectural concerns
- Code quality problems
- Missing tests

**P3 - Nice to Have (Optional)**
- Style improvements
- Minor optimizations
- Documentation gaps
- Refactoring opportunities

### Finding Format

```markdown
### [P1/P2/P3] [Category]: [Title]

**Location**: `file/path.ext:line`

**Issue**:
[Description of the problem]

**Impact**:
[Why this matters]

**Suggestion**:
[How to fix]

**Code Example** (if helpful):
```[language]
# Before
[problematic code]

# After
[suggested fix]
```
```

## Review Output

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

## Special Review Modes

### Pre-Commit Review

Before committing:
```bash
/workflow:review changes
```

Focuses on:
- Accidental debug code
- Sensitive data in code
- Incomplete implementations
- Missing tests for changes

### Deployment Range Review

Before deploying:
```bash
/workflow:review "production..HEAD"
```

Focuses on:
- Breaking changes
- Migration safety
- Rollback considerations
- Feature flags

### Security-Focused Review

For security-sensitive changes:
```bash
/workflow:review #123 --depth deep
```

Enhanced focus on:
- Authentication flows
- Authorization checks
- Data encryption
- Input sanitization
- OWASP compliance

## Integration Points

### With PR Comments (if PR target)

Option to post findings:
```markdown
Post review findings to PR?
1. Yes - Add as PR comment
2. No - Keep local only
```

### With /workflow:plan and /workflow:execute

Review automatically loads acceptance criteria to verify completeness — not just code quality. In file mode, criteria come from `requirements.md`. In PM mode, criteria are fetched from the linked PM issue. `implementation-plan.md` provides the Definition of Done and task breakdown in both modes. This closes the loop between what was planned and what was delivered. Unmet criteria are flagged as P1 (blocking) findings.

### With /workflow:compound

If significant issues found and fixed:
```markdown
Document the fix pattern?
1. Yes - Run /workflow:compound
2. No - Skip
```

### With Session State

If reviewing during execute session, findings can inform session notes.

## Quality Principles

### Reasoning Rigor

Every review finding must be grounded in evidence, not intuition:

- **Cite evidence for every claim.** Reference specific `file:line` locations. If you can't point to a concrete location, you haven't verified the claim.
- **Trace, don't assume.** When a finding involves a function call, follow it to its actual definition. A function named `validate()` might be shadowed, overridden, or intercepted by a framework.
- **Check the opposite hypothesis.** Before flagging a P1 or P2 finding, ask: "What if this code is actually correct?" Look for evidence that would refute your finding (guards elsewhere, framework behavior, test coverage). If you find it, downgrade or retract.
- **Distinguish crash sites from root causes.** A bug manifesting at line 200 may originate at line 50. Trace back to where the incorrect behavior begins, not where it surfaces.

### Focus on Impact
- P1 issues are blockers
- P2 issues improve quality
- P3 issues are suggestions
- Don't overwhelm with minor issues

### Be Constructive
- Explain why issues matter
- Provide concrete suggestions
- Acknowledge good practices
- Focus on code, not author

### Scale Appropriately
- Quick reviews for small changes
- Deep reviews for critical paths
- Don't over-review trivial changes
- Don't under-review complex changes

## Common Review Patterns

### Database Changes
- Migration reversibility
- Index implications
- Data integrity
- Performance impact

### API Changes
- Breaking changes
- Versioning
- Documentation
- Error handling

### Security Changes
- Auth flow correctness
- Permission checks
- Data exposure
- Audit logging

### UI Changes
- Accessibility
- Responsive design
- Error states
- Loading states
