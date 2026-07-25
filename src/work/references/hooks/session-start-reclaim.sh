#!/usr/bin/env bash
# SessionStart hook: if reclaim-pending.json exists, inject resume guidance and clear marker.
# Does NOT auto-run work:continue — user/orchestrator or next prompt does.
set -euo pipefail

input=$(cat || true)
cwd=$(echo "$input" | jq -r '.cwd // .workspaceRoot // .workspace_root // "."' 2>/dev/null || echo ".")
pending="$cwd/.agent-tools/reclaim-pending.json"

if [[ ! -f "$pending" ]]; then
  exit 0
fi

unit=$(jq -r '.unit // empty' "$pending" 2>/dev/null || true)
cont=$(jq -r '.continue // "work:continue"' "$pending" 2>/dev/null || true)
host_cmd=$(jq -r '.host_command // empty' "$pending" 2>/dev/null || true)

unit=${unit:-.agent-tools/planning}
ss="$cwd/$unit/session-state.md"
ctx="Mid-item reclaim completed or new/clean session started. Durable steering is on disk.
Unit: ${unit}
1) Read resume_loads from the latest Intentional Compaction in: ${unit}/session-state.md
2) Restate NEXT from that IC only — do not re-run portfolio discovery.
3) Continue the same workstream: /${cont}
Do not treat this as a new product task or end-of-item handoff."

if [[ -f "$ss" ]]; then
  ctx="${ctx}
Session-state path exists: ${unit}/session-state.md"
fi

# Claude-style additionalContext (also harmless if ignored by host)
jq -n --arg ctx "$ctx" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  },
  decision: "allow"
}' 2>/dev/null || echo "$ctx"

rm -f "$pending" 2>/dev/null || true
exit 0
