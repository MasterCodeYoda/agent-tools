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

### 3. Select Review Depth

Based on scope, recommend depth:

| Depth | When to Use | Agents |
|-------|-------------|--------|
| **Quick** | Small changes (<100 lines, <5 files) | 2 |
| **Standard** | Most reviews | 5 |
| **Deep** | Large/complex changes, security-sensitive | 8 |

Ask user to confirm: "This looks like a [quick/standard/deep] review. Proceed?"

## Agent Orchestration

For review criteria and quality standards, reference @workflow-guide (quality checkpoints)

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

**test-reviewer**:
- Test coverage
- Test quality
- Edge cases
- Regression risk

### Deep Review (8 agents)

Standard agents plus:

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

### Positive Observations

- [Good pattern followed]
- [Well-tested area]
- [Clean implementation]

### Review Agents Used
- [List of agents and focus areas]

## Verdict

[ ] **APPROVE** - No P1 issues, code is ready
[ ] **REQUEST CHANGES** - P1 issues must be addressed
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
