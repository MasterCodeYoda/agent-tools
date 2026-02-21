# Execution Model

Sentinel executes specs by driving a real browser via Chrome DevTools MCP. Claude reads the spec, performs actions in the browser, evaluates outcomes, and records results. This is on-demand validation, not CI — a human decides when to run it.

## Execution Flow

```
1. Load config        — Read sentinel.config.yaml for base URL, auth, browser settings
2. Resolve specs      — Parse spec files, build dependency graph, determine execution order
3. Authenticate       — Log in or set auth state based on config
4. For each spec (in dependency order):
   a. Verify preconditions
   b. For each scenario:
      i.   Drive browser (navigate, click, fill, wait)
      ii.  Capture evidence at assertion points
      iii. Judge outcome against expected result
      iv.  Record PASS, FAIL, or SKIP with notes
   c. Write run file
5. Generate summary   — Aggregate results, detect regressions
```

## Dependency Resolution

Specs declare dependencies via the `dependencies` frontmatter field. Sentinel resolves these into a topological execution order:

- Specs with no dependencies run first
- A spec only runs after all its dependencies have passed
- If a dependency fails, the dependent spec is skipped (status: SKIP, note: "dependency {ID} failed")
- Circular dependencies are detected and reported as an error before execution begins

Within the same dependency tier, specs are ordered by priority: P1 before P2 before P3.

## Browser Control via Chrome DevTools MCP

Sentinel uses Chrome DevTools MCP tools for all browser interaction. The key tools used:

| Action | MCP Tool |
|--------|----------|
| Navigate to URL | `navigate_page` |
| Read page state | `take_snapshot` |
| Click elements | `click` |
| Fill form fields | `fill` or `fill_form` |
| Press keys | `press_key` |
| Wait for content | `wait_for` |
| Capture screenshots | `take_screenshot` |
| Emulate conditions | `emulate` (network throttling, viewport, etc.) |

Claude reads the scenario description, determines the actions to perform, finds elements on the page using the accessibility snapshot, and executes them. There are no hardcoded selectors — Claude locates elements by their role, label, text content, or structural position, the same way a human tester would.

## Self-Healing

Because Claude interprets the page through accessibility snapshots rather than CSS selectors, execution naturally adapts to UI changes:

- **Renamed buttons** — Claude finds "Complete Purchase" even if it was "Pay Now" in the last release, as long as the intent matches the scenario description
- **Moved elements** — Layout changes don't break execution because Claude locates elements by semantics, not coordinates
- **Added steps** — If a new confirmation dialog appears, Claude can navigate it if the scenario description covers the expected flow

Self-healing has limits. Claude adapts to cosmetic and structural changes, but cannot compensate for:
- Fundamental flow changes (e.g., checkout now requires a new mandatory step not described in the spec)
- Missing functionality (e.g., the Pay button was removed entirely)
- Backend changes that alter expected outcomes

When a scenario's expected result no longer matches reality due to intentional product changes, the spec should be updated — that's a spec maintenance task, not a self-healing scenario.

## LLM-as-Judge

After performing the actions in a scenario, Claude evaluates the outcome by comparing what it observes (page content, visual state, error messages) against the expected result stated in the spec.

### Judgment Process

1. **Take a snapshot** of the current page state after completing the scenario actions
2. **Compare** the observed state against the `→ expected result` in the scenario
3. **Decide**: PASS if the expected result is present and correct, FAIL if it is not
4. **Record notes** explaining the judgment, especially on failures

### What Claude Evaluates

- **Text content** — Is the expected message, label, or value visible on the page?
- **Page state** — Is the user on the expected page (URL, heading, page title)?
- **Visual elements** — Are expected UI components present (buttons, forms, confirmations)?
- **Absence of errors** — Are there unexpected error messages or broken states?

### Confidence and Ambiguity

If the outcome is ambiguous — the expected result is partially present, or the page state is unclear — Claude should:
1. Capture a screenshot as evidence
2. Mark the scenario as FAIL with a note explaining the ambiguity
3. Let the human reviewer make the final call

Conservative judgment is preferred. A false FAIL that gets manually reviewed is better than a false PASS that masks a real bug.

## On-Demand Execution

Sentinel is designed for on-demand pre-release validation sessions, not automated CI:

- A human decides when to run Sentinel (before a release, after a major change, during QA review)
- Claude needs a running browser and access to the application under test
- Execution speed depends on the application's response time and the number of scenarios
- Results are written to local run files for review

This is intentional. Browser-based QA with LLM judgment is too slow and resource-intensive for CI pipelines, but provides high-value validation that complements automated tests.
