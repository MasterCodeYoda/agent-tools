---
name: qa-sentinel:report
description: Generate coverage and regression reports from Sentinel run data
argument-hint: "[run timestamp, '--latest' (default), or '--compare <run1> <run2>']"
---

# Generate Sentinel Report

Produce coverage, regression, and gap reports from Sentinel run data.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

Parse input to determine report mode:

| Input Pattern | Mode | Action |
|---------------|------|--------|
| Empty or `--latest` | Latest Run | Report on the most recent run |
| `YYYY-MM-DD-HHmmss` | Specific Run | Report on the named run directory |
| `--compare <run1> <run2>` | Comparison | Side-by-side diff of two runs |

## Load Configuration

```bash
cat tests/qa-sentinel/sentinel.config.yaml
```

Extract `runs_dir`, `specs_dir`, and `reports_dir` paths. If no config exists, tell the user to run `qa-sentinel:setup` first and stop.

---

## Step 1: Locate Target Run

### Latest (default)

```bash
# List run directories sorted by name (timestamp format ensures sort order)
ls -d tests/qa-sentinel/runs/*/ | sort | tail -1
```

If no runs exist, report:

> "No run data found. Run `qa-sentinel:run` to execute specs first."

### Specific Timestamp

```bash
ls -d tests/qa-sentinel/runs/<timestamp>/
```

If the directory doesn't exist, show available runs and ask the user to pick one.

### Compare Mode

Locate both run directories. If either doesn't exist, show available runs and ask the user to correct the input.

---

## Step 2: Read All Spec Files

Scan the specs directory to build the full inventory of specs and scenarios:

```bash
find tests/qa-sentinel/specs -name "*.spec.md" -type f
```

For each spec file, parse:
- YAML frontmatter: `id`, `area`, `priority`, `feature`
- Scenario lines: count total scenarios, extract scenario IDs

Build a map: `spec_id → { area, priority, feature, scenario_ids[], scenario_count }`.

---

## Step 3: Read Run Files

From the target run directory, read all `.run.md` files:

```bash
find tests/qa-sentinel/runs/<timestamp>/results -name "*.run.md" -type f
```

For each run file, parse:
- YAML frontmatter: `spec`, `run_date`, `duration`, `passed`, `failed`, `skipped`
- Results table: individual scenario statuses (PASS, FAIL, SKIP) and notes

Build a map: `spec_id → { passed, failed, skipped, scenarios[] }`.

---

## Step 4: Calculate Coverage

### Per-Spec Coverage

For each spec in the inventory:
- If a run file exists: `coverage = passed / (passed + failed + skipped)`
- If no run file exists: coverage = 0%, status = "Never tested"

### Per-Area Coverage

Group specs by `area` and aggregate:

```
area_passed = sum(passed) across all specs in area
area_total = sum(passed + failed + skipped) across all specs in area
area_coverage = area_passed / area_total
```

For areas with some never-tested specs, note the gap.

### Overall Coverage

```
overall_passed = sum(passed) across all specs
overall_total = sum(passed + failed + skipped) across all specs
overall_coverage = overall_passed / overall_total
```

---

## Step 5: Detect Regressions

Find the previous run (the run directory immediately before the target run by timestamp sort order).

If a previous run exists:

1. For each spec that has run files in **both** the current and previous runs
2. Compare scenario-by-scenario:
   - **Regression**: scenario was PASS in previous, FAIL in current
   - **Fix**: scenario was FAIL in previous, PASS in current
   - **Persistent failure**: FAIL in both
   - **New**: scenario exists in current but not in previous

If no previous run exists, skip regression detection and note it in the report.

---

## Step 6: Identify Gaps

### Never-Tested Specs

Specs in the inventory with no run file in any run directory:

```bash
# List all run files across all runs to find which specs have been tested
find tests/qa-sentinel/runs -name "*.run.md" -type f
```

Cross-reference against the spec inventory. Any spec ID with no matching run file is never-tested.

### Low Coverage Areas

Areas where `area_coverage` is below 80%.

---

## Step 7: Generate Report

### Archive Previous Report

If `tests/qa-sentinel/reports/latest.md` exists:

```bash
mkdir -p tests/qa-sentinel/reports/history
# Extract the date from the previous report or use file modification time
mv tests/qa-sentinel/reports/latest.md tests/qa-sentinel/reports/history/<previous-run-date>.md
```

### Write Report

Generate `tests/qa-sentinel/reports/latest.md` with this structure:

