# Coverage Model

Sentinel tracks coverage at three levels: individual scenarios, specs, and functional areas. Coverage is derived from run files — there is no separate coverage database.

## Coverage Levels

### Scenario-Level

The atomic unit of tracking. Each scenario line in a spec is either:

| Status | Marker | Meaning |
|--------|--------|---------|
| PASS | `[x]` | Scenario executed, outcome matched expected result |
| FAIL | `[!]` | Scenario executed, outcome did not match expected result |
| SKIP | `[-]` | Scenario was not executed (dependency failure, precondition not met, or manual skip) |
| UNTESTED | `[ ]` | No run file exists for this scenario |

### Spec-Level

A spec's coverage is the ratio of passing scenarios to total scenarios, taken from the most recent run.

```
spec_coverage = passing_scenarios / total_scenarios
```

A spec is considered:
- **Fully covered** — all scenarios PASS
- **Partially covered** — some scenarios PASS, others FAIL or SKIP
- **Failing** — at least one scenario FAILs
- **Never tested** — no run file exists for this spec

### Area-Level

Areas aggregate all specs that share the same `area` frontmatter field. Area coverage rolls up from spec coverage:

```
area_coverage = sum(passing_scenarios across area specs) / sum(total_scenarios across area specs)
```

## Run Files

Each execution of a spec produces a run file. Run files are the source of truth for coverage data.

### Location

```
{runs_dir}/{timestamp}/
  results/
    {SPEC-ID}.run.md
  evidence/
    {SCENARIO-ID}-{description}.png
    ...
```

The `timestamp` directory uses the format `YYYY-MM-DD-HHmmss` (e.g., `2026-02-21-143052`).

### Run File Format

Each run file is a markdown file with YAML frontmatter and a results table:

```markdown
---
spec: PAY-CHECKOUT
run_date: 2026-02-21T14:30:52Z
duration: 45s
passed: 5
failed: 1
skipped: 1
---

# Run: PAY-CHECKOUT

| Scenario | Status | Duration | Notes |
|----------|--------|----------|-------|
| PAY-01 | PASS | 8s | |
| PAY-02 | PASS | 7s | |
| PAY-03 | PASS | 4s | |
| PAY-04 | PASS | 5s | |
| PAY-05 | PASS | 6s | |
| PAY-06 | FAIL | 12s | Duplicate charge detected — two orders created |
| PAY-07 | SKIP | - | Network emulation not available in current browser config |
```

### Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `spec` | string | The spec `id` this run corresponds to |
| `run_date` | ISO 8601 | When the run started |
| `duration` | string | Total wall-clock time for the spec execution |
| `passed` | integer | Count of PASS scenarios |
| `failed` | integer | Count of FAIL scenarios |
| `skipped` | integer | Count of SKIP scenarios |

## Coverage Calculation

### Per-Spec Coverage

From the most recent run file for a given spec:

```
coverage = passed / (passed + failed + skipped)
```

If no run file exists, coverage is 0% and the spec is flagged as "never tested."

### Per-Area Coverage

Aggregate across all specs in the area, using each spec's most recent run:

```
area_passed = sum of passed across all specs in area
area_total = sum of (passed + failed + skipped) across all specs in area
area_coverage = area_passed / area_total
```

### Overall Coverage

Same aggregation across all specs, regardless of area:

```
overall_passed = sum of passed across all specs
overall_total = sum of (passed + failed + skipped) across all specs
overall_coverage = overall_passed / overall_total
```

## Regression Detection

Regression detection compares the current run against the previous run for the same spec.

### What Counts as a Regression

A scenario is a **regression** if:
- It was PASS in the previous run
- It is FAIL in the current run

Scenarios that were already FAIL, SKIP, or UNTESTED are not regressions — they are pre-existing failures.

### How to Compare

1. Find the two most recent run directories (by timestamp)
2. For each spec that has run files in both directories, compare scenario statuses
3. Flag any PASS-to-FAIL transitions

### Regression Report Format

```
## Regressions

| Spec | Scenario | Previous | Current | Notes |
|------|----------|----------|---------|-------|
| PAY-CHECKOUT | PAY-06 | PASS | FAIL | Duplicate charge — guard removed? |
```

## Never-Tested Detection

A spec is "never tested" if no run file exists for its `id` in any run directory. The `discover` command identifies these by:

1. Scanning all spec files to collect spec IDs
2. Scanning all run directories for run files
3. Reporting specs with no matching run file

This ensures new specs are surfaced for testing and don't silently accumulate without coverage.
