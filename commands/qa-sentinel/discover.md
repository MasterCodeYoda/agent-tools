---
name: qa-sentinel:discover
description: Discover and document test specifications through app scanning, doc import, or guided conversation
argument-hint: "[--scan | --import <path> | <area-name> for interactive discovery]"
---

# Discover Test Specifications

Build structured test specs by scanning the live app, importing from existing docs, or guided conversation.

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

```bash
# Find and read Sentinel config
cat tests/qa-sentinel/sentinel.config.yaml
```

Extract `base_url`, `specs_dir`, and `auth` settings. If no config exists, tell the user to run `qa-sentinel:setup` first and stop.

---

## Mode 1: Sitemap Scan (`--scan`)

Systematically explore the running application to build a feature map.

### Step 1: Launch Browser and Navigate

Use Chrome DevTools MCP to open the app:

1. Navigate to `base_url` from config
2. Wait for page load
3. Take a snapshot to capture initial navigation structure

### Step 2: Authenticate (if needed)

If `auth.strategy` is `credentials`:

1. Navigate to `auth.login_url`
2. Fill in credentials from config (resolve password from env var)
3. Submit login form
4. Verify authentication succeeded by checking for redirect or user indicator

### Step 3: Explore Navigation

Systematically discover the app's structure:

1. Take a snapshot of the main page
2. Identify all navigation elements (nav bars, sidebars, menus, tabs)
3. For each top-level navigation link:
   - Navigate to it
   - Take a snapshot
   - Record the URL path, page title, and key interactive elements (forms, buttons, tables, modals)
   - Identify sub-navigation if present and follow one level deep
4. Look for common patterns:
   - Auth pages (login, register, forgot password)
   - Dashboard / home
   - CRUD resource pages (list, detail, create, edit)
   - Settings / profile / account pages
   - Search functionality
   - Admin sections

### Step 4: Build Feature Map

Organize discoveries into functional areas:

```markdown
# Sitemap: [App Name]

Scanned: [timestamp]
Base URL: [base_url]

## Areas Discovered

### auth
- Login page (`/login`) — email/password form, "Forgot password" link
- Registration page (`/register`) — signup form with email, password, name
- Password reset (`/forgot-password`) — email input form

### dashboard
- Main dashboard (`/dashboard`) — stats widgets, recent activity feed, quick actions
- ...

### [area-name]
- [Page] (`/path`) — [key elements]
- ...
```

### Step 5: Save Sitemap

Write the feature map to `tests/qa-sentinel/specs/_sitemap.md`.

### Step 6: Present Results

Show the user the discovered areas and suggest next steps:

```
Discovered [N] functional areas with [M] total pages.

Areas found:
  - auth (3 pages)
  - dashboard (2 pages)
  - [area] ([n] pages)
  ...

Next steps:
  Run interactive discovery for each area to create test specs:
    /qa-sentinel:discover auth
    /qa-sentinel:discover dashboard
    ...
```

---

## Mode 2: Import from Docs (`--import <path>`)

Extract test specifications from existing documentation files.

### Step 1: Read Source Files

The `<path>` argument can be:
- A single markdown file: `--import ./docs/features.md`
- A directory: `--import ./docs/`
- A glob pattern: `--import "./docs/**/*.md"`

```bash
# List files to import
ls <path>
# or for glob patterns
find <path> -name "*.md" -type f
```

Read each file and extract testable content.

### Step 2: Extract Features and Scenarios

From each document, identify:

- **Feature names** — section headings describing capabilities
- **User stories** — "As a... I want... So that..." patterns
- **Acceptance criteria** — checkboxes, numbered steps, "should" statements
- **Behaviors** — descriptions of what happens when users take actions
- **Error cases** — mentions of validation, error messages, edge cases
- **Test data** — any specific values, accounts, or configuration mentioned

### Step 3: Map to Spec Format

For each distinct feature found, generate a spec file following the format in @qa-sentinel `references/spec-format.md`:

1. Derive a unique spec `id` from the area and feature (e.g., `AUTH-LOGIN`, `DASH-WIDGETS`)
2. Set `area` based on the functional grouping
3. Assign `priority` — P1 for core flows mentioned as critical, P2 for standard features, P3 for edge cases
4. Generate scenario IDs following `{SPEC-PREFIX}-{NN}` convention
5. Write each scenario with specific actions and expected results (using `→`)
6. Infer preconditions from context
7. Extract test data into the Test Data table

Use the template from @qa-sentinel `templates/spec-template.md` as the structural basis.

### Step 4: Write Spec Files

Write generated specs to `tests/qa-sentinel/specs/{area}/{feature}.spec.md`:

```bash
mkdir -p tests/qa-sentinel/specs/{area}
```

### Step 5: Present for Review

For each generated spec, show the user:

```
Generated: tests/qa-sentinel/specs/auth/auth-login.spec.md
  - ID: AUTH-LOGIN
  - Area: auth
  - Priority: P1
  - Scenarios: 6 (3 happy path, 2 validation, 1 edge case)

Review this spec? (The file has been written — edit it directly or confirm to continue.)
```

Use `AskUserQuestion` to let the user review each spec and request changes before moving on.

### Step 6: Validate

After all specs are generated, run validation:

```bash
npx sentinel validate
```

Report any issues found and offer to fix them.

---

## Mode 3: Interactive Discovery (`<area-name>`)

Guide the user through creating test specs for a specific functional area.

### Step 1: Load Context

Check if `tests/qa-sentinel/specs/_sitemap.md` exists:
- If yes, read it and find the section for `<area-name>`. Use the discovered pages and elements as context.
- If no, proceed without pre-existing context.

Check if any specs already exist for this area:

```bash
ls tests/qa-sentinel/specs/<area-name>/ 2>/dev/null
```

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

**Question 5: Test Data**
> "What test data is needed? (e.g., test accounts, specific values, environment setup)"

### Step 3: Generate Spec

From the user's answers, create a structured spec file:

1. Derive spec `id` and feature name from the area and user's description
2. Write a Context section from the user's flow descriptions
3. Build Preconditions from test data and setup requirements
4. Create scenarios with proper IDs, specific actions, and expected results (using `→`)
5. Organize into Happy Path, Validation, and Edge Cases groups
6. Populate the Test Data table
7. Add Notes if the user mentioned known issues or constraints

Follow the format in @qa-sentinel `references/spec-format.md` exactly. Use the template from @qa-sentinel `templates/spec-template.md`.

### Step 4: Write Spec File

```bash
mkdir -p tests/qa-sentinel/specs/<area-name>
```

Write to `tests/qa-sentinel/specs/<area-name>/<feature>.spec.md`.

### Step 5: Present for Review

Show the complete generated spec to the user. Use `AskUserQuestion`:

> "Here is the generated spec. Would you like to make any changes, or does this look good?"

If changes are requested, edit the file accordingly.

### Step 6: Offer Next Steps

```
Spec saved: tests/qa-sentinel/specs/<area-name>/<feature>.spec.md

What's next?
1. Discover another feature in this area
2. Discover a different area
3. Run validation on all specs
4. Done for now
```

Use `AskUserQuestion` to let the user choose.

---

## No Arguments — Auto-Detect

If `$ARGUMENTS` is empty:

1. Check if `tests/qa-sentinel/specs/_sitemap.md` exists

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
- A unique scenario ID (`ID-NN` format)
- Specific user actions (not vague descriptions)
- An expected result after `→` that is observable and verifiable

### IDs Must Be Unique

- Spec IDs are uppercase with hyphens: `AUTH-LOGIN`, `PAY-CHECKOUT`
- Scenario IDs follow `{SPEC-PREFIX}-{NN}`: `AUTH-01`, `AUTH-02`
- Check existing specs to avoid ID collisions

### Follow the Format

Generated specs must match `references/spec-format.md` exactly — YAML frontmatter with required fields, standard section headings (Context, Preconditions, Scenarios, Test Data, Notes), and proper scenario line format.

### Interactive Over Assumed

When in doubt, ask the user rather than guess. A spec based on real knowledge is worth more than one filled with assumptions.
