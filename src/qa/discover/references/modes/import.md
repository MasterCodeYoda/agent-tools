# Mode 2: Import from Docs

Load when `/qa:discover --import <path>`.

## Mode 2: Import from Docs (`--import <path>`)

Extract NL test specifications from existing documentation files.

### Step 1: Read Source Files

The `<path>` argument can be:
- A single markdown file: `--import ./docs/features.md`
- A directory: `--import ./docs/`
- A glob pattern: `--import "./docs/**/*.md"`

Read each file and extract testable content.

### Step 2: Extract Features and Scenarios

From each document, identify:

- **Feature names** — section headings describing capabilities
- **User stories** — "As a... I want... So that..." patterns
- **Acceptance criteria** — checkboxes, numbered steps, "should" statements
- **Behaviors** — descriptions of what happens when users take actions
- **Error cases** — mentions of validation, error messages, edge cases
- **Test data** — any specific values, accounts, or configuration mentioned

### Step 3: Map to NL Spec Format

For each distinct feature found, generate a spec file:

1. Derive a unique spec `id` from the area and feature (e.g., `AUTH-LOGIN`, `DASH-WIDGETS`)
2. Set `area` based on the functional grouping
3. Assign `priority` — P0 for data-loss risk, P1 for core flows mentioned as critical, P2 for standard features, P3 for edge cases
4. Assign `persona` based on who the feature serves: `new-user`, `power-user`, or `returning-user`
5. Set `tags` based on classification (e.g., `[core-flow, data-loss-prevention]`)
6. Set `seed` to `specs.seed` from `sentinel.config.yaml`
7. Write an Overview section explaining why the feature matters
8. Write numbered H3 scenarios with step-by-step actions and **Expected:** lines
9. Extract test data into the Test Data table

Use the template from @qa `templates/spec-template.md` as the structural basis.

### Step 4: Write Spec Files

Write generated specs to `specs/{area}-{feature}.md`:

```bash
mkdir -p specs
```

File naming convention: `{area}-{feature}.md` (no `.spec.md` suffix).

### Step 5: Present for Review

For each generated spec, show the user:

```
Generated: specs/auth-login.md
  - ID: AUTH-LOGIN
  - Area: auth
  - Priority: P1
  - Persona: new-user
  - Scenarios: 6 (3 happy path, 2 validation, 1 edge case)

Review this spec? (The file has been written — edit it directly or confirm to continue.)
```

Use `AskUserQuestion` to let the user review each spec and request changes before moving on.

### Step 6: Planner Handoff

After all specs are generated, explain the next steps:

```
NL specs generated in specs/. Next steps:

1. Review and refine specs — edit any spec files directly in specs/
2. Run Playwright Planner — the Planner reads your NL specs and creates a test plan
3. Run Playwright Generator — converts the plan into .spec.ts files in tests/
4. Run tests — `npx playwright test` to execute
5. Audit drift — `/workflow:audit` (qa domain) to keep specs and tests aligned (planned dedicated `/qa:audit`)
```

---

