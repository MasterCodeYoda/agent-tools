# Conversation History Analysis

Reference for extracting signals from Claude Code conversation history stored in `~/.claude/`. Used by `/evolve`, `/workflow:compound`, and `/workflow:audit` for data-driven improvement.

## Data Sources

### 1. Command History (`~/.claude/history.jsonl`)

JSONL file with one entry per user input. Fields:

```json
{
  "display": "/workflow:audit",
  "pastedContents": {},
  "timestamp": 1774093069131,
  "project": "/Users/.../project-name",
  "sessionId": "uuid-..."
}
```

**Use for**: Command usage frequency, invocation patterns, which commands are used in which projects.

### 2. Session Quality Facets (`~/.claude/usage-data/facets/{sessionId}.json`)

Post-session quality analysis. Fields:

```json
{
  "underlying_goal": "...",
  "outcome": "fully_achieved",
  "friction_counts": {"wrong_approach": 2},
  "friction_detail": "...",
  "user_satisfaction_counts": {"likely_satisfied": 1},
  "claude_helpfulness": "essential",
  "session_type": "single_task",
  "brief_summary": "...",
  "session_id": "uuid-..."
}
```

**Use for**: Session quality signals, friction detection, identifying solved-but-undocumented problems.

### 3. Conversation Database (`~/.claude/__store.db`)

SQLite database with conversation messages. Key tables:

**`base_messages`**: Threading and metadata.
- `uuid`, `parent_uuid` (parent-child for branching/corrections)
- `session_id`, `timestamp`, `cwd`, `message_type` (user/assistant)

**`user_messages`**: User input content.
- `uuid`, `message` (JSON with role + content array), `tool_use_result`

**`assistant_messages`**: Agent output content.
- `uuid`, `message` (JSON with content including tool_use blocks)
- `cost_usd`, `duration_ms`, `model`

**Use for**: Full conversation reconstruction, tool usage patterns, cost analysis.

### 4. Project Conversations (`~/.claude/projects/{encoded-path}/`)

Project paths encoded as directory names (slashes replaced with dashes):
`/Users/foo/Source/myapp` → `-Users-foo-Source-myapp/`

Contains conversation JSONL files (UUID-named) and subagent directories.

**Use for**: Project-specific conversation threads, subagent analysis.

## Project Scoping

**Critical**: History is global across all projects. When analyzing for a specific project, filter correctly.

### How to scope to current project

```
1. Get project root: git rev-parse --show-toplevel
2. For history.jsonl: filter entries where "project" field starts with the project root
3. For __store.db: filter base_messages where "cwd" starts with the project root
4. For projects/: encode the project root as a directory name and read that directory
```

**Use prefix matching, not exact match.** Users frequently work from subfolders within a project (e.g., `src/`, `packages/api/`). A session with CWD `/Users/foo/Source/myapp/src/components` is still a session for the `/Users/foo/Source/myapp` project.

```python
# Correct: prefix match against project root
project_root = get_project_root()  # git rev-parse --show-toplevel
is_match = entry["project"].startswith(project_root)

# Wrong: exact CWD match (misses subfolder sessions)
is_match = entry["project"] == os.getcwd()
```

### Cross-project analysis

When `--global` is specified (or when looking for cross-project patterns), skip the project filter. Note which project each signal came from for attribution.

## Signal Extraction Patterns

### Command Usage Frequency

```
1. Read history.jsonl
2. Filter by project root (prefix match)
3. Group by display field (the command text)
4. Count invocations and distinct sessions
5. Sort by frequency
```

Output: "workflow:audit invoked 12 times across 8 sessions in this project"

### Session Quality by Command

```
1. Get command history entries for current project
2. Group by sessionId to identify which commands ran in which sessions
3. For each session, read its facet file from usage-data/facets/{sessionId}.json
4. Aggregate: friction_counts, outcomes, satisfaction by command type
```

Output: "Sessions using /workflow:plan had 0 friction (8 sessions). Sessions using /workflow:review had wrong_approach friction in 2 of 5 sessions."

### Undocumented Solutions

```
1. Read facets for sessions matching current project
2. Filter for outcome "fully_achieved" with meaningful brief_summary
3. Cross-reference against existing docs/solutions/ directory
4. Present sessions that solved problems with no corresponding compound doc
```

Output: "3 sessions solved problems not documented in docs/solutions/"

### Recurring Friction Patterns

```
1. Read facets for sessions matching current project
2. Filter for sessions with friction_counts > 0
3. Group friction_detail by theme
4. Identify recurring patterns
```

Output: "Architecture guidance caused friction in 3 sessions — users consistently corrected layer placement advice"

### Finding Persistence (for audits)

```
1. After producing audit findings, check history.jsonl for prior audit sessions
2. Load prior audit session conversations from projects/{path}/
3. Look for similar findings in prior audit output
4. Classify: recurring (appeared before) vs. new
5. If recurring: check if user acted on it (follow-up commits) or ignored it
```

Output: "3 findings are recurring from 2 prior audits — may indicate systemic issues or persistent false positives"

## Privacy Guidance

When analyzing conversation history:

- **Extract patterns, not content.** Report "3 sessions had friction with architecture guidance" — not the specific code or user messages.
- **No external transmission.** All analysis runs locally. Signals feed into local evolve/compound reports only.
- **Aggregate over specifics.** Prefer counts and categories over individual session details. When referencing specific sessions, use brief_summary (already anonymized by design) rather than conversation content.
- **Respect project boundaries.** Default to current-project filtering. Cross-project analysis only when explicitly requested.
