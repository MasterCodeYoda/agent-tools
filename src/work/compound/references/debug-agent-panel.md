# Debugging-solution analysis agents

Load only on the **debugging-solution** capture path (not for pattern/entry-only captures).

## Parallel Analysis (debugging-solution path only)

For patterns, decisions, and gotchas headed to `entries/` / ADR / AGENTS.md, skip this fan-out: capture the insight, alternatives, and when it applies, then index.

For **solutions**, launch specialized agents:

### Agent 1: Context Analyzer
Extracts problem type, component, symptoms, errors → YAML frontmatter structure

### Agent 2: Solution Extractor
Steps tried, root cause, working solution, insights

### Agent 3: Related Docs Finder
Searches `.agent-tools/memory/solutions/`, `entries/`, ADRs, similar patterns

### Agent 4: Prevention Strategist
Recurrence avoidance, practices, tests, warning signs

### Agent 5: Category Classifier
Best-fit category, slug, tags

## Debugging-Solution Categories

| Category | When to Use |
|----------|-------------|
| `build-errors/` | Compilation, bundling, dependency issues |
| `test-failures/` | Test suite issues, flaky tests |
| `runtime-errors/` | Exceptions, crashes, unexpected behavior |
| `performance-issues/` | Slow responses, memory leaks, N+1 queries |
| `database-issues/` | Migrations, queries, connection problems |
| `security-issues/` | Vulnerabilities, auth problems |
| `ui-bugs/` | Visual issues, interaction problems |
| `integration-issues/` | API failures, service communication |
| `logic-errors/` | Incorrect behavior, edge cases |

Unknown legacy categories from migrate: map to closest above or `misc/`.

