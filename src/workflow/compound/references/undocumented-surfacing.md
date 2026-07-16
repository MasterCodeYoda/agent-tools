# Undocumented solution surfacing

Load before capture when scanning harness history for uncaptured work.

## Undocumented Solution Surfacing

Before starting capture, check conversation history for completed work that was never captured. References: @workflow (`references/conversation-analysis.md`)

```
1. Get project root: git rev-parse --show-toplevel
2. Read harness history (e.g. ~/.claude/history.jsonl) — filter entries where "project" starts with project root
3. Group by sessionId
4. For each session, read facets if available
5. Filter for sessions with outcome "fully_achieved" and a meaningful brief_summary
6. Cross-reference against:
   - .agent-tools/memory/solutions/
   - .agent-tools/memory/entries/
   - legacy docs/solutions/ (if still present)
7. Present undocumented work (if any) before proceeding
```

If found, offer select by number / skip / all. If none, proceed.

