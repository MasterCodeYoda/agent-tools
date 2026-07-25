#!/usr/bin/env bash
# Stop hook: if the last assistant message contains a mid-item workflow_reclaim signal,
# write reclaim-pending.json and coach clean-session + continue. Does NOT run /clear|/new.
set -euo pipefail

input=$(cat || true)
# Allow non-end_turn / missing fields (Grok session-end observe fire, etc.)
reason=$(echo "$input" | jq -r '.reason // .stop_reason // empty' 2>/dev/null || true)
if [[ -n "$reason" && "$reason" != "end_turn" && "$reason" != "endTurn" ]]; then
  exit 0
fi

msg=$(echo "$input" | jq -r '
  .lastAssistantMessage // .last_assistant_message // .message // empty
' 2>/dev/null || true)

if [[ -z "$msg" ]] || ! echo "$msg" | grep -q 'workflow_reclaim:'; then
  exit 0
fi

# Extract fields from fenced yaml if present (best-effort)
unit=$(echo "$msg" | sed -n 's/.*unit:[[:space:]]*//p' | head -1 | tr -d '"' | tr -d "'" | awk '{print $1}')
host_cmd=$(echo "$msg" | sed -n 's/.*host_command:[[:space:]]*//p' | head -1 | sed 's/[[:space:]]*$//')
cont=$(echo "$msg" | sed -n 's/.*continue:[[:space:]]*//p' | head -1 | tr -d '"' | awk '{print $1}')
reclaim=$(echo "$msg" | sed -n 's/.*reclaim:[[:space:]]*//p' | head -1 | tr -d '"' | awk '{print $1}')

unit=${unit:-.agent-tools/planning}
host_cmd=${host_cmd:-/clear}
cont=${cont:-work:continue}
reclaim=${reclaim:-clean-session}

cwd=$(echo "$input" | jq -r '.cwd // .workspaceRoot // .workspace_root // "."' 2>/dev/null || echo ".")
mkdir -p "$cwd/.agent-tools" 2>/dev/null || true
pending="$cwd/.agent-tools/reclaim-pending.json"
jq -n \
  --arg kind "mid-item" \
  --arg unit "$unit" \
  --arg continue "$cont" \
  --arg host_command "$host_cmd" \
  --arg reclaim "$reclaim" \
  --arg written_at "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" \
  '{kind:$kind, unit:$unit, continue:$continue, host_command:$host_command, reclaim:$reclaim, written_at:$written_at}' \
  >"$pending" 2>/dev/null || true

# Block stop with coach message (Claude/Grok-compatible decision JSON)
reason_text="Mid-item reclaim pending (durable IC should already be on disk). Run exactly: ${host_cmd} — then send /${cont} (or execute continue) for unit ${unit}. Do not treat this as end-of-item handoff."
jq -n --arg r "$reason_text" '{decision:"block", reason:$r}'
exit 0
