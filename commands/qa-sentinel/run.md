---
name: qa-sentinel:run
description: Execute Sentinel specs against the running application via browser automation
argument-hint: "[spec-id, area name, or '--all' for full regression]"
---

# Execute Sentinel Specs

Run spec-driven QA tests against the live application using browser automation via Chrome DevTools MCP. Reference @qa-sentinel for methodology, spec format, and execution model.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

| Input Pattern | Interpretation | Example |
|---------------|----------------|---------|
| Empty or `--all` | Run all specs, sorted by priority then dependency order | `/qa-sentinel:run` |
| Spec ID (uppercase, hyphenated) | Run that single spec | `/qa-sentinel:run PAY-CHECKOUT` |
| Area name (lowercase) | Run all specs in that area | `/qa-sentinel:run payments` |
| Multiple spec IDs | Run listed specs in dependency order | `/qa-sentinel:run AUTH-LOGIN PAY-CHECKOUT` |

## Phase 1: Load Configuration

Read the Sentinel config file:

```bash
cat tests/qa-sentinel/sentinel.config.yaml
```

If the config file does not exist, stop and tell the user: "Sentinel is not set up in this project. Run `/qa-sentinel:setup` first."

Parse the config to extract:
- `app.base_url` — where the application is running
- `auth.strategy` — how to authenticate
- `auth.credentials` — login details (if applicable)
- `browser.viewport` — viewport dimensions
- `browser.timeout` — default timeout for waits
- `evidence.screenshots` — when to capture screenshots (`on_failure`, `always`, `never`)
- `paths.specs_dir` — where spec files live (relative to config directory)
- `paths.runs_dir` — where to write run results

## Phase 2: Resolve Specs

### Scan Spec Files

```bash
find tests/qa-sentinel/specs -name '*.spec.md' -type f
```

Parse the YAML frontmatter of each spec file to extract: `id`, `feature`, `area`, `priority`, `dependencies`.

### Filter by Input

Based on `$ARGUMENTS`:

- **Empty or `--all`**: include all specs
- **Spec ID**: include only the spec whose `id` matches (case-insensitive match, but IDs are conventionally uppercase). Also include any specs listed in its `dependencies` that haven't been run in this session.
- **Area name**: include all specs whose `area` field matches

If no specs match the input, stop and tell the user: "No specs found matching '{input}'. Run `/qa-sentinel:discover` to see available specs."

### Build Execution Order

1. Build a dependency graph from the `dependencies` frontmatter fields
2. Detect circular dependencies — if found, report the cycle and stop
3. Topologically sort specs so dependencies run before dependents
4. Within the same dependency tier, order by priority: P1 first, then P2, then P3

Display the execution plan:

```
## Execution Plan

Running {N} specs in order:

1. AUTH-LOGIN (P1, auth) — no dependencies
2. CART-ADD (P1, catalog) — depends on: AUTH-LOGIN
3. PAY-CHECKOUT (P1, payments) — depends on: AUTH-LOGIN, CART-ADD
```

## Phase 3: Create Run Directory

Generate a timestamped run directory:

```bash
RUN_DIR="tests/qa-sentinel/runs/$(date +%Y-%m-%d-%H%M%S)"
mkdir -p "$RUN_DIR/results"
mkdir -p "$RUN_DIR/evidence"
```

Record the run directory path for use throughout execution.

## Phase 4: Authenticate

Based on the config `auth.strategy`, establish an authenticated session before running specs.

### Strategy: `credentials`

1. Navigate to `{base_url}{login_url}` using `navigate_page`
2. Take a snapshot to find the login form
3. Fill in the username field with `auth.credentials.username`
4. Read the password from the environment variable named in `auth.credentials.password_env`:
   ```bash
   echo $SENTINEL_QA_PASSWORD
   ```
   If the env var is empty or unset, stop and tell the user: "Password env var '{password_env}' is not set. Export it before running tests."
5. Fill in the password field
6. Click the login/submit button
7. Wait for navigation to complete — verify login succeeded by checking the page state (no error messages, redirected away from login page)
8. Take a screenshot as evidence: `{run_dir}/evidence/auth-login-success.png`

If login fails, stop and report: "Authentication failed. Check your credentials and try again."

### Strategy: `token`

```bash
echo $SENTINEL_AUTH_TOKEN
```

If set, the token will need to be injected into requests. Use `evaluate_script` to set the token in localStorage or as a cookie, depending on how the application handles auth tokens.

