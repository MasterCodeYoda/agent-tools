---
name: qa-sentinel:audit
description: Detect drift between NL specs, generated tests, and app behavior
argument-hint: "[--live | --area <name> | --fix]"
---

# Audit Spec-Test-App Alignment

Detect drift between NL specs, generated `.spec.ts` tests, and live app behavior.

## User Input

```text
$ARGUMENTS
```

## Input Interpretation

| Flag | Behavior |
|------|----------|
| (none) | Full audit using existing Playwright results if available |
| `--live` | Re-run Playwright tests to get fresh results before auditing |
| `--area <name>` | Scope audit to a single functional area |
| `--fix` | Offer to auto-fix what's possible interactively |

## Load Configuration

Read `sentinel.config.yaml` and extract `specs.nl_dir` (`specs/`) and `specs.tests_dir` (`tests/`). If no config exists, tell the user to run `qa-sentinel:setup` first and stop.

---

## Phase 1: Load Inventory

### Parse NL Specs

Read all `.md` files from `specs/` (excluding `_sitemap.md`). For each file:

1. Parse YAML frontmatter: `id`, `area`, `priority`, `persona`, `tags`, `seed`
2. Count numbered H3 scenario sections (lines matching `### [0-9]+\.`)
3. Build a spec inventory:

```
specs/_sitemap.md             [skipped]
specs/auth-login.md           id=AUTH-LOGIN  area=auth    priority=P1  scenarios=4
specs/workspace-create.md     id=WS-CREATE   area=workspace priority=P0 scenarios=3
...
```

If `--area` is specified, filter to only specs where `area` matches.

### Parse Generated Tests

Read all `.spec.ts` files from `tests/` (excluding `seed.spec.ts`). For each file:

1. Extract test names using these patterns:
   - `test('...', ` or `test("...", `
   - `test.describe('...', ` block names
2. Build a test inventory:

```
tests/auth-login.spec.ts       tests: ["logs in with valid credentials", "shows error on wrong password", ...]
tests/workspace-create.spec.ts tests: ["creates workspace with name", ...]
...
```

### Load Playwright Results (if available)

Check for a recent Playwright report in `playwright-report/` or `test-results/`:

```bash
ls -t playwright-report/index.html 2>/dev/null | head -1
```

If a report exists, read the JSON summary from `test-results/.last-run.json` or parse `playwright-report/data/*.jsonl` for pass/fail/skip per test.

If `--live` flag is set, run Playwright first:

```bash
npx playwright test --reporter=json > test-results/audit-run.json
```

---

## Phase 2: Spec → Test Coverage

For each NL spec, determine whether a corresponding `.spec.ts` exists:

**Naming convention match**: `specs/auth-login.md` → `tests/auth-login.spec.ts`

**Content match**: Check if scenario titles from the NL spec appear as test names in the `.spec.ts` (partial substring match is acceptable).

Classify each spec as:

| Status | Meaning |
|--------|---------|
| **covered** | `.spec.ts` exists and scenario titles match |
| **partial** | `.spec.ts` exists but some scenarios are missing |
| **uncovered** | No corresponding `.spec.ts` found |

Report per spec:

```
AUTH-LOGIN (auth, P1)
  Status: partial
  Covered scenarios: 3 / 4
  Missing: "handles expired session gracefully"

WS-CREATE (workspace, P0)
  Status: uncovered
  No tests/workspace-create.spec.ts found
```

---

## Phase 3: Test → Spec Freshness

Find orphaned `.spec.ts` files — tests with no corresponding NL spec:

For each `.spec.ts` in `tests/` (excluding `seed.spec.ts`):
- Check if a matching NL spec exists in `specs/` using the naming convention
- If no match: mark as **orphaned**

Report orphaned tests:

```
Orphaned tests (no corresponding NL spec):
  tests/legacy-import.spec.ts  — write a NL spec in specs/ or delete this test
```

---

## Phase 4: Behavioral Drift

Only runs if `--live` flag was set OR a recent Playwright report exists.

Compare test failures against NL spec expectations. For each failing test:

1. Find the corresponding NL spec scenario
2. Categorize the failure:

| Category | Signal | Action |
|----------|--------|--------|
| **App regression** | Test correctly describes expected behavior; app changed | File a bug |
| **Spec staleness** | App behavior is intentionally different; spec is outdated | Update the NL spec |
| **Test brittleness** | Selector or assertion broke; underlying behavior is fine | Run Healer |

Report per failure:

```
FAILING: "creates workspace with name" (tests/workspace-create.spec.ts)
  NL Spec: WS-CREATE scenario 1 (P0)
  Category: App regression — "Create" button no longer visible after navigation change
  Recommended action: File a bug, this is P0

FAILING: "shows tag count in sidebar" (tests/tags-management.spec.ts)
  NL Spec: TAGS-MGMT scenario 3 (P2)
  Category: Test brittleness — selector [data-testid="tag-count"] not found
  Recommended action: Run Healer to update selector
```

---

## Phase 5: Recommendations

Summarize findings and present actionable recommendations.

### Summary Table

```markdown
## Audit Summary

| Category | Count |
|----------|-------|
| NL specs | [n] |
| Fully covered | [n] |
| Partially covered | [n] |
| Uncovered | [n] |
| Orphaned tests | [n] |
| Failing tests | [n] |
```

### Prioritized Recommendations

```markdown
## Recommendations

### Immediate (P0/P1 gaps)
- [ ] Generate tests for WS-CREATE (P0, uncovered) — run Playwright Generator
- [ ] Fix failing AUTH-LOGIN scenario 4 — app regression, file a bug

### Soon (P2 gaps + orphans)
- [ ] Generate tests for EDITOR-PASTE (P2, uncovered)
- [ ] Review orphaned tests/legacy-import.spec.ts — write NL spec or delete

### Maintenance
- [ ] Update TAGS-MGMT scenario 3 — spec describes old behavior
- [ ] Run Healer on tests/tags-management.spec.ts — brittle selector
```

### Auto-Fix (if `--fix` flag)

For each fixable issue, offer interactively:

1. **Stale NL spec** — Show the current scenario and the failing test assertion. Ask: "Update this scenario to match current app behavior?" If yes, edit the NL spec.
2. **Orphaned test** — Ask: "Generate a NL spec for this test, or delete the test?"

Use `AskUserQuestion` for each fix offer. Do not auto-apply fixes without confirmation.

---

## Output

Display the full audit report as structured markdown to the user.

If `--area` was specified, prefix the report title: "Audit Report — [area] area".

End with a reminder:

```
Run `npx playwright test` to execute tests.
Run `/qa-sentinel:discover` to author new NL specs.
Run `/qa-sentinel:audit --live` to get fresh behavioral drift data.
```
