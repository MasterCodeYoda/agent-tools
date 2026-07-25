# Debugging solution document template

Load when writing `.agent-tools/memory/solutions/<category>/<slug>.md`.

## Output Document (debugging-solution path)

Create `.agent-tools/memory/solutions/<category>/<slug>.md`:

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

