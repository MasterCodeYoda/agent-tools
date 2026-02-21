---
id: AREA-FEATURE        # Unique identifier, uppercase with hyphens (e.g., AUTH-LOGIN, PAY-CHECKOUT)
feature: Feature Name   # Human-readable name of the feature under test
area: area-name         # Functional area for coverage grouping (e.g., auth, payments, catalog)
priority: P2            # P1 = critical path, P2 = important, P3 = edge cases
dependencies:           # Spec IDs that must pass before this spec runs (remove if none)
  - OTHER-SPEC-ID
---

## Context

<!-- Brief description of the feature and why it matters.
     Give enough background for Claude to understand the domain context. -->

## Preconditions

<!-- State that must be true before any scenario can run.
     Include: required user accounts, data setup, environment config. -->

- User is logged in as [test account]
- [Required data or state exists]
- [Environment/config requirement]

## Scenarios

### Happy Path

<!-- Core user flows that must always work. These are your P1 scenarios. -->

- [ ] `ID-01` [User action with specific inputs] → [exact expected outcome]
- [ ] `ID-02` [Another core flow action] → [expected result]

### Validation

<!-- Input validation and error handling. Verify the app rejects bad input correctly. -->

- [ ] `ID-03` [Submit with invalid/missing input] → [specific error message and location]
- [ ] `ID-04` [Another validation case] → [expected error behavior]

### Edge Cases

<!-- Boundary conditions, race conditions, unusual but valid situations. -->

- [ ] `ID-05` [Edge case action] → [expected behavior]

## Test Data

<!-- Specific values needed for scenarios. Keep data close to the tests that use it.
     Never put real credentials here — use env var references. -->

| Label | Value | Notes |
|-------|-------|-------|
| Test user | user@example.com | Password in TEST_USER_PASS env var |
| [Data label] | [Value] | [Notes] |

## Notes

<!-- Optional: known issues, environment constraints, related specs, history. -->
