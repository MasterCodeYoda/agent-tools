---
# ── Sentinel NL Spec ─────────────────────────────────────────────────
# id:       Unique uppercase identifier (e.g., WORKSPACE-CREATE)
# area:     Functional area for grouping (e.g., workspace-management)
# priority: P0 (data-loss) | P1 (core) | P2 (advanced) | P3 (edge)
# persona:  new-user | power-user | returning-user
# tags:     Classification tags (e.g., [data-loss-prevention, core-flow])
# seed:     Path to seed spec file (e.g., tests/seed.spec.ts)
# ──────────────────────────────────────────────────────────────────────
id: FEATURE-NAME
area: area-name
priority: P1
persona: new-user
tags: [tag1, tag2]
seed: tests/seed.spec.ts
---

# Feature Name

## Overview

<!-- Why this feature matters. Domain context that helps the Planner understand
     the significance and scope of what's being tested. -->

## Preconditions

<!-- Required state before any scenario can run. Be specific about accounts,
     data, and environment. -->

- Application is running and accessible
- User is logged in with appropriate permissions

## Scenarios

<!-- Numbered scenarios with step-by-step actions and expected outcomes.
     The Planner reads these to generate .spec.ts test files.
     Each scenario should be independently executable. -->

### 1. [Happy path scenario title]

- [Action step 1]
- [Action step 2]
- **Expected:** [Observable, verifiable outcome]

### 2. [Validation scenario title]

- [Action that triggers validation]
- **Expected:** [Error message or validation behavior]

### 3. [Edge case scenario title]

- [Unusual but valid action]
- **Expected:** [Correct handling of edge case]

## Test Data

<!-- Specific values needed for scenarios. Keep test data close to the
     scenarios that use it. -->

| Label | Value | Notes |
|-------|-------|-------|
| [Data label] | [Value] | [Context or source] |

## Notes

<!-- Optional: Known issues, environment constraints, related specs,
     or anything that doesn't fit elsewhere. -->
