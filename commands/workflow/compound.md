---
name: workflow:compound
description: Capture knowledge from solved problems to compound your team's effectiveness
argument-hint: "[optional: brief context about what was solved]"
---

# Knowledge Capture and Compounding

Document recently solved problems to build a searchable knowledge base that makes future work easier.

## Purpose

**Why "compound"?** Each documented solution compounds your team's knowledge:
- First time solving a problem: Research (30+ minutes)
- After documenting: Quick lookup (2-3 minutes)
- Knowledge compounds over time

Each unit of engineering work should make subsequent units of work easier, not harder.

## User Input

```text
$ARGUMENTS
```

## Invocation Modes

### 1. Session Boundary (Auto from Execute)
Pre-filled with session context:
```bash
/workflow:compound "Fixed N+1 query in brief generation"
```

### 2. On-Demand
Analyzes recent conversation and commits:
```bash
/workflow:compound
```

### 3. With Context Hint
User provides brief description:
```bash
/workflow:compound "resolved circular dependency in auth module"
```

## Preconditions

Before documenting, verify:

- [ ] **Problem is solved** - Not in-progress
- [ ] **Solution is verified** - Confirmed working
- [ ] **Non-trivial** - Worth documenting (not typos or obvious fixes)

If conditions not met, ask: "Is this problem fully resolved and worth documenting?"

## Parallel Analysis

Launch specialized agents simultaneously for efficient analysis:

### Agent 1: Context Analyzer
Extracts from conversation history:
- Problem type and category
- Component/module affected
- Observable symptoms
- Error messages if any

**Returns**: YAML frontmatter structure

### Agent 2: Solution Extractor
Analyzes investigation and fix:
- Steps tried (what didn't work)
- Root cause identified
- Working solution with code
- Key insights

**Returns**: Solution content block

### Agent 3: Related Docs Finder
Searches existing knowledge:
- Related docs in `docs/solutions/`
- Similar patterns elsewhere
- Cross-references to link
- GitHub issues if applicable

**Returns**: Links and relationships

### Agent 4: Prevention Strategist
Develops preventive measures:
- How to avoid recurrence
- Best practices to follow
- Test cases if applicable
- Warning signs to watch for

**Returns**: Prevention content

### Agent 5: Category Classifier
Determines organization:
- Best-fit category
- Filename from slug
- Tags for searchability
- Related categories

**Returns**: File path and metadata

## Document Categories

Auto-classify into appropriate category:

| Category | When to Use |
|----------|-------------|
| `build-errors/` | Compilation, bundling, dependency issues |
| `test-failures/` | Test suite issues, flaky tests |
| `runtime-errors/` | Exceptions, crashes, unexpected behavior |
| `performance-issues/` | Slow responses, memory leaks, N+1 queries |
| `database-issues/` | Migrations, queries, connection problems |
| `security-issues/` | Vulnerabilities, auth problems |
| `ui-bugs/` | Visual issues, interaction problems |
| `integration-issues/` | API failures, service communication |
| `logic-errors/` | Incorrect behavior, edge cases |

## Output Document

Create `docs/solutions/<category>/<slug>.md`:

```markdown
---
title: [Descriptive Title]
category: [category-name]
created: [timestamp]
symptoms:
  - [Observable symptom 1]
  - [Observable symptom 2]
tags:
  - [tag1]
  - [tag2]
related:
  - [path/to/related/doc]
---

# [Title]

## Problem

[What went wrong - the observable issue]

**Symptoms:**
- [How the problem manifested]
- [Error messages if any]
- [Observable behavior]

## Investigation

[What was tried during debugging]

### Steps Tried
1. [First approach] - [why it didn't work]
2. [Second approach] - [what was learned]
3. [Approach that worked] - [led to solution]

## Root Cause

[Technical explanation of why the problem occurred]

## Solution

[Step-by-step fix with code examples]

### Code Changes

```[language]
# Before (problematic)
[code that caused the issue]

# After (fixed)
[corrected code]
```

### Implementation Notes
- [Important detail 1]
- [Important detail 2]

## Prevention

[How to avoid this in the future]

### Best Practices
- [Practice 1]
- [Practice 2]

### Warning Signs
- [Early indicator 1]
- [Early indicator 2]

### Related Tests
```[language]
# Test to catch this issue
[test code if applicable]
```

## References

- [Link to PR/commit]
- [Link to related documentation]
- [External resources consulted]
```

## Integration Points

### With /workflow:execute

Compound is prompted at session boundaries:

```markdown
This session you solved: [context from session]
Document this for future reference?
1. Yes - create documentation now
2. No - skip
3. Note for later - add to session notes
```

### With Existing Knowledge

Link new docs to related content:
- Add cross-references in related documents
- Update index if exists
- Tag for discoverability

### With AGENTS.md (Optional)

For project-specific learnings:
```markdown
Consider adding to AGENTS.md:
- Pattern: [what we learned]
- When: [when it applies]
```

## Success Output

```markdown
## Knowledge Documented

**File created:**
`docs/solutions/[category]/[slug].md`

**Summary:**
- Problem: [one-line description]
- Category: [category]
- Tags: [tag list]

**Linked to:**
- [Related doc 1]
- [Related doc 2]

**Next time this happens:**
Search for: "[symptoms]" or browse `docs/solutions/[category]/`

---

What's next?
1. Continue workflow
2. View documentation
3. Add to related docs
4. Other
```

## The Compounding Philosophy

```
Build -> Test -> Find Issue -> Research -> Improve -> Document -> Deploy
  ^                                                                  |
  └──────────────────────────────────────────────────────────────────┘
         Each cycle builds on documented knowledge
```

### Value Accumulation

| Occurrence | Without Compound | With Compound |
|------------|------------------|---------------|
| First time | 30+ min research | 30+ min (document) |
| Second time | 20+ min research | 3 min lookup |
| Third time | 15+ min research | 2 min lookup |
| Team member | 30+ min research | 3 min lookup |

### When to Compound

**Always document:**
- Non-obvious solutions
- Environment-specific issues
- Integration problems
- Performance optimizations
- Security fixes

**Skip documenting:**
- Typos and obvious fixes
- One-off issues
- Already well-documented problems
- Trivial configuration changes

## Quality Checklist

Before completing documentation:

- [ ] Problem clearly described
- [ ] Symptoms are searchable
- [ ] Root cause explained
- [ ] Solution is reproducible
- [ ] Prevention strategies included
- [ ] Tags enable discovery
- [ ] Related docs linked
- [ ] Code examples are accurate

## Commands to Remember

```bash
# After solving a problem
/workflow:compound "brief context"

# Search existing solutions
grep -r "symptom" docs/solutions/

# Browse by category
ls docs/solutions/[category]/
```