```markdown
# Sentinel Report

**Run**: [timestamp]
**Date**: [formatted date]
**App**: [app name from config]

## Summary

| Metric | Value |
|--------|-------|
| Specs Executed | X / Y total |
| Scenarios Passed | N |
| Scenarios Failed | N |
| Scenarios Skipped | N |
| Overall Pass Rate | XX% |
| Regressions | N |
| Never Tested | N specs |

## Coverage by Area

| Area | Specs | Scenarios | Passed | Failed | Skipped | Coverage |
|------|-------|-----------|--------|--------|---------|----------|
| auth | 3 | 15 | 13 | 1 | 1 | 87% |
| payments | 2 | 12 | 10 | 2 | 0 | 83% |
| ... | | | | | | |
| **Total** | **X** | **Y** | **N** | **N** | **N** | **XX%** |

## Regressions

[If regressions found:]

| Spec | Scenario | Previous | Current | Notes |
|------|----------|----------|---------|-------|
| PAY-CHECKOUT | PAY-06 | PASS | FAIL | Duplicate charge detected |

[If no regressions:]

No regressions detected.

[If no previous run for comparison:]

No previous run available for regression comparison.

## Fixes (FAIL → PASS)

[If fixes found:]

| Spec | Scenario | Previous | Current |
|------|----------|----------|---------|
| AUTH-LOGIN | AUTH-03 | FAIL | PASS |

[If none:]

No fixes detected in this run.

## Failures

[List all currently failing scenarios with details:]

### PAY-CHECKOUT

| Scenario | Notes | Evidence |
|----------|-------|----------|
| PAY-06 | Duplicate charge detected — two orders created | [screenshot](../runs/<timestamp>/evidence/PAY-06-duplicate.png) |

### [SPEC-ID]

...

[If no failures:]

All executed scenarios passed.

## Never Tested

[If any specs have never been tested:]

| Spec | Area | Priority | Scenarios |
|------|------|----------|-----------|
| SEARCH-FILTERS | search | P2 | 8 |
| ADMIN-USERS | admin | P3 | 5 |

[If all specs have been tested:]

All specs have run data.

## Low Coverage Areas

[Areas below 80% coverage:]

| Area | Coverage | Gap |
|------|----------|-----|
| payments | 67% | 4 failing scenarios |

[If all areas above 80%:]

All areas above 80% coverage threshold.

---

Generated: [timestamp]
Config: tests/qa-sentinel/sentinel.config.yaml
```

---

## Compare Mode (`--compare <run1> <run2>`)

When comparing two runs, generate a different report format:

### Read Both Runs

Read all run files from both run directories.

### Build Comparison

For each spec that appears in either run:

| Status | Meaning |
|--------|---------|
| Improved | More passing scenarios in run2 than run1 |
| Regressed | Fewer passing scenarios in run2 than run1 |
| Unchanged | Same results in both runs |
| New | Spec only exists in run2 |
| Removed | Spec only exists in run1 |

### Generate Comparison Report

Write to `tests/qa-sentinel/reports/latest.md`:

```markdown
# Sentinel Comparison Report

**Run 1**: [timestamp1] ([date])
**Run 2**: [timestamp2] ([date])

## Overall Trend

| Metric | Run 1 | Run 2 | Delta |
|--------|-------|-------|-------|
| Pass Rate | XX% | YY% | +/-ZZ% |
| Passing | N | N | +/-N |
| Failing | N | N | +/-N |
| Skipped | N | N | +/-N |
| Total Scenarios | N | N | +/-N |

## Regressions (PASS → FAIL)

| Spec | Scenario | Run 1 | Run 2 | Notes |
|------|----------|-------|-------|-------|
| ... | | | | |

## Improvements (FAIL → PASS)

| Spec | Scenario | Run 1 | Run 2 |
|------|----------|-------|-------|
| ... | | | |

## Per-Area Comparison

| Area | Run 1 Coverage | Run 2 Coverage | Delta |
|------|----------------|----------------|-------|
| auth | 87% | 93% | +6% |
| ... | | | |

## Unchanged Failures

[Scenarios that failed in both runs — persistent issues:]

| Spec | Scenario | Notes |
|------|----------|-------|
| ... | | |

---

Compared: [timestamp]
```

---

## Step 8: Display Summary

After writing the report, show the user a condensed summary:

```
Sentinel Report Generated
=========================

Run:        [timestamp]
Pass Rate:  XX% (N/M scenarios)
Failures:   N
Regressions: N
Never Tested: N specs

Report: tests/qa-sentinel/reports/latest.md

[If regressions > 0:]
WARNING: [N] regression(s) detected — scenarios that previously passed are now failing.

[If never-tested > 0:]
NOTE: [N] spec(s) have never been tested. Run `qa-sentinel:run` to cover them.
```

For compare mode, show the trend:

```
Sentinel Comparison
===================

Run 1: [timestamp1]  →  Run 2: [timestamp2]

Pass Rate: XX% → YY% ([+/-]ZZ%)
Regressions: N
Improvements: N

Report: tests/qa-sentinel/reports/latest.md
```
