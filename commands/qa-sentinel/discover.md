---
name: qa-sentinel:discover
description: Discover and author NL test specifications through app scanning, doc import, or guided conversation
argument-hint: "[--scan | --import <path> | <area-name> for interactive discovery]"
---

# Discover Test Specifications

Build NL test specs by scanning the live app, importing from existing docs, or guided conversation.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

Parse input to determine discovery mode:

| Input Pattern | Mode | Action |
|---------------|------|--------|
| `--scan` | Sitemap Scan | Launch browser, explore app, build feature map |
| `--import <path>` | Doc Import | Extract specs from existing markdown/docs |
| `<area-name>` | Interactive | Guide user through spec creation for an area |
| Empty | Auto-detect | Check for sitemap, suggest next step |

## Load Configuration

Read `sentinel.config.yaml` and extract `app.base_url`, `specs.nl_dir`, and `auth` settings. If no config exists, tell the user to run `qa-sentinel:setup` first and stop.

---

## Mode 1: Sitemap Scan (`--scan`)

Systematically explore the running application to build a feature map organized by priority tier.

### Step 1: Launch Browser and Navigate

Use Playwright MCP to open the app:

1. If the config has a `bridge` section with a `shim_path`, inject the bridge shim first using `browser_run_code` with `page.addInitScript()`
2. Navigate to `base_url` from config using `browser_navigate`
3. Wait for page load using `browser_wait_for`
4. Take a snapshot with `browser_snapshot` to capture initial navigation structure

### Step 2: Authenticate (if needed)

If `auth.strategy` is `credentials`:

1. Navigate to `auth.login_url` using `browser_navigate`
2. Use `browser_fill_form` to fill credentials from config (resolve password from env var)
3. Click the submit button using `browser_click` with the button's `ref` from the snapshot
4. Verify authentication succeeded by taking a `browser_snapshot` and checking for redirect or user indicator

### Step 3: Explore Navigation

Systematically discover the app's structure:

1. Take a snapshot of the main page using `browser_snapshot`
2. Identify all navigation elements (nav bars, sidebars, menus, tabs) from `ref` attributes
3. For each top-level navigation link:
   - Click it using `browser_click` with its `ref`
   - Take a `browser_snapshot`
   - Record the URL path, page title, and key interactive elements (forms, buttons, tables, modals)
   - Identify sub-navigation if present and follow one level deep
4. Look for common patterns:
   - Auth pages (login, register, forgot password)
   - Dashboard / home
   - CRUD resource pages (list, detail, create, edit)
   - Settings / profile / account pages
   - Search functionality
   - Admin sections

### Step 4: Build Feature Map by Priority Tier

Organize discoveries into functional areas, grouped by priority:

```markdown
# Sitemap: [App Name]

Scanned: [timestamp]
Base URL: [base_url]

## P0 — Data Loss Prevention

Features where failure could cause permanent data loss or corruption.

- [Feature] (`/path`) — [why data-loss risk]

## P1 — Core Flows

Features that must work for the app to be usable.

### [area-name]
- [Page] (`/path`) — [key elements]

## P2 — Advanced Features

Important features that power users rely on.

### [area-name]
- [Page] (`/path`) — [key elements]

## P3 — Edge Cases

Boundary conditions and unusual but valid scenarios.

- [Feature] — [edge case description]
```

### Step 5: Save Sitemap

Write the feature map to `specs/_sitemap.md`.

### Step 6: Present Results

Show the user the discovered areas and suggest next steps:

```
Discovered [N] functional areas with [M] total pages.

Priority breakdown:
  P0 (data-loss): [n] features
  P1 (core):      [n] features
  P2 (advanced):  [n] features
  P3 (edge):      [n] features

Next steps:
  Run interactive discovery for each area to create NL specs:
    /qa-sentinel:discover auth
    /qa-sentinel:discover dashboard
    ...

  Start with P0 and P1 features for maximum coverage impact.
```

---

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
6. Set `seed` to `tests/seed.spec.ts`
7. Write an Overview section explaining why the feature matters
8. Write numbered H3 scenarios with step-by-step actions and **Expected:** lines
9. Extract test data into the Test Data table