### Strategy: `cookie`

```bash
echo $SENTINEL_SESSION_COOKIE
```

Use `evaluate_script` to set the session cookie in the browser before navigating to the application.

### Strategy: `none`

No authentication step needed. Navigate directly to `{base_url}` to verify the application is reachable.

### Verify Application is Running

After authentication (or for `none` strategy), confirm the application is reachable:

1. Navigate to `{base_url}` using `navigate_page`
2. Take a snapshot to verify the page loaded (not a connection error or blank page)

If the application is not reachable, stop and tell the user: "Cannot reach the application at {base_url}. Make sure it is running."

## Phase 5: Execute Specs

For each spec in the execution plan, in order:

### 5a. Check Dependencies

Before running a spec, verify that all its dependencies passed in this run session:
- If a dependency was not run (not in the execution plan), skip the check — assume it passed in a prior run
- If a dependency ran and FAILED in this session, SKIP this entire spec with the note: "Dependency {DEP-ID} failed"
- Record a run file for the skipped spec with all scenarios marked SKIP

### 5b. Load Spec

Read the spec file and parse:
- Context section (background understanding)
- Preconditions (state that must be true before execution)
- All scenarios with their IDs, descriptions, expected results, and groups
- Test data table (values to use during execution)

Display:

```
## Running: {feature} ({id}) — {N} scenarios
```

### 5c. Set Up Preconditions

Read the preconditions from the spec. For each precondition:
- Navigate to the appropriate page state
- Verify the precondition is met using `take_snapshot`
- If a precondition cannot be met, SKIP the entire spec with a note explaining which precondition failed

### 5d. Execute Scenarios

For each scenario in the spec, in the order they appear:

#### Read the Scenario

Parse the scenario line: `- [ ] \`SCENARIO-ID\` Description → expected result`

Extract:
- `SCENARIO-ID` — for tracking and evidence naming
- Description — the actions to perform
- Expected result (after `→`) — what to verify

#### Drive the Browser

Interpret the scenario description and perform the actions using Chrome DevTools MCP tools:

- **Navigate**: Use `navigate_page` to go to URLs
- **Understand page state**: Use `take_snapshot` to read the accessibility tree — this is your primary way to understand what is on the page. Prefer snapshots over screenshots for understanding structure.
- **Click elements**: Use `click` with the `uid` of elements found in the snapshot
- **Fill form fields**: Use `fill` or `fill_form` with values from the scenario or Test Data table
- **Press keys**: Use `press_key` for keyboard interactions (Enter, Tab, Escape, etc.)
- **Wait for state changes**: Use `wait_for` to wait for expected text or elements to appear after actions
- **Emulate conditions**: Use `emulate` for viewport changes, network throttling, geolocation if needed

#### Self-Healing

If an expected element is not found by exact text in the snapshot:
1. Look for elements with similar text (partial match, different casing, synonyms like "Submit" vs "Pay Now")
2. Look for elements with the same role in the expected position (e.g., a button in a form footer)
3. If a reasonable match is found, use it and add a note: "Element found by approximate match: '{actual text}' instead of '{expected text}'"
4. If no reasonable match is found, FAIL the scenario with a note: "Expected element not found: '{description}'"

#### Capture Evidence

Take evidence based on the `evidence.screenshots` config setting:

- **`always`**: Take a screenshot at the start of each scenario, at each assertion point, and at the end
- **`on_failure`**: Take a screenshot only when a scenario fails
- **`never`**: Skip screenshot capture

Regardless of the config setting, ALWAYS take a screenshot on FAIL.

Save screenshots to `{run_dir}/evidence/{SCENARIO-ID}-{description}.png` using the `take_screenshot` tool with a `filePath` parameter.

Evidence naming convention:
- `{SCENARIO-ID}-start.png` — initial state
- `{SCENARIO-ID}-assertion.png` — at the assertion point
- `{SCENARIO-ID}-fail-{description}.png` — on failure, describing what was wrong
- For multi-step scenarios: `{SCENARIO-ID}-step{N}-{description}.png`

#### Judge the Outcome

After performing all actions in the scenario:

1. Take a snapshot of the current page state using `take_snapshot`
2. Compare the observed state against the expected result from the scenario
3. Evaluate:
   - **PASS**: The expected result is clearly present — the right text, page, state, or element is visible
   - **FAIL**: The expected result is not present, or something contradicts it (wrong page, error message, missing element)
   - **SKIP**: The scenario could not be executed (precondition failed, dependency element missing, not applicable)

