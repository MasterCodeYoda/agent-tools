# Evidence Guide

Evidence files provide a visual and structural record of what Sentinel observed during execution. They make run results reviewable by humans and enable debugging of failures without re-running the spec.

## Evidence Types

### Screenshots (PNG)

Visual captures of the browser viewport at specific moments during scenario execution.

- Format: PNG (lossless, suitable for UI detail inspection)
- Captured via: `take_screenshot` MCP tool
- Primary evidence type — most failures can be diagnosed from a screenshot

### DOM Snapshots

Text-based accessibility tree snapshots of the page at capture time. These provide structural information that screenshots alone don't convey (element roles, labels, states, values).

- Format: Plain text (output of `take_snapshot` MCP tool)
- Useful for verifying: form field values, element enabled/disabled state, ARIA attributes, content that may not be visually obvious

### Trace Files

Performance trace recordings captured during scenario execution. Only needed when diagnosing performance-related scenarios.

- Format: JSON (`.json` or `.json.gz`)
- Captured via: `performance_start_trace` / `performance_stop_trace` MCP tools
- Use sparingly — traces are large and only relevant for performance scenarios

## When to Capture

### At Assertion Points

Capture a screenshot and/or DOM snapshot immediately before making a pass/fail judgment. This provides evidence for the judgment regardless of outcome.

### On Failure

Always capture on failure:
- Screenshot showing the actual state
- DOM snapshot for structural analysis
- Any error messages visible on the page

This is the minimum evidence requirement for any FAIL result.

### At Key State Transitions

For multi-step scenarios, capture at significant state changes:
- After navigation to a new page
- After form submission
- After a modal or dialog appears
- After a loading state resolves

This creates a visual trail of the scenario execution, useful for diagnosing where a multi-step flow diverged from expectations.

## Naming Convention

```
{SCENARIO-ID}-{description}.{ext}
```

- `SCENARIO-ID` — matches the scenario ID from the spec (e.g., `PAY-04`)
- `description` — short, hyphenated description of what the capture shows
- `ext` — file extension (`png`, `txt` for DOM snapshots, `json.gz` for traces)

### Examples

```
PAY-01-confirmation-page.png
PAY-04-expired-card-error.png
PAY-04-expired-card-error-dom.txt
PAY-06-double-click-second-order.png
PAY-07-network-error-state.png
PAY-07-network-error-trace.json.gz
```

For multi-step scenarios that need multiple captures, add a step indicator:

```
PAY-01-step1-enter-card.png
PAY-01-step2-click-pay.png
PAY-01-step3-confirmation.png
```

## Storage

Evidence is stored inside run directories, making each run a self-contained record.

```
{runs_dir}/
  {timestamp}/
    results/
      PAY-CHECKOUT.run.md
      AUTH-LOGIN.run.md
    evidence/
      PAY-01-confirmation-page.png
      PAY-04-expired-card-error.png
      PAY-04-expired-card-error-dom.txt
      AUTH-01-login-success.png
      ...
```

### Directory Structure

| Path | Contents |
|------|----------|
| `{runs_dir}/{timestamp}/` | One directory per execution session |
| `{runs_dir}/{timestamp}/results/` | Run files (`.run.md`) for each executed spec |
| `{runs_dir}/{timestamp}/evidence/` | All evidence files from this run |

### Self-Contained Runs

Each run directory is a complete, independent snapshot of that validation pass. You can:
- Archive or share a run directory on its own
- Compare evidence across runs by looking at the same scenario ID in different timestamp directories
- Delete old runs without affecting current coverage data (coverage is recalculated from the most recent run)

## Evidence in Run Files

Run file notes should reference evidence filenames when relevant:

```markdown
| Scenario | Status | Duration | Notes |
|----------|--------|----------|-------|
| PAY-04 | FAIL | 5s | Expected "Card has expired" but got generic error. See PAY-04-expired-card-error.png |
```

This creates a clear link between the result and the supporting evidence without embedding images directly in the run file.

## Configuration

Evidence capture behavior is controlled by `sentinel.config.yaml`:

```yaml
evidence:
  screenshots: on_failure   # on_failure | always | never
  traces: on_failure         # on_failure | always | never
  dom_snapshots: on_failure  # on_failure | always | never
```

- `on_failure` — Capture only when a scenario fails (default, balances detail with storage)
- `always` — Capture for every scenario (useful for baseline runs or debugging)
- `never` — Skip capture (faster execution, no evidence trail)

Regardless of configuration, DOM snapshots used for pass/fail judgment are always taken internally. The config controls whether they are persisted to the evidence directory.