Use the template from @qa-sentinel `templates/spec-template.md` as the structural basis.

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
5. Audit drift — `/qa-sentinel:audit` to keep specs and tests aligned
```

---

## Mode 3: Interactive Discovery (`<area-name>`)

Guide the user through creating NL test specs for a specific functional area.

### Step 1: Load Context

Check if `specs/_sitemap.md` exists:
- If yes, read it and find the section for `<area-name>`. Use the discovered pages and elements as context.
- If no, proceed without pre-existing context.

Check if any specs already exist for this area by looking for files matching `specs/<area-name>-*.md`.

If specs exist, mention them so the user can decide whether to add or replace.

### Step 2: Gather Information

Use `AskUserQuestion` for each prompt. Ask one question at a time and wait for the answer before proceeding.

**Question 1: Main User Flows**
> "What are the main things a user does in the [area-name] area? Describe the key user flows or actions."

**Question 2: Critical Happy Path**
> "Which of these flows is the most critical — the one that absolutely must work? What does the ideal path look like step by step?"

**Question 3: Error Cases**
> "What are the common error cases? What happens when users provide bad input or do something wrong?"

**Question 4: Edge Cases**
> "Are there any edge cases or tricky scenarios you're worried about? (e.g., race conditions, unusual data, permissions issues)"

**Question 5: Persona**
> "Which persona does this flow primarily serve? (new-user = someone setting up for the first time, power-user = someone using advanced features daily, returning-user = someone resuming work)"

**Question 6: Test Data**
> "What test data is needed? (e.g., test accounts, specific values, environment setup)"

### Step 3: Generate NL Spec

From the user's answers, create a structured NL spec file:

1. Derive spec `id` and feature name from the area and user's description
2. Set `area`, `priority`, `persona`, `tags`, and `seed` in the YAML frontmatter
3. Write an Overview from the user's flow descriptions
4. Build Preconditions from test data and setup requirements
5. Create numbered H3 scenario sections with step-by-step actions and **Expected:** lines
6. Populate the Test Data table
7. Add Notes if the user mentioned known issues or constraints

Follow the template from @qa-sentinel `templates/spec-template.md` exactly.

### Step 4: Write Spec File

Write to `specs/<area-name>-<feature>.md`.

### Step 5: Present for Review

Show the complete generated spec to the user. Use `AskUserQuestion`:

> "Here is the generated spec. Would you like to make any changes, or does this look good?"

If changes are requested, edit the file accordingly.

### Step 6: Planner Handoff

```
Spec saved: specs/<area-name>-<feature>.md

Next steps:
1. Discover another feature in this area
2. Discover a different area
3. Generate tests from this spec using Playwright Planner/Generator
4. Done for now
```

Use `AskUserQuestion` to let the user choose.

---

## No Arguments — Auto-Detect

If `$ARGUMENTS` is empty:

1. Check if `specs/_sitemap.md` exists

**If sitemap exists:**

Read the sitemap and show discovered areas. Use `AskUserQuestion`:

> "Sitemap found with these areas: [list areas]. Which area would you like to discover specs for? Or type '--scan' to re-scan the app."

Then proceed with interactive discovery for the chosen area.

**If no sitemap:**

> "No sitemap found. Would you like to scan the app first? Run with --scan to explore the app and build a feature map, or provide an area name to start interactive discovery directly."

---

## Key Principles

### Specs Must Be Concrete

Every generated scenario must have:
- A numbered H3 heading with a descriptive title
- Specific step-by-step user actions
- An **Expected:** line that is observable and verifiable

### Persona Tagging Is Required

Every spec needs a `persona` field. This helps the Planner understand who is doing the action and what prior state to assume:
- `new-user` — first-time setup, no existing data
- `power-user` — heavy usage, complex data, advanced features
- `returning-user` — resuming work, existing data present

### Priority Reflects Risk

- P0 — data loss or corruption possible
- P1 — app is unusable without this working
- P2 — meaningful feature, app is still usable without it
- P3 — edge case or boundary condition

### Interactive Over Assumed

When in doubt, ask the user rather than guess. A spec based on real knowledge is worth more than one filled with assumptions.