**Judgment principles:**
- Be conservative — if the outcome is ambiguous, mark FAIL with detailed notes rather than a false PASS
- Check for the expected result specifically, not just the absence of errors
- An error message visible on the page is a strong signal of failure, even if some elements match
- A loading spinner or "please wait" state means the action hasn't completed — wait and re-check before judging

Record the result with:
- Status: PASS / FAIL / SKIP
- Duration: approximate time for the scenario
- Notes: empty for PASS, explanation for FAIL or SKIP. Reference evidence filenames.

### 5e. Write Run File

After all scenarios in a spec are executed, write the run file to `{run_dir}/results/{SPEC-ID}.run.md`:

```markdown
---
spec: {SPEC-ID}
run_date: {ISO-8601 timestamp}
duration: {total duration for this spec}
passed: {count}
failed: {count}
skipped: {count}
---

# Run: {SPEC-ID}

| Scenario | Status | Duration | Notes |
|----------|--------|----------|-------|
| {SCENARIO-ID} | {PASS/FAIL/SKIP} | {duration} | {notes} |
```

### 5f. Display Spec Result

After each spec completes, display a brief summary:

```
{id}: {passed} passed, {failed} failed, {skipped} skipped
```

If there were failures, list them:

```
  FAIL {SCENARIO-ID}: {brief note}
```

## Phase 6: Run Summary

After all specs have been executed, display the aggregate summary:

```markdown
## Run Complete

**Run directory**: {run_dir}
**Duration**: {total duration}

### Results

| Spec | Passed | Failed | Skipped | Result |
|------|--------|--------|---------|--------|
| AUTH-LOGIN | 3 | 0 | 0 | PASS |
| CART-ADD | 4 | 1 | 0 | FAIL |
| PAY-CHECKOUT | 0 | 0 | 7 | SKIP |

### Totals

- **Passed**: {total_passed}
- **Failed**: {total_failed}
- **Skipped**: {total_skipped}
- **Pass rate**: {pass_rate}%

### Failures

| Spec | Scenario | Notes |
|------|----------|-------|
| CART-ADD | CART-03 | Add to cart button unresponsive. See CART-03-fail-button-unresponsive.png |

### Next Steps

1. **Review failures** — Check evidence in `{run_dir}/evidence/` for screenshots of failed scenarios
2. **Generate report** — Run `/qa-sentinel:report` for coverage and regression analysis
3. **Fix and re-run** — After fixing issues, run `/qa-sentinel:run {failed-specs}` to re-test
```

## Key Execution Guidance

### Use Snapshots Over Screenshots for Understanding

`take_snapshot` returns the accessibility tree — a structured text representation of every element on the page with roles, labels, values, and states. This is far more reliable than screenshots for understanding page state. Use screenshots for evidence capture and visual verification, but use snapshots for element discovery and state evaluation.

### Be Conservative in Judgment

A false FAIL that gets reviewed by a human is better than a false PASS that hides a real bug. When in doubt:
- Mark as FAIL
- Add detailed notes explaining the ambiguity
- Capture a screenshot as evidence
- Let the human reviewer make the final call

### Handle Timing and Async Operations

Web applications often have asynchronous operations. After actions that trigger network requests or state changes:
1. Use `wait_for` to wait for expected content to appear
2. If `wait_for` times out, take a snapshot to see the current state
3. Check for loading indicators — if still loading, wait longer
4. Only judge after the page has settled

### Recover from Unexpected States

If the browser ends up in an unexpected state (wrong page, unexpected modal, error screen):
1. Take a snapshot and screenshot to document the unexpected state
2. Try to recover (dismiss modal, navigate back) if it makes sense
3. If recovery fails, FAIL the current scenario with notes about the unexpected state
4. Continue to the next scenario — do not abort the entire spec unless preconditions are broken

### Evidence File Management

- Save all evidence files to `{run_dir}/evidence/` using absolute paths with `take_screenshot`'s `filePath` parameter
- Use the naming convention: `{SCENARIO-ID}-{description}.png`
- Keep descriptions short and hyphenated: `PAY-01-confirmation-page.png`, `AUTH-03-fail-invalid-password.png`
- Reference evidence filenames in run file notes so reviewers can find them
