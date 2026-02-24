# Spec Format Reference

NL specs are structured markdown files that define what to test and what to expect. Each spec covers a single feature or functional area. They are the contract between sentinel (authoring) and Playwright's Planner (test generation).

## File Location and Naming

Specs live in the configured `specs_dir` (default: `./specs` relative to sentinel config).

Naming convention: `{area}-{feature}.md`
Examples: `checkout-payment.md`, `auth-login.md`, `dashboard-widgets.md`

Note: No `.spec.md` suffix — that suffix is reserved for generated Playwright test files.

## YAML Frontmatter

Every spec file starts with YAML frontmatter:

```yaml
---
id: WORKSPACE-CREATE
area: workspace-management
priority: P0
persona: new-user
tags: [data-loss-prevention, core-flow]
seed: tests/seed.spec.ts
---
```

### Fields

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier. Uppercase, hyphenated. Used for cross-references and audit tracking. |
| `area` | Yes | Functional area for grouping and coverage rollup (e.g., `workspace-management`, `auth`, `editor`). |
| `priority` | Yes | `P0` (data-loss-prevention), `P1` (core-flow), `P2` (advanced), or `P3` (edge-case). |
| `persona` | Yes | Target user type: `new-user`, `power-user`, or `returning-user`. |
| `tags` | No | Array of free-form tags for filtering and cross-referencing. |
| `seed` | No | Path to the seed spec file (e.g., `tests/seed.spec.ts`). Generated tests import fixtures from the seed. |

### Priority Definitions

| Priority | Label | Meaning |
|----------|-------|---------|
| `P0` | data-loss-prevention | Scenarios where failure could cause permanent data loss. Run first, must pass. |
| `P1` | core-flow | Critical user journeys required for basic product function. |
| `P2` | advanced | Important but non-blocking features and secondary flows. |
| `P3` | edge-case | Boundary conditions and unusual but valid situations. |

### Persona Definitions

| Persona | Meaning |
|---------|---------|
| `new-user` | First-time user with no prior knowledge of the app. |
| `power-user` | Experienced user who knows the app well and uses advanced features. |
| `returning-user` | User who has used the app before but may need to re-orient. |

### What the Planner Sees

The Planner agent ignores YAML frontmatter entirely. It consumes only the markdown body (Overview, Preconditions, Scenarios, Test Data). The frontmatter is sentinel metadata used for audit, coverage rollup, and filtering — not test generation.

## Spec Body Sections

### Overview

Brief description of the feature under test and why it matters. Replaces "Context" from older formats. Gives the Planner enough background to understand domain intent.

```markdown
## Overview

The workspace creation flow is the first action a new user takes in the app.
A workspace is the top-level container for all pages and content.
This flow must be reliable and clear — failure here blocks all other usage.
```

### Preconditions

State that must be true before any scenario in this spec can run. The Planner uses these to set up test fixtures and before-hooks.

```markdown
## Preconditions

- Application is running and accessible at the base URL
- No workspace exists (fresh state or reset)
- User has not previously completed onboarding
```

### Scenarios

The core of the spec. Scenarios are numbered H3 sections. Each scenario has a title and a list of steps ending with a `**Expected:**` line.

```markdown
## Scenarios

### 1. Create workspace with valid name
- Navigate to the application
- Enter workspace name "My First Workspace"
- Click create
- **Expected:** Workspace created, editor view with sidebar visible

### 2. Attempt empty name
- Leave name field empty, attempt submit
- **Expected:** Validation error, form not submitted

### 3. Name at maximum length
- Enter a name at the character limit
- Click create
- **Expected:** Workspace created successfully with full name displayed
```

#### Scenario Format Rules

- Each scenario is a numbered H3 heading (`### 1. Title`)
- Steps are a plain bullet list (no checkboxes, no IDs)
- The last bullet must be `**Expected:** <observable outcome>`
- Expected outcomes must be concrete and verifiable — not "it works"
- No scenario IDs like `PAY-01` — numbered sections are the reference

### Test Data

Specific data values needed for scenarios. Keeps test data close to the scenarios that use it.

```markdown
## Test Data

| Label | Value | Notes |
|-------|-------|-------|
| Default name | My First Workspace | Standard input for happy path |
| Max length name | (64 characters) | At character limit |
| Invalid chars | My/Workspace | Slash is not permitted |
```

### Notes

Optional section for anything that doesn't fit elsewhere — known issues, environment constraints, related specs.

```markdown
## Notes

- Workspace name validation is client-side only in the current release.
- Related specs: `workspace-management-rename.md`, `workspace-management-delete.md`.
```

## Complete Example (Good)

```markdown
---
id: WORKSPACE-CREATE
area: workspace-management
priority: P0
persona: new-user
tags: [data-loss-prevention, core-flow]
seed: tests/seed.spec.ts
---

# Workspace Creation

## Overview

The workspace creation flow is the first action a new user takes in the app.
A workspace is the top-level container for all pages and content.
This flow must be reliable and clear — failure here blocks all other usage.

## Preconditions

- Application is running and accessible at the base URL
- No workspace exists (fresh state or reset)
- User has not previously completed onboarding

## Scenarios

### 1. Create workspace with valid name
- Navigate to the application
- Enter workspace name "My First Workspace"
- Click create
- **Expected:** Workspace created, editor view with sidebar visible

### 2. Attempt empty name
- Leave name field empty, attempt submit
- **Expected:** Validation error shown, form not submitted

### 3. Name with special characters
- Enter workspace name "Work/Space"
- Attempt to submit
- **Expected:** Validation error, slash character rejected

## Test Data

| Label | Value | Notes |
|-------|-------|-------|
| Default name | My First Workspace | Standard happy path input |
| Invalid chars | Work/Space | Slash is not permitted |

## Notes

- Workspace name validation is client-side only in the current release.
- Related specs: `workspace-management-rename.md`.
```

## Bad Example (Common Mistakes)

```markdown
---
id: workspace
feature: Workspace
area: workspaces
priority: high
dependencies:
  - AUTH-LOGIN
---

## Scenarios

- [ ] `WS-01` Test workspace creation works → it works
- [ ] Check validation
- [ ] Try edge cases
```

**What's wrong:**

| Problem | Why it matters |
|---------|----------------|
| `priority` uses "high" instead of P0/P1/P2/P3 | Not machine-parseable, inconsistent with coverage model |
| `feature` and `dependencies` fields | These fields are not part of the NL spec format |
| Checkbox markers `[ ]` and scenario IDs `WS-01` | New format uses numbered H3 headings, not checkboxes or IDs |
| `→ it works` as expected result | Not observable or verifiable — what exactly should be visible? |
| Vague scenario descriptions | Not actionable for the Planner — what name? what flow? |
| Missing Overview, Preconditions, Test Data | Planner lacks context for fixture setup |

## What Makes a Good NL Spec

1. **Concrete expected results** — Every scenario ends with `**Expected:**` describing exactly what should be observable. "Workspace created" is vague; "editor view with sidebar visible" is testable.

2. **Specific steps** — Scenarios describe exactly what to do: which button to click, what value to enter, which page to navigate to. The Planner should not have to guess interaction steps.

3. **Clear preconditions** — Required state before testing begins is documented, including test accounts, data setup, and environment configuration.

4. **Appropriate scope** — One spec per feature. If a spec has more than ~12 scenarios, consider splitting it into sub-features.

5. **Planner-friendly language** — Write in plain imperative English. The Planner reads the markdown body and generates test code; ambiguous phrasing produces ambiguous tests.
