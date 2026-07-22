---
project: [project-name]
requirements_source: [file|pm]
work_item: [ISSUE-ID]
pm_tool: [linear|jira|manual]
session_count: [N]
status: in_progress
# Optional orchestration fields: preserve existing values; omit when no continue run exists.
track: [feature|micro|research]
run_id: r-YYYYMMDD-N
source_channel: [cli|linear|github|chat|other]
progress:
  total_tasks: [X]
  completed: [Y]
  percent: [Z%]
current_layer: [domain|infrastructure|application|framework]
branch: <type>/<issue-key or description>
worktree: <path>  # Only when using --worktree; absolute path
visual_plan: <path-to-visual-plan.html | skipped — reason>
# Preserve existing counters; never reset them while filling this template.
reentry_counts:
  refine_from_execute_or_review: 0
  plan_from_execute_or_review: 0
thrash_bound_hits: 0
last_updated: [timestamp]
---

## Current Focus
[What's being worked on]

## Last Session Summary
[Detailed summary for handoff - what was done, key decisions, blockers]

## Intentional Compaction
[Latest mid-phase snapshot when used; otherwise omit this section]

## Session History
### Session N - [date]
- Completed: [list]
- Decisions: [list]
- Blockers: [list]
